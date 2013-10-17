require 'spec_helper'

describe Slosilo::Key do
  include_context "with example key"
  
  subject { key }
  its(:to_der) { should == rsa.to_der }
  its(:to_s) { should == rsa.public_key.to_pem }
  its(:fingerprint) { should == key_fingerprint }

  context "with identical key" do
    let(:other) { Slosilo::Key.new rsa.to_der }
    it "is equal" do
      subject.should == other
    end

    it "is eql?" do
      subject.eql?(other).should be_true
    end

    it "has equal hash" do
      subject.hash.should == other.hash
    end
  end
  
  context "with a different key" do
    let(:other) { Slosilo::Key.new another_rsa }
    it "is not equal" do
      subject.should_not == other
    end

    it "is not eql?" do
      subject.eql?(other).should_not be_true
    end

    it "has different hash" do
      subject.hash.should_not == other.hash
    end
  end

  let(:plaintext) { 'quick brown fox jumped over the lazy dog' }
  describe '#encrypt' do
    it "generates a symmetric encryption key and encrypts the plaintext with the public key" do
      ctxt, skey = subject.encrypt plaintext
      pskey = rsa.private_decrypt skey
      Slosilo::Symmetric.new.decrypt(ctxt, key: pskey).should == plaintext
    end
  end

  describe '#encrypt_message' do
    it "#encrypts a message and then returns the result as a single string" do
      subject.should_receive(:encrypt).with(plaintext).and_return ['fake ciphertext', 'fake key']
      subject.encrypt_message(plaintext).should == 'fake keyfake ciphertext'
    end
  end
  
  let(:ciphertext) { "\x8B\xE6\xEC\x8C\xAB\xA4\xC0\x8EF\"\x0F\xD5Yh\xA1\aq\x00\xF5\xAC\xAB\v\a\xEC\xF6G\xA6\e\x14N\xFF\x11\x98\xDA\x19\xB5\x8994_:\xA0\xF8\x06l\xDC\x9B\xB1\xE8z\x83\xCC\x9A\x02E\x02tOhu\x92F]h".force_encoding("ASCII-8BIT") }
  let(:skey) { "\x15\xFF\xD4>\x9C\xF4\x0F\xB6\x04C\x18\xC1\x96\xC3\xE0T\xA3\xF5\xE8\x17\xA6\xE0\x86~rrw\xC3\xDF\x11)$\x9B\r@\x0E\xE4Zv\rw-\xFC\x1C\x84\x17\xBD\xDB\x12u\xCD\r\xFEo\xD5\xC8[\x8FEA\\\xA9\xA2F#\x8BH -\xFA\xF7\xA9\xEBf\x97\xAAT}\x8E*\xC0r\x944p\xD0\x9A\xE7\xBD\a;O\f\xEF\xE4B.y\xFA\xB4e@O\xBB\x15>y\xC9\t=\x01\xE1J\xF3X\xA9\x9E3\x04^H\x1F\xFF\x19C\x93ve)@\xF7\t_\xCF\xDE\xF1\xB7]\x83lL\xB8%A\x93p{\xE9Y\xBAu\xCE\x99T\xDC\xDF\xE7\x0FD%\xB9AXb\x1CW\x94$P\xBB\xE1g\xDEE\t\xC4\x92\x9E\xFEt\xDF\xD0\xEA\x03\xC4\x12\xA9\x02~u\xF4\x92 ;\xA0\xCE.\b+)\x05\xEDo\xA5cF\xF8\x12\xD7F\x97\xE44\xBF\xF1@\xA5\xC5\xA8\xE5\a\xE8ra<\x04\xB5\xA2\f\t\xF7T\x97\e\xF5(^\xAB\xA5%84\x10\xD1\x13e<\xCA/\xBF}%\xF6\xB1%\xB2".force_encoding("ASCII-8BIT") }
  describe '#decrypt' do
    it "decrypts the symmetric key and then uses it to decrypt the ciphertext" do
      subject.decrypt(ciphertext, skey).should == plaintext
    end
  end
  
  describe '#decrypt_message' do
    it "splits the message into key and rest, then #decrypts it" do
      subject.should_receive(:decrypt).with(ciphertext, skey).and_return plaintext
      subject.decrypt_message(skey + ciphertext).should == plaintext
    end
  end

  describe '#initialize' do
    context "when no argument given" do
      subject { Slosilo::Key.new }
      let (:rsa) { double "key" }
      it "generates a new key pair" do
        OpenSSL::PKey::RSA.should_receive(:new).with(2048).and_return(rsa)
        subject.key.should == rsa
      end
    end
    context "when given an armored key" do
      subject { Slosilo::Key.new rsa.to_der }
      its(:to_der) { should == rsa.to_der }
    end
    context "when given a key instance" do
      subject { Slosilo::Key.new rsa }
      its(:to_der) { should == rsa.to_der }
    end
    context "when given something else" do
      subject { Slosilo::Key.new "foo" }
      it "fails early" do
        expect { subject }.to raise_error
      end
    end
  end
  
  describe "#sign" do
    context "when given a hash" do
      it "converts to a sorted array and signs that" do
        key.should_receive(:sign_string).with '[["a",3],["b",42]]'
        key.sign b: 42, a: 3
      end
    end
    context "when given an array" do
      it "signs a JSON representation instead" do
        key.should_receive(:sign_string).with '[2,[42,2]]'
        key.sign [2, [42, 2]]
      end
    end
    context "when given a string" do
      let(:expected_signature) { "d[\xA4\x00\x02\xC5\x17\xF5P\x1AD\x91\xF9\xC1\x00P\x0EG\x14,IN\xDE\x17\xE1\xA2a\xCC\xABR\x99'\xB0A\xF5~\x93M/\x95-B\xB1\xB6\x92!\x1E\xEA\x9C\v\xC2O\xA8\x91\x1C\xF9\x11\x92a\xBFxm-\x93\x9C\xBBoM\x92%\xA9\xD06$\xC1\xBC.`\xF8\x03J\x16\xE1\xB0c\xDD\xBF\xB0\xAA\xD7\xD4\xF4\xFC\e*\xAB\x13A%-\xD3\t\xA5R\x18\x01let6\xC8\xE9\"\x7F6O\xC7p\x82\xAB\x04J(IY\xAA]b\xA4'\xD6\x873`\xAB\x13\x95g\x9C\x17\xCAB\xF8\xB9\x85B:^\xC5XY^\x03\xEA\xB6V\x17b2\xCA\xF5\xD6\xD4\xD2\xE3u\x11\xECQ\x0Fb\x14\xE2\x04\xE1<a\xC5\x01eW-\x15\x01X\x81K\x1A\xE5A\vVj\xBF\xFC\xFE#\xD5\x93y\x16\xDC\xB4\x8C\xF0\x02Y\xA8\x87i\x01qC\xA7#\xE8\f\xA5\xF0c\xDEJ\xB0\xDB BJ\x87\xA4\xB0\x92\x80\x03\x95\xEE\xE9\xB8K\xC0\xE3JbE-\xD4\xCBP\\\x13S\"\eZ\xE1\x93\xFDa pinch of salt".force_encoding("ASCII-8BIT") }
      it "signs it" do
        key.stub salt: 'a pinch of salt'
        key.sign("this sentence is not this sentence").should == expected_signature
      end
    end
  end
  
  describe "#signed_token" do
    let(:time) { Time.new(2012,1,1,1,1,1,0).utc }
    let(:expiration){ time + 8 * 60 }
    let(:expiration_option){ nil }
    let(:data) { { "foo" => :bar } }
    let(:token_to_sign) { { "data" => data, "timestamp" => time.to_s, "expiration" => expiration.ergo(&:to_s) }.compact }
    let(:signature){ "signature" }
    let(:expected_signature) { Base64::urlsafe_encode64 signature }
    let(:expected_token){ token_to_sign.merge "signature" => expected_signature, "key" => key_fingerprint }
    
    before do
      key.should_receive(:sign).with(token_to_sign).and_return signature
      key.stub current_time: time
    end
    
    subject { key.signed_token data, expiration: expiration_option }
    it { should == expected_token }
    
    context "when given an expiration option" do
      context "as a Time" do
        let(:expiration){ time + 2 * 60 }
        let(:expiration_option){ expiration }
        it { should == expected_token }
      end
      context "as a duration in seconds" do
        let(:expiration_option){ 18 * 60 }
        let(:expiration){ time + expiration_option }
        it{ should == expected_token }
      end
      context "when false" do
        let(:expiration_option){ false }
        let(:expiration){ nil }
        it{ should == expected_token }
        it "does not include an expiration field" do
          subject.should_not include "expiration"
        end
      end
    end
  end
  
  describe "#token_expired?" do
    let(:now){ Time.new(2013,1,1,1,1,1,0).utc }
    let(:expiry_arg){ nil }
    let(:expiration){ nil }
    let(:timestamp){ nil }
    let(:token){ Hash[{"timestamp" => timestamp,
                  "expiration" => expiration}.reject{|k,v| v.nil?}.map{|k,v| [k,v.utc.to_s]}] }
    
    before do
      key.stub current_time: now
    end
    
    subject{ key.token_expired? *[token, expiry_arg].compact }
    
    context "when token contains an expiration field" do
      context "of 6 minutes ago" do
        let(:expiration){ now - 6 * 60 }
        it{ should be_true }
        context "when an expiry is given" do
          let(:expiry_arg){ 200 * 60 }
          it("it is ignored"){ should be_true }
        end
      end
      context "of 1 minute from now" do
        let(:expiration){ now + 60 }
        it{ should be_false }
        context "when an expiry arg is given" do
          let(:expiry_arg){ 10 }
          it("is ignored"){ should be_false }
        end
      end
    end
    
    context "when token does not contain an expiration" do
      context "when timestamp is 3 minutes ago" do
        let(:timestamp){ now - 180 }
        it{ should be_false }
        context "when expiry arg is 10 seconds" do
          let(:expiry_arg){ 10 }
          it{ should be_true }
        end
        context "when expiry arg is 4 minutes" do
          let(:expiry_arg){ 240 }
          it{ should be_false }
        end
      end
      
      context "when timestamp is 10 minutes ago" do
        let(:timestamp){ now - 600 }
        it{ should be_true }
        context "when expiry arg is 15 minutes" do
          let(:expiry_arg){ 15 * 60 }
          it{ should be_false }
        end
      end
      
    end
  end
  
  describe "#token_valid?" do
    let(:data) { { "foo" => :bar } }
    let(:now){ Time.new(2013,1,1,1,1,1,0).utc }
    let(:timestamp){ now }
    let(:expiration){ timestamp.ergo{ |t| t + 8 * 60 } }
    let(:unsigned_token){ { "data" => data, "timestamp" => timestamp.ergo(&:to_s), "expiration" => expiration.ergo(&:to_s) }.compact }
    let(:raw_signature){ key.sign unsigned_token }
    let(:signature){ Base64.urlsafe_encode64(raw_signature) }
    let(:token){ unsigned_token.merge "signature" => signature }
    
    before { 
      key.stub current_time: now
    }
    
    subject { key.token_valid? token }
    it { should be_true }
    
    it "calls #token_expired? with the token and expiry" do
      key.should_receive(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return false, true
      key.token_valid?(token).should be_true
      key.token_valid?(token).should be_false
    end
    
    context "when #token_expired? returns false" do
      before{ key.stub(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return false }
      it{ should be_true }
    end
    
    context "when #token_expired? returns true" do
      before{ key.stub(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return true }
      it{ should be_false }
    end
    
    it "doesn't check signature on the advisory key field" do
      key.token_valid?(token.merge "key" => key_fingerprint).should be_true
    end
    
    it "rejects the token if the key field is present and doesn't match" do
      key.token_valid?(token.merge "key" => "this is not the key you are looking for").should_not be_true
    end
    
    context "when token is 5 minutes old" do
      before{ key.stub current_time: now + 60 * 5 }
      it{should be_true }
      context "when the token expiration is 3 minutes from now" do
        let(:expiration){ now + 3 * 60 }
        it{ should be_false }
      end
    end
    
    context "when token is 1 hour old" do
      let(:later){ now + 60 * 60 }
      before { key.stub current_time: later }
      it { should be_false }
      context "when timestamp in the token is changed accordingly" do
        let(:messed_with_token) { token.merge("timestamp" => later.to_s) }
        it "should not be valid" do 
          key.token_valid?(messed_with_token).should be_false
        end
      end
      context "when expiration in the token is changed accordingly" do
        let(:messed_with_token){ token.merge("expiration" => (later + 120).to_s) }
        it "should not be valid" do
          key.token_valid?(messed_with_token).should be_false
        end
      end
    end
    
    context "when expiration is not present" do
      let(:expiration){ nil }
      let(:timestamp){ now + 8 * 60 }
      it{ should be_true }
    end
    
    context "when the data is changed" do
      let(:messed_with_token) { token.merge("data" => { "foo" => :baz }) }
      it "is not valid" do
        key.token_valid?(messed_with_token).should be_false
      end
    end
    context "when RSA decrypt raises an error" do
      before { OpenSSL::PKey::RSA.any_instance.should_receive(:public_decrypt).and_raise(OpenSSL::PKey::RSAError) }
      it { should be_false }
    end
  end
end
