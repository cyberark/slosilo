require 'spec_helper'

describe Slosilo::Keystore do
  include_context "with example key"
  include_context "with mock adapter"
  
  describe '#put' do
    it "handles Slosilo::Keys" do
      subject.put(:test, key)
      adapter['test'].to_der.should == rsa.to_der
    end

    it "passes the Slosilo key to the adapter" do
      adapter.should_receive(:put_key).with "test", key
      subject.put :test, key
    end
  end
end
