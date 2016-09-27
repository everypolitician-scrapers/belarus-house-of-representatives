#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def birth_date(text)
  return unless text
  Date.parse(text).to_s
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('a.d_list/@href').each do |mp_url|
    # the mp page only has the shortened version of this
    area = mp_url.xpath('../../following-sibling::td[2]').text
    scrape_person mp_url.text, area
  end
end

def scrape_person(url, area)
  noko = noko_for(url)

  data_table = noko.xpath('.//h1/following-sibling::table[1]')
  area.sub!(/ number /, ' no. ')
  raise "bad area: #{area}" unless res = area.match(/(.*) No.\s*(\d+)\s*\((.*)\)/i)
  constituency, constituency_id, region = res.captures

  data = { 
    id: url[/7508,(\d+)/, 1],
    name: noko.css('h1').text.tidy,
    image: data_table.css('img/@src').text,
    constituency: constituency,
    region: region,
    area: area,
    area_id: constituency_id,
    phone: noko.xpath('.//p[contains(.,"Contact phone")]').text.to_s.split(':', 2).last.to_s.tidy,
    party: '',
    email: noko.xpath('.//p[contains(.,"E-mail")]').text.to_s.split(':', 2).last.to_s.split(',').first.to_s.gsub(' ',''),
    birth_date: birth_date(noko.xpath('.//p[contains(.,"Born on")]').text.to_s[/Born on (\w+ \d+, \d+)/, 1]),
    term: '5',
    source: url,
  }
  data[:image] = URI.join('http://house.gov.by/', data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://house.gov.by/index.php/,7508,,,,1,,,0.html')
