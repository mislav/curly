require 'rubygems'
require 'curb'
gem 'activesupport', '>= 2.1'
require 'active_support/basic_object'
require 'hpricot'

class Curly < ActiveSupport::BasicObject
  def initialize(url = nil)
    @curl = Curl::Easy.new(url)
    self.follow_location = true
    yield self if block_given?
  end
  
  def method_missing(method, *args, &block)
    @curl.send(method, *args, &block)
  end
  
  def cookiejar=(filename)
    self.enable_cookies = true
    @curl.cookiejar = filename
  end
  
  def get
    http_get
  end
  
  def self.get_document(url)
    curl = new(url)
    curl.get
    parse_curl curl
  end
  
  def self.parse_curl(object)
    Hpricot(object.body_str)
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
