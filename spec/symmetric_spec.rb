require 'spec_helper'

describe Slosilo::Symmetric do
  let(:plaintext) { "quick brown fox jumped over the lazy dog" }
  let(:key) { "^\xBAIv\xDB1\x0Fi\x04\x11\xFD\x14\xA7\xCD\xDFf\x93\xFE\x93}\v\x01\x11\x98\x14\xE0;\xC1\xE2 v\xA5" }
  let(:iv) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xED" }
  let(:ciphertext) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xED\x15\xC9r\xC9\xEE\xB9\xBC5\xB7\ni\x0F\f\xC8X\x80 h\a\xF4\xA6\xE3\x15\x9D\xF1-\xE5\bs\xF6\x02Z\x0F\xCD|S\x1A\xAA\x9At\xEFT\x17\xA5lT\x8C\xF3" }
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
