class UsbSwitchHandler
	attr_reader :usb_switch_controller
	def initialize()
		@usb_switch_controller = Hash.new
	end

	def load_usb_ports(io_info)
        atf_session_runner = yield
		return if !io_info
		io_info.each_key do |key|
			if !@usb_switch_controller[key.to_s.downcase]
				atf_session_runner.add_equipment("usb_switch#{key}") do |log_path|
                    @usb_switch_controller[key.to_s.downcase] = Object.const_get($equipment_table['usb_switch_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['usb_switch_controller'][key.to_s.downcase][0], log_path)
                end
            end
        end
	    rescue Exception => e
		    raise e.to_s+"\nUnable to create usb switch controller: " + io_info.to_s
	end

	def disconnect(switch)
		@usb_switch_controller[switch.to_s.downcase].disconnect()
	end

	def select_input(input)
		input.each { |switch, port|
			@usb_switch_controller[switch.to_s.downcase].select_input(port)
		}
	end

	def reset(input)
		input.each { |switch, port|
			if @usb_switch_controller[switch.to_s.downcase].respond_to?(:reset)
				@usb_switch_controller[switch.to_s.downcase].reset(port)
			end
		}
	end
end
