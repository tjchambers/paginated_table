require 'test_helper'

module PaginatedTable
  module View
    describe TableDescription do
      let(:options) { {} }
      let(:description) { TableDescription.new(options) }

      describe "#column" do
        let(:row) { row = stub("row", :column => nil) }

        before do
          RowDescription.stubs(:new).returns(row)
        end

        describe "when first called in a table description" do
          it "creates a new row" do
            description.column
            description.rows.must_equal [row]
          end

          it "calls column on the row" do
            args = [stub("arg1"), stub("arg2")]
            row.expects(:column).with(*args)
            description.column(*args)
          end
        end

        describe "when subsequently called in a table description" do
          before do
            description.column
          end

          it "does not create a new row" do
            description.expects(:row).never
            description.column
          end

          it "calls column on the default row" do
            args = [stub("arg1"), stub("arg2")]
            row.expects(:column).with(*args)
            description.column(*args)
          end
        end

        describe "when called after row has been called by a table description" do
          before do
            description.row
          end

          it "raises TableDescription::Invalid" do
            lambda { description.column }.must_raise TableDescription::Invalid
          end
        end

      end

      describe "#row" do
        it "constructs a new RowDescription and appends it to the rows array" do
          row = stub("row")
          row_options = stub("options")
          RowDescription.stubs(:new).with(description, row_options, nil).returns(row)
          description.row(row_options)
          description.rows.must_equal [row]
        end
      end

      describe "#colspan" do
        before do
          description.row do |row|
            row.column 'foo'
            row.column 'bar'
          end
          description.row do |row|
            row.column 'foo'
            row.column 'bar'
            row.column 'baz'
          end
        end

        it "returns the maximum number of columns in a row as a string for :all" do
          description.colspan(:all).must_equal '3'
        end

        it "returns ArgumentError otherwise" do
          lambda { description.colspan(:foo) }.must_raise ArgumentError
        end
      end

      describe "#model_label" do
        it "returns the model_label option" do
          options[:model_label] = model_label = stub("model_label")
          description.model_label.must_equal model_label
        end
      end
    end
  end
end
