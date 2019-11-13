require File.dirname(__FILE__)+'/../target/linux/linux_localhost_driver'
require 'timeout'

module TestEquipment

include Equipment

  # This class controls basic functions used in SDWire gadget.
  class SDWire < LinuxLocalHostDriver
    def initialize(platform_info, log_path = nil)
      super(platform_info, log_path)
      @__sd_mux = "#{@params['control_bin']} -e #{@params['serial_no']}"
      __sd_mux_cmd('-i', "Serial:\s+#{@params['serial_no']}")
    end
    
    def switch_microsd_to_host(e=nil)
      __sd_mux_cmd('-s')
      __sd_mux_cmd('-u', 'SD connected to: TS')
    end

    def switch_microsd_to_dut(e=nil)
     __sd_mux_cmd('-d')
     __sd_mux_cmd('-u', 'SD connected to: DUT')
    end
    
    #Not used, created to comply with sd mux api
    def set_interfaces(params)
    end
    
    def connect(params)
    end
    
    def disconnect(type)
    end
    #End of not used
    private
    def __sd_mux_cmd(command, expected_match=/.*/, timeout=10, check_cmd_echo=true)
      send_cmd("#{@__sd_mux} #{command}", expected_match, timeout, check_cmd_echo)
      raise "SDWire: Command #{command} timedout waiting for #{expected_match}" if @timeout
    end
    
  end

end
