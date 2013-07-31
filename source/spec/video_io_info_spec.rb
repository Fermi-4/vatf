require 'spec_helper'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "equipment_info")

describe VideoIOInfo do
  before :each do
    @video = VideoIOInfo.new

  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@video).to be_an_instance_of described_class
    end
  end

  methods = [
    :vga_outputs,
    :component_inputs,
    :component_outputs,
    :composite_inputs,
    :composite_outputs,
    :svideo_inputs,
    :svideo_outputs,
    :hdmi_inputs,
    :hdmi_outputs,
    :sdi_inputs,
    :sdi_outputs,
    :dvi_inputs,
    :dvi_outputs,
    :scart_inputs,
    :scart_outputs,
    :vga_inputs
  ]

  methods.each do |method|
    describe "##{method}" do
      it { @video.should respond_to(method) }
      it { @video.should respond_to(method).with(0).arguments }
      it { @video.should respond_to((method.to_s + "=").to_sym).with(1).argument }
    end
  end
end
