module Slosilo
  unless defined? V1_WARNED
    puts """
      WARNING!! You are loading compatibility Slosilo code. It has known potential
      security problems and is deprecated; this code is ONLY meant to be used in
      migrations and tests.
    """
    V1_WARNED = true
  end
end

require 'slosilo/v1/attr_encrypted'
require 'slosilo/v1/symmetric'
