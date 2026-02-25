# frozen_string_literal: true

RSpec.describe ActiveTree::Configuration::ModelDsl do
  let(:model_config) { ActiveTree::Configuration::Model.new("TestModel") }
  subject(:dsl) { described_class.new(model_config) }

  describe "#field" do
    it "delegates to configure_field" do
      dsl.field(:email)
      expect(model_config.fields[:email].name).to eq(:email)
    end

    it "passes label option" do
      dsl.field(:email, label: "Email Address")
      expect(model_config.fields[:email].label).to eq("Email Address")
    end
  end

  describe "#fields" do
    it "delegates to configure_fields" do
      dsl.fields(:id, :name, :email)
      expect(model_config.fields.keys).to eq(%i[id name email])
    end
  end

  describe "#child" do
    it "delegates to configure_child" do
      dsl.child(:orders)
      expect(model_config.children[:orders].name).to eq(:orders)
    end

    it "passes label option" do
      dsl.child(:orders, label: "Customer Orders")
      expect(model_config.children[:orders].label).to eq("Customer Orders")
    end

    it "accepts a positional scope proc" do
      scope_proc = -> { where(active: true) }
      dsl.child(:orders, scope_proc)
      expect(model_config.children[:orders].scope).to be(scope_proc)
    end
  end

  describe "#children" do
    it "delegates to configure_children" do
      dsl.children(:orders, :shipments)
      expect(model_config.children.keys).to eq(%i[orders shipments])
    end
  end

  describe "#label" do
    it "delegates to configure_label" do
      dsl.label { |r| "custom-#{r.id}" }
      instance = double("Instance", id: 5)
      expect(model_config.label(instance)).to eq("custom-5")
    end
  end
end
