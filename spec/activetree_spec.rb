# frozen_string_literal: true

RSpec.describe ActiveTree do
  it "has a version number" do
    expect(ActiveTree::VERSION).not_to be_nil
  end

  describe ActiveTree::Configuration do
    subject(:config) { described_class.new }

    it "defaults max_depth to 3" do
      expect(config.max_depth).to eq(3)
    end

    it "defaults default_limit to 25" do
      expect(config.default_limit).to eq(25)
    end

    it "allows setting max_depth" do
      config.max_depth = 5
      expect(config.max_depth).to eq(5)
    end

    it "allows setting default_limit" do
      config.default_limit = 50
      expect(config.default_limit).to eq(50)
    end

    it "returns and memoizes model_configuration by class" do
      klass = Class.new { def self.name = "TestWidget" }
      model_config = config.model_configuration(klass)
      expect(model_config).to be_a(ActiveTree::Configuration::Model)
      expect(config.model_configuration(klass)).to be(model_config)
    end

    it "returns and memoizes model_configuration by string" do
      model_config = config.model_configuration("Product")
      expect(model_config).to be_a(ActiveTree::Configuration::Model)
      expect(config.model_configuration("Product")).to be(model_config)
    end

    it "resolves string and class to the same model_configuration" do
      klass = Class.new { def self.name = "Gadget" }
      by_class = config.model_configuration(klass)
      by_string = config.model_configuration("Gadget")
      expect(by_class).to be(by_string)
    end
  end

  describe ".configure" do
    it "yields the configuration in yield-style" do
      ActiveTree.configure do |c|
        expect(c).to be_a(ActiveTree::Configuration)
      end
    end

    it "supports DSL-style without block parameter" do
      ActiveTree.configure do
        max_depth 10
        default_limit 100
      end

      expect(ActiveTree.config.max_depth).to eq(10)
      expect(ActiveTree.config.default_limit).to eq(100)
    end

    it "merges initializer DSL and Model concern configs into one instance" do
      # Simulate initializer DSL
      ActiveTree.configure do
        model "MergeTestModel" do
          field :name
        end
      end

      # Simulate Model concern (passing the class)
      klass = Class.new { def self.name = "MergeTestModel" }
      ActiveTree.config.model_configuration(klass).configure_field(:email)

      model_config = ActiveTree.config.model_configuration("MergeTestModel")
      expect(model_config.fields.keys).to contain_exactly(:name, :email)
    end

    it "last-write-wins for same field defined both ways" do
      ActiveTree.configure do
        model "OverwriteTestModel" do
          field :name, label: "First"
        end
      end

      klass = Class.new { def self.name = "OverwriteTestModel" }
      ActiveTree.config.model_configuration(klass).configure_field(:name, label: "Second")

      model_config = ActiveTree.config.model_configuration("OverwriteTestModel")
      expect(model_config.fields[:name].label).to eq("Second")
    end
  end
end
