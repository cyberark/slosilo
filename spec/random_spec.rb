require 'spec_helper'

describe Slosilo::Random do
  subject { Slosilo::Random }
  let(:other_salt) { Slosilo::Random::salt }
  
  its('salt.length') { should == 32 }
  its(:salt) { should_not == other_salt }
end
