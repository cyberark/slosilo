require 'spec_helper'

describe Slosilo::Key do
  include_context "with example key"
  
  subject { key }

  describe '#to_der' do
    subject { super().to_der }
    it { is_expected.to eq(rsa.to_der) }
  end

  describe '#to_s' do
    subject { super().to_s }
    it { is_expected.to eq(rsa.public_key.to_pem) }
  end

  describe '#fingerprint' do
    subject { super().fingerprint }
    it { is_expected.to eq(key_fingerprint) }
  end
  it { is_expected.to be_private }

  context "with identical key" do
    let(:other) { Slosilo::Key.new rsa.to_der }
    it "is equal" do
      expect(subject).to eq(other)
    end

    it "is eql?" do
      expect(subject.eql?(other)).to be_truthy
    end

    it "has equal hash" do
      expect(subject.hash).to eq(other.hash)
    end
  end
  
  context "with a different key" do
    let(:other) { Slosilo::Key.new another_rsa }
    it "is not equal" do
      expect(subject).not_to eq(other)
    end

    it "is not eql?" do
      expect(subject.eql?(other)).not_to be_truthy
    end

    it "has different hash" do
      expect(subject.hash).not_to eq(other.hash)
    end
  end

  describe '#public' do
    it "returns a key with just the public half" do
      pkey = subject.public
      expect(pkey).to be_a(Slosilo::Key)
      expect(pkey).to_not be_private
      expect(pkey.key).to_not be_private
      expect(pkey.to_der).to eq(rsa.public_key.to_der)
    end
  end

  let(:plaintext) { 'quick brown fox jumped over the lazy dog' }
  describe '#encrypt' do
    it "generates a symmetric encryption key and encrypts the plaintext with the public key" do
      ctxt, skey = subject.encrypt plaintext
      pskey = rsa.private_decrypt skey, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      expect(Slosilo::Symmetric.new.decrypt(ctxt, key: pskey)).to eq(plaintext)
    end
  end

  describe '#encrypt_message' do
    it "#encrypts a message and then returns the result as a single string" do
      expect(subject).to receive(:encrypt).with(plaintext).and_return ['fake ciphertext', 'fake key']
      expect(subject.encrypt_message(plaintext)).to eq('fake keyfake ciphertext')
    end
  end
  
  let(:ciphertext){ "G\xAD^\x17\x11\xBBQ9-b\x14\xF6\x92#Q0x\xF4\xAD\x1A\x92\xC3VZW\x89\x8E\x8Fg\x93\x05B\xF8\xD6O\xCFGCTp\b~\x916\xA3\x9AN\x8D\x961\x1F\xA3mSf&\xAD\xA77/]z\xA89\x01\xA7\xA9\x92\f".force_encoding('ASCII-8BIT') }
  let(:skey){  "\xA6H\xC7\xC6\xFE\xD7!\xD2\xDA\xAE\xD4;\xA9\nH\xB24\t\xEAW\xDB\xCFvV!\xD1\x03\xEA\xAA\x84_\x03;\xF2\x13+#km\x06\x0E\xF4\xA7\xD1\xE2\xAE\xD4\x00\xF2\xEAx\x03~\x04\xBA\xCB\xB8\xA9\x13\xF5\xA13\xBE\xCF\xD9\xF2=\x8C3Y\x16%8\n\xC4\xCA\xC3Z:A\xE0l\x9D#\xCE\xCB\x11\xEAW\xA1\x89\xD4\xF1\xBAdN\xE2\xDD\x13x\xD4\x9B\xFA\xFF\x8E\x80\xF6\xA1Y\vDu2\xBD\x7F\xFD\xEC\x1D\x9BP^\a\v+o\xB5z\xADJPTC\xC0\xAA\xEFV\x0E2'\x8F\xB7)mF\xB7\x06\xCE\xF3\xC7\"\xD0\x81\xFE\x83\x990!\x1E@\xF2\x96=\xD9I\xB8=&\x85\x88\xCE\x9E\x15\x03X#|\b\xE6\xD4\xCC[29\x13\x99\xE7[X\xD0F\x1AT+\x02s\x84\xEC\nB\x1D\x1C|\xA8\x10\xC6\xAF\xC8\xED\x17\xBE\xA5i\xEA\x16\xCB\xF5\x14\x1E\xE3\x04\xC7\xCF\x18W\x01\xDA\x93u\x9C(\x13!\x85w\xEF\x98otHU#\xDA\x858\xE6%\xAC\xE6\x97\xA4\xC9\xC8\xFE\xC0J\x15".force_encoding('ASCII-8BIT') }
  describe '#decrypt' do
    it "decrypts the symmetric key and then uses it to decrypt the ciphertext" do
      expect(subject.decrypt(ciphertext, skey)).to eq(plaintext)
    end
  end
  
  describe '#decrypt_message' do
    it "splits the message into key and rest, then #decrypts it" do
      expect(subject).to receive(:decrypt).with(ciphertext, skey).and_return plaintext
      expect(subject.decrypt_message(skey + ciphertext)).to eq(plaintext)
    end
  end

  describe '#initialize' do
    context "when no argument given" do
      subject { Slosilo::Key.new }
      let (:rsa) { double "key" }
      it "generates a new key pair" do
        expect(OpenSSL::PKey::RSA).to receive(:new).with(2048).and_return(rsa)
        expect(subject.key).to eq(rsa)
      end
    end
    context "when given an armored key" do
      subject { Slosilo::Key.new rsa.to_der }

      describe '#to_der' do
        subject { super().to_der }
        it { is_expected.to eq(rsa.to_der) }
      end
    end
    context "when given a key instance" do
      subject { Slosilo::Key.new rsa }

      describe '#to_der' do
        subject { super().to_der }
        it { is_expected.to eq(rsa.to_der) }
      end
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
        expect(key).to receive(:sign_string).with '[["a",3],["b",42]]'
        key.sign b: 42, a: 3
      end
    end
    context "when given an array" do
      it "signs a JSON representation instead" do
        expect(key).to receive(:sign_string).with '[2,[42,2]]'
        key.sign [2, [42, 2]]
      end
    end
    context "when given a string" do
      let(:expected_signature) { "d[\xA4\x00\x02\xC5\x17\xF5P\x1AD\x91\xF9\xC1\x00P\x0EG\x14,IN\xDE\x17\xE1\xA2a\xCC\xABR\x99'\xB0A\xF5~\x93M/\x95-B\xB1\xB6\x92!\x1E\xEA\x9C\v\xC2O\xA8\x91\x1C\xF9\x11\x92a\xBFxm-\x93\x9C\xBBoM\x92%\xA9\xD06$\xC1\xBC.`\xF8\x03J\x16\xE1\xB0c\xDD\xBF\xB0\xAA\xD7\xD4\xF4\xFC\e*\xAB\x13A%-\xD3\t\xA5R\x18\x01let6\xC8\xE9\"\x7F6O\xC7p\x82\xAB\x04J(IY\xAA]b\xA4'\xD6\x873`\xAB\x13\x95g\x9C\x17\xCAB\xF8\xB9\x85B:^\xC5XY^\x03\xEA\xB6V\x17b2\xCA\xF5\xD6\xD4\xD2\xE3u\x11\xECQ\x0Fb\x14\xE2\x04\xE1<a\xC5\x01eW-\x15\x01X\x81K\x1A\xE5A\vVj\xBF\xFC\xFE#\xD5\x93y\x16\xDC\xB4\x8C\xF0\x02Y\xA8\x87i\x01qC\xA7#\xE8\f\xA5\xF0c\xDEJ\xB0\xDB BJ\x87\xA4\xB0\x92\x80\x03\x95\xEE\xE9\xB8K\xC0\xE3JbE-\xD4\xCBP\\\x13S\"\eZ\xE1\x93\xFDa pinch of salt".force_encoding("ASCII-8BIT") }
      it "signs it" do
        allow(key).to receive_messages shake_salt: 'a pinch of salt'
        expect(key.sign("this sentence is not this sentence")).to eq(expected_signature)
      end
    end
  end
  
  describe "#signed_token" do
    let(:time) { Time.new(2012,1,1,1,1,1,0).utc }
    let(:expiration){ time + 8 * 60 }
    let(:expiration_option){ nil }
    let(:data) { { "foo" => :bar } }
    let(:token_to_sign) { { "data" => data, "timestamp" => time.to_s, "expiration" => expiration.ergo(&:to_s), "key" => key_fingerprint }.compact }
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
        it{ should be_truthy }
        context "when an expiry is given" do
          let(:expiry_arg){ 200 * 60 }
          it("it is ignored"){ should be_truthy }
        end
      end
      context "of 1 minute from now" do
        let(:expiration){ now + 60 }
        it{ should be_falsey }
        context "when an expiry arg is given" do
          let(:expiry_arg){ 10 }
          it("is ignored"){ should be_falsey }
        end
      end
    end
    
    context "when token does not contain an expiration" do
      context "when timestamp is 3 minutes ago" do
        let(:timestamp){ now - 180 }
        it{ should be_falsey }
        context "when expiry arg is 10 seconds" do
          let(:expiry_arg){ 10 }
          it{ should be_truthy }
        end
        context "when expiry arg is 4 minutes" do
          let(:expiry_arg){ 240 }
          it{ should be_falsey }
        end
      end
      
      context "when timestamp is 10 minutes ago" do
        let(:timestamp){ now - 600 }
        it{ should be_truthy }
        context "when expiry arg is 15 minutes" do
          let(:expiry_arg){ 15 * 60 }
          it{ should be_falsey }
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
    it { is_expected.to be_truthy }
    
    it "does check signature on the key field" do
      expect(key.token_valid?(token.merge "key" => key_fingerprint)).to be_falsey
    end

    it "calls #token_expired? with the token and expiry" do
      key.should_receive(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return false, true
      key.token_valid?(token).should be_truthy
      key.token_valid?(token).should be_falsey
    end
    
    context "when #token_expired? returns false" do
      before{ key.stub(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return false }
      it{ should be_truthy }
    end
    
    context "when #token_expired? returns true" do
      before{ key.stub(:token_expired?).with(unsigned_token, kind_of(Numeric)).and_return true }
      it{ should be_falsey }
    end
    
    it "rejects the token if the key field is present and doesn't match" do
      expect(key.token_valid?(token.merge "key" => "this is not the key you are looking for")).not_to be_truthy
    end
    
    context "when token is 5 minutes old" do
      before{ key.stub current_time: now + 60 * 5 }
      it{should be_truthy }
      context "when the token expiration is 3 minutes from now" do
        let(:expiration){ now + 3 * 60 }
        it{ should be_falsey }
      end
    end
    
    context "when token is 1 hour old" do
      let(:later){ now + 60 * 60 }
      before { key.stub current_time: later }
      it { should be_falsey }
      context "when timestamp in the token is changed accordingly" do
        let(:messed_with_token) { token.merge("timestamp" => later.to_s) }
        it "should not be valid" do 
          key.token_valid?(messed_with_token).should be_falsey
        end
      end
      context "when expiration in the token is changed accordingly" do
        let(:messed_with_token){ token.merge("expiration" => (later + 120).to_s) }
        it "should not be valid" do
          key.token_valid?(messed_with_token).should be_falsey
        end
      end
    end
    
    context "when expiration is not present" do
      let(:expiration){ nil }
      let(:timestamp){ now + 8 * 60 }
      it{ should be_truthy }
    end
    
    context "when the data is changed" do
      let(:messed_with_token) { token.merge("data" => { "foo" => :baz }) }
      it "is not valid" do
        key.token_valid?(messed_with_token).should be_falsey
      end
    end
    context "when RSA decrypt raises an error" do
      before { expect_any_instance_of(OpenSSL::PKey::RSA).to receive(:public_decrypt).and_raise(OpenSSL::PKey::RSAError) }
      it { is_expected.to be_falsey }
    end
  end
end
