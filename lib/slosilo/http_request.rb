module Slosilo
  class HTTPRequest
    def encrypt! keyname
      self.body, self['X-Slosilo-Key'] = Slosilo[keyname].encrypt body
    end
  end
end
