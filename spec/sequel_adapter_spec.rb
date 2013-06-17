require 'spec_helper'

require 'slosilo/adapters/sequel_adapter'

describe Slosilo::Adapters::SequelAdapter do
  include_context "with example key"

  let(:model) { double "model" }
  before { subject.stub create_model: model }
  
  describe "#get_key" do
    context "when given key does not exist" do
      before { model.stub :[] => nil }
      it "returns nil" do
        subject.get_key(:whatever).should_not be
      end
    end

    context "when it exists" do
      let(:id) { "id" }
      before { model.stub(:[]).with(id).and_return (double "key entry", id: id, key: rsa.to_der) }
      it "returns it" do
        subject.get_key(id).should == key
      end
    end
  end
  
  describe "#put_key" do
    let(:id) { "id" }
    it "creates the key" do
      model.should_receive(:create).with id: id, key: key.to_der
      subject.put_key id, key
    end
  end
  
  let(:adapter) { subject }
  describe "#each" do
    let(:one) { double("one", id: :one, key: :onek) }
    let(:two) { double("two", id: :two, key: :twok) }
    before { model.stub(:each).and_yield(one).and_yield(two) }
    
    it "iterates over each key" do
      results = []
      Slosilo::Key.stub(:new) {|x|x}
      adapter.each { |id,k| results << { id => k } }
      results.should == [ { one: :onek}, {two: :twok } ]
    end
  end
  
  describe '#model' do
    let(:db) { Sequel.sqlite }
    before do
      Slosilo::encryption_key = Slosilo::Symmetric.new.random_key
      subject.unstub :create_model
      require 'sequel'
      Sequel::Model.db = db
      Sequel.extension :migration
      require 'slosilo/adapters/sequel_adapter/migration'
      Sequel::Migration::descendants.first.apply db, :up
    end
      
    let(:key) { 'fake key' }
    let(:id) { 'some id' }
    it "transforms (encrypts) the key" do
      subject.model.create id: id, key: key
      db[:slosilo_keystore][id: id][:key].should_not == key
      subject.model[id].key.should == key
    end
  end
end
