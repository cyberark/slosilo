require 'spec_helper'

describe "http request stack" do
  include_context "with example key"
  include_context "with mock adapter"
  before { Slosilo[:own] = key }

  class MockRequest < Hash
    def exec *a
    end
    
    def [] name
      name = name.sub(/^HTTP_/,'').gsub('_', '-').split(/(\W)/).map(&:capitalize).join
      result = super name
    end
    
    def initialize
      extend Slosilo::HTTPRequest
      self['Authorization'] = "Simon says it's fine"
    end
  end
  
  subject { MockRequest.new }
  let(:path) { '/some/path' }

  context "with authorization header" do
    it "works" do
      mw = Slosilo::Rack::Middleware.new lambda{|_|:ok}, signature_required: true
      subject.stub path: path, body: ''
      mw.stub path: path
      subject.send :exec
      mw.call(subject).should == :ok
    end
    
    it "detects tampering" do
      mw = Slosilo::Rack::Middleware.new lambda{|_|:ok}, signature_required: true
      subject.stub path: path, body: ''
      mw.stub path: path
      subject.send :exec
      subject['Authorization'] = "Simon changed his mind"
      mw.call(subject).should_not == :ok
    end
  end
end
