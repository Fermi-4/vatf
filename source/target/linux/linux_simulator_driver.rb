require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
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
      timeout*=8  # Simulators run much slower than real device
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

    def login_simulator(params)
      connect({'type'=>'serial'}) if !target.serial
      boot_timeout = params['var_boot_timeout'] ? params['var_boot_timeout'].to_i : 600
      wait_for(params['dut'].login_prompt, boot_timeout)
      params['dut'].boot_log = params['dut'].response
      raise "DUT rebooted while Starting Kernel" if params['dut'].boot_log.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
      params['dut'].check_for_boot_errors()
      if params['dut'].timeout?
        params['dut'].log_info("Collecting kernel traces via sysrq...")
        params['dut'].send_sysrq('t')
        params['dut'].send_sysrq('l')
        params['dut'].send_sysrq('w')
      end
      3.times {
        send_cmd(params['dut'].login, params['dut'].prompt, 40, false)
        break if !params['dut'].timeout?
      }
      raise "Error executing boot" if params['dut'].timeout?
    end

    # Take the DUT from power on to system prompt
    def boot (params)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @boot_loader.run params
      @system_loader.run params
      @platform_info.serial_server_port = @system_loader.get_step('start_simulator')[0].simulator_socket
      login_simulator(params)
    end

  end
end
