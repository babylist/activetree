# frozen_string_literal: true

require "tty-box"
require "pastel"

RSpec.describe ActiveTree::DialogRenderer do
  subject(:renderer) { described_class.new }

  let(:dialog) do
    ActiveTree::Dialog.new(
      title: "Test Dialog",
      fields: [
        ActiveTree::DialogField.new(name: :model, label: "Model class", value: "User"),
        ActiveTree::DialogField.new(name: :query, label: "Query", value: "")
      ]
    )
  end

  let(:output) { renderer.render(dialog, 80, 24) }

  it "contains the dialog title" do
    expect(output).to include("Test Dialog")
  end

  it "contains field labels" do
    expect(output).to include("Model class:")
    expect(output).to include("Query:")
  end

  it "contains footer help text" do
    expect(output).to include("Tab: next")
    expect(output).to include("Enter: submit")
    expect(output).to include("Esc: cancel")
  end

  it "uses TTY::Box frame characters" do
    # TTY::Box thick border uses unicode box-drawing characters
    expect(output).to include("\u2554").or include("\u250F") # top-left corners
  end

  context "when error message is set" do
    before { dialog.error_message = "Something went wrong" }

    it "includes the error message" do
      expect(output).to include("Something went wrong")
    end
  end
end
