module Slosilo
  module Rack
    class Middleware
      class BadEncryption < SecurityError
      end
      class BadSignature < SecurityError
      end
      class SignatureRequired < SecurityError
      end

      def initialize app, opts = {}
        @app = app
        @encryption_required = opts[:encryption_required] || false
        @signature_required = opts[:signature_required] || false
      end
      
      def call env
        @env = env
        if decrypt(env) == :not_encrypted && encryption_required?
          error 403, encryption_required_message
        else
          verify
          @app.call env
        end
      rescue BadEncryption
        error 403, bad_encryption_message
      rescue SignatureRequired
        error 401, "Signature required"
      rescue BadSignature
        error 401, "Bad signature"
      end
      
      private
      def verify
        raise SignatureRequired unless !signature_required? || signature
        raise BadSignature unless signature.nil? || Slosilo.token_valid?(token)
      end
      
      attr_reader :env
      
      def token
        { data: { path: path, body: body }, timestamp: timestamp, signature: signature } if signature
      end
      
      def path
        env['SCRIPT_NAME'] + env['PATH_INFO'] + query_string
      end
      
      def query_string
        '?' + env['QUERY_STRING'] if env['QUERY_STRING'] 
      end
      
      def body
        env['rack.input'].read
      end
      
      def timestamp
        env['HTTP_TIMESTAMP']
      end
      
      def signature
        env['HTTP_X_SLOSILO_SIGNATURE']
      end
      
      def decrypt env
        if key = env['HTTP_X_SLOSILO_KEY']
          key = Base64::urlsafe_decode64(key)
          ciphertext = env['rack.input'].read
          plaintext = Slosilo[:own].decrypt ciphertext, key
          env['rack.input'] = StringIO.new plaintext
        else
          :not_encrypted
        end
      rescue Exception => e
        raise BadEncryption.new e
      end
      
      def error status, message
        [status, { 'Content-Type' => 'text/plain', 'Content-Length' => message.length.to_s }, [message] ]
      end
      
      def bad_encryption_message
        "Bad encryption key used"
      end
      
      def encryption_required_message
        "Encryption is required"
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
