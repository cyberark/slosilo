require "simplecov"
SimpleCov.start

require 'slosilo'

shared_context "with mock adapter" do
  require 'slosilo/adapters/mock_adapter'

  let(:adapter) { Slosilo::Adapters::MockAdapter.new }
  before { Slosilo::adapter = adapter }
end

shared_context "with example key" do
  let(:rsa) { OpenSSL::PKey::RSA.new """
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
  let (:key) { Slosilo::Key.new rsa.to_der }
  
  def self.mock_own_key
    before { Slosilo.stub(:[]).with(:own).and_return key }
  end
end

class RackEnvironmentInputMatcher
  def initialize expected
    @expected = expected
  end
  
  def == env
    env['rack.input'].read.should == @expected
  end
end

def rack_environment_with_input expected
  RackEnvironmentInputMatcher.new expected
end
