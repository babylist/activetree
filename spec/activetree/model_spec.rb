# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::Model do
  let(:model_class) do
    Class.new do
      def self.name
        "TestModel"
      end

      def id
        42
      end

      include ActiveTree::Model
    end
  end

  describe ".tree_configuration" do
    it "returns a Configuration::Model for the class" do
      expect(model_class.tree_configuration).to be_a(ActiveTree::Configuration::Model)
    end

    it "returns the same configuration on repeated calls" do
      expect(model_class.tree_configuration).to be(model_class.tree_configuration)
    end
  end

  describe ".tree_fields" do
    it "registers fields in the configuration" do
      model_class.tree_fields :id, :name, :email
      fields = model_class.tree_configuration.fields
      expect(fields.keys).to eq(%i[id name email])
    end

    it "accepts options per field" do
      model_class.tree_fields :id, { name: { label: "Full Name" } }
      field = model_class.tree_configuration.fields[:name]
      expect(field.label).to eq("Full Name")
    end
  end

  describe ".tree_field" do
    it "registers a single field" do
      model_class.tree_field :name
      fields = model_class.tree_configuration.fields
      expect(fields.keys).to eq([:name])
    end

    it "accepts an optional label" do
      model_class.tree_field :name, label: "Full Name"
      field = model_class.tree_configuration.fields[:name]
      expect(field.label).to eq("Full Name")
    end
  end

  describe ".tree_children" do
    it "registers children in the configuration" do
      model_class.tree_children :orders, :shipments
      children = model_class.tree_configuration.children
      expect(children.keys).to eq(%i[orders shipments])
    end

    it "accepts options per child" do
      model_class.tree_children :orders, { shipments: { label: "User Shipments" } }
      child = model_class.tree_configuration.children[:shipments]
      expect(child.label).to eq("User Shipments")
    end
  end

  describe ".tree_child" do
    it "registers a single child" do
      model_class.tree_child :orders
      children = model_class.tree_configuration.children
      expect(children.keys).to eq([:orders])
    end

    it "accepts an optional label" do
      model_class.tree_child :orders, label: "Customer Orders"
      child = model_class.tree_configuration.children[:orders]
      expect(child.label).to eq("Customer Orders")
    end
  end

  describe ".tree_label" do
    it "sets a custom label block" do
      model_class.tree_label { |r| "Record-#{r.id}" }
      instance = model_class.new
      expect(model_class.tree_configuration.label(instance)).to eq("Record-42")
    end
  end

  describe "subclass independence" do
    let(:parent_class) do
      Class.new do
        def self.name
          "Parent"
        end

        def id
          1
        end

        include ActiveTree::Model
      end
    end

    let(:child_class) do
      Class.new(parent_class) do
        def self.name
          "Child"
        end
      end
    end

    it "gives each class its own configuration" do
      parent_class.tree_fields :id, :name
      child_class.tree_fields :id, :status

      expect(parent_class.tree_configuration.fields.keys).to eq(%i[id name])
      expect(child_class.tree_configuration.fields.keys).to eq(%i[id status])
    end

    it "does not inherit parent configuration" do
      parent_class.tree_fields :id, :name
      expect(child_class.tree_configuration.fields).to be_empty
    end
  end
end
