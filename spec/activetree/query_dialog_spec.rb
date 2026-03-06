# frozen_string_literal: true

RSpec.describe ActiveTree::QueryDialog do
  subject(:dialog) { described_class.new(model_name: model_name, query: query) }

  let(:model_name) { "QueryTestModel" }
  let(:query) { "" }

  describe "#initialize" do
    it "creates two fields" do
      expect(dialog.fields.size).to eq(2)
      expect(dialog.fields[0].name).to eq(:model)
      expect(dialog.fields[1].name).to eq(:query)
    end

    it "populates fields with provided values" do
      dialog = described_class.new(model_name: "User", query: "42")
      expect(dialog.fields[0].value).to eq("User")
      expect(dialog.fields[1].value).to eq("42")
    end
  end

  describe "#root_query" do
    it "delegates to RootQuery" do
      dialog = described_class.new(model_name: "User", query: "42")
      result = { record: double("Record") }
      root_query = instance_double(ActiveTree::RootQuery, result:)
      allow(ActiveTree::RootQuery).to receive(:new).with("User", "42").and_return(root_query)

      expect(dialog.root_query).to eq(root_query)
      expect(ActiveTree::RootQuery).to have_received(:new).with("User", "42")
    end
  end
end
