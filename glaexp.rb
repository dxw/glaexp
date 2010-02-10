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
  "£%.02f" % (amount.to_i / 100.0)
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
    raw_amount = (params[:q].to_f * 100).to_i
  end
  amount = pretty_amount(raw_amount)

  title = "What can you buy with #{amount}?"
  doc = <<HERE
<!DOCTYPE html>
<title>#{title}</title>
<h1>#{title}</h1>
HERE

  exact = conn.exec('SELECT * FROM expenditure WHERE amount = %d' % raw_amount);
  highfive = conn.exec('SELECT * FROM expenditure WHERE amount > %d ORDER BY amount ASC LIMIT 5' % raw_amount);
  lowfive = conn.exec('SELECT * FROM expenditure WHERE amount < %d ORDER BY amount DESC LIMIT 5' % raw_amount);

  doc << "<h2>Things costing exactly #{amount}</h2>"
  doc << render_expenditure(exact)

  doc << "<h2>Things costing just under #{amount}</h2>"
  doc << render_expenditure(lowfive)

  doc << "<h2>Things costing just over #{amount}</h2>"
  doc << render_expenditure(highfive)

  doc
end
