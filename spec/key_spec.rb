require 'spec_helper'

describe Slosilo::Key do
  include_context "with example key"
  
  subject { key }
  its(:to_der) { should == rsa.to_der }
  its(:to_s) { should == rsa.public_key.to_pem }
  
  let(:plaintext) { 'quick brown fox jumped over the lazy dog' }
  describe '#encrypt' do
    it "generates a symmetric encryption key and encrypts the plaintext with the public key" do
      ctxt, skey = subject.encrypt plaintext
      pskey = rsa.private_decrypt skey
      Slosilo::Symmetric.new.decrypt(ctxt, key: pskey).should == plaintext
    end
  end
  
  describe '#decrypt' do
    let(:ciphertext) { "\xEF\x8A\xF3\xC0<\xB1[\x93\xDA\x00\xD9\x11s\xC8\x87\x81\xD9\xE0V>#\b\xD4\xFB@\xA4\x1D\x02\xDB\xB6lv\xF2\x168BF\x8A\xAE\x9B;\xE9 N\x86\x96\xEB\x86\x0F\xC7\xAC\xE2\xB6\xD4~L" }
    let(:skey) { "\x15\xFF\xD4>\x9C\xF4\x0F\xB6\x04C\x18\xC1\x96\xC3\xE0T\xA3\xF5\xE8\x17\xA6\xE0\x86~rrw\xC3\xDF\x11)$\x9B\r@\x0E\xE4Zv\rw-\xFC\x1C\x84\x17\xBD\xDB\x12u\xCD\r\xFEo\xD5\xC8[\x8FEA\\\xA9\xA2F#\x8BH -\xFA\xF7\xA9\xEBf\x97\xAAT}\x8E*\xC0r\x944p\xD0\x9A\xE7\xBD\a;O\f\xEF\xE4B.y\xFA\xB4e@O\xBB\x15>y\xC9\t=\x01\xE1J\xF3X\xA9\x9E3\x04^H\x1F\xFF\x19C\x93ve)@\xF7\t_\xCF\xDE\xF1\xB7]\x83lL\xB8%A\x93p{\xE9Y\xBAu\xCE\x99T\xDC\xDF\xE7\x0FD%\xB9AXb\x1CW\x94$P\xBB\xE1g\xDEE\t\xC4\x92\x9E\xFEt\xDF\xD0\xEA\x03\xC4\x12\xA9\x02~u\xF4\x92 ;\xA0\xCE.\b+)\x05\xEDo\xA5cF\xF8\x12\xD7F\x97\xE44\xBF\xF1@\xA5\xC5\xA8\xE5\a\xE8ra<\x04\xB5\xA2\f\t\xF7T\x97\e\xF5(^\xAB\xA5%84\x10\xD1\x13e<\xCA/\xBF}%\xF6\xB1%\xB2" }
    
    it "decrypts the symmetric key and then uses it to decrypt the ciphertext" do
      subject.decrypt(ciphertext, skey).should == plaintext
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
      let(:expected_signature) { "d[\xA4\x00\x02\xC5\x17\xF5P\x1AD\x91\xF9\xC1\x00P\x0EG\x14,IN\xDE\x17\xE1\xA2a\xCC\xABR\x99'\xB0A\xF5~\x93M/\x95-B\xB1\xB6\x92!\x1E\xEA\x9C\v\xC2O\xA8\x91\x1C\xF9\x11\x92a\xBFxm-\x93\x9C\xBBoM\x92%\xA9\xD06$\xC1\xBC.`\xF8\x03J\x16\xE1\xB0c\xDD\xBF\xB0\xAA\xD7\xD4\xF4\xFC\e*\xAB\x13A%-\xD3\t\xA5R\x18\x01let6\xC8\xE9\"\x7F6O\xC7p\x82\xAB\x04J(IY\xAA]b\xA4'\xD6\x873`\xAB\x13\x95g\x9C\x17\xCAB\xF8\xB9\x85B:^\xC5XY^\x03\xEA\xB6V\x17b2\xCA\xF5\xD6\xD4\xD2\xE3u\x11\xECQ\x0Fb\x14\xE2\x04\xE1<a\xC5\x01eW-\x15\x01X\x81K\x1A\xE5A\vVj\xBF\xFC\xFE#\xD5\x93y\x16\xDC\xB4\x8C\xF0\x02Y\xA8\x87i\x01qC\xA7#\xE8\f\xA5\xF0c\xDEJ\xB0\xDB BJ\x87\xA4\xB0\x92\x80\x03\x95\xEE\xE9\xB8K\xC0\xE3JbE-\xD4\xCBP\\\x13S\"\eZ\xE1\x93\xFDa pinch of salt" }
      it "signs it" do
        key.stub salt: 'a pinch of salt'
        key.sign("this sentence is not this sentence").should == expected_signature
      end
    end
  end
end
