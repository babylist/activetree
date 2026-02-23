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
      expect(field.label).to eq(:email)
    end

    it "accepts a custom label" do
      config.configure_field(:email, "Email Address")
      field = config.fields[:email]
      expect(field.label).to eq("Email Address")
    end
  end

  describe "#configure_fields" do
    it "adds multiple fields" do
      config.configure_fields(:id, :name, :email)
      expect(config.fields.keys).to eq(%i[id name email])
    end
  end

  describe "#configure_child" do
    it "adds a child with name as default label" do
      config.configure_child(:orders)
      child = config.children[:orders]
      expect(child.name).to eq(:orders)
      expect(child.label).to eq(:orders)
    end

    it "accepts a custom label" do
      config.configure_child(:orders, "Customer Orders")
      child = config.children[:orders]
      expect(child.label).to eq("Customer Orders")
    end
  end

  describe "#configure_children" do
    it "adds multiple children" do
      config.configure_children(:orders, :shipments)
      expect(config.children.keys).to eq(%i[orders shipments])
    end
  end

  describe ActiveTree::Configuration::Model::Field do
    it "defaults label to name" do
      field = described_class.new(:email)
      expect(field.name).to eq(:email)
      expect(field.label).to eq(:email)
    end

    it "uses provided label" do
      field = described_class.new(:email, "Email Address")
      expect(field.label).to eq("Email Address")
    end
  end

  describe ActiveTree::Configuration::Model::Child do
    it "defaults label to name" do
      child = described_class.new(:orders)
      expect(child.name).to eq(:orders)
      expect(child.label).to eq(:orders)
    end

    it "uses provided label" do
      child = described_class.new(:orders, "Customer Orders")
      expect(child.label).to eq("Customer Orders")
    end
  end
end
