require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  class KeithleyMultiMeterDriver < Equipment::EquipmentDriver
    attr_reader :number_of_channels, :dut_power_domains, :dut_domain_resistors, :keithley_version
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
      
    #this function configures the multimeter for five channel reading
    # Input parameters: platform name
    # # Return Parameter: No return 
    def configure_multimeter(power_info)
      @number_of_channels = [@params['number_of_channels'].to_i, power_info['power_domains'].length * 2].min
      @keithley_version = @params['keithley_version']
      @connection_type =  @params['connection_type']
      @dut_power_domains = power_info['power_domains'] 
      @dut_domain_resistors = power_info['domain_resistors']  
      send_cmd("*IDN?",/\w+/,1,false)
      keithley_model = response.match(/model\s+(\d+)/i).captures[0]
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
     def get_multimeter_output(loop_count, timeout, delay_between_samples=0)
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

  # Client-side of FTDI's FT2232-based power meter card.
  # This client-side driver requires server-side to be properly running.
  # Due to limitations on FTDI libraries, it is not possible to run the server side
  # on the Linux host machine that connects to DUTs (e.g. dra7xx-evm).
  # See test_equipment/usb_to_i2c_controller/README for more details
  class FtdiMultimeterDriver 
    attr_reader :number_of_channels, :dut_power_domains, :dut_domain_resistors

    def initialize(platform_info, log_path = nil)
      platform_info.instance_variables.each {|var|
        if platform_info.instance_variable_get(var).to_s.size > 0   
          self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
          self.instance_variable_set(var, platform_info.instance_variable_get(var))
        end
      }
    end

    def configure_multimeter(power_info)
      @number_of_channels = [@params['number_of_channels'].to_i, power_info['power_domains'].length * 2].min
      @dut_power_domains = power_info['power_domains'] 
      @dut_domain_resistors = power_info['domain_resistors']  
    end

    #Function collects data from multimeter.
    # Input parameters: 
    #    loop_count: Integer defining the number of times to perform channel measurements
    #    timeout: Integer defining the read timeout in sec
    # Return Parameter: Array containing all voltage reading for all domains. 
    def get_multimeter_output(loop_count, timeout, delay_between_samples=0)
      h = Hash.new
      @dut_power_domains.each {|d|
          h["domain_" + d + "_volt_readings"] = Array.new()
          h["domain_" + d + "drop_volt_readings"] = Array.new()
          h["domain_" + d + "_current_readings"] = Array.new()
      }
      
      s = TCPSocket.open(@telnet_ip, @telnet_port)
      # Send params to server
      s.puts @params['executable_path']
      s.puts loop_count   # number of samples
      s.puts delay_between_samples
      # Read data from server
      while line = s.gets
          puts line.chop
          m = line.match(/^Measure\s+([A-Z0-9_]+)\s*,\s+Bus = ([\d\.]+)mV, Shunt = ([\d\.]+)uV,/)
          if m
              domain, bus, shunt = m.captures
              h["domain_"+ domain + "drop_volt_readings"] << shunt.to_f * 10**-6
              h["domain_"+ domain + "_current_readings"] << (shunt.to_f * 10**-6)/(@dut_domain_resistors[domain]).to_f
              h["domain_"+ domain + "_volt_readings"]  << bus.to_f * 10**-3
          end
      end
      s.close               # Close the socket when done
      h
    end

  end

  # Driver for any board running ptool https://github.com/nmenon/powertool
  class PtoolDriver < Equipment::EquipmentDriver
    attr_reader :number_of_channels, :dut_power_domains, :dut_config_file

    def _translate_domain_names(domain)
      dict = {'dra74x_evm.conf' => {'DDR_CPU'  => 'cpu_vdd_ddr',
                                    'CORE_VDD' => 'vdd_core',
                                    'DDR_MEM' => 'vdd_ddr_mem',
                                   },
             }
      return dict[@dut_config_file][domain] if dict[@dut_config_file] and dict[@dut_config_file][domain]
      return domain.downcase
    end

    def _reverse_translate_domain_names(domain)
      dict = {'dra74x_evm.conf' => {'cpu_vdd_ddr' => 'DDR_CPU',
                                    'vdd_core' => 'CORE_VDD',
                                    'vdd_ddr_mem' => 'DDR_MEM',
                                   },
             }
      return dict[@dut_config_file][domain] if dict[@dut_config_file] and dict[@dut_config_file][domain]
      return domain.upcase
    end

    def _map_platform_to_config_file(platform)
      case platform
      when 'dra7xx-evm'
        @dut_config_file = 'dra74x_evm.conf'
      when 'dra72x-evm'
        @dut_config_file = 'dra72x_evm.conf'
      else
        raise "powertool config file not defined for #{platform}"
      end
    end

    def initialize(platform_info, log_path = nil)
      super(platform_info, log_path)
    end

    def configure_multimeter(power_info)
      @number_of_channels = [@params['number_of_channels'].to_i, power_info['power_domains'].length * 2].min
      @dut_power_domains = power_info['power_domains']
      _map_platform_to_config_file(power_info['dut_type'])
      send_cmd("cd #{@params['executable_path']}", @prompt)
      if response.match(/[Pp]assword/)
        send_cmd(' ',/login:/, 10)
        send_cmd('root', @prompt, 10)
        send_cmd("cd #{@params['executable_path']}", @prompt)
      end
      raise "Error initializing Powertool driver" if timeout?
    end

    #Function collects data from multimeter.
    # Input parameters: 
    #    loop_count: Integer defining the number of times to perform channel measurements
    #    timeout: Integer defining the read timeout in sec
    # Return Parameter: Array containing all voltage reading for all domains. 
    def get_multimeter_output(loop_count, timeout, delay_between_samples=10)
      h = Hash.new
      rails_str = ''
      @dut_power_domains.each {|d|
          h["domain_" + d.upcase + "_volt_readings"] = Array.new()
          h["domain_" + d.upcase + "drop_volt_readings"] = Array.new()
          h["domain_" + d.upcase + "_current_readings"] = Array.new()
          h["domain_" + d.upcase + "_power_readings"] = Array.new()
          rails_str += "-r #{_translate_domain_names(d)} "
      }
      send_cmd("./ptool -c configs/#{@dut_config_file} #{rails_str} -n #{loop_count} -s #{delay_between_samples}", @prompt, loop_count.to_i*delay_between_samples.to_i + 10)
      response().scan(/^\|\s*\d+\s*\|\s*(\w+)\s*\|\s*([\d\.]+)\s*\|\s*([\d\.]+)\s*\|\s*([\d\.]+)\s*\|\s*([\d\.]+)\s*\|/).each{|data|
        puts "domain \t drop V \t volt \t current \t power"
        puts "#{data[0]} \t #{data[1]} \t #{data[2]} \t #{data[3]} \t #{data[4]}"
        h["domain_"+ _reverse_translate_domain_names(data[0]) + "drop_volt_readings"] << data[1].to_f * 10**-6
        h["domain_"+ _reverse_translate_domain_names(data[0]) + "_volt_readings"]  << data[2].to_f 
        h["domain_"+ _reverse_translate_domain_names(data[0]) + "_current_readings"] << data[3].to_f * 10**-3
        h["domain_"+ _reverse_translate_domain_names(data[0]) + "_power_readings"] << data[4].to_f 
      }
      h
    end

  end

end  
