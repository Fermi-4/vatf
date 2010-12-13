require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r
include Equipment

  # This class controls basic functions used in the ApcPowercontrollers, such as on, off, reboot, and get port status.  The interactions from this driver can be logged using Log4r functionality
  class ExtronUsbSwitch < EquipmentDriver
    
    # Select USB Host input to connect to the USB devices. 
    def select_input(input)
      send_cmd("#{input}!",/^Chn#{input}/mi,3,false,false)
      #check to make sure the input was selected
      if timeout?
        puts "FAILED to select Input #{input}"
        log_error("FAILED to select Input #{input}")
      else
        puts "USB Input #{input} selected"
        log_info("USB Input #{input} selected")
      end
    end

  end
end

