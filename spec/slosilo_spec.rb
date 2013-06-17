require 'spec_helper'

describe Slosilo do
  include_context "with mock adapter"
  include_context "with example key"
  before { Slosilo['test'] = key }
  
  describe '[]' do
    it "returns a Slosilo::Key" do
      Slosilo[:test].should be_instance_of Slosilo::Key
    end

    it "allows looking up by fingerprint" do
      Slosilo[fingerprint: key_fingerprint].should == key
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
      before { Slosilo::Key.stub new: (double "key", token_valid?: false) }
      it { should be_false }
    end
    
    context "when a key validates the token" do
      let(:valid_key) { double token_valid?: true }
      let(:invalid_key) { double token_valid?: true }
      before do
        Slosilo::Key.stub new: invalid_key
        adapter[:key2] = valid_key
      end
      
      it { should be_true }
    end
  end
  
  describe '.token_signer' do
    let(:token) { double "token" }
    let(:key_one) { double "key", token_valid?: false }
    let(:other_key) { double "another key", token_valid?: false }
    
    before do
      subject.stub(:each).and_yield('test', key_one).and_yield('other', other_key)
    end
    
    it "returns nil when token doesn't have a valid signature from any known key" do
      subject.token_signer(token).should_not be
    end
    
    it "returns the name of the key which validates the token" do
      other_key.stub(:token_valid?).with(token).and_return true
      subject.token_signer(token).to_s.should == 'other'
    end
  end
end
