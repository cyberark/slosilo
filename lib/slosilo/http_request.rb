module Slosilo
  # A mixin module which simplifies generating signed and encrypted requests.
  # It's designed to be mixed into a standard Net::HTTPRequest object
  # and ensures the request is signed and optionally encrypted before execution.
  # Requests prepared this way will be recognized by Slosilo::Rack::Middleware.
  #
  # As an example, you can use it with RestClient like so:
  #   RestClient.add_before_execution_proc do |req, params|
  #     require 'slosilo'
  #     req.extend Slosilo::HTTPRequest
  #     req.keyname = :somekey
  #   end
  #
  # The request won't be encrypted unless you set the destination keyname.
  
  module HTTPRequest
    # Encrypt the request with key named @keyname from Slosilo::Keystore. 
    # If calling this manually, make sure to encrypt before signing.
    def encrypt!
      return unless @keyname
      return unless body && !body.empty?
      self.body, key = Slosilo[@keyname].encrypt body
      self['X-Slosilo-Key'] = Base64::urlsafe_encode64 key
    end
    
    # Sign the request with :own key from Slosilo::Keystore. 
    # If calling this manually, make sure to encrypt before signing.
    def sign!
      # Hmm, I'm not sure whether we should update this to include an expiration
      # in a header, or just continue to leave out the expiration field.  Leaving it
      # out requires fewer changes (to Slosilo::Rack::MiddleWare) so I'm going with 
      # that for now.
      token = Slosilo[:own].signed_token signed_data, expiration: false
      self['Timestamp'] = token["timestamp"]
      self['X-Slosilo-Signature'] = token["signature"]
    end
    
    # Build the data hash to sign.
    def signed_data
      data = { "path" => path, "body" => [body].pack('m0') }
      if key = self['X-Slosilo-Key']
        data["key"] = key
      end
      if authz = self['Authorization']
        data["authorization"] = authz
      end
      data
    end
    
    # Encrypt, sign and execute the request.
    def exec *a
      # we need to hook here because the body might be set
      # in several ways and here it's hopefully finalized
      encrypt!
      sign!
      super *a
    end
    
    # Name of the key used to encrypt the request. 
    # Use it to establish the identity of the receiver.
    attr_accessor :keyname
  end
end
