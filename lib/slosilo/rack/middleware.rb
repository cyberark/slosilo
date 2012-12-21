module Slosilo
  module Rack
    class Middleware
      class BadEncryption < SecurityError
      end

      def initialize app
        @app = app
      end
      
      def call env
        decrypt env
        @app.call env
      rescue BadEncryption
        error
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
      
      def error
        [403, { 'Content-Type' => 'text/plain', 'Content-Length' => error_message.length }, error_message ]
      end
      
      def error_message
        "Bad encryption key used"
      end
    end
  end
end
