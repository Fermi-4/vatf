require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/../../site_info.rb'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxSimulatorDriver < LinuxEquipmentDriver

    def power_cycle(params)
      begin
        disconnect('serial')
      end
    end

    def send_cmd(command, expected_match=/.*/, timeout=10, check_cmd_echo=true, append_linefeed=true)
      timeout*=30  # Simulators run much slower than real device
      super(command, expected_match, timeout, check_cmd_echo, append_linefeed)
    end

    # Select BootLoader's load_method based on params
    def set_bootloader(params)
      SysBootModule::reset_sysboot(params['dut'])
      @boot_loader = SkipBootLoader.new
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::SimulatorSystemLoader.new
    end

    def install_startup_files(params)
      startup_tarball = params['simulator_startup_files']
      install_directory = File.join(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name']), File.basename(startup_tarball))
      if !File.directory?(install_directory)
        params['server'].send_cmd("mkdir -p #{install_directory}", params['server'].prompt, 30)
        params['server'].send_cmd("tar -C #{install_directory} -xvf #{startup_tarball}; echo $?", /^0/, 30)
        raise "Error installing simulator_startup_files" if params['server'].timeout?
      end
      if params.key?('var_simulator_startup_script_name') and params['var_simulator_startup_script_name'].match(/.+\.sh/)
        params['dut'].params['simulator_startup_cmd'] = "cd #{install_directory}; cd $(dirname $(find . -name vlab-startup)); "
      elsif not params.key?('linux_system') or params['linux_system'].size < 2
        params['dut'].params['simulator_startup_cmd'] = "cd #{install_directory}; cd $(dirname $(find . -name vlab-startup)); ./vlab-startup -c -d `pwd` -p '"
      else
        params['dut'].params['simulator_startup_cmd'] = "cd #{install_directory}; cd $(dirname $(find . -name vlab-startup)); ./vlab-startup -c -p '"
      end
    end

    # Take the DUT from power on to system prompt
    def boot (params)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      if params.key?('simulator_startup_files') and params['simulator_startup_files'].size > 0
        install_startup_files(params)
      end
      if params.key?('var_simulator_startup_script_name') and params['var_simulator_startup_script_name'].size > 0
        params['dut'].params['simulator_python_script'] = params['var_simulator_startup_script_name']
      end
      params.each{|k,v| puts "#{k}:#{v}"}
      @boot_loader.run params
      @system_loader.run params
      @platform_info.serial_server_port = @system_loader.get_step('start_simulator')[0].simulator_socket
    end

    def reset_sysboot(dut)
      @system_loader.get_step('start_simulator')[0].simulator_stdin.puts("quit()")
      Process.kill("KILL", @system_loader.get_step('start_simulator')[0].simulator_thread.pid)
    end


  end
end
