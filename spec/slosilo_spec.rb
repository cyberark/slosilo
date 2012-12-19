require 'spec_helper'

describe Slosilo do
  include_context "with mock adapter"
  let(:key) { OpenSSL::PKey::RSA.new 512 }
  before { adapter['test'] = key.to_der }
  
  describe '[]' do
    it "returns a Slosilo::Key" do
      Slosilo[:test].should be_instance_of Slosilo::Key
    end
  end
  
  describe '.sign' do
    let(:own_key) { double "own key" }
    before { Slosilo.stub(:[]).with(:own).and_return own_key }
    let (:argument) { double "thing to sign" }
    it "fetches the own key and signs using that" do
      own_key.should_receive(:sign).with(argument)
      Slosilo.sign argument
    end
  end
end
