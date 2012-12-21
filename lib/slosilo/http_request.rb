module Slosilo
  module HTTPRequest
    def encrypt!
      return unless @keyname
      self.body, key = Slosilo[@keyname].encrypt body
      self['X-Slosilo-Key'] = Base64::urlsafe_encode64 key
    end
    
    def exec *a
      # we need to hook here because the body might be set
      # in several ways and here it's hopefully finalized
      encrypt!
      super *a
    end
    
    attr_accessor :keyname
  end
end
