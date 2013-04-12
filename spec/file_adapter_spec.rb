require 'spec_helper'

require 'slosilo/adapters/file_adapter'

describe Slosilo::Adapters::FileAdapter do
  let(:dir) {
    require 'tmpdir' 
    Dir.mktmpdir 
  }
  let(:adapter) { Slosilo::Adapters::FileAdapter.new dir }
  subject { adapter }
  
  describe "#get_key" do
    context "when given key does not exist" do
      it "returns nil" do
        subject.get_key(:whatever).should_not be
      end
    end
  end
  
  describe "#put_key" do
    let(:key) { "key" }
    context "unacceptable id" do
      let(:id) { "foo.bar" }
      it "isn't accepted" do
        lambda { subject.put_key id, key }.should raise_error
      end    
    end
    context "acceptable id" do
      let(:id) { "id" }
      let(:key_encrypted) { "encrypted key" }
      let(:fname) { "#{dir}/#{id}.key" }
      it "creates the key" do
        Slosilo::EncryptedAttributes.should_receive(:encrypt).with(key).and_return key_encrypted
        File.should_receive(:write).with(fname, key_encrypted)
        File.should_receive(:chmod).with(0400, fname)
        subject.put_key id, key
        subject.instance_variable_get("@keys")[id].should == key
      end    
    end
  end
  
  describe "#each" do
    before { adapter.instance_variable_set("@keys", one: :onek, two: :twok) }
    
    it "iterates over each key" do
      results = []
      adapter.each { |id,k| results << { id => k } }
      results.should == [ { one: :onek}, {two: :twok } ]
    end
  end
  
  describe 'key store' do
    let(:key) { 'fake key' }
    let(:id) { 'some id' }

    before do
      Slosilo::encryption_key = Slosilo::Symmetric.new.random_key
      pre_adapter = Slosilo::Adapters::FileAdapter.new dir
      pre_adapter.put_key(id, key)
    end
      
    it "loads and decrypts the key" do
      adapter.get_key(id).should == key
    end
    it "enumerates the keys" do
      results = []
      adapter.each { |id,k| results << { id => k } }
      results.should == [ { id => key } ]
    end
  end
end
