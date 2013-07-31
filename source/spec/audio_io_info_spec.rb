require 'spec_helper'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "equipment_info")

describe AudioIOInfo do
  before :each do
    @audio = AudioIOInfo.new

  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@audio).to be_an_instance_of described_class
    end
  end

  methods = [
    :rca_inputs,
    :rca_outputs,
    :xlr_inputs,
    :xlr_outputs,
    :optical_inputs,
    :optical_outputs,
    :mini35mm_inputs,
    :mini35mm_outputs,
    :mini25mm_inputs,
    :mini25mm_outputs,
    :phoneplug_inputs,
    :phoneplug_outputs
  ]

  methods.each do |method|
    describe "##{method}" do
      it { @audio.should respond_to(method) }
      it { @audio.should respond_to(method).with(0).arguments }
      it { @audio.should respond_to((method.to_s + "=").to_sym).with(1).argument }
    end
  end
end
