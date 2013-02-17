require 'spec_helper'

describe Slosilo::Symmetric do
  # TODO transform it to class methods only?
  let(:plaintext) { "quick brown fox jumped over the lazy dog" }
  let(:key) { "^\xBAIv\xDB1\x0Fi\x04\x11\xFD\x14\xA7\xCD\xDFf\x93\xFE\x93}\v\x01\x11\x98\x14\xE0;\xC1\xE2 v\xA5" }
  let(:iv) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xED" }
  let(:ciphertext) { "\xA1\xFA#z\x16\x80R\xCC|\x0Fyc\xB7j\x17\xED\x15\xC9r\xC9\xEE\xB9\xBC5\xB7\ni\x0F\f\xC8X\x80 h\a\xF4\xA6\xE3\x15\x9D\xF1-\xE5\bs\xF6\x02Z\x0F\xCD|S\x1A\xAA\x9At\xEFT\x17\xA5lT\x8C\xF3" }
  describe '#encrypt' do
    it "encrypts with AES-256-CBC" do
      subject.stub random_iv: iv
      subject.encrypt(plaintext, key: key).should == ciphertext
    end
  end
  
  describe '#decrypt' do
    it "decrypts with AES-256-CBC" do
      subject.decrypt(ciphertext, key: key).should == plaintext
    end
    
    context "when ciphertext happens to end in a zero" do
      let(:ciphertext) { "\x7F\xD6\xEAb\xE56\a\xD3\xC5\xF2J\n\x8C\x8Fg\xB7-\\\x8A\fh\x18\xC8\x91\xB9 \x97\xC9\x12\xE6\xA6\xAE\xB1I\x1E\x80\xAB\xD8\xDC\xBD\xB6\xCD\x9A\xA3MH\xA8\xB0\xC7\xDA\x87\xA7c\xD75,\xD2A\xB8\x9E\xE3o\x04\x00" }
      let(:key) { "4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y" }
      it "works correctly" do
        subject.decrypt(ciphertext, key: key).should == "R6KNTQ4aUivojbaqhgAqj1I4PaF8h/5/YcENy4uNbfk="
      end
    end

    context "when the iv ends in space" do
      let(:ciphertext) { "\xC0\xDA#\xE9\xE1\xFD\xEDJ\xADs4P\xA9\xD6\x92 \xF7\xF8_M\xF6\x16\xC2i$\x8BT^\b\xA1\xB2L&\xE9\x80\x02[]6i\x9B\xD3\xC3\xED\xA9\xD1\x94\xE8\x15\xFD\xDA\xFEUj\xC5upH*\xBF\x82\x15le" }
      let(:key) { "4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y" }
      it "works correctly" do
        subject.decrypt(ciphertext, key: key).should == "zGptmL3vd4obi1vqSiWHt/Ias2k+6qDtuq9vdow8jNA="
      end
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
