# ti_power_controller.rb v.10
# Copyright: 4/18/2008 Texas Instruments Inc.

require 'rubygems'

module TestEquipment
  # This class controls basic functions used in the TiPowercontrollers, 
  # such as on, off, reboot, and get port status.  
  # The interactions from this driver can be logged using Log4r functionality
  class TiPowerController
	def initialize(platform_info, log_path = nil)
	    @dev_node   = platform_info.params['dev_node']
	end

  	# Turns ON the equipment at the specified address
  	# * pow_address - the port address to turn ON
    	def switch_on(pow_address)    
		system("echo #{pow_address}.1 > #{@dev_node}")
    	end
    
    	# Turns OFF the equipment at the specified address
    	# * pow_address - the port address to turn OFF
    	def switch_off(pow_address)
		system("echo #{pow_address}.0 > #{@dev_node}");
    	end
		
    	# Power cycles the equipment at the specified address
    	# * pow_address - the port address to powercycle
    	# * waittime - how long to wait between powercycling (default: 5 seconds)
    	def reset(pow_address, waittime=5)
      		puts "reset\n"
      		switch_off(pow_address)
      		sleep(waittime)
		puts "Resetting the DUT connected to switch #{pow_address}"
      		switch_on(pow_address) 
    	end
  end
    
end

