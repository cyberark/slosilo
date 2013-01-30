require 'spec_helper'

describe Slosilo do
  include_context "with mock adapter"
  let(:key) { OpenSSL::PKey::RSA.new 512 }
  before { adapter['test'] = key.to_der }
  
  describe '[]' do
    it "returns a Slosilo::Key" do
      Slosilo[:test].should be_instance_of Slosilo::Key
    end
    
    context "when the requested key does not exist" do
      it "returns nil instead of creating a new key" do
        Slosilo[:aether].should_not be
      end
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
  
  describe '.token_valid?' do
    before { adapter['test'].stub token_valid?: false }
    let(:key2) { double "key 2", token_valid?: false }
    let(:key3) { double "key 3", token_valid?: false }
    before do
      adapter[:key2] = key2
      adapter[:key3] = key3
    end
    
    let(:token) { double "token" }
    subject { Slosilo.token_valid? token }
    
    context "when no key validates the token" do
      before { Slosilo::Key.any_instance.stub token_valid?: false }
      it { should be_false }
    end
    
    context "when a key validates the token" do
      let(:valid_key) { double token_valid?: true }
      let(:invalid_key) { double token_valid?: true }
      before do
        Slosilo::Key.stub new: invalid_key
        Slosilo::Key.stub(:new).with(key2).and_return(valid_key)
      end
      
      it { should be_true }
    end
  end
end
