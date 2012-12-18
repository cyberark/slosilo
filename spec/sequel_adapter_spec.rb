require 'spec_helper'

require 'slosilo/adapters/sequel_adapter'

describe Slosilo::Adapters::SequelAdapter do
  let(:model) { double "model" }
  before { subject.stub create_model: model }
  
  describe "#get_key" do
    context "when given key does not exist" do
      before { model.stub :[] => nil }
      it "returns nil" do
        subject.get_key(:whatever).should_not be
      end
    end
  end
end
