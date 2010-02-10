#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'pg'

# PostgreSQL
conn = PGconn.connect(:dbname => 'glaexp')

# Content types
# http://alicebobandmallory.com/articles/2009/07/31/setting-charset-with-a-before-filter-in-sinatra
CONTENT_TYPES = {:html => 'text/html', :css => 'text/css',
  :js  => 'application/javascript'}

before do
  request_uri = case request.env['REQUEST_URI']
                when /\.css$/ : :css
                when /\.js$/  : :js
                else          :html
                end
  content_type CONTENT_TYPES[request_uri], :charset => 'utf-8'
end

# Helpers

def month(n)
  %w[January February March April May June July August September October November December][n.to_i-1]
end

def pretty_amount(amount)
  one, two = ("%.02f" % (amount.to_i / 100.0)).match(/^(\d+)(\.\d\d)$/)[1..2]
  '£' + one.reverse.gsub(/(...)/,'\1,').reverse + two
end

def render_expenditure(results)
  s = '<ul>'
  results.each do |row|

    values = [pretty_amount(row['amount']), row['expense'], month(row['month']), row['year'], row['supplier']]
    values.map!{|v|CGI.escapeHTML v}
    s << '<li class="expenditure">'
    s << %Q&<span class="amount">%s</span> was spent on <span class="description">%s</span> during <span class="month">%s</span> <span class="year">%d</span>. The supplier was <span class="supplier">%s</span>.& % values

    unless row['doctype'].nil? or row['docno'].nil? or row['date'].nil?
      val = [row['doctype'], row['docno'], row['date']]
      val.map!{|v|CGI.escapeHTML v}
      s << %Q& Some additional information: document type <span class="doctype">%s</span>, document number <span class="docno">%s</span>, date <span class="fulldate">%s<span>.& % val
    end

    s << '</li>'
  end
  s << '</ul>'
  s
end

# Controllers

get '/' do
  if params[:q].nil?
    max = 246969921
    min = 15817263
    raw_amount = rand(max-min).to_i - min
  else
    raw_amount = (params[:q].gsub(',','').to_f * 100).to_i
  end
  amount = pretty_amount(raw_amount)

  title = "What can you buy with #{amount}?"
  doc = <<HERE
<!DOCTYPE html>
<link rel="stylesheet" href="glaexp.css">
<title>#{title}</title>
<h1>What can you buy with £<span class="titular_amount">#{amount[2..-1]}</span><span class="titular_ques">?</span></h1>
HERE

  exact = conn.exec('SELECT * FROM expenditure WHERE amount = %d' % raw_amount);
  highfive = conn.exec('SELECT * FROM expenditure WHERE amount > %d ORDER BY amount ASC LIMIT 5' % raw_amount);
  lowfive = conn.exec('SELECT * FROM expenditure WHERE amount < %d ORDER BY amount DESC LIMIT 5' % raw_amount);

  if exact.to_a.empty?
    moreorless = highfive.to_a.empty? ? 'less' : 'more'
    doc << "<h2>Nothing costs exactly #{amount}. Why not spend a little #{moreorless}?</h2>"
  else
    doc << "<h2>Things costing exactly #{amount}</h2>"
    doc << render_expenditure(exact)
  end

  if lowfive.to_a.empty?
    doc << "<h2>This must be the cheapest thing ever at #{amount}</h2>"
  else
    doc << "<h2>Things costing just under #{amount}</h2>"
    doc << render_expenditure(lowfive)
  end

  if highfive.to_a.empty?
    doc << "<h2>You must have a huge budget! Nothing costs more than #{amount}</h2>"
  else
    doc << "<h2>Things costing just over #{amount}</h2>"
    doc << render_expenditure(highfive)
  end

  doc << '<address>Made in an afternoon by <a href="mailto:tom@thedextrousweb.com">Tom Adams</a> (<a href="http://twitter.com/holizz">@holizz</a> at <a href="http://thedextrousweb.com/">The Dextrous Web</a> using <a href="http://www.sinatrarb.com/">Sinatra</a>.</address>'
  doc << %q&<p class="citation">Data taken from London's Datastore: <a href="http://data.london.gov.uk/datastore/package/expenditure-over-£1000">Expenditure over £1000</a></p>&

  doc << '<script src="jquery-1.4.1.min.js"></script>'
  doc << '<script src="glaexp.js"></script>'

  doc
end
