require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  class MultiMeterEquipmentDriver < Equipment::EquipmentDriver

    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
     
      
	  #this function configures the multimeter for five channel reading 
	  def configure_multimter(sample_count)
		send_cmd("*RST", ".*", 1, false)
		send_cmd("*CLS", ".*", 1, false)
		send_cmd(":TRAC:CLE", ".*", 1, false)
		send_cmd(":VOLT:DC:RANG 2", ".*", 1, false)
		send_cmd(":FUNC 'VOLT:DC'", ".*", 1, false)
		send_cmd(":ROUT:SCAN (@1:5)", ".*", 1, false)
		send_cmd(":ROUT:SCAN:LSEL INT", ".*", 1, false)
		send_cmd(":SAMP:COUN #{sample_count}", ".*", 1, false)
		send_cmd(":FORM:ELEM READ", ".*", 1, false)
		send_cmd(":TRIG:SOUR IMM", ".*", 1, false)
	  end
	  
  end
end  