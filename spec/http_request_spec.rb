require 'spec_helper'

describe Slosilo::HTTPRequest do
  let(:keyname) { :bacon }
  let(:encrypt) { subject.encrypt! }
  subject { Hash.new }
  before do 
    subject.extend Slosilo::HTTPRequest
    subject.keyname = keyname
  end
  
  describe "#sign!" do
    let(:own_key) { double "own key" }
    before { Slosilo.stub(:[]).with(:own).and_return own_key }
    
    let(:signed_data) { "this is the truest truth" }
    before { subject.stub signed_data: signed_data }
    let(:timestamp) { "long time ago" }
    let(:signature) { "seal of approval" }
    let(:token) { { "data" => signed_data, "timestamp" => timestamp, "signature" => signature } }
    
    it "makes a token out of the data to sign and inserts headers" do
      own_key.stub(:signed_token).with(signed_data, expiration: false).and_return token
      subject.should_receive(:[]=).with 'Timestamp', timestamp
      subject.should_receive(:[]=).with 'X-Slosilo-Signature', signature
      subject.sign!
    end
  end
  
  describe "#signed_data" do
    before { subject.stub path: :path, body: 'body' }
    context "when X-Slosilo-Key not present" do
      its(:signed_data) { should == { "path" => :path, "body" => "Ym9keQ==" } }
    end
    
    context "when X-Slosilo-Key is present" do
      before { subject.merge! 'X-Slosilo-Key' => :key } 
      its(:signed_data) { should == { "path" => :path, "body" => "Ym9keQ==", "key" => :key } }
    end
  end
  
  describe "#encrypt!" do
    context "when key not set" do
      before { subject.keyname = nil }
      it "does nothing" do
        subject.should_not_receive(:body=)
        encrypt
      end
    end
    
    context "when requested key does not exist" do
      before { Slosilo.stub(:[]).and_return nil }
      it "raises error" do
        expect{ encrypt }.to raise_error
      end
    end
    
    context "when the key exists" do
      let(:key) { double "key" }
      context "when the body is not empty" do
        let(:plaintext) { "Keep your solutions close, and your problems closer." }
        let(:ciphertext) { "And, when you want something, all the universe conspires in helping you to achieve it." }
        let(:skey) { "make me sound like a fool instead" }
        before do 
          subject.stub body: plaintext
          key.stub(:encrypt).with(plaintext).and_return([ciphertext, skey])
          Slosilo.stub(:[]).with(keyname).and_return key
        end
        
        it "encrypts the message body and adds the X-Slosilo-Key header" do
          subject.should_receive(:body=).with ciphertext
          subject.should_receive(:[]=).with 'X-Slosilo-Key', Base64::urlsafe_encode64(skey)
          encrypt
        end
      end
      
      context "when the body is empty" do
        before { subject.stub body: "" }
        it "doesn't set the key header" do
          subject.should_not_receive(:[]=).with 'X-Slosilo-Key'
          encrypt
        end
      end
    end
  end
  
  describe "#exec" do
    class Subject
      def exec *a
        "ok, got it"
      end

      def initialize keyname
        extend Slosilo::HTTPRequest
        self.keyname = keyname
      end
    end
    
    subject { Subject.new keyname }

    it "encrypts, then signs and delegates to the superclass" do
      subject.should_receive(:encrypt!).once.ordered
      subject.should_receive(:sign!).once.ordered
      subject.exec(:foo).should == "ok, got it"
    end
  end
end
