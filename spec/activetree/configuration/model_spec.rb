# frozen_string_literal: true

RSpec.describe ActiveTree::Configuration::Model do
  let(:model_class) { Class.new { def self.name = "Widget" } }
  subject(:config) { described_class.new(model_class) }

  describe "defaults" do
    it "has empty fields" do
      expect(config.fields).to eq({})
    end

    it "has empty children" do
      expect(config.children).to eq({})
    end

    it "stores the model class" do
      expect(config.model_class).to eq(model_class)
    end

    it "stores the model class name" do
      expect(config.model_class_name).to eq("Widget")
    end
  end

  context "when constructed with a string" do
    subject(:config) { described_class.new("StringOnlyModel") }

    it "has empty fields" do
      expect(config.fields).to eq({})
    end

    it "has empty children" do
      expect(config.children).to eq({})
    end

    it "stores the model class name" do
      expect(config.model_class_name).to eq("StringOnlyModel")
    end

    it "returns nil for model_class when class does not exist" do
      expect(config.model_class).to be_nil
    end
  end

  describe "#label" do
    it "returns default format" do
      instance = double("Instance", class: model_class, id: 7)
      expect(config.label(instance)).to eq("Widget #7")
    end
  end

  describe "#configure_label" do
    it "overrides the label block" do
      config.configure_label { |r| "custom-#{r.id}" }
      instance = double("Instance", id: 3)
      expect(config.label(instance)).to eq("custom-3")
    end
  end

  describe "#configure_field" do
    it "adds a field with name as default label" do
      config.configure_field(:email)
      field = config.fields[:email]
      expect(field.name).to eq(:email)
      expect(field.label).to eq("email")
    end

    it "accepts a custom label" do
      config.configure_field(:email, label: "Email Address")
      field = config.fields[:email]
      expect(field.label).to eq("Email Address")
    end
  end

  describe "#configure_fields" do
    it "adds multiple fields from array" do
      config.configure_fields(%i[id name email])
      expect(config.fields.keys).to eq(%i[id name email])
    end

    it "adds multiple fields from array with options" do
      config.configure_fields([:id, :name, { email: { label: "Email Address" } }])
      expect(config.fields.keys).to eq(%i[id name email])
      expect(config.fields.values.map(&:label)).to eq(["id", "name", "Email Address"])
    end
  end

  describe "#configure_child" do
    it "adds a child with name as default label" do
      config.configure_child(:orders)
      child = config.children[:orders]
      expect(child.name).to eq(:orders)
      expect(child.label).to eq("orders")
    end

    it "accepts a custom label" do
      config.configure_child(:orders, label: "Customer Orders")
      child = config.children[:orders]
      expect(child.label).to eq("Customer Orders")
    end
  end

  describe "#configure_children" do
    it "adds multiple children" do
      config.configure_children(%i[orders shipments])
      expect(config.children.keys).to eq(%i[orders shipments])
    end
  end

  describe ActiveTree::Configuration::Model::Field do
    it "defaults label to name" do
      field = described_class.new(:email)
      expect(field.name).to eq(:email)
      expect(field.label).to eq("email")
    end

    it "uses provided label" do
      field = described_class.new(:email, label: "Email Address")
      expect(field.label).to eq("Email Address")
    end
  end

  describe ActiveTree::Configuration::Model::Child do
    it "defaults label to name" do
      child = described_class.new(:orders)
      expect(child.name).to eq(:orders)
      expect(child.label).to eq("orders")
    end

    it "uses provided label" do
      child = described_class.new(:orders, label: "Customer Orders")
      expect(child.label).to eq("Customer Orders")
    end

    it "defaults scope to nil" do
      child = described_class.new(:orders)
      expect(child.scope).to be_nil
    end

    it "stores and exposes a scope proc" do
      scope_proc = -> { approved }
      child = described_class.new(:orders, scope: scope_proc)
      expect(child.scope).to be(scope_proc)
    end
  end
end
