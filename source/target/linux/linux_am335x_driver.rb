require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxAm335xDriver < LinuxEquipmentDriver

    def set_api(dummy_var)
    end

    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      # Make the code backward compatible, previous API used optional power_handler object as first parameter 
      @power_handler = params if (params and params.respond_to?(:reset) and params.respond_to?(:switch_on))  
    
      if params.instance_of? Hash and params['primary_bootloader'] and params['secondary_bootloader']
        params['minicom_script_generator'] = method( :create_minicom_uart_script_spl )
        load_bootloader_from_uart(params)
        
      else
        connect({'type'=>'serial'}) if !@target.serial
        power_cycle()
        wait_for(/cpsw/, 5)
        send_cmd("\e", /#{@boot_prompt}/, 10)
        
      end
      
    end
     
  end
end
