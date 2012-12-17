require 'spec_helper'

describe Slosilo::Symmetric do
  let(:plaintext) { "quick brown fox jumped over the lazy dog" }
  let(:key) { "^\xBAIv\xDB1\x0Fi\x04\x11\xFD\x14\xA7\xCD\xDFf\x93\xFE\x93}\v\x01\x11\x98\x14\xE0;\xC1\xE2 v\xA5" }
  let(:iv) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xED" }
  let(:ciphertext) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xEDinV\n\x15\xF0t\xDA\xB4\xC6\xCB\x84a\"!r\x8E\t\xF1\xD1\xB8|a\xFAaZ\x01=\x98p\xC0\x1D8\x957x\xF4\x15<\xA3" }
  describe '#encrypt' do
    it "encrypts with AES-256-CTR" do
      subject.stub random_iv: iv
      subject.encrypt(plaintext, key: key).should == ciphertext
    end
  end
  
  describe '#decrypt' do
    it "decrypts with AES-256-CTR" do
      subject.decrypt(ciphertext, key: key).should == plaintext
    end
  end
  
  describe '#random_iv' do
    it "generates a random iv" do
      OpenSSL::Cipher.any_instance.should_receive(:random_iv).and_return :iv
      subject.random_iv.should == :iv
    end
  end

  describe '#random_key' do
    it "generates a random key" do
      OpenSSL::Cipher.any_instance.should_receive(:random_key).and_return :key
      subject.random_key.should == :key
    end
  end
end
