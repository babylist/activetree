# frozen_string_literal: true

RSpec.describe ActiveTree::Configuration::Dsl do
  let(:configuration) { ActiveTree::Configuration.new }
  subject(:dsl) { described_class.new(configuration) }

  describe "#max_depth" do
    it "sets the configuration max_depth" do
      dsl.max_depth(10)
      expect(configuration.max_depth).to eq(10)
    end
  end

  describe "#default_limit" do
    it "sets the configuration default_limit" do
      dsl.default_limit(50)
      expect(configuration.default_limit).to eq(50)
    end
  end

  describe "#global_scope" do
    it "sets the configuration global_scope" do
      block = -> { where(org_id: 1) }
      dsl.global_scope(&block)
      expect(configuration.global_scope).to eq(block)
    end
  end

  describe "#model" do
    it "creates a model configuration by string name" do
      dsl.model("User") do
        field :email
      end

      model_config = configuration.model_configuration("User")
      expect(model_config.fields.keys).to eq([:email])
    end

    it "returns the model configuration" do
      result = dsl.model("User") { field :id }
      expect(result).to be_a(ActiveTree::Configuration::Model)
    end

    it "delegates fields correctly" do
      dsl.model("Order") do
        fields :id, :total, :status
      end

      model_config = configuration.model_configuration("Order")
      expect(model_config.fields.keys).to eq(%i[id total status])
    end

    it "delegates children correctly" do
      dsl.model("User") do
        children :orders, :shipments
      end

      model_config = configuration.model_configuration("User")
      expect(model_config.children.keys).to eq(%i[orders shipments])
    end

    it "delegates label correctly" do
      dsl.model("User") do
        label { |r| "user-#{r.id}" }
      end

      model_config = configuration.model_configuration("User")
      instance = double("Instance", id: 42)
      expect(model_config.label(instance)).to eq("user-42")
    end
  end
end
