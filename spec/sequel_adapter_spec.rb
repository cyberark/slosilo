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

  shared_context "database" do
    let(:db) { Sequel.sqlite }
    before do
      subject.unstub :create_model
      begin
        Sequel::Model.cache_anonymous_models = false
      rescue NoMethodError # sequel 4.0 moved the method
        Sequel.cache_anonymous_models = false
      end
      Sequel::Model.db = db
    end
  end

  shared_context "encryption key" do
    before do
      Slosilo.encryption_key = Slosilo::Symmetric.new.random_key
    end
  end

  context "with old schema" do
    include_context "encryption key"
    include_context "database"

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

  shared_context "current schema" do
    include_context "database"
    before do
      Sequel.extension :migration
      require 'slosilo/adapters/sequel_adapter/migration.rb'
      Sequel::Migration.descendants.first.apply db, :up
    end
  end

  context "with current schema" do
    include_context "encryption key"
    include_context "current schema"
    before do
      subject.put_key 'test', key
    end

    it "supports look up by id" do
      subject.get_key("test").should == key
    end

    it "supports look up by fingerprint" do
      subject.get_by_fingerprint(key.fingerprint).should == [key, 'test']
    end
  end

  context "with an encryption key", :wip do
    include_context "encryption key"
    include_context "current schema"

    it { should be_secure }

    it "saves the keys in encrypted form" do
      subject.put_key 'test', key

      expect(db[:slosilo_keystore][id: 'test'][:key]).to_not eq(key.to_der)
      expect(subject.get_key 'test').to eq(key)
    end
  end

  context "without an encryption key", :wip do
    before do
      Slosilo.encryption_key = nil
    end

    include_context "current schema"

    it { should_not be_secure }

    it "refuses to store a private key" do
      expect { subject.put_key 'test', key }.to raise_error(Slosilo::Error::InsecureKeyStorage)
    end

    it "saves the keys in plaintext form" do
      pkey = key.public
      subject.put_key 'test', pkey

      expect(db[:slosilo_keystore][id: 'test'][:key]).to eq(pkey.to_der)
      expect(subject.get_key 'test').to eq(pkey)
    end
  end
end
