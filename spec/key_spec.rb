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
    let(:time) { Time.new(2012,1,1,1,1,1,0) }
    let(:data) { { "foo" => :bar } }
    let(:token_to_sign) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC" } }
    let(:signature) { "signature" }
    let(:salt) { 'a pinch of salt' }
    let(:expected_signature) { "Z5L2MCjoe8ULXPa-3NFjoQ-Q6GxPD-8jptGRhE57R39Sk8gOFUyjuCFL8etgxTtb7N7RzYSP8TYr3maPLHZ_TEwocQux4e_EcRkYJrPED_EReyu01ttS1sj93pIWUR-WpUvd8Vh9xgqKywqwd2oBF9TkSLdsLp8jCe7vOEaM6jm_Wt8LDGzsLUXWm9Bs7kEJAvxB_hiv70FRhHJ_szg05pWGU194eYntL1Uz14ZZEspFZfrs0yndxaD3fiASCedF3EWU07wQcxCgiJ8hgwoa-YfmfrxjRinenuYAncjRcA-Q4B86meWXvRLGebZ9QpXTALfrWG4CU-_mJ7vfCPmzUWEgcGluY2ggb2Ygc2FsdA==" }
    let(:expected_token) { token_to_sign.merge "signature" => expected_signature, "key" => key_fingerprint }
    before do
      allow(key).to receive_messages shake_salt: salt
      allow(Time).to receive_messages new: time
    end
    subject { key.signed_token data }
    it { is_expected.to eq(expected_token) }
  end
  
  describe "#token_valid?" do
    let(:data) { { "foo" => :bar } }
    let(:signature) { Base64::urlsafe_encode64 "\xB0\xCE{\x9FP\xEDV\x9C\xE7b\x8B[\xFAil\x87^\x96\x17Z\x97\x1D\xC2?B\x96\x9C\x8Ep-\xDF_\x8F\xC21\xD9^\xBC\n\x16\x04\x8DJ\xF6\xAF-\xEC\xAD\x03\xF9\xEE:\xDF\xB5\x8F\xF9\xF6\x81m\xAB\x9C\xAB1\x1E\x837\x8C\xFB\xA8P\xA8<\xEA\x1Dx\xCEd\xED\x84f\xA7\xB5t`\x96\xCC\x0F\xA9t\x8B\x9Fo\xBF\x92K\xFA\xFD\xC5?\x8F\xC68t\xBC\x9F\xDE\n$\xCA\xD2\x8F\x96\x0EtX2\x8Cl\x1E\x8Aa\r\x8D\xCAi\x86\x1A\xBD\x1D\xF7\xBC\x8561j\x91YlO\xFA(\x98\x10iq\xCC\xAF\x9BV\xC6\v\xBC\x10Xm\xCD\xFE\xAD=\xAA\x95,\xB4\xF7\xE8W\xB8\x83;\x81\x88\xE6\x01\xBA\xA5F\x91\x17\f\xCE\x80\x8E\v\x83\x9D<\x0E\x83\xF6\x8D\x03\xC0\xE8A\xD7\x90i\x1D\x030VA\x906D\x10\xA0\xDE\x12\xEF\x06M\xD8\x8B\xA9W\xC8\x9DTc\x8AJ\xA4\xC0\xD3!\xFA\x14\x89\xD1p\xB4J7\xA5\x04\xC2l\xDC8<\x04Y\xD8\xA4\xFB[\x89\xB1\xEC\xDA\xB8\xD7\xEA\x03Ja pinch of salt".force_encoding("ASCII-8BIT") }
    let(:token) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC", "signature" => signature } }
    before { allow(Time).to receive_messages now: Time.new(2012,1,1,1,2,1,0) }
    subject { key.token_valid? token }
    it { is_expected.to be_truthy }
    
    it "does check signature on the key field" do
      expect(key.token_valid?(token.merge "key" => key_fingerprint)).to be_falsey
    end
    
    it "rejects the token if the key field is present and doesn't match" do
      expect(key.token_valid?(token.merge "key" => "this is not the key you are looking for")).not_to be_truthy
    end
    
    context "when token is 1 hour old" do
      before { allow(Time).to receive_messages now: Time.new(2012,1,1,2,1,1,0) }
      it { is_expected.to be_falsey }
      context "when timestamp in the token is changed accordingly" do
        let(:token) { { "data" => data, "timestamp" => "2012-01-01 02:00:01 UTC", "signature" => signature } }
        it { is_expected.to be_falsey }
      end
    end
    context "when the data is changed" do
      let(:data) { { "foo" => :baz } }
      it { is_expected.to be_falsey }
    end
    context "when RSA decrypt raises an error" do
      before { expect_any_instance_of(OpenSSL::PKey::RSA).to receive(:public_decrypt).and_raise(OpenSSL::PKey::RSAError) }
      it { is_expected.to be_falsey }
    end
  end
end
