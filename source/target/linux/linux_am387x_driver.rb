require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxAm387xDriver < LinuxEquipmentDriver

    def set_api(dummy_var)
    end

    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      connect({'type'=>'serial'}) if !@target.serial
      # Make the code backward compatible. Previous API used optional power_handler object as first parameter 
      @power_handler = params if ((!params.instance_of? Hash) and params.respond_to?(:reset) and params.respond_to?(:switch_on))
      @power_handler = params['power_handler'] if !@power_handler
      #@power_handler = power_hdler if power_hdler 
      puts 'rebooting DUT am387x'
      if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
        wait_for(/I2C:/, 10)
        #send_cmd("\e", /#{@boot_prompt}/, 10)
      else
        puts "Soft reboot..."
        send_cmd('reboot', /I2C:/, 40)        
      end
      send_cmd("\e", /#{@boot_prompt}/, 10)     
      # stop the autobooter from autobooting the box
      0.upto 5 do
        send_cmd("\n", @boot_prompt, 1)
        puts 'Sending newline character'
        sleep 1
        break if !timeout?
      end
      # now in the uboot prompt
    end
  end
end
