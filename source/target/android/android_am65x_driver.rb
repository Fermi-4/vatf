require File.dirname(__FILE__)+'/../linux/linux_equipment_driver'
require File.dirname(__FILE__)+'/../linux/boot_loader'
require File.dirname(__FILE__)+'/../linux/system_loader'

module Equipment
  include SystemLoader

  class AndroidAm65xDriver < AndroidEquipmentDriver
	# Auto Interface on AM654x requires especial sequence to set sysboot pins
    # because I/O expander on I2C bus loses power/context during EVM power off.
    def power_cycle(params)
      @power_handler = params['power_handler'] if !@power_handler
      connected = true
      begin
        connect({'type'=>'serial'})
        send_cmd(@login,@prompt, 3) if at_login_prompt?
      rescue Exception => e
        raise e if !@power_port
        log_info("Problems while trying to connect to the board...\n" \
                 "#{e.to_s}\nWill try to connect again after power cycle...")
        connected = false
      end

      last_response = ''
      if @power_port !=nil
        puts 'Resetting using power switch'
        poweroff(params) if connected && at_prompt?({'prompt'=>@prompt})
        disconnect('serial')
        if @params and @params.key?('sysboot_ctrl') and @params['sysboot_ctrl'].driver_class_name == 'AutomationInterfaceDriver'
          # Use POR instead of power off due to AM654x auto interface limitation
          @power_handler.por(@power_port) do
            yield if block_given?
          end
        else
          @power_handler.reset(@power_port) do
            yield if block_given?
          end
        end
        trials = 0
        while (@serial_port && !File.exist?(@serial_port) && trials < 600)
          sleep 0.1
          trials += 1
        end
        raise "Unable to detect serial node for the dut" if trials >= 600

      else
        puts "Soft reboot..."
        send_cmd('#check prompt', @prompt, 8)
        yield if block_given?
        if timeout?
          # assume at u-boot prompt
          send_cmd('reset', /resetting/i, 3)
        else
          reboot(params)
        end
        last_response = @response
        disconnect('serial')
      end
        last_response
    end

    def set_systemloader(params)
      @system_loader = SystemLoader::FastbootScriptSystemLoader.new
      if params.has_key?("autologin")
        @system_loader.replace_step('boot', BootAutologinStep.new)
      end
    end

    def recover_bootloader(params)
      ub_params = params.dup
      ub_params['primary_bootloader_dev'] = 'uart'
      raise "Bootloader cannot be recovered from failing device(s), #{params['initial_bootloader']}, #{params['sysfw']} #{params['primary_bootloader']} and #{params['secondary_bootloader']} must be defined" if !ub_params['primary_bootloader'] || !ub_params['initial_bootloader'] || !ub_params['secondary_bootloader'] || !ub_params['sysfw']
      msg = "Failed to boot to bootloader from #{params['primary_bootloader_dev']}, trying to recover from UART"
      puts msg
      log_info(msg)
      @boot_loader = nil
      disconnect('serial')
      boot_to_bootloader(ub_params)
      @updated_bootloader = true
    end

  end

end
