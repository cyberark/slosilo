require 'spec_helper'

# (Mostly) integration tests for JWT token format
describe Slosilo::Key do
  include_context "with example key"

  describe '#issue_jwt' do
    it 'issues an JWT token with given claims' do
      allow(Time).to receive(:now) { DateTime.parse('2014-06-04 23:22:32 -0400').to_time }

      tok = key.issue_jwt sub: 'host/example', cidr: %w(fec0::/64)

      expect(tok).to be_frozen

      expect(tok.header).to eq \
        alg: 'conjur.org/slosilo/v2',
        kid: key_fingerprint
      expect(tok.claims).to eq \
        iat: 1401938552,
        sub: 'host/example',
        cidr: ['fec0::/64']

      expect(key.verify_signature tok.string_to_sign, tok.signature).to be_truthy
    end
  end
end

describe Slosilo::JWT do
  context "with a signed token" do
    let(:signature) { 'very signed, such alg' }
    subject(:token) { Slosilo::JWT.new test: "token" }
    before do
      allow(Time).to receive(:now) { DateTime.parse('2014-06-04 23:22:32 -0400').to_time }
      token.add_signature(alg: 'test-sig') { signature }
    end

    it 'allows conversion to JSON representation with #to_json' do
      json = JSON.load token.to_json
      expect(JSON.load Base64.urlsafe_decode64 json['protected']).to eq \
          'alg' => 'test-sig'
      expect(JSON.load Base64.urlsafe_decode64 json['payload']).to eq \
          'iat' => 1401938552, 'test' => 'token'
      expect(Base64.urlsafe_decode64 json['signature']).to eq signature
    end

    it 'allows conversion to compact representation with #to_s' do
      h, c, s = token.to_s.split '.'
      expect(JSON.load Base64.urlsafe_decode64 h).to eq \
          'alg' => 'test-sig'
      expect(JSON.load Base64.urlsafe_decode64 c).to eq \
          'iat' => 1401938552, 'test' => 'token'
      expect(Base64.urlsafe_decode64 s).to eq signature
    end
  end

  describe '#to_json' do
    it "passes any parameters" do
      token = Slosilo::JWT.new
      allow(token).to receive_messages \
          header: :header,
          claims: :claims,
          signature: :signature
      expect_any_instance_of(Hash).to receive(:to_json).with :testing
      expect(token.to_json :testing)
    end
  end

  describe '()' do
    include_context "with example key"

    it 'understands both serializations' do
      [COMPACT_TOKEN, JSON_TOKEN].each do |token|
        token = Slosilo::JWT token
        expect(token.header).to eq \
            'typ' => 'JWT',
            'alg' => 'conjur.org/slosilo/v2',
            'kid' => key_fingerprint
        expect(token.claims).to eq \
            'sub' => 'host/example',
            'iat' => 1401938552,
            'exp' => 1401938552 + 60*60,
            'cidr' => ['fec0::/64']

        expect(key.verify_signature token.string_to_sign, token.signature).to be_truthy
      end
    end

    it 'is a noop if already parsed' do
      token = Slosilo::JWT COMPACT_TOKEN
      expect(Slosilo::JWT token).to eq token
    end

    it 'raises ArgumentError on failure to convert' do
      expect { Slosilo::JWT "foo bar" }.to raise_error ArgumentError
      expect { Slosilo::JWT elite: 31337 }.to raise_error ArgumentError
      expect { Slosilo::JWT "foo.bar.xyzzy" }.to raise_error ArgumentError
    end
  end

  COMPACT_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiJkMjhlM2EzNDdlMzY4NDE2YjMxMjlhNDBjMWI4ODdmZSJ9.eyJzdWIiOiJob3N0L2V4YW1wbGUiLCJpYXQiOjE0MDE5Mzg1NTIsImV4cCI6MTQwMTk0MjE1MiwiY2lkciI6WyJmZWMwOjovNjQiXX0=.cw9S8Oxu8BmvDgEotBlNiZoJNkAGDpvGIuhCCnG-nMq80dy0ECjC4xERYXHx3bcadEJ8jWfqDB90d7CGvJyepbMhC1hEdsb8xNWGkkqTvQOh33cnZiEJjjfbORpKnOpcc8QySmB9Eb_zKl5WaM6Sjm-uINJri3djuVo_n_S7I43YvKw7gbd5u2gVttgaWnqlnJoeXZnnmXSYH8_66Lr__BqO4tCedShQIf4gA0R_dljrzVSZtJsFTKvwuNOuCvBqO8dQkhp8vplOkKynDkdip-H2nDBQb9Y3bQ8K0NVtSJatBy-d1HvPHSwFZrH4K7P_J2OgJtw9GtckT43QasliXoibdk__Hyvy4HJIIM44rSm7JUuyZWl8e8svRqLujBP7".freeze

  JSON_TOKEN = "{\"protected\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiJkMjhlM2EzNDdlMzY4NDE2YjMxMjlhNDBjMWI4ODdmZSJ9\",\"payload\":\"eyJzdWIiOiJob3N0L2V4YW1wbGUiLCJpYXQiOjE0MDE5Mzg1NTIsImV4cCI6MTQwMTk0MjE1MiwiY2lkciI6WyJmZWMwOjovNjQiXX0=\",\"signature\":\"cw9S8Oxu8BmvDgEotBlNiZoJNkAGDpvGIuhCCnG-nMq80dy0ECjC4xERYXHx3bcadEJ8jWfqDB90d7CGvJyepbMhC1hEdsb8xNWGkkqTvQOh33cnZiEJjjfbORpKnOpcc8QySmB9Eb_zKl5WaM6Sjm-uINJri3djuVo_n_S7I43YvKw7gbd5u2gVttgaWnqlnJoeXZnnmXSYH8_66Lr__BqO4tCedShQIf4gA0R_dljrzVSZtJsFTKvwuNOuCvBqO8dQkhp8vplOkKynDkdip-H2nDBQb9Y3bQ8K0NVtSJatBy-d1HvPHSwFZrH4K7P_J2OgJtw9GtckT43QasliXoibdk__Hyvy4HJIIM44rSm7JUuyZWl8e8svRqLujBP7\"}".freeze
end
