require 'spec_helper'

describe Slosilo::HTTPRequest do
  describe "#encrypt!" do
    let(:keyname) { :bacon }
    let(:encrypt) { subject.encrypt! keyname }
    
    context "when requested key does not exist" do
      before { Slosilo.stub(:[]).and_return nil }
      it "raises error" do
        expect{ encrypt }.to raise_error
      end
    end
    
    context "when the key exists" do
      let(:key) { double "key" }
      before do 
        key.stub(:encrypt).with(plaintext).and_return([ciphertext, skey])
        Slosilo.stub(:[]).with(keyname).and_return key
      end
      
      let(:plaintext) { "Keep your solutions close, and your problems closer." }
      before { subject.stub body: plaintext }
      let(:ciphertext) { "And, when you want something, all the universe conspires in helping you to achieve it." }
      let(:skey) { "make me sound like a fool instead" }
      
      it "encrypts the message body and adds the X-Slosilo-Key header" do
        subject.should_receive(:body=).with ciphertext
        subject.should_receive(:[]=).with 'X-Slosilo-Key', skey
        encrypt
      end
    end
  end
end
