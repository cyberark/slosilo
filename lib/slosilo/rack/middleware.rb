module Slosilo
  module Rack
    class Middleware
      class BadEncryption < SecurityError
      end

      def initialize app, opts = {}
        @app = app
        @encryption_required = opts[:encryption_required] || false
      end
      
      def call env
        if decrypt(env) == :not_encrypted && encryption_required?
          error encryption_required_message
        else
          @app.call env
        end
      rescue BadEncryption
        error bad_encryption_message
      end
      
      private
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
      
      def error message
        [403, { 'Content-Type' => 'text/plain', 'Content-Length' => message.length }, message ]
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
    end
  end
end
