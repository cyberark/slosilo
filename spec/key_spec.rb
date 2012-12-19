require 'spec_helper'

describe Slosilo::Key do
  let(:key) { OpenSSL::PKey::RSA.new """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAtTG/SQhW9QawP+GL6EZ5Al9gscCr7HiRO7MuQqFkaXIJD6+3
prdHRrb0qqjNlGFgDBGAuswZ2AYqhBt7eekup+/vIpI5n04b0w+is3WwZAFco4uP
ojDeM0aY65Ar3Zgra2vWUJXRwBumroZjVBVoLJSgVfwIhwU6ORbS2oJflbtqxpuS
zkPDqS6RwEzI/DHuHTOI26fe+vfuDqGOuSR6iVI16lfvTbWwccpDwU0W9vSlyjjD
LIw0MnoKL3DHyzO66s+oNNRleMvjghQtJk/xg1kRuHReJ5/ygt2zyzdKSLeqU+T+
TCWw/F65jrFElftexiS+g+lZC467VLCaMe1fJQIDAQABAoIBAQCiNWzXRr4CEQDL
z3Deeehu9U+tEZ1Xzv/FgD0TrUQlGc9+2YIBn+YRKkySUxfnk9zWMP0bPQiN2cdK
CQhbNSNteGCOhHVNZjGGm2K+YceNX6K9Tn1BZ5okMTlI+QIsGMQWIK316omh/58S
coCNj7R45H09PKmtpkJfRU1yDHDhqypjPDpb9/7U5mt3g2BdXYi+1hilfonHoDrC
yy3eRdf7Tlij9O3UeM+Z7pZrKATcvpDkYbNWizDITvKMYy6Ss+ajM5v7lt6QN5LP
MHjwX8Ilrxkxl0jeopr4f94tR7rNDZbLC457j8gns7cUeODtF7pPZqlrlk4KOq8Q
DvEMt2ZpAoGBAOLNUiO1SwRo75Y8ukuMVQev8O8WuzEEGINoM1lQiYlbUw3HmVp3
iUvv58ANmKSzTXpOEZ1L8pZHSp435FrzD2WZmCAoXhNdfAXtmZA7Y46iE6BF4qrr
UegtLPhVgwpO74Y+4w2YwfDknzCOhWE4sxCbukuSvxz2pz1Vm31eFB6jAoGBAMyF
VxfYq9WhmLNsHqR+qfhb1EC5FfpSq23z/o4ryiKqCaWHimVtOO7DL7x2SK3mVNNZ
X8b4+vnJpAQ3nOxeg8fpmBaLAWYRna2AN/CYVIMKYusawhsGAlZZTu2mtJKLiOPS
8/z5dK55xJWlG5JalUB+n/4vd3WmXiT/XJj3qU+XAoGBALyHzLXeKCPcTvzmMj5G
wxAG0xMMJEMUkoP5hGXEKvBBOAMGXpXzM/Ap1s2w/6g5XDhE2SOWVGtTi9WFxI9N
6Qid6vUgWUNjvIr4/WQF2jZgyEu8jDVkM8v6cZ1lB+7zuuwvLnLI/r6ObT3h20H7
7e3qZawYqkEbT94OYZiPMc5dAoGAHmIQtjIyFOKU1NLTGozWo1bBCXx1j2KIpSUC
RAytUsj/9d9U6Ax50L6ecNkBoxP8tgko+V4zqrgR7a51WYgQ+7nwJikwZAFp80SB
CvUWWQFKALNQ8sLJxhouZ4/Ec6DXDUFhjcthUio00iZdGjjqw1IMYq6aiJfWlJh7
IR5pwLECgYEAyjlguks/3cjrHRF+yjonxT4tLuBI/n3TAQUPqmtkJtcwZSAJas/1
c/twlAJ7F6n3ZroF3lgPxMJRRHZl4Z4dJsDatIxVShf3nSGg9Mi5C25obxahbv5/
Dg1ikwi8GUF4HPZe9DyhXgDhg19wM/qcpjX8bSypsUWHWP+FanhjdWU=
-----END RSA PRIVATE KEY-----
          """ }
  subject{ Slosilo::Key.new key.to_der }
  
  let(:plaintext) { 'quick brown fox jumped over the lazy dog' }
  describe '#encrypt' do
    it "generates a symmetric encryption key and encrypts the plaintext with the public key" do
      ctxt, skey = subject.encrypt plaintext
      pskey = key.private_decrypt skey
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
      let (:key) { double "key" }
      it "generates a new key pair" do
        OpenSSL::PKey::RSA.should_receive(:new).with(2048).and_return(key)
        subject.key.should == key
      end
    end
  end
end
