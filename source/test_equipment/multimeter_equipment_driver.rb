require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  class KeithleyMultiMeterDriver < Equipment::EquipmentDriver
    attr_reader :number_of_channels, :dut_power_domains, :dut_domain_resistors, :keithley_version
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
      
    #this function configures the multimeter for five channel reading
    # Input parameters: platfrom name
    # # Return Parameter: No return 
    def configure_multimeter(power_info)
      @number_of_channels = [@params['number_of_channels'].to_i, power_info['power_domains'].length * 2].min
      @keithley_version = @params['keithley_version']
      @connection_type =  @params['connection_type']
      @dut_power_domains = power_info['power_domains'] 
      @dut_domain_resistors = power_info['domain_resistors']  
      keithley_model = send_cmd("*IDN?",".*",1,true).match(/model\s+(\d+)/i).captures[0]
      send_cmd("*RST", ".*", 1, false)
      send_cmd("*CLS", ".*", 1, false)
      send_cmd(":TRAC:CLE", ".*", 1, false)
      send_cmd(":VOLT:DC:RANG AUTO ON", ".*", 1, false)
      send_cmd(":FUNC 'VOLT:DC'", ".*", 1, false)
      if keithley_model.to_s == "2701" or keithley_model.to_s == "2700"
      	 send_cmd(":ROUT:SCAN (@201:2#{"%02d" % @number_of_channels})", ".*", 1, false)
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
       timeout  = timeout + 10
       sleep 5    # Make sure multimeter is configured and DUT is in the right state
       volt_reading = []
       counter=0
       regexp = ""
       for i in (2..@number_of_channels)
        regexp = regexp + ".+?,"
       end 
       while counter < loop_count 
	        send_cmd("READ?", /#{regexp}[^\s]+/, timeout, false)
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
             volt_reading_array.concat(resort_data(current_line_arr))
         else 
          puts "Bad Data  #{current_line}  Read, parsing failed"
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
  # Re-arranging data for processing 
  def resort_data(current_line_arr) 
      sorted_data = Array.new(current_line_arr.length) 
      odd_counter = current_line_arr.length/2 
      even_counter = 0
      for i in (0..current_line_arr.length - 1)
        mod_value = i % 2
        if mod_value == 1  
         sorted_data[odd_counter ] = current_line_arr[i]
         odd_counter +=  1
        else 
         sorted_data[even_counter] = current_line_arr[i]
         even_counter +=1        
        end 
      end 
     return sorted_data
  end 
 
  end

end  
