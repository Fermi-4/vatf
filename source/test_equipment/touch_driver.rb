require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  # To install pre-requisite driver on beaglebone, run following command:
  # sudo pip install Adafruit_BBIO
  class BeagleboneSingleTouchDriver < Equipment::EquipmentDriver
    attr_reader :number_of_servos, :dut_type, :executable_path

    def initialize(platform_info, log_path = nil)
      super(platform_info, log_path)
      @number_of_servos = @params['number_of_servos']
      @executable_path = @params['executable_path']
    end

    def configure_device(dut_type)
      @dut_type = dut_type
      send_cmd("cd #{@params['executable_path']}", @prompt)
      if response.match(/[Pp]assword/)
        send_cmd(' ',/login:/, 10)
        send_cmd('root', @prompt, 10)
        send_cmd("cd #{@params['executable_path']}", @prompt)
      end
       send_cmd("ls touch.py &> /dev/null || wget --no-proxy http://10.218.103.34/anonymous/releases/bins/touch.py && chmod +x touch.py", @prompt)
      raise "Error initializing SingleTouch driver" if timeout?
    end

    # Generate a touch event by driving Servos
    # Input parameters:
    #    coordinates: 'top-left', 'top-right', 'center', 'bottom-left', 'bottom-right'
    # Return: Nothing. Raise exception if can't communicate with beaglebone
    def touch(coordinates)
      cmd = "./touch.py #{translate_coordinates(coordinates)}"
      send_cmd(cmd, @prompt)
      raise "Error generating touch event from BeagleboneSingleTouchDriver" if timeout?
	end

    # Input: coordinates (e.g. 'top-left')
    # Output: Returns command string to send to beaglebone
    def translate_coordinates(coordinates)
	    case coordinates
	    when /top-left/
	        case @dut_type
	        when /am437x-sk/
	            return '1:40 2:40 3:70'
	        end
		when /top-right/
			case @dut_type
	        when /am437x-sk/
	            return '3:20 1:54 2:62'
	        end
	    when /center/
	        case @dut_type
	        when /am437x-sk/
                return '1:62 2:52 3:55'
	        end
	    when /bottom-left/
	        case @dut_type
	        when /am437x-sk/
                 return '2:34 1:69 3:65'
	        end
	    when /bottom-right/
	        case @dut_type
	        when /am437x-sk/
                 return '3:23 1:70 2:53'
	        end
	    else
	        raise "Invalid coordinate #{coordinates} specified"
	    end

    end

  end

end