
class PowerHandler
	attr_reader :power_controllers
	def initialize()
		@power_controllers = Hash.new
	end
	
        def load_power_ports(io_info)
                return if !io_info
                if (io_info.kind_of?(Array))
                       io_info.each { |io_info_element|
                                io_info_element.each_key do |key|
                                        if !@power_controllers[key.to_s.downcase]
                                           @power_controllers[key.to_s.downcase] = Object.const_get($equipment_table['power_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['power_controller'][key.to_s.downcase][0])
			               end
                                end
                                    }
                else
                    io_info.each_key do |key|
                       if !@power_controllers[key.to_s.downcase]
                                 @power_controllers[key.to_s.downcase] = Object.const_get($equipment_table['power_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['power_controller'][key.to_s.downcase][0])
                       end
                    end
                 end
                 rescue Exception => e
                 raise e.to_s+"\nUnable to create power controller: " + io_info.to_s
        end

	def disconnect
		@power_controllers.each_value { |val| val.disconnect()}
	end
	
	def get_status(power_port)
		power_port.each {|key,val|
			@power_controllers[key.to_s.downcase].get_status(val)
		}
	end
	
	def switch_on(power_port)
		power_port.each {|key,val|
			@power_controllers[key.to_s.downcase].switch_on(val)
		}
	end
	
	def switch_off(power_port)
		power_port.each {|key,val|
			@power_controllers[key.to_s.downcase].switch_off(val)
		}
	end
	
	def reset(power_port)
                if (power_port.kind_of?(Array))
                  power_port.each {|power_port_element|
		        power_port_element.each {|key,val|
                             puts "ABOUT TO RESET #{power_port_element}\n"
			     @power_controllers[key.to_s.downcase].reset(val)
		                                }
                                }
                else
                     power_port.each {|key,val|
                             puts "ABOUT TO RESET #{power_port}\n"
                             @power_controllers[key.to_s.downcase].reset(val)
                                                }
                end
	end
end
  
