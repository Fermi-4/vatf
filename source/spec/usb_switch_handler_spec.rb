require 'spec_helper'
require 'rspec/mocks'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "usb_switch_handler")

describe UsbSwitchHandler do
  before :each do
    @usb = UsbSwitchHandler.new
  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@usb).to be_an_instance_of described_class
    end
  end

  describe "#usb_switch_controller" do
    it { expect(@usb).to respond_to(:usb_switch_controller) }
    it { expect(@usb.usb_switch_controller).to be_an_instance_of Hash }
    it "raises error when trying to modify usb_switch_controller Hash" do
      expect { @usb.usb_switch_controller = nil }.to raise_error
    end
  end

  describe "#load_usb_ports" do
    it { expect(@usb).to respond_to(:load_usb_ports).with(1).arguments }

    it "does not raise error with nil argument" do
      expect { @usb.load_usb_ports(nil) }.to_not raise_error
    end
  end

  describe "#disconnect" do
    it { expect(@usb).to respond_to(:disconnect).with(1).argument }
  end

  describe "#select_input" do
    it { expect(@usb).to respond_to(:select_input).with(1).argument }

    it "doesn't raise and error" do
      controller = double("usb_switch_controller", :select_input => 0)
      input = double("input", :each => controller)

      expect { @usb.select_input(input) }.to_not raise_error
    end
  end
end
