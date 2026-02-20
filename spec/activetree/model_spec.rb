# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::Model do
  let(:model_class) do
    Class.new do
      # Simulate class_attribute from ActiveSupport
      def self.name
        "TestModel"
      end

      def id
        42
      end

      include ActiveTree::Model
    end
  end

  describe "class methods" do
    it "defaults _tree_fields to nil" do
      expect(model_class._tree_fields).to be_nil
    end

    it "defaults _tree_children to empty array" do
      expect(model_class._tree_children).to eq([])
    end

    it "defaults _tree_label_block to nil" do
      expect(model_class._tree_label_block).to be_nil
    end

    it "stores tree_fields" do
      model_class.tree_fields :id, :name, :email
      expect(model_class._tree_fields).to eq(%i[id name email])
    end

    it "stores tree_children" do
      model_class.tree_children :orders, :shipments
      expect(model_class._tree_children).to eq(%i[orders shipments])
    end

    it "stores tree_label block" do
      model_class.tree_label { |r| "Custom #{r.id}" }
      expect(model_class._tree_label_block).to be_a(Proc)
    end
  end

  describe "instance methods" do
    let(:instance) { model_class.new }

    it "returns default label when no block configured" do
      expect(instance.tree_node_label).to eq("TestModel #42")
    end

    it "returns custom label when block configured" do
      model_class.tree_label { |r| "Record-#{r.id}" }
      expect(instance.tree_node_label).to eq("Record-42")
    end

    it "returns tree_node_fields" do
      model_class.tree_fields :id, :status
      expect(instance.tree_node_fields).to eq(%i[id status])
    end

    it "returns tree_node_children" do
      model_class.tree_children :items
      expect(instance.tree_node_children).to eq([:items])
    end
  end

  describe "subclass inheritance" do
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

    it "inherits tree_fields from parent" do
      parent_class.tree_fields :id, :name
      expect(child_class._tree_fields).to eq(%i[id name])
    end

    it "can override tree_fields in child" do
      parent_class.tree_fields :id, :name
      child_class.tree_fields :id, :status
      expect(child_class._tree_fields).to eq(%i[id status])
      expect(parent_class._tree_fields).to eq(%i[id name])
    end
  end
end
