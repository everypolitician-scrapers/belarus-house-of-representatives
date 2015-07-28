#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('a.d_list/@href').map(&:text).each do |mp_url|
    scrape_person mp_url
  end
end

def scrape_person(url)
  noko = noko_for(url)

  data_table = noko.xpath('.//h1/following-sibling::table[1]')

  data = { 
    id: url[/7508,(\d+)/, 1],
    name: noko.css('h1').text.tidy,
    image: data_table.css('img/@src').text,
    area: data_table.xpath('.//b[contains(.,"constituency")]').text.tidy,
    phone: noko.xpath('.//p[contains(.,"Contact phone")]').text.to_s.split(':', 2).last.to_s.tidy,
    email: noko.xpath('.//p[contains(.,"E-mail")]').text.to_s.split(':', 2).last.to_s.tidy,
    term: '2012',
    source: url,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  data[:area_id] = data[:area][/(\d+)$/, 1]
  puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://house.gov.by/index.php/,7508,,,,1,,,0.html')
