module Slosilo
  class << self
    def []= id, value
      require 'slosilo/model'
      Key.create id: id, key: value.to_der
    end
  end
end
