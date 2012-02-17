require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  class KeithleyMultiMeterDriver < Equipment::EquipmentDriver
    attr_reader :number_of_channels, :dut_power_domains, :dut_domain_resistors
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
      
    #this function configures the multimeter for five channel reading
    # Input parameters: platfrom name
    # # Return Parameter: No return 
    def configure_multimeter(power_info)
      @number_of_channels = @params['number_of_channels']
      @dut_power_domains = power_info['power_domains'] 
      @dut_domain_resistors = power_info['domain_resistors']      
      send_cmd("*RST", ".*", 1, false)
      send_cmd("*CLS", ".*", 1, false)
      send_cmd(":TRAC:CLE", ".*", 1, false)
      send_cmd(":VOLT:DC:RANG 2", ".*", 1, false)
      send_cmd(":FUNC 'VOLT:DC'", ".*", 1, false)
      if @number_of_channels == 20
      	send_cmd(":ROUT:SCAN (@101:120)", ".*", 1, false)
      else 
      	send_cmd(":ROUT:SCAN (@1:#{@number_of_channels})", ".*", 1, false)
      end 
      send_cmd(":ROUT:SCAN:LSEL INT", ".*", 1, false)
      send_cmd(":SAMP:COUN #{@number_of_channels}", ".*", 1, false)
      send_cmd(":FORM:ELEM READ", ".*", 1, false)
      send_cmd(":TRIG:SOUR IMM", ".*", 1, false)
     end

     #Function collects data from multimeter.
     # Input parameters: 
     #    loop_count: Integer defining the number of times to perform channel measurements
     #    timeout: Integer defining the read timeout in sec
     # Return Parameter: Array containing all voltage reading for all domains. 
     def get_multimeter_output(loop_count, timeout)
       sleep 5    # Make sure multimeter is configured and DUT is in the right state
       volt_reading = []
       counter=0
       regexp = ""
       for i in (2..@number_of_channels)
       regexp = regexp + ".+?,"
       end 
       while counter < loop_count 
	  send_cmd("READ?", /#{regexp}[^\r\n]+/, timeout, false)
          Kernel.print("\n")
          volt_reading << response
	  counter += 1
       end
	  return sort_raw_data(volt_reading)
     end

     private
     # Sort out the row data collected from multimeter. The data is returned on hash table 
     # containing all reading for domains' valatage, voltage drop and current.
     # Input parameters: Array containing all voltage reading for all domains. 
     # Return Parameter: A hash table voltage, current and voltage drop for all domains.   
     def sort_raw_data(volt_readings) 
       chan_all_volt_reading = Hash.new
       for i in (0..@number_of_channels/2 - 1 ) 
	 chan_all_volt_reading["domain_" + @dut_power_domains[i] + "_volt_readings"] = Array.new()
         chan_all_volt_reading["domain_" + @dut_power_domains[i] + "drop_volt_readings"] = Array.new()
         chan_all_volt_reading["domain_" + @dut_power_domains[i] + "_current_readings"] = Array.new()
       end 
       volt_reading_array = Array.new
       volt_readings.each do |current_line| 
         current_line = current_line.gsub(/\x00/,'')
         current_line_arr = current_line.strip.split(/[,\r\n]+/)
         count = @number_of_channels - 1
         if current_line_arr.length == (@number_of_channels) && current_line.match(/([+-]\d+\.\d+E[+-]\d+,){#{count}}[+-]\d+\.\d+E[+-]\d+/)
          volt_reading_array.concat(current_line_arr)
         else 
          puts "NOTHING #{current_line}"
         end
      end
    #process arrays 
    volt_reading_array.each_index{|array_index|
    mod = array_index % @number_of_channels
    temp_data = volt_reading_array[array_index].gsub(/\+/,'').to_f
    if (0 <= mod and mod < (@number_of_channels / 2))
     chan_all_volt_reading["domain_"+ @dut_power_domains[mod] + "drop_volt_readings"] << temp_data
     chan_all_volt_reading["domain_"+ @dut_power_domains[mod] + "_current_readings"] << temp_data/(@dut_domain_resistors[@dut_power_domains[mod]]).to_f
    elsif   (@number_of_channels/2 <= mod) and (mod < @number_of_channels)
     index = mod - @number_of_channels/2 
     chan_all_volt_reading["domain_" + @dut_power_domains[index]  + "_volt_readings"]  << temp_data
    end 
    }
    return chan_all_volt_reading
  end

  end

end  
