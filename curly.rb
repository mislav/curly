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

if $0 == __FILE__
  require 'spec'
  
  describe Curly do
    before do
      @curly = Curly.new
    end
    
    it "should enable cookies when cookiejar is set" do
      @curly.enable_cookies?.should == false
      @curly.cookiejar = 'foo'
      @curly.enable_cookies?.should == true
    end
    
    it "should post params hash" do
      field_arg = an_instance_of(Curl::PostField)
      @curly.should_receive(:http_post).with(field_arg, field_arg)
      @curly.post(:foo => 'bar', :baz => 'foo')
    end
  end
  
  describe Curly, "class methods" do
    it "should post" do
      curly = mock('Curly')
      Curly.should_receive(:new).with('example.com').and_return(curly)
      curly.should_receive(:post).with(:foo => 'bar')
      
      Curly.post('example.com', :foo => 'bar')
    end
    
    it "should get document" do
      curly = mock('Curly')
      Curly.should_receive(:new).with('example.com').and_return(curly)
      curly.should_receive(:get).with().and_return(true)
      curly.should_receive(:body_str).and_return("<html><body>You are being <a href=\"http://localhost:3000/login\">redirected</a>.</body></html>")
      
      doc = Curly.get_document('example.com')
      doc.class.should == Hpricot::Doc
      doc.at('a[@href]').inner_text.should == 'redirected'
    end
  end
end