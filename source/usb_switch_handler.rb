class UsbSwitchHandler
	attr_reader :usb_switch_controller
	def initialize()
		@usb_switch_controller = Hash.new
	end

	def load_usb_ports(io_info)
		return if !io_info
		io_info.each_key do |key|
			if !@usb_switch_controller[key.to_s.downcase]
				@usb_switch_controller[key.to_s.downcase] = Object.const_get($equipment_table['usb_switch_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['usb_switch_controller'][key.to_s.downcase][0])
			end
		end
	rescue Exception => e
		raise e.to_s+"\nUnable to create power controller: " + io_info.to_s
	end

	def disconnect(switch)
		@usb_switch_controller[switch.to_s.downcase].disconnect()
	end

	def select_input(input)
		input.each { |switch, port|
			@usb_switch_controller[switch.to_s.downcase].select_input(port)
		}
	end
end
