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