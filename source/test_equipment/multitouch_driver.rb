require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  # To install pre-requisite driver on beaglebone, run following command:
  # sudo pip install Adafruit_BBIO
  class BeagleboneMultiTouchDriver < Equipment::EquipmentDriver
    attr_reader :number_of_servos, :dut_type, :executable_path

    def initialize(platform_info, log_path = nil)
      super(platform_info, log_path)
      @number_of_servos = @params['number_of_servos']
      @executable_path = @params['executable_path']
      @PX_TO_MM = @params['px_to_mm']
      @X_OFFSET = @params['x_offset']
    end

    def configure_device(dut_type)
      @dut_type = dut_type
      send_cmd("cd #{@params['executable_path']}", @prompt)
      if response.match(/[Pp]assword/)
        send_cmd(' ',/login:/, 10)
        send_cmd('root', @prompt, 10)
        send_cmd("cd #{@params['executable_path']}", @prompt)
      end
      
      ## UPDATE THIS SCRIPT WITH touchxy.py 
       send_cmd("ls touchxy.py &> /dev/null || wget --no-proxy http://10.218.103.34/anonymous/releases/bins/touchxy.py && chmod +x touchxy.py", @prompt)
      raise "Error initializing MultiTouch driver" if timeout?
    end

    def set_screen(screen_x, screen_y)
      @screen_x = screen_x
      @screen_y = screen_y
    end

    # Function generates touch point in the middle of the screen
    def generate_point()
        return @screen_x / 2.0 , @screen_y / 2.0
    end

    # Function builds second touch point based off the coordinates of the input point
    # Input: The original touch point
    # Return: A new point calculated by adding the offset of the distance between the two stylus
    def build_multitouch_point(p) 
        return p.x + @X_OFFSET, p.y     
    end 

    # Generate a touch event by driving Servos
    # Input parameters:
    #    screen_x: size of screen x coordinates in px
    #    screen_y: size of screen y coordinates in px
    #    coordinate: {x, y}
    # Return: Error if the point was invalid or unreachable
    def touch(coordinate)
      cmd = "./touchxy.py -p #{@screen_x} #{@screen_y} #{coordinate.x} #{coordinate.y}"
      send_cmd(cmd, @prompt)
      raise "Error generating touch event from BeagleboneMultiTouchDriver" if timeout?
      check_response(response, coordinate)
    end

    # Checks for touch error in response from beaglebone
    def check_response(res, coordinate)
      if res.match(/Error:.*dimensions.*/)
        raise "Error: point (#{coordinate.x}, #{coordinate.y}) outside of given screen dimensions"
      elsif res.match(/Error:.*reach.*/)
        raise "Error: cannot reach point (#{coordinate.x}, #{coordinate.y})"
      end
    end
  end
  
end