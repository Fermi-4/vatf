require File.dirname(__FILE__)+'/../target/equipment_driver' 


module TestEquipment

  class HpWaveGenDriver < Equipment::EquipmentDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
      
    #This function configures wave generator.
    # Input parameters: none
    # # Return Parameter: No return 
    def configure_wave_gen()
      send_cmd("*RST\r\n", ".*", 1, false)
      send_cmd("*CLS\r\n", ".*", 1, false)
      send_cmd("SYStem:Remote\r\n", ".*", 1, false)
      cmd_status = response.match(/-1/).captures[0]
      raise 'wave generator tool initialization failed' if cmd_status = nil 
       
    end

    #Function sends individual command to wave generator.
    # Input parameters: wave_gen_cmd: string command with a proper syntax to generate wave.
    # Return Parameter: none 
    def gen_wave_cmd(wave_gen_cmd)
	    send_cmd("#{wave_gen_cmd}\r\n", ".*", 1, false)
    end

    private
  end

end  
