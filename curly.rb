require 'rubygems'
require 'uri'
require 'curb'
gem 'activesupport', '>= 2.1'
require 'active_support/basic_object'
require 'hpricot'
require 'iconv'

class Curly < ActiveSupport::BasicObject
  attr_reader :uri
  
  def initialize(uri = nil)
    @curl = Curl::Easy.new
    self.uri = uri
    self.follow_location = true
    yield self if block_given?
  end
  
  def uri=(obj)
    case obj
    when String
      unless @uri
        @uri = URI.parse(obj)
      else
        @uri += obj
      end
    when URI::HTTP
      @uri = obj
    when nil
      return
    else
      raise "unsupported URI type (#{obj.class.name} given)"
    end
    
    self.url = @uri.to_s
  end
  
  def method_missing(method, *args, &block)
    @curl.send(method, *args, &block)
  end
  
  def cookiejar=(filename)
    self.enable_cookies = true
    @curl.cookiejar = filename
  end
  
  def get(uri = nil)
    self.uri = uri
    http_get
    raise "expected 2xx, got #{response_code} (GET #{url})" unless success?
    self
  end
  
  def success?
    response_code >= 200 and response_code < 300
  end
  
  def doc
    Hpricot body_unicode
  end
  
  def body_unicode
    body = body_str
    if body =~ /;\s*charset=([\w-]+)\s*['"]/ and $1.downcase != 'utf-8'
      body = Iconv.conv('UTF-8', $1, body)
    end
    body
  end
  
  def self.get_document(url)
    curl = new(url)
    curl.get
    parse_curl curl
  end
  
  def self.parse_curl(object)
    body = object.body_str
    if body =~ /;\s*charset=([\w-]+)\s*['"]/ and $1.downcase != 'utf-8'
      body = Iconv.conv('UTF-8', $1, body)
    end
    Hpricot(body)
  end
  
  def post(params)
    fields = params.map do |key, value|
      Curl::PostField.content(key.to_s, value.to_s)
    end
    http_post *fields
  end
  
  def self.post(url, params)
    new(url).post(params)
  end
  
  class Form
    def initialize(element)
      @node = element
    end
    
    def elements
      @node.search('input, button, select, textarea')
    end
  end
end

Hpricot::Doc.class_eval do
  def forms
    search('form').map { |f| Curly::Form.new(f) }
  end
end
