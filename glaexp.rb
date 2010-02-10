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
  %w[January February March April May June July August September October November December][n-1]
end

def render_expenditure(results)
  s = ''
  results.each do |row|
    s << "<p>%s</p>" % row.inspect
  end
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
  amount = "£%.02f" % (raw_amount / 100.0)

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
