require "spec_helper"

describe Mongoid::Contextual::Mongo do

  [ :blank?, :empty? ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
      end

      context "when the count is zero" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns true" do
          context.send(method).should be_true
        end
      end

      context "when the count is greater than zero" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns false" do
          context.send(method).should be_false
        end
      end
    end
  end

  describe "#count" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when no arguments are provided" do

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the number of documents that match" do
        context.count.should eq(1)
      end
    end

    context "when provided a document" do

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count(depeche)
      end

      it "returns the number of documents that match" do
        count.should eq(1)
      end
    end

    context "when provided a block" do

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count do |doc|
          doc.likes.nil?
        end
      end

      it "returns the number of documents that match" do
        count.should eq(1)
      end
    end
  end

  [ :delete, :delete_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:deleted) do
          context.send(method)
        end

        it "deletes the matching documents" do
          Band.find(new_order.id).should eq(new_order)
        end

        it "deletes the correct number of documents" do
          Band.count.should eq(1)
        end

        it "returns the number of documents deleted" do
          deleted.should eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "deletes all the documents" do
          Band.count.should eq(0)
        end
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:destroyed) do
          context.send(method)
        end

        it "destroys the matching documents" do
          Band.find(new_order.id).should eq(new_order)
        end

        it "destroys the correct number of documents" do
          Band.count.should eq(1)
        end

        it "returns the number of documents destroyed" do
          destroyed.should eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "destroys all the documents" do
          Band.count.should eq(0)
        end
      end
    end
  end

  describe "#distinct" do

    before do
      Band.create(name: "Depeche Mode")
      Band.create(name: "New Order")
    end

    context "when limiting the result set" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct matching fields" do
        context.distinct(:name).should eq([ "Depeche Mode" ])
      end
    end

    context "when not limiting the result set" do

      let(:criteria) do
        Band.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        context.distinct(:name).should eq([ "Depeche Mode", "New Order" ])
      end
    end
  end

  describe "#each" do

    before do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a block" do

      it "yields mongoid documents to the block" do
        context.each do |doc|
          doc.should be_a(Mongoid::Document)
        end
      end

      it "iterates over the matching documents" do
        context.each do |doc|
          doc.name.should eq("Depeche Mode")
        end
      end

      it "returns self" do
        context.each{}.should be(context)
      end
    end

    context "when no block is provided" do

      let(:enum) do
        context.each
      end

      it "returns an enumerator" do
        enum.should be_a(Enumerator)
      end

      context "when iterating over the enumerator" do

        context "when iterating with each" do

          it "yields mongoid documents to the block" do
            enum.each do |doc|
              doc.should be_a(Mongoid::Document)
            end
          end
        end

        context "when iterating with next" do

          it "yields mongoid documents" do
            enum.next.should be_a(Mongoid::Document)
          end
        end
      end
    end
  end

  describe "#eager_load" do

    let(:criteria) do
      Person.includes(:game)
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when no documents are returned" do

      let(:game_metadata) do
        Person.reflect_on_association(:game)
      end

      it "does not make any additional database queries" do
        game_metadata.expects(:eager_load).never
        context.send(:eager_load, [])
      end
    end
  end

  describe "#exists?" do

    before do
      Band.create(name: "Depeche Mode")
    end

    context "when the count is zero" do

      let(:criteria) do
        Band.where(name: "New Order")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        context.should_not be_exists
      end
    end

    context "when the count is greater than zero" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns true" do
        context.should be_exists
      end
    end
  end

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "returns the criteria explain path" do
      context.explain["cursor"].should eq("BasicCursor")
    end
  end

  describe "#find_and_modify" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create(name: "Tool")
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(tool)
        end

        it "updates the document in the database" do
          tool.reload.likes.should eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "limits the returned fields" do
          result.name.should be_nil
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_and_modify({ "$inc" => { likes: 1 }}, new: true)
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "returns the updated document" do
          result.likes.should eq(1)
        end
      end

      context "when removing" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_and_modify({}, remove: true)
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:result) do
        context.find_and_modify("$inc" => { likes: 1 })
      end

      it "returns nil" do
        result.should be_nil
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the first matching document" do
        context.send(method).should eq(depeche_mode)
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sets the criteria" do
      context.criteria.should eq(criteria)
    end

    it "sets the klass" do
      context.klass.should eq(Band)
    end

    it "sets the query" do
      context.query.should be_a(Moped::Query)
    end

    it "sets the query selector" do
      context.query.selector.should eq({ "name" => "Depeche Mode" })
    end
  end

  describe "#last" do

    context "when no default scope" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the last matching document" do
        context.last.should eq(new_order)
      end
    end

    context "when default scope" do

      let!(:palm) do
        Tree.create(name: "Palm")
      end

      let!(:maple) do
        Tree.create(name: "Maple")
      end

      let(:criteria) do
        Tree.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "respects default scope" do
        context.last.should eq(palm)
      end
    end
  end

  [ :length, :size ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the number of documents that match" do
        context.send(method).should eq(1)
      end

      context "when calling more than once" do

        before do
          context.query.expects(:count).once.returns(1)
        end

        it "returns the cached value for subsequent calls" do
          2.times { context.send(method).should eq(1) }
        end
      end

      context "when the results have been iterated over" do

        before do
          context.entries
          context.query.expects(:count).never
        end

        it "returns the cached value for all calls" do
          context.send(method).should eq(1)
        end

        context "when the results have been iterated over multiple times" do

          before do
            context.entries
          end

          it "resets the length on each full iteration" do
            context.should have(1).item
          end
        end
      end
    end
  end

  describe "#limit" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      context.limit(1).entries.should eq([ depeche_mode ])
    end
  end

  describe "#map_reduce" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode", likes: 200)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 100)
    end

    let(:map) do
      %Q{
      function() {
        emit(this.name, { likes: this.likes });
      }}
    end

    let(:reduce) do
      %Q{
      function(key, values) {
        var result = { likes: 0 };
        values.forEach(function(value) {
          result.likes += value.likes;
        });
        return result;
      }}
    end

    context "when no selection is provided" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        results.should include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the second aggregate result" do
        results.should include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the correct number of documents" do
        results.count.should eq(2)
      end

      it "contains the entire raw results" do
        results["results"].should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end

      it "contains the execution time" do
        results.time.should_not be_nil
      end

      it "contains the count statistics" do
        results["counts"].should eq({
          "input" => 2, "emit" => 2, "reduce" => 0, "output" => 2
        })
      end

      it "contains the input count" do
        results.input.should eq(2)
      end

      it "contains the emitted count" do
        results.emitted.should eq(2)
      end

      it "contains the reduced count" do
        results.reduced.should eq(0)
      end

      it "contains the output count" do
        results.output.should eq(2)
      end
    end

    context "when selection is provided" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "includes the aggregate result" do
        results.should include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire raw results" do
        results["results"].should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end

      it "contains the execution time" do
        results.time.should_not be_nil
      end

      it "contains the count statistics" do
        results["counts"].should eq({
          "input" => 1, "emit" => 1, "reduce" => 0, "output" => 1
        })
      end

      it "contains the input count" do
        results.input.should eq(1)
      end

      it "contains the emitted count" do
        results.emitted.should eq(1)
      end

      it "contains the reduced count" do
        results.reduced.should eq(0)
      end

      it "contains the output count" do
        results.output.should eq(1)
      end
    end

    context "when sorting is provided" do

      let(:criteria) do
        Band.desc(:name)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        results.should include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the second aggregate result" do
        results.should include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        results.count.should eq(2)
      end

      it "contains the entire raw results" do
        results["results"].should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when limiting is provided" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        results.should include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire raw results" do
        results["results"].should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is replace" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(replace: "mr-output")
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire results" do
        results.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is reduce" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(reduce: :mr_output)
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire results" do
        results.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is merge" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(merge: :mr_output)
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire results" do
        results.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when providing no output" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce)
      end

      it "raises an error" do
        expect {
          results.entries
        }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
      end
    end

    context "when providing a finalize" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:finalize) do
        %Q{
        function(key, value) {
          value.extra = true;
          return value;
        }}
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1).finalize(finalize)
      end

      it "returns the correct number of documents" do
        results.count.should eq(1)
      end

      it "contains the entire results" do
        results.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200, "extra" => true }}
        ])
      end
    end
  end

  describe "#skip" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      context.skip(1).entries.should eq([ new_order ])
    end
  end

  describe "#sort" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sorts the results" do
      context.sort(name: -1).entries.should eq([ new_order, depeche_mode ])
    end

    it "returns the context" do
      context.sort(name: 1).should eq(context)
    end
  end

  [ :update, :update_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when providing attributes" do

        before do
          context.send(method, name: "Smiths")
        end

        it "updates the first matching document" do
          depeche_mode.reload.name.should eq("Smiths")
        end

        it "updates the last matching document" do
          new_order.reload.name.should eq("Smiths")
        end
      end

      context "when providing no attributes" do

        it "returns false" do
          context.send(method).should be_false
        end
      end
    end
  end
end
