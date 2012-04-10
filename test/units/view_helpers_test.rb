require 'test_helper'

module PaginatedTable
  describe ViewHelpers do
    let(:params) { stub("params") }
    let(:view) {
      view = Object.new
      view.send(:extend, ViewHelpers)
      view.stubs("params" => params)
      view
    }
    let(:collection) { stub("collection") }
    let(:description_block) { lambda {} }

    describe "#paginated_table" do
      it "renders a table" do
        table_description = stub("table_description")
        TableDescription.stubs("new").with(description_block).returns(table_description)
        page = stub("page")
        PageParams.stubs("create_page_from_params").with(params).returns(page)
        link_renderer = stub("link_renderer")
        LinkRenderer.stubs("new").with(page).returns(link_renderer)
        table_renderer = stub("table_renderer")
        RendersTable.stubs("new").
          with(view, table_description, collection, link_renderer).
          returns(table_renderer)
        table_renderer.expects("render")
        view.paginated_table(collection, &description_block)
      end
    end
  end

  describe TableDescription do
    describe "#initialize" do
      it "creates a new instance with empty columns" do
        TableDescription.new.columns.must_equal []
      end

      it "calls the given block with itself" do
        fake_proc = stub("proc")
        fake_proc.expects(:call)
        TableDescription.new(fake_proc)
      end
    end

    describe "#column" do
      it "constructs a new Column and appends it to the columns array" do
        column = stub("column")
        TableDescription::Column.stubs(:new).with(:foo).returns(column)
        description = TableDescription.new
        description.column(:foo)
        description.columns.must_equal [column]
      end
    end
  end

  describe TableDescription::Column do
    describe "#initialize" do
      it "creates a new instance with a name and an optional block" do
        TableDescription::Column.new(:foo) { true }
      end

      it "accepts an options hash" do
        TableDescription::Column.new(:foo, :baz => 'bat')
      end
    end

    describe "#sortable?" do
      it "returns true by default" do
        TableDescription::Column.new(:foo).sortable?.must_equal true
      end

      it "returns false if the :sortable option is false" do
        TableDescription::Column.new(:foo, :sortable => false).sortable?.must_equal false
      end
    end

    describe "#render_header" do
      it "returns the titleized name" do
        TableDescription::Column.new(:foo).render_header.must_equal "Foo"
      end
    end

    describe "#render_cell" do
      let(:results) { stub("results") }

      describe "on a column with no block" do
        let(:column) { TableDescription::Column.new(:foo) }

        it "sends its name to the datum" do
          datum = stub("datum", :foo => results)
          column.render_cell(datum).must_equal results
        end
      end

      describe "on a column with a block" do
        it "calls its block with the datum" do
          datum = stub("datum")
          column = TableDescription::Column.new(:foo) do |block_arg|
            results if block_arg == datum
          end
          column.render_cell(datum).must_equal results
        end
      end
    end
  end

  describe LinkRenderer do
    let(:page) { Page.new(:number => 2, :rows => 5, :sort_column => 'to_s', :sort_direction => 'desc') }
    let(:collection) { (1..10).to_a }
    let(:data_page) { collection.paginate(:page => 2, :per_page => 5) }
    let(:view) { stub("view") }
    let(:renderer) do
      renderer = LinkRenderer.new(page)
      renderer.prepare(collection, {}, view)
      renderer
    end
    let(:text) { stub("text") }
    let(:href) { stub("href") }
    let(:link) { stub("link") }


    describe "#sort_link" do
      it "calls link_to on the view with the sort url and the :remote option" do
        view.stubs("url_for").
          with(:sort_direction => 'asc', :per_page => '5', :page => '1', :sort_column => 'to_s').
          returns(href)
        view.stubs("link_to").with(text, href, :remote => true).returns(link)
        renderer.sort_link(text, 'to_s').must_equal link
      end
    end

    describe "#tag" do
      it "calls link_to on the view with the :remote option for :a tags" do
        view.expects(:link_to).
          with(text, href, { :class => 'highlight', :remote => true }).
          returns(link)
        renderer.tag(:a, text, :class => 'highlight', :href => href).must_equal link
      end

      it "delegates to its parent for all other tags" do
        view.expects(:link_to).never
        renderer.tag(:span, "foo")
      end
    end

  end

  describe RendersTable do
    let(:view) { stub("view") }
    let(:description) { stub("description") }
    let(:collection) { stub("collection") }
    let(:link_renderer) { stub("link_renderer") }
    let(:table) { RendersTable.new(view, description, collection, link_renderer) }

    describe "#initialize" do
      it "creates a new instance with the view, description, and collection" do
        table
      end
    end

    describe "#render" do
      it "makes a div.pagination with the table and a pagination header and footer" do
        table.stubs(:render_pagination_area).returns("<pagination/>")
        table.stubs(:render_table).returns("<table/>")
        view.expects(:content_tag).with('div', "<pagination/><table/><pagination/>", :class => 'pagination')
        table.render
      end
    end

    describe "#render_pagination_area" do
      it "makes a div.header with the pagination info and links" do
        table.stubs(:render_pagination_info).returns("<info/>")
        table.stubs(:render_pagination_links).returns("<links/>")
        view.expects(:content_tag).with('div', "<info/><links/>", :class => 'header')
        table.render_pagination_area
      end
    end

    describe "#render_pagination_info" do
      it "makes a div.info with the page_entries_info from will_paginate" do
        view.stubs(:page_entries_info).with(collection).returns("<info/>")
        view.expects(:content_tag).with('div', "<info/>", :class => 'info')
        table.render_pagination_info
      end
    end

    describe "#render_pagination_links" do
      it "makes a div.links with the will_paginate links from will_paginate" do
        view.stubs(:will_paginate).
          with(collection, :renderer => link_renderer).
          returns("<links/>")
        view.expects(:content_tag).with('div', "<links/>", :class => 'links')
        table.render_pagination_links
      end
    end

    describe "#render_table" do
      it "makes a table.paginated with the table header and body" do
        table.stubs(:render_table_header).returns("<header/>")
        table.stubs(:render_table_body).returns("<body/>")
        view.expects(:content_tag).with('table', "<header/><body/>", :class => 'paginated')
        table.render_table
      end
    end

    describe "#render_table_header" do
      it "makes a thead with the table header row" do
        table.stubs(:render_table_header_row).returns("<header/>")
        view.expects(:content_tag).with('thead', "<header/>")
        table.render_table_header
      end
    end

    describe "#render_table_header_row" do
      it "makes a tr with the table header columns" do
        columns = [stub("column1"), stub("column2")]
        description.stubs(:columns).returns(columns)
        table.stubs(:render_table_header_column).with(columns.first).returns("<col1/>")
        table.stubs(:render_table_header_column).with(columns.last).returns("<col2/>")
        view.expects(:content_tag).with('tr', "<col1/><col2/>")
        table.render_table_header_row
      end
    end

    describe "#render_table_header_column" do
      it "makes a th with the render_header from the column" do
        column = stub("column")
        table.stubs(:render_table_header_column_content).with(column).returns("<header/>")
        view.expects(:content_tag).with('th', "<header/>")
        table.render_table_header_column(column)
      end
    end

    describe "#render_table_header_column_content" do
      describe "with a sortable column" do
        let(:column) { stub("column", :name => :foo, :render_header => '<header/>', :sortable? => true) }

        it "asks the link renderer to render a link to sort the column" do
          result = stub("result")
          link_renderer.stubs(:sort_link).with("<header/>", 'foo').returns(result)
          table.render_table_header_column_content(column).must_equal result
        end
      end

      describe "with an unsortable column" do
        let(:column) { stub("column", :render_header => '<header/>', :sortable? => false) }

        it "simply renders the column's header" do
          table.render_table_header_column_content(column).must_equal '<header/>'
        end
      end
    end

    describe "#render_table_body" do
      it "makes a tbody with the table body rows" do
        data = [stub("datum1"), stub("datum2")]
        table = RendersTable.new(view, description, data, link_renderer)
        table.stubs(:render_table_body_row).with(data.first).returns("<row1/>")
        table.stubs(:render_table_body_row).with(data.last).returns("<row2/>")
        view.expects(:content_tag).with('tbody', "<row1/><row2/>")
        table.render_table_body
      end
    end

    describe "#render_table_body_row" do
      it "makes a tr with the table body cells" do
        datum = stub("datum")
        columns = [stub("column1"), stub("column2")]
        description.stubs(:columns).returns(columns)
        table.stubs(:render_table_body_cell).with(datum, columns.first).returns("<cell1/>")
        table.stubs(:render_table_body_cell).with(datum, columns.last).returns("<cell2/>")
        view.expects(:content_tag).with('tr', "<cell1/><cell2/>")
        table.render_table_body_row(datum)
      end
    end

    describe "#render_table_body_cell" do
      it "makes a td with the render_cell from the column" do
        datum = stub("datum")
        column = stub("column")
        column.stubs(:render_cell).with(datum).returns("<datum/>")
        view.expects(:content_tag).with('td', "<datum/>")
        table.render_table_body_cell(datum, column)
      end
    end
  end
end
