require "spec_helper"

RSpec.describe Uncouple::ActionPerformer do

  User = Struct.new(:email)

  class Controller

    include Uncouple::ActionPerformer
    attr_reader :params, :action

    def initialize(params)
      @params = params
    end

  end

  class SampleAction < Uncouple::Action

    attr_reader :foo

    def perform
      @foo = "bar"
    end

    def success?
      !@foo.nil?
    end

  end

  let(:controller) { Controller.new(something: "nothing") }

  describe "#perform" do

    it "initializes an action with params" do
      expect(SampleAction).to receive(:new).with(something: "nothing")
      controller.perform(SampleAction)
    end

    it "merges current user into params" do
      @user = User.new("test@example.com")
      expect(controller).to receive(:current_user).and_return(@user).at_least(:once)
      expect(SampleAction).to receive(:new).with(something: "nothing", current_user: @user)
      controller.perform(SampleAction)
    end

    it "initializes an action with custom params" do
      expect(SampleAction).to receive(:new).with(foo: "bar")
      controller.perform(SampleAction, foo: "bar")
    end

    it "calls to perform the action with authorization" do
      expect_any_instance_of(SampleAction).to receive(:perform_with_authorization)
      controller.perform(SampleAction)
    end

    it "yields a block when action is successful" do
      controller.perform(SampleAction) do
        @called = true
      end
      expect(@called).to eq(true)
    end

    it "skips block when action is unsuccessful" do
      expect_any_instance_of(SampleAction).to receive(:success?).and_return(false)
      controller.perform(SampleAction) do
        @called = true
      end
      expect(@called).to be_nil
    end

    it "returns the action instance" do
      @action = controller.perform(SampleAction)
      expect(@action).to be_a(SampleAction)
    end

  end

end
