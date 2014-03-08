require 'spec_helper'

describe Slosilo::Key do
  include_context "with example key"
  
  subject { key }
  its(:to_der) { should == rsa.to_der }
  its(:to_s) { should == rsa.public_key.to_pem }
  its(:fingerprint) { should == key_fingerprint }
  it { should be_private }

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
        key.stub shake_salt: 'a pinch of salt'
        key.sign("this sentence is not this sentence").should == expected_signature
      end
    end
  end
  
  describe "#signed_token" do
    let(:time) { Time.new(2012,1,1,1,1,1,0) }
    let(:data) { { "foo" => :bar } }
    let(:token_to_sign) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC" } }
    let(:signature) { "signature" }
    let(:salt) { 'a pinch of salt' }
    let(:expected_signature) { Base64::urlsafe_encode64 "\xB0\xCE{\x9FP\xEDV\x9C\xE7b\x8B[\xFAil\x87^\x96\x17Z\x97\x1D\xC2?B\x96\x9C\x8Ep-\xDF_\x8F\xC21\xD9^\xBC\n\x16\x04\x8DJ\xF6\xAF-\xEC\xAD\x03\xF9\xEE:\xDF\xB5\x8F\xF9\xF6\x81m\xAB\x9C\xAB1\x1E\x837\x8C\xFB\xA8P\xA8<\xEA\x1Dx\xCEd\xED\x84f\xA7\xB5t`\x96\xCC\x0F\xA9t\x8B\x9Fo\xBF\x92K\xFA\xFD\xC5?\x8F\xC68t\xBC\x9F\xDE\n$\xCA\xD2\x8F\x96\x0EtX2\x8Cl\x1E\x8Aa\r\x8D\xCAi\x86\x1A\xBD\x1D\xF7\xBC\x8561j\x91YlO\xFA(\x98\x10iq\xCC\xAF\x9BV\xC6\v\xBC\x10Xm\xCD\xFE\xAD=\xAA\x95,\xB4\xF7\xE8W\xB8\x83;\x81\x88\xE6\x01\xBA\xA5F\x91\x17\f\xCE\x80\x8E\v\x83\x9D<\x0E\x83\xF6\x8D\x03\xC0\xE8A\xD7\x90i\x1D\x030VA\x906D\x10\xA0\xDE\x12\xEF\x06M\xD8\x8B\xA9W\xC8\x9DTc\x8AJ\xA4\xC0\xD3!\xFA\x14\x89\xD1p\xB4J7\xA5\x04\xC2l\xDC8<\x04Y\xD8\xA4\xFB[\x89\xB1\xEC\xDA\xB8\xD7\xEA\x03Ja pinch of salt".force_encoding("ASCII-8BIT") }
    let(:expected_token) { token_to_sign.merge "signature" => expected_signature, "key" => key_fingerprint }
    before do
      key.stub shake_salt: salt
      Time.stub new: time
    end
    subject { key.signed_token data }
    it { should == expected_token }
  end
  
  describe "#token_valid?" do
    let(:data) { { "foo" => :bar } }
    let(:signature) { Base64::urlsafe_encode64 "\xB0\xCE{\x9FP\xEDV\x9C\xE7b\x8B[\xFAil\x87^\x96\x17Z\x97\x1D\xC2?B\x96\x9C\x8Ep-\xDF_\x8F\xC21\xD9^\xBC\n\x16\x04\x8DJ\xF6\xAF-\xEC\xAD\x03\xF9\xEE:\xDF\xB5\x8F\xF9\xF6\x81m\xAB\x9C\xAB1\x1E\x837\x8C\xFB\xA8P\xA8<\xEA\x1Dx\xCEd\xED\x84f\xA7\xB5t`\x96\xCC\x0F\xA9t\x8B\x9Fo\xBF\x92K\xFA\xFD\xC5?\x8F\xC68t\xBC\x9F\xDE\n$\xCA\xD2\x8F\x96\x0EtX2\x8Cl\x1E\x8Aa\r\x8D\xCAi\x86\x1A\xBD\x1D\xF7\xBC\x8561j\x91YlO\xFA(\x98\x10iq\xCC\xAF\x9BV\xC6\v\xBC\x10Xm\xCD\xFE\xAD=\xAA\x95,\xB4\xF7\xE8W\xB8\x83;\x81\x88\xE6\x01\xBA\xA5F\x91\x17\f\xCE\x80\x8E\v\x83\x9D<\x0E\x83\xF6\x8D\x03\xC0\xE8A\xD7\x90i\x1D\x030VA\x906D\x10\xA0\xDE\x12\xEF\x06M\xD8\x8B\xA9W\xC8\x9DTc\x8AJ\xA4\xC0\xD3!\xFA\x14\x89\xD1p\xB4J7\xA5\x04\xC2l\xDC8<\x04Y\xD8\xA4\xFB[\x89\xB1\xEC\xDA\xB8\xD7\xEA\x03Ja pinch of salt".force_encoding("ASCII-8BIT") }
    let(:token) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC", "signature" => signature } }
    before { Time.stub now: Time.new(2012,1,1,1,2,1,0) }
    subject { key.token_valid? token }
    it { should be_true }
    
    it "doesn't check signature on the advisory key field" do
      key.token_valid?(token.merge "key" => key_fingerprint).should be_true
    end
    
    it "rejects the token if the key field is present and doesn't match" do
      key.token_valid?(token.merge "key" => "this is not the key you are looking for").should_not be_true
    end
    
    context "when token is 1 hour old" do
      before { Time.stub now: Time.new(2012,1,1,2,1,1,0) }
      it { should be_false }
      context "when timestamp in the token is changed accordingly" do
        let(:token) { { "data" => data, "timestamp" => "2012-01-01 02:00:01 UTC", "signature" => signature } }
        it { should be_false }
      end
    end
    context "when the data is changed" do
      let(:data) { { "foo" => :baz } }
      it { should be_false }
    end
    context "when RSA decrypt raises an error" do
      before { OpenSSL::PKey::RSA.any_instance.should_receive(:public_decrypt).and_raise(OpenSSL::PKey::RSAError) }
      it { should be_false }
    end
  end
end
