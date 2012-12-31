module Slosilo
  module Rack
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
        
        verify
        decrypt
        @app.call env
      rescue EncryptionError
        error 403, $!.message
      rescue SignatureError
        error 401, $!.message
      end
      
      private
      def verify
        if signature
          puts "looking at token: #{token.inspect}"
          raise SignatureError, "Bad signature" unless Slosilo.token_valid?(token)
        else
          raise SignatureError, "Signature required" if signature_required?
        end
      end
      
      attr_reader :env
      
      def token
        { data: { path: path, body: body }, timestamp: timestamp, signature: signature } if signature
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
      
      def body
        @body ||= env['rack.input'].read
      end
      
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
          raise EncryptionError("Encryption required") if encryption_required?
        end
      end
      
      def decrypt
        return unless key
        plaintext = Slosilo[:own].decrypt body, key
        env['rack.input'] = StringIO.new plaintext
      rescue EncryptionError
        raise
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
