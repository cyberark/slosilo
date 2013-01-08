require 'spec_helper'

describe Slosilo::Rack::Middleware do
  include_context "with example key"
  mock_own_key
  
  let(:app) { double "app" }
  subject { Slosilo::Rack::Middleware.new app }
  
  describe '#path' do
    context "when QUERY_STRING is empty" do
      let(:env) { { 'SCRIPT_NAME' => '/foo', 'PATH_INFO' => '/bar', 'QUERY_STRING' => '' } }
      before { subject.stub env: env }
      its(:path) { should == '/foo/bar' }
    end
    context "when QUERY_STRING is not" do
      let(:env) { { 'SCRIPT_NAME' => '/foo', 'PATH_INFO' => '/bar', 'QUERY_STRING' => 'baz' } }
      before { subject.stub env: env }
      its(:path) { should == '/foo/bar?baz' }
    end
  end
  
  describe '#call' do
    let(:call) { subject.call(env) }
    let(:path) { "/this/is/the/path" }
    before { subject.stub path: path }
    context "when no X-Slosilo-Key is given" do
      let(:env) { {} }
      let(:result) { double "result" }
      it "passes the env verbatim" do
        app.should_receive(:call).with(env).and_return(result)
        call.should == result
      end

      context "and X-Slosilo-Signature is given" do
        let(:body) { "the body" }
        let(:timestamp) { "long time ago" }
        let(:signature) { "in blood" }
        let(:env) { {'rack.input' => StringIO.new(body), 'HTTP_TIMESTAMP' => timestamp, 'HTTP_X_SLOSILO_SIGNATURE' => signature } }
        let(:token) { { data: { path: path, body: "dGhlIGJvZHk=" }, timestamp: timestamp, signature: signature } }
        context "when the signature is valid" do
          before { Slosilo.stub(:token_valid?).with(token).and_return true }
          it "passes the env verbatim" do
            app.should_receive(:call).with(env).and_return(result)
            call.should == result
          end
        end
        context "when the signature is invalid" do
          before { Slosilo.stub(:token_valid?).with(token).and_return false }
          it "returns 401" do
            call[0].should == 401
          end
        end
      end

      context "but encryption is required" do
        subject { Slosilo::Rack::Middleware.new app, encryption_required: true }
        context "and the body is not empty" do
          let(:env) { {'rack.input' => StringIO.new('foo') } }
          it "returns 403" do
            status, headers, body = call
            status.should == 403
          end
        end
        context "but the body is empty" do
          subject { Slosilo::Rack::Middleware.new app, encryption_required: true, signature_required: false }
          let(:body) { "" }
          let(:timestamp) { "long time ago" }
          let(:env) { {'rack.input' => StringIO.new(body) } }
          it "passes the env verbatim" do
            app.should_receive(:call).with(env).and_return(result)
            call.should == result
          end
        end
      end
    end
    
    context "when no X-Slosilo-Signature is given" do
      context "but signature is required" do
        let(:env) {{}}
        subject { Slosilo::Rack::Middleware.new app, signature_required: true }
        it "returns 401" do
          status, headers, body = call
          status.should == 401
        end
      end
    end
      
    let(:plaintext) { "If you were taught that elves caused rain, every time it rained, you'd see the proof of elves." }
    let(:skey) { "Eiho7xIoFj-Qwqc0swcQQJzJyM1sSv_b6VdRIoHCPRUwemB0v5MNyOirU_5dQ_bNzlmSlo8HDvfAnMgapwpIBH__uDUV_3nCkzrzQVV3-bSp6owJnqebeSQxJMoVMKEWqqek3ZCBPo0OB63A8mkYGu9955gDEDOnlxLkETGb3SmDQIVJtiMmAkUWN0fh9z1M9Ycw9FfworaHKQXRLw6z6Rl-Yoe_TDaiKVlGIYjQKpCz8h_I5lRdrhPJaP53d0yQuKMK3PBHMzE77IikZyQ3VZdoqI9XqzUJF27KehxJ_BCx0oAcPaxG6I7WWe3Xb7K7MhE4HgzqVZACDLhYfm_0XA==" }
    let(:ciphertext) { "0\xDE\xE1\xBA=\x06+K\xE0\xCAD\xC6\xE3 d\xC7kx\x90\r\ni\xDCXmS!EP\xAB\xEF\xAA\x13{\x85f\x8FU,\xB3zO\x1F\x85\f\x0E\xAE\xF8\x10`\x1C\x94\xAB@\xFA\xBC\xC0/\x1F\xA6nX\xFF-m\xF4\xC3f\xBB\xCA\x05\xC82\x18l\xC3\xF0v\x96\v\x8F\xFC\xB2\xC7wX;\xF6v\xDCX:\xCC\xF8\xD7\x99\xC8\x1A\xBA\x9F\xDB\xE7\x0F\xF2\xC9f\aaGs\xEFc" }
    context "when X-Slosilo-Key is given" do
      context "when the key decrypts cleanly" do
        let(:env) { {'HTTP_X_SLOSILO_KEY' => skey, 'rack.input' => StringIO.new(ciphertext) } }
        it "passes the decrypted contents" do
          app.should_receive(:call).with(rack_environment_with_input(plaintext)).and_return(:result)
          call.should == :result
        end
      end
      context "when the key is invalid" do
        let(:env) { {'HTTP_X_SLOSILO_KEY' => "broken #{skey}", 'rack.input' => StringIO.new(ciphertext) } }
        it "returns 403 status" do
          status, headers, body = call
          status.should == 403
        end
      end
    end
  end
end
