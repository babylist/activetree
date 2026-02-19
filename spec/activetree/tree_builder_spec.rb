# frozen_string_literal: true

RSpec.describe ActiveTree::TreeBuilder do
  subject(:builder) { described_class.new(config: config) }

  let(:config) { ActiveTree::Configuration.new }

  describe "#discover!" do
    it "returns an empty array when ActiveRecord is not defined" do
      expect(builder.discover!).to eq([])
    end
  end

  describe "#to_tree_data" do
    it "returns a no-models tree when ActiveRecord is not defined" do
      expect(builder.to_tree_data).to eq({ "No models found" => [] })
    end
  end
end
