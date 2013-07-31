require 'spec_helper'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "power_handler")

describe PowerHandler do
  before :each do
    @power = PowerHandler.new
  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@power).to be_an_instance_of described_class
    end
  end

  describe "#power_controllers" do
    it { @power.should respond_to(:power_controllers) }
    it { @power.power_controllers.should be_an_instance_of Hash }
    it "raises error when trying to modify power_controllers Hash" do
      expect { @power.power_controllers = nil }.to raise_error
    end
  end

  describe "#load_power_ports" do
    it { @power.should respond_to(:load_power_ports).with(1).arguments }

    it "does not raise error with nil argument" do
      expect { @power.load_power_ports(nil) }.to_not raise_error
    end
  end

  describe "#disconnect" do
    it { @power.should respond_to(:disconnect).with(0).arguments }
    it "disconnects a port" do
      expect { @power.disconnect }.to_not raise_error
    end
  end

  # Ideally we would be able to mock a power_controllers Hash and still
  # have get_status(), switch_on(), switch_off(), reset() functionality,
  # but mocking those objects will take too much work because of the way
  # EquipmentInfo was designed.
  #
  # For these methods, we will stick to just checking that the object responds
  # to them. Perhaps later someone can decide to 'fix' EquipmentInfo (and many
  # of the classes in this Framework, for that matter) so that they have a
  # cleaner API and are easier to mock.

  describe "#get_status" do
    it { @power.should respond_to(:get_status).with(1).argument }
  end

  describe "#switch_on" do
    it { @power.should respond_to(:switch_on).with(1).argument }
  end

  describe "#switch_off" do
    it { @power.should respond_to(:switch_off).with(1).argument }
  end

  describe "#reset" do
    it {@power.should respond_to(:reset).with(1).argument }
  end
end
