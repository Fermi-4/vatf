require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'net/telnet'
require 'rubygems'
require 'delegate'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r
include Equipment


  # This class controls basic functions used in TI's MSP432-based launchpad gadget.
  # It is possible to connect multiple booster packs to the same launchpad, which
  # gives the gadget multiple functionality.
  # The interactions from this driver can be logged using Log4r
  class TiMultiPurposeTestGadget < EquipmentDriver
    def set_interfaces(params)
      # Add here bootster packs available
      #self = MicroSdSwitch.new(self) if params.has_key?("microsd_switch")
      self.extend(MicroSdSwitch) if params.has_key?("microsd_switch")
    end
  end


  # Micro SD card switch bootster pack
  # It selects side (DUT or Host PC) that can access micro SD card.
  # Useful to flash SD cards with new images from host side before DUT boots.
  # To use append following element to DUT params dictionary in your bench file:
  #   'microsd_switch' => { <msp432 EquipmentInfo instance> => <side> }
  # where <side> : 'l' | 'r'. 'l' means DUT is connected to switch's left side,
  #                           while 'r' means is connected to right side
  # For example:
  # ti_test_gadget = EquipmentInfo.new("msp432", "0")
  # ti_test_gadget.serial_port = '/dev/ttyACM0'
  # ti_test_gadget.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
  # ti_test_gadget.driver_class_name = 'TiMultiPurposeTestGadget'
  #
  # dut.params = {
  #               'microsd_switch' => {ti_test_gadget => 'r'},
  #              }

  module MicroSdSwitch

    def switch_microsd_to_host(e)
      switch_microsd(e, 'host')
    end

    def switch_microsd_to_dut(e)
      switch_microsd(e, 'dut')
    end

    private
    def switch_microsd(e, dev)
      begin
        dut_side = e.params['microsd_switch'].values[0]
        if (dev == 'dut' and dut_side.match(/^r/i)) or (dev == 'host' and !dut_side.match(/^r/i))
          send_cmd("mmc r-microsd",/Using Right microd*SD connection/mi, 3, false, true)
        else
          send_cmd("mmc l-microsd",/Using Left microSD connection/mi, 3, false, true)
        end
      rescue Exception => e
        e.log_info("microsd_switch parameter is not defined in bench file. See <vatf source>/source/bench.rb")
        raise e
      end
    end

  end

end
