# frozen_string_literal: true

RSpec.describe ActiveTree do
  it "has a version number" do
    expect(ActiveTree::VERSION).not_to be_nil
  end

  describe ActiveTree::Configuration do
    subject(:config) { described_class.new }

    it "defaults excluded_models to an empty array" do
      expect(config.excluded_models).to eq([])
    end

    it "defaults max_depth to 3" do
      expect(config.max_depth).to eq(3)
    end

    it "allows setting excluded_models" do
      config.excluded_models = ["User"]
      expect(config.excluded_models).to eq(["User"])
    end

    it "allows setting max_depth" do
      config.max_depth = 5
      expect(config.max_depth).to eq(5)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      ActiveTree.configure do |c|
        expect(c).to be_a(ActiveTree::Configuration)
      end
    end
  end
end
