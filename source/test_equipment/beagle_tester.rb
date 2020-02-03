# Beaglebone Black (BBB) drivers to support different functionality
# BBB MUST be flashed with appropriate debian images prior to using these drivers
# The images are available at https://beagleboard.org/latest-images
# The drivers were developed and tested using following image
# https://debian.beagleboard.org/images/bone-debian-9.9-iot-armhf-2019-08-03-4gb.img.xz
# Also available at /mnt/gtautoftp/releases/bbb_images/bone-debian-9.9-iot-armhf-2019-08-03-4gb.img.xz
# The image can be easily flashed to a uSD card using https://www.balena.io/etcher/
# The drivers are ruby wrappers for Adafruit_BBIO library
# BBB pintout is available at http://www.toptechboy.com/wp-content/uploads/2015/06/beaglebone-black-pinout.jpg

require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'

module TestEquipment

  class BeagleTester < Equipment::EquipmentDriver

    def initialize(platform_info, log_path = nil)
      super(platform_info, log_path)
    end


    def log_in()
      send_cmd(@login, /[Pp]assword:/, 10)
      send_cmd(@login_passwd, @prompt, 20, false)
    end

    # Must be called prior to using BeagleTester functions to control pins
    def configure_device()
      3.times do
        send_cmd("", @prompt)
        break if !timeout?
        if response.match(/[Pp]assword:/)
          send_cmd(' ',/login:/, 10, false)
        end
        log_in()
      end
      raise "Error login into BeagleTester device" if timeout?
      send_cmd("cd ~", @prompt)
      transfer_file(File.join(File.dirname(__FILE__), 'beagle_adc.py'))
      transfer_file(File.join(File.dirname(__FILE__), 'beagle_gpio.py'))
      transfer_file(File.join(File.dirname(__FILE__), 'beagle_pwm.py'))
    end


    def transfer_file(file_path)
      file_name = File.basename(file_path)
      raise "#{file_path} does not exist in the host machine" if ! File.exists? file_path
      send_cmd("ls #{file_name} && echo $?", /^0/, 2)
      if timeout?
        in_file = File.new(file_path, 'r')
        raw_test_lines = in_file.readlines
        send_cmd("cat > #{file_name} << EOF", />/)
        raw_test_lines.each do |current_line|
          send_cmd(current_line)
        end
        send_cmd("EOF", @prompt)
        raise "Error transfering #{file_name}. Check rootfs has enough space" if /write\s+error:/i.match(response)
        send_cmd("chmod +x #{file_name}", @prompt)
      end
    end

    # Read adc channel on BBB.
    # It returns normalized values from 0 to 1.0, where full scale corresponds to 1.8volts
    def adc_read(channel)
      begin
        cmd = "./beagle_adc.py -c #{channel}"
        send_cmd(cmd, @prompt)
        response.match(/^(\d[\d\.]+)/).captures[0].to_f
      rescue Exception => err
        puts err
        log_info("BeagleTester Exception: #{err}")
        raise "Error reading adc channel"
      end
    end


    # Set GPIO channel as output and write value
    # value can be either 0 or 1
    def gpio_write(channel, value)
      cmd = "./beagle_gpio.py -c #{channel} -d 1 -o #{value}"
      send_cmd(cmd, @prompt)
      raise "Error setting gpio output" if timeout?
    end


    # Set GPIO channel as input and read value
    # Valid pull_up_down values are 0 for off (default), 1 for pull-down, 2 for pull-up
    # Returns 0 or 1
    def gpio_read(channel, pull_up_down=0)
      begin
        cmd = "./beagle_gpio.py -c #{channel} -d 0 -p #{pull_up_down}"
        send_cmd(cmd, @prompt)
        response.match(/^([01]{1})/).captures[0].to_i
      rescue Exception => e
        puts err
        log_info("BeagleTester Exception: #{err}")
        raise "Error reading gpio channel"
      end
    end


    # Set GPIO channel as input and wait for edge detection
    # Both low-to-high or high-to-low edges will trigger detection
    # Wait 60 seconds by default, timeout is in seconds
    # Return true if timeout occur waiting for edge, false otherwise
    def gpio_wait_for_edge(channel, timeout=60)
      cmd = "./beagle_gpio.py -c #{channel} -d 0 -e 1 -t #{timeout*1000+3000}"
      send_cmd(cmd, @prompt, timeout)
      timeout?
    end


    # Generate PWM signal on desired channel
    # duty_cycle must have a value from 0 to 100
    # frequency is in hertz, default is 2000
    # polarity is not operational, but same effect can be achieved by changing the duty_cycle
    def pwm_start(channel, duty_cycle, frequency=2000, polarity=0)
      cmd = "./beagle_pwm.py -c #{channel} -d #{duty_cycle} -f #{frequency} -p #{polarity}"
      send_cmd(cmd, @prompt)
      raise "Error starting pwm signal" if timeout?
    end


    # Stop generating PWM signal on desired channel
    def pwm_stop(channel)
      cmd = "./beagle_pwm.py -c #{channel} -d 10 -s 1"
      send_cmd(cmd, @prompt)
      raise "Error stopping pwm signal" if timeout?
    end

  end

end
