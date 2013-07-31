require 'spec_helper'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "equipment_info")

describe AudioHardwareInfo do
  before :each do
    @audio = AudioHardwareInfo.new
  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@audio).to be_an_instance_of described_class
    end
  end

  methods = [
    :analog_audio_inputs,
    :analog_audio_outputs,
    :digital_audio_inputs,
    :digital_audio_outputs,
    :midi_audio_inputs,
    :midi_audio_outputs
  ]

  methods.each do |method|
    describe "#{method}" do
      it { @audio.should respond_to(method) }
      it { @audio.should respond_to(method).with(0).arguments }
      it { @audio.should respond_to((method.to_s + "=").to_sym).with(1).argument }
    end
  end
end
