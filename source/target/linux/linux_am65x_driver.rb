require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/../../site_info.rb'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxArm64Driver < LinuxEquipmentDriver

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
          # at linux prompt
          reboot_regexp = /(Restarting|Rebooting|going\s+down|Reboot\s+start)/i
          reboot_regexp = params['reboot_regex'] if params['reboot_regex']
          send_cmd('sync; reboot', reboot_regexp, 100)
        end
        disconnect('serial')
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      super(params)
      @system_loader.replace_step('boot_cmd', SystemLoader::Arm64BootCmdStep.new)  if @system_loader.contains?('boot')
    end

  end
end
