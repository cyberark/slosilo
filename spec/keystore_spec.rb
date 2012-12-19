require 'spec_helper'

describe Slosilo::Keystore do
  include_context "with example key"
  include_context "with mock adapter"
  
  describe '#put' do
    it "handles Slosilo::Keys too" do
      subject.put(:test, key)
      adapter['test'].should == rsa.to_der
    end
  end
end
