require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'

module Equipment
  class StarterwareDriver < EquipmentDriver

    include CmdTranslator
    
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end

    def boot(params)
      @power_handler = params['power_handler'] if !@power_handler
      if params.instance_of? Hash and params['primary_bootloader'] and params['secondary_bootloader'] and params['boot_device'] == 'uart'
        # Boot from SERIAL port
        params['minicom_script_generator'] = method( :create_minicom_uart_script )
        load_bootloader(params)
      else
        raise "Boot Device was not specified"
      end
    end

    def load_bootloader(params)
      server = params['server']
      power_cycle()
      params['minicom_script_name'] = 'platform-boot.minicom'
      params['minicom_script_generator'].call params
      server.send_cmd("cd #{File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'])}; minicom -D #{@serial_port} -b 115200 -S #{params['minicom_script_name']}", server.prompt, 90)
    end
    
    def power_cycle
      if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
      else
        raise "Power Switch is not available. Please make sure 'dut.power_port' is defined in your bench file"
      end
    end

    def create_minicom_uart_script(params)
      File.open(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['minicom_script_name']), "w") do |file|
        sleep 1  
        file.puts "timeout 90"
        file.puts "verbose on"
        file.puts "! /usr/bin/sx -v -k --xmodem #{params['primary_bootloader']}"
        file.puts "expect {"
        file.puts "    \"CCC\""
        file.puts "}"
        file.puts "! /usr/bin/sx -v -k --xmodem #{params['secondary_bootloader']}"
        file.puts "! killall -s SIGHUP minicom"
      end
    end

  end

end


