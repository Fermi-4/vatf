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
      @PX_TO_MM = @params['px_to_mm']
      @MAX_X = @params['max_x']
      @MAX_Y = @params['max_y']
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
      raise "Error initializing SingleTouch driver" if timeout?
    end

    def set_screen(screen_x, screen_y)
      @screen_x = screen_x
      @screen_y = screen_y
    end

    # Generate points to touch based on screen size
    # Input parameters:
    #    screen_x: size of screen x coordinates in px
    #    screen_y: size of screen y coordinates in px
    # Return: Array of points
    def generate_points()
      points = Array.new

      high_x = safety_check(3 * @screen_x / 4.0, true)
      low_x = safety_check(@screen_x / 4.0, true)
      
      high_y = safety_check(3 * @screen_y / 4.0, false)
      low_y = safety_check(@screen_y / 4.0, false)
      
      # Top Left:
      points.push(low_x)
      points.push(low_y)

      # Top Right:
      points.push(high_x)
      points.push(low_y)

      # Bottom Left:
      points.push(low_x)
      points.push(high_y)

      # Bottom Right:
      points.push(high_x)
      points.push(high_y)

      # Center:
      points.push(@screen_x / 2.0)
      points.push(@screen_y / 2.0)

      return points
    end

    # Ensures that generated points are within the 
    # determined safe touch range to prevent possible screen damage
    # Input: x or y coordinate, x_flag true if x false if y 
    # Return: original point or modified points to fit safety constraints
    def safety_check(point, x_flag)
      max = x_flag ? @MAX_X : @MAX_Y  
            
      # Translate point to mm
      p_mm = px_to_mm(point, x_flag)
      
      # If point greater than max or less than min touch value, set it to respective extreme
      # Else, return original point
      if (p_mm > max) 
        return mm_to_px(max, x_flag)
      elsif (p_mm < max * -1)
        return mm_to_px(max * -1, x_flag)
      else
        return point
      end      
    end
    
    # Translates a screen point from pixels to millimeters
    # Input: x or y coordinate, with true flag for x or false flag for y
    # Return: new values in millimeters
    def px_to_mm(p, x_flag)
      screen = x_flag ? @screen_x : @screen_y  
      
      p -= (screen / 2.0)
      p *= @PX_TO_MM
      
      return p
    end
    
    # Translates a screen point from millimeters to pixels
    # Input: x or y coordinate, with true flag for x or false flag for y
    # Return: new value in pixels
    def mm_to_px(p, x_flag) 
      screen = x_flag ? @screen_x : @screen_y  

      p /= @PX_TO_MM
      p += (screen / 2.0)

      return p
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
      raise "Error generating touch event from BeagleboneSingleTouchDriver" if timeout?
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
