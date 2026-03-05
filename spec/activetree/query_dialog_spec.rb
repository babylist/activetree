# frozen_string_literal: true

RSpec.describe ActiveTree::QueryDialog do
  subject(:dialog) { described_class.new(model_name: model_name, query: query) }

  let(:model_name) { "QueryTestModel" }
  let(:query) { "" }

  let(:mock_relation) do
    rel = double("Relation")
    allow(rel).to receive(:find_by).and_return(nil)
    allow(rel).to receive(:merge).and_return(rel)
    allow(rel).to receive(:offset).and_return(rel)
    allow(rel).to receive(:limit).and_return(rel)
    allow(rel).to receive(:to_a).and_return([])
    allow(rel).to receive(:instance_eval).and_return(rel)
    rel
  end

  let(:mock_class) do
    klass = double("ModelClass")
    allow(klass).to receive(:unscoped).and_return(mock_relation)
    klass
  end

  before do
    stub_const("QueryTestModel", mock_class)
  end

  describe "#initialize" do
    it "creates two fields" do
      expect(dialog.fields.size).to eq(2)
      expect(dialog.fields[0].name).to eq(:model)
      expect(dialog.fields[1].name).to eq(:query)
    end
  end

  describe "#execute" do
    context "with blank model" do
      let(:model_name) { "" }
      let(:query) { "all" }

      it "raises ArgumentError" do
        expect { dialog.execute }.to raise_error(ArgumentError, "Model class is required")
      end
    end

    context "with blank query" do
      let(:query) { "" }

      it "raises ArgumentError" do
        expect { dialog.execute }.to raise_error(ArgumentError, "Query is required")
      end
    end

    context "with unknown model" do
      let(:model_name) { "NoSuchModel" }
      let(:query) { "all" }

      before { hide_const("NoSuchModel") }

      it "raises ArgumentError" do
        expect { dialog.execute }.to raise_error(ArgumentError, "Model 'NoSuchModel' not found")
      end
    end

    context "with numeric query" do
      let(:query) { "42" }
      let(:record) { double("Record", id: 42) }

      it "finds record by ID" do
        allow(mock_relation).to receive(:find_by).with(id: 42).and_return(record)
        result = dialog.execute
        expect(result).to eq({ record: record })
      end

      it "raises when record not found" do
        allow(mock_relation).to receive(:find_by).with(id: 42).and_return(nil)
        expect { dialog.execute }.to raise_error(ArgumentError, /not found/)
      end
    end

    context "with DSL query returning one record" do
      let(:query) { "where(active: true)" }
      let(:record) { double("Record", id: 1) }
      let(:dsl_relation) { double("DslRelation") }

      before do
        allow(mock_relation).to receive(:instance_eval).with(query).and_return(dsl_relation)
        allow(dsl_relation).to receive(:limit).with(2).and_return(dsl_relation)
        allow(dsl_relation).to receive(:to_a).and_return([record])
      end

      it "returns the single record" do
        result = dialog.execute
        expect(result).to eq({ record: record })
      end
    end

    context "with DSL query returning multiple records" do
      let(:query) { "where(active: true)" }
      let(:records) { [double("R1"), double("R2")] }
      let(:dsl_relation) { double("DslRelation") }
      let(:fresh_relation) { double("FreshRelation") }

      before do
        call_count = 0
        allow(mock_relation).to receive(:instance_eval).with(query) do
          call_count += 1
          call_count == 1 ? dsl_relation : fresh_relation
        end
        allow(dsl_relation).to receive(:limit).with(2).and_return(dsl_relation)
        allow(dsl_relation).to receive(:to_a).and_return(records)
      end

      it "returns relation and description" do
        result = dialog.execute
        expect(result[:relation]).to eq(fresh_relation)
        expect(result[:description]).to eq("QueryTestModel.where(active: true)")
      end
    end

    context "with DSL query returning no results" do
      let(:query) { "where(active: true)" }
      let(:dsl_relation) { double("DslRelation") }

      before do
        allow(mock_relation).to receive(:instance_eval).with(query).and_return(dsl_relation)
        allow(dsl_relation).to receive(:limit).with(2).and_return(dsl_relation)
        allow(dsl_relation).to receive(:to_a).and_return([])
      end

      it "raises ArgumentError" do
        expect { dialog.execute }.to raise_error(ArgumentError, /No results/)
      end
    end

    context "with DSL query that raises an error" do
      let(:query) { "bad_method" }

      before do
        allow(mock_relation).to receive(:instance_eval)
          .with(query)
          .and_raise(NoMethodError, "undefined method 'bad_method'")
      end

      it "wraps the error in ArgumentError" do
        expect { dialog.execute }.to raise_error(ArgumentError, /bad_method/)
      end
    end

    context "with global_scope configured" do
      let(:query) { "42" }
      let(:record) { double("Record", id: 42) }
      let(:scope) { double("Scope") }
      let(:scoped_relation) { double("ScopedRelation") }

      before do
        ActiveTree.config.global_scope = scope
        allow(mock_relation).to receive(:merge).with(scope).and_return(scoped_relation)
        allow(scoped_relation).to receive(:find_by).with(id: 42).and_return(record)
      end

      it "applies the global scope" do
        result = dialog.execute
        expect(result).to eq({ record: record })
        expect(mock_relation).to have_received(:merge).with(scope)
      end
    end
  end
end
