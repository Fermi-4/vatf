require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxAm335xDriver < LinuxEquipmentDriver

    def set_api(dummy_var)
    end

    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      # Make the code backward compatible, previous API used optional power_handler object as first parameter 
      @power_handler = params if ((!params.instance_of? Hash) and params.respond_to?(:reset) and params.respond_to?(:switch_on))  
      @power_handler = params['power_handler'] if !@power_handler
    
      if params.instance_of? Hash and params['primary_bootloader'] and params['secondary_bootloader']
        params['minicom_script_generator'] = method( :create_minicom_uart_script_spl )
        load_bootloader_from_uart(params)
        
      else
        connect({'type'=>'serial'}) if !@target.serial
        power_cycle()
        wait_for(/cpsw/, 90)
        send_cmd("\e", /#{@boot_prompt}/, 10)
        
      end
      
    end
     
  end

  class LinuxAm335xSKDriver < LinuxAm335xDriver

    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      # Make the code backward compatible, previous API used optional power_handler object as first parameter 
      @power_handler = params if ((!params.instance_of? Hash) and params.respond_to?(:reset) and params.respond_to?(:switch_on))  
      @power_handler = params['power_handler'] if !@power_handler
    
      if params.instance_of? Hash and params['primary_bootloader'] and params['secondary_bootloader']
        params['minicom_script_generator'] = method( :create_minicom_uart_script_spl )
        load_bootloader_from_uart(params)
        
      else
        power_cycle()
        sleep 0.5    # To allow USB serial port to be enumerated
        connect({'type'=>'serial'}) if !@target.serial
        20.times { 
          send_cmd("", @boot_prompt, 0.2, false)
          break if !timeout?
        }
      end
    end
     
    def boot (params)
      @power_handler = params['power_handler'] if !@power_handler
      image_path = params['image_path']
      puts "\n\n====== uImage is at #{image_path} =========="
      tftp_path  = params['server'].tftp_path
      tftp_ip    = params['server'].telnet_ip
      nfs_root  =params['nfs_root']
      @boot_args = params['bootargs'] if params['bootargs']
      tmp_path = File.join(params['tester'].downcase.strip,params['target'].downcase.strip,params['platform'].downcase.strip)
      
      boot_to_bootloader(params)
      connect({'type'=>'serial'}) if !@target.serial
      
      if image_path == 'mmc'  then
        send_cmd('boot', /#{@login_prompt}/, 600)
      
      elsif image_path != nil && File.exists?(image_path) && get_image(image_path, params['server'], tmp_path)
        send_cmd("",@boot_prompt, 5)
        raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if timeout?
        @uboot_version = get_uboot_version(params)
        send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 10) if image_path != 'mmc'
        send_cmd("setenv nfs_root_path #{nfs_root}",@boot_prompt, 10)
        raise 'Unable to set nfs root path' if timeout?
        #set bootloader env vars -- Note: add more commands here if you need to change the environment further
        get_boot_cmd(params).each {|cmd|
          send_cmd("#{cmd}",@boot_prompt, 10)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if timeout?
        }
        send_cmd("printenv", @boot_prompt, 20)
        send_cmd('boot', /#{@login_prompt}/, 600)
      
      else
        raise "image #{image_path} does not exist, unable to copy"
      end
      
      raise 'Unable to boot platform or platform took more than 10 minutes to boot' if timeout?
      # command prompt context commands
      send_cmd(@login, @prompt, 10) # login to the unit
      raise 'Unable to login' if timeout?
    end

  end #Class

end #Module



