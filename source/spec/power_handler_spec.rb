require 'spec_helper'
require 'rspec/mocks'
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
    it { expect(@power).to respond_to(:power_controllers) }
    it { expect(@power.power_controllers).to be_an_instance_of Hash }
    it "raises error when trying to modify power_controllers Hash" do
      expect { @power.power_controllers = nil }.to raise_error
    end
  end

  describe "#load_power_ports" do
    it { expect(@power).to respond_to(:load_power_ports).with(1).arguments }

    it "does not raise error with nil argument" do
      expect { @power.load_power_ports(nil) }.to_not raise_error
    end
  end

  describe "#disconnect" do
    it { expect(@power).to respond_to(:disconnect).with(0).arguments }
    it "disconnects a port" do
      expect { @power.disconnect }.to_not raise_error
    end
  end

  describe "#get_status" do
    it { expect(@power).to respond_to(:get_status).with(1).argument }

    it "doesn't raise and error" do
      controller = double("power_controller", :get_status => "ON")
      port = double("power_port", :each => controller)

      expect { @power.get_status(port) }.to_not raise_error
    end
  end

  describe "#switch_on" do
    it { expect(@power).to respond_to(:switch_on).with(1).argument }

    it "doesn't raise and error" do
      controller = double("power_controller", :switch_on => 0)
      port = double("power_port", :each => controller)

      expect { @power.switch_on(port) }.to_not raise_error
    end
  end

  describe "#switch_off" do
    it { expect(@power).to respond_to(:switch_off).with(1).argument }

    it "doesn't raise and error" do
      controller = double("power_controller", :switch_off => 0)
      port = double("power_port", :each => controller)

      expect { @power.switch_off(port) }.to_not raise_error
    end
  end

  describe "#reset" do
    it {expect(@power).to respond_to(:reset).with(1).argument }

    it "doesn't raise and error" do
      controller = double("power_controller", :reset => 0)
      port = double("power_port", :each => controller)

      expect { @power.reset(port) }.to_not raise_error
    end
  end
end
