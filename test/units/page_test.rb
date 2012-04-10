module PaginatedTable
  describe Page do
    let(:page) { Page.new(:number => 2, :rows => 5, :sort_column => 'name', :sort_direction => 'desc') }

    it "has a page number" do
      page.number.must_equal 2
    end

    it "does not accept a negative page number" do
      lambda { Page.new(:number => -1) }.must_raise ArgumentError
    end

    it "does not accept a zero page number" do
      lambda { Page.new(:number => 0) }.must_raise ArgumentError
    end

    it "does not accept an invalid page number" do
      lambda { Page.new(:number => 'foo') }.must_raise ArgumentError
    end

    it "has a rows number" do
      page.rows.must_equal 5
    end

    it "does not accept a negative number of rows" do
      lambda { Page.new(:rows => -1) }.must_raise ArgumentError
    end

    it "does not accept a zero number of rows "do
      lambda { Page.new(:rows => 0) }.must_raise ArgumentError
    end

    it "does not accept an invalid page number" do
      lambda { Page.new(:rows => 'foo') }.must_raise ArgumentError
    end

    it "has a sort column" do
      page.sort_column.must_equal 'name'
    end

    it "has a sort direction" do
      page.sort_direction.must_equal 'desc'
    end

    it "does not accept an invalid sort direction" do
      lambda { Page.new(:sort_direction => 'foo') }.must_raise ArgumentError
    end

    describe ".opposite_sort_direction" do
      it "returns asc for desc" do
        Page.opposite_sort_direction('asc').must_equal 'desc'
      end

      it "returns desc for asc" do
        Page.opposite_sort_direction('desc').must_equal 'asc'
      end
    end

    describe "#page_for_number" do
      describe "with a new page number" do
        let(:number_page) { page.page_for_number(3) }

        it "returns a new page with the new page number" do
          number_page.number.must_equal 3
        end

        it "returns a new page with the same number of rows" do
          number_page.rows.must_equal 5
        end

        it "returns a new page with the same sort column" do
          number_page.sort_column.must_equal 'name'
        end

        it "returns a new page with the same sort direction" do
          number_page.sort_direction.must_equal 'desc'
        end
      end
    end

    describe "#page_for_sort_column" do
      describe "on a new sort column" do
        let(:sort_page) { page.page_for_sort_column('title') }

        it "returns a new page with page number 1" do
          sort_page.number.must_equal 1
        end

        it "returns a new page with the same number of rows" do
          sort_page.rows.must_equal 5
        end

        it "returns a new page with the given sort column" do
          sort_page.sort_column.must_equal 'title'
        end

        it "returns a new page with sort direction asc" do
          sort_page.sort_direction.must_equal 'asc'
        end
      end

      describe "on the same sort column" do
        let(:sort_page) { page.page_for_sort_column('name') }

        it "returns a new page with page number 1" do
          sort_page.number.must_equal 1
        end

        it "returns a new page with the same number of rows" do
          sort_page.rows.must_equal 5
        end

        it "returns a new page with the same sort column" do
          sort_page.sort_column.must_equal 'name'
        end

        it "returns a new page with the opposite sort direction" do
          sort_page.sort_direction.must_equal 'asc'
          sort_page.page_for_sort_column('name').sort_direction.must_equal 'desc'
        end
      end
    end
  end

  describe PageParams do
    describe ".create_from_params" do
      it "returns a new page created from the request params" do
        page = PageParams.create_page_from_params(
          :page => '2',
          :per_page => '5',
          :sort_column => 'name',
          :sort_direction => 'desc'
        )
        page.number.must_equal 2
        page.rows.must_equal 5
        page.sort_column.must_equal 'name'
        page.sort_direction.must_equal 'desc'
      end
    end

    describe ".to_params" do
      it "creates a params hash from the page" do
        page = Page.new(
          :number => 2,
          :rows => 5,
          :sort_column => 'name',
          :sort_direction => 'desc'
        )
        PageParams.to_params(page).must_equal(
          :page => '2',
          :per_page => '5',
          :sort_column => 'name',
          :sort_direction => 'desc'
        )
      end
    end
  end

  describe DataPage do
    describe "#data" do
      let(:page) {
        Page.new(
          :number => 2,
          :rows => 5,
          :sort_column => 'name',
          :sort_direction => 'asc'
        )
      }
      let(:collection) {
        collection = (1..10).map { |i| "Name #{i}" }
        def collection.order(clause)
          raise unless clause == "name asc"
          sort
        end
        collection
      }

      it "sorts the collection and pages to the given page number" do
        DataPage.new(collection, page).data.must_equal(
          ["Name 5", "Name 6", "Name 7", "Name 8", "Name 9"]
        )
      end

      describe "#page" do
        it "provides a reference to the given page" do
          DataPage.new(collection, page).page.must_equal page
        end
      end
    end
  end

end
