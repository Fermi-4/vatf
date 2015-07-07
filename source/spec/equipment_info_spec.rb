require 'spec_helper'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "equipment_info")

describe EquipmentInfo do
  before :each do
    @equipment = EquipmentInfo.new("test", "linux_sd_sdhc_usbhostmsc_usbhosthid_power")
  end

  describe "#new"do
    it "returns an instance of #{described_class}" do
      expect(@equipment).to be_an_instance_of described_class
    end
  end

  describe "#id" do
    it { expect(@equipment).to respond_to(:id) }
    it { expect(@equipment.id).to eq "linux_power_sd_sdhc_usbhosthid_usbhostmsc" }
  end

  describe "#name" do
    it { expect(@equipment).to respond_to(:name) }
    it { expect(@equipment.name).to eq "test" }
  end

  methods = [
    :telnet_ip,
    :telnet_port,
    :driver_class_name,
    :audio_hardware_info,
    :telnet_login,
    :telnet_passwd,
    :prompt,
    :first_boot_prompt,
    :boot_prompt,
    :executable_path,
    :nfs_root_path,
    :samba_root_path,
    :login,
    :login_prompt,
    :login_passwd,
    :power_port,
    :tftp_path,
    :tftp_ip,
    :video_io_info,
    :audio_io_info,
    :usb_ip,
    :serial_server_ip,
    :serial_server_port,
    :serial_port,
    :serial_params,
    :board_id,
    :boot_load_address,
    :params,
    :password_prompt,
    :timeout,
    :telnet_bin_mode
  ]

  methods.each do |method|
    describe "##{method}" do
      it { expect(@equipment).to respond_to(method) }
      it { expect(@equipment).to respond_to(method).with(0).arguments }
      it { expect(@equipment).to respond_to((method.to_s + "=").to_sym).with(1).argument }
    end
  end
end
