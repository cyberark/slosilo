module Slosilo
  module Rack
    # Con perform verification of request signature and decryption of request body.
    #
    # Signature verification and body decryption are enabled with constructor switches and are 
    # therefore performed (or not) for all requests.
    #
    # When signature verification is performed, the following elements are included in the 
    # signature string:
    # 
    # 1. Request path and query string
    # 2. base64 encoded request body
    # 3. Request timestamp from HTTP_TIMESTAMP
    # 4. Body encryption key from HTTP_X_SLOSILO_KEY (if present)
    # 
    # When body decryption is performed, an encryption key for the message body is encrypted
    # with this service's public key and placed in HTTP_X_SLOSILO_KEY. This middleware
    # decryps the key using our :own private key, and then decrypts the body using the decrypted key.
    class Middleware
      class EncryptionError < SecurityError
      end
      class SignatureError < SecurityError
      end

      def initialize app, opts = {}
        @app = app
        @encryption_required = opts[:encryption_required] || false
        @signature_required = opts[:signature_required] || false
      end
      
      def call env
        @env = env
        @body = env['rack.input'].read rescue ""
        
        begin
          verify
          decrypt
        rescue EncryptionError
          return error 403, $!.message
        rescue SignatureError
          return error 401, $!.message
        end
        
        @app.call env
      end
      
      private
      def verify
        if signature
          raise SignatureError, "Bad signature" unless Slosilo.token_valid?(token)
        else
          raise SignatureError, "Signature required" if signature_required?
        end
      end
      
      attr_reader :env
      
      def token
        return nil unless signature
        t = { "data" => { "path" => path, "body" => [body].pack('m0') }, "timestamp" => timestamp, "signature" => signature }
        t["data"]["key"] = encoded_key if encoded_key
        t['data']['authorization'] = env['HTTP_AUTHORIZATION'] if env['HTTP_AUTHORIZATION']
        t
      end
      
      def path
        env['SCRIPT_NAME'] + env['PATH_INFO'] + query_string
      end
      
      def query_string
        if env['QUERY_STRING'].empty?
          ''
        else
          '?' + env['QUERY_STRING']
        end
      end

      attr_reader :body
      
      def timestamp
        env['HTTP_TIMESTAMP']
      end
      
      def signature
        env['HTTP_X_SLOSILO_SIGNATURE']
      end
      
      def encoded_key
        env['HTTP_X_SLOSILO_KEY']
      end
      
      def key
        if encoded_key
          Base64::urlsafe_decode64(encoded_key)
        else
          raise EncryptionError, "Encryption required" if encryption_required?
        end
      end
      
      def decrypt
        return unless key
        plaintext = Slosilo[:own].decrypt body, key
        env['rack.input'] = StringIO.new plaintext
      rescue EncryptionError
        raise unless body.empty? || body.nil?
      rescue Exception => e
        raise EncryptionError, "Bad encryption", e.backtrace
      end
      
      def error status, message
        [status, { 'Content-Type' => 'text/plain', 'Content-Length' => message.length.to_s }, [message] ]
      end
      
      def encryption_required?
        @encryption_required
      end
      
      def signature_required?
        @signature_required
      end
    end
  end
end
