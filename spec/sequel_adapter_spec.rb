require 'spec_helper'
require 'sequel'
require 'io_helper'

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
      model.stub columns: [:id, :key]
      subject.put_key id, key
    end

    it "adds the fingerprint if feasible" do
      model.should_receive(:create).with id: id, key: key.to_der, fingerprint: key.fingerprint
      model.stub columns: [:id, :key, :fingerprint]
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

  context do
    let(:db) { Sequel.sqlite }
    before do
      Slosilo::encryption_key = Slosilo::Symmetric.new.random_key
      subject.unstub :create_model
      begin
        Sequel::Model.cache_anonymous_models = false
      rescue NoMethodError # sequel 4.0 moved the method
        Sequel.cache_anonymous_models = false
      end
      Sequel::Model.db = db
    end

    context "with old schema" do
      before do
        db.create_table :slosilo_keystore do
          String :id, primary_key: true
          bytea :key, null: false
        end
        subject.put_key 'test', key
      end

      context "after migration" do
        before { subject.migrate! }

        it "supports look up by id" do
          subject.get_key("test").should == key
        end

        it "supports look up by fingerprint, without a warning" do
          STDERR.grab do
            subject.get_by_fingerprint(key.fingerprint).should == [key, 'test']
          end.should be_empty
        end
      end

      it "supports look up by id" do
        subject.get_key("test").should == key
      end

      it "supports look up by fingerprint, but issues a warning" do
        STDERR.grab do
          subject.get_by_fingerprint(key.fingerprint).should == [key, 'test']
        end.should_not be_empty
      end
    end

    context "with current schema" do
      before do
        Sequel.extension :migration
        require 'slosilo/adapters/sequel_adapter/migration.rb'
        Sequel::Migration::descendants.first.apply db, :up
        subject.put_key 'test', key
      end


      it "supports look up by id" do
        subject.get_key("test").should == key
      end

      it "supports look up by fingerprint" do
        subject.get_by_fingerprint(key.fingerprint).should == [key, 'test']
      end
    end
  end
end
