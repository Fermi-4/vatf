
class PowerHandler
	attr_reader :power_controllers
	def initialize()
		@power_controllers = Hash.new
	end
	
  def load_power_ports(lio_info)
    return if !lio_info
    io_info = lio_info
    io_info = [lio_info] if !io_info.kind_of?(Array)
      io_info.each { |io_info_element|
        io_info_element.each_key do |key|
          if !@power_controllers[key.to_s.downcase]
            @power_controllers[key.to_s.downcase] = Object.const_get($equipment_table['power_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['power_controller'][key.to_s.downcase][0])
          end
        end
     }
    rescue Exception => e
      raise e.to_s+"\nUnable to create power controller: " + io_info.to_s
  end

	def disconnect
		@power_controllers.each_value { |val| val.disconnect()}
	end
	
	def get_status(p_port)
	  power_port = p_port
	  power_port = [p_port] if !p_port.kind_of?(Array)
		power_port.each {
		  port_info.each{|key,val|
			  @power_controllers[key.to_s.downcase].get_status(val)
			}
		}
	end
	
	def switch_on(p_port)
	  power_port = p_port
	  power_port = [p_port] if !p_port.kind_of?(Array)
		power_port.each {
		  port_info.each{|key,val|
			  @power_controllers[key.to_s.downcase].switch_on(val)
			}
		}
	end
	
	def switch_off(p_port)
	  power_port = p_port
	  power_port = [p_port] if !p_port.kind_of?(Array)
		power_port.each {
		  port_info.each{|key,val|
			  @power_controllers[key.to_s.downcase].switch_off(val)
		  }
		}
	end
	
	def reset(p_port)
	  power_port = p_port
	  power_port = [p_port] if !p_port.kind_of?(Array)
    power_port.each {|power_port_element|
      power_port_element.each {|key,val|
        puts "Turning off port #{val} at #{key}\n"
	      @power_controllers[key.to_s.downcase].switch_off(val)
      }
    }
    sleep 2
    power_port.each {|power_port_element|
      power_port_element.each {|key,val|
        puts "Turning on port #{val} at #{key}\n"
	      @power_controllers[key.to_s.downcase].switch_on(val)
      }
    }
  end
  
end
  
