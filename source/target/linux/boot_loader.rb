require File.dirname(__FILE__)+'/../../lib/sysboot'

module BootLoader

  class BootloaderException < Exception
    def initialize(e=nil)
      super()
      set_backtrace(e.backtrace.insert(0,e.to_s)) if e
    end
  end
  ####################################################################################
  ###################### Define ways to load bootloader here #########################
  ####################################################################################
  def LOAD_NOTHING(params)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_SERIAL(params)
    puts "########LOAD_FROM_SERIAL########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'uart')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params.merge!({'bootloader_load_script_name' => 'uart-spl-boot.sh'})
    params['bootloader_class'].create_bootloader_load_script_uart_spl(params)
    params['bootloader_class'].run_bootloader_load_script(params)
  end

  def LOAD_FROM_SERIAL_TI_MIN(params)
    params.merge!({'bootloader_load_script_name' => 'uart-ti-min-boot.sh'})
    params['bootloader_class'].create_bootloader_load_script_uart_ti_min(params)
    params['bootloader_class'].run_bootloader_load_script(params)
  end

  def LOAD_FROM_SERIAL_UBOOT(params)
    puts "########LOAD_FROM_SERIAL_UBOOT########"
    params.merge!({'bootloader_load_script_name' => 'uart-u-boot.sh'})
    params['bootloader_class'].create_bootloader_load_script_uart_uboot(params)
    params['bootloader_class'].run_bootloader_load_script(params)
  end
  
  def LOAD_FROM_NAND_BY_BMC(params)
    puts "########LOAD_FROM_NAND_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'nand')
  end

  def LOAD_FROM_NAND(params)
    puts "########LOAD_FROM_NAND########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'nand')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_QSPI_BY_BMC(params)
    puts "########LOAD_FROM_QSPI_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'qspi')
  end

  def LOAD_FROM_QSPI(params)
    puts "########LOAD_FROM_QSPI########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'qspi')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_SPI_BY_BMC(params)
    puts "########LOAD_FROM_SPI_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'spi')
  end

  def LOAD_FROM_SPI(params)
    puts "########LOAD_FROM_SPI########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'spi')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_EMMC(params)
    puts "########LOAD_FROM_EMMC########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'emmc')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_USBETH(params)
    puts "########LOAD_FROM_USBETH########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'usbeth')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_USBMSC(params)
    puts "########LOAD_FROM_USBMSC########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'usbmsc')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_ETHERNET(params)
    raise "Loading bootloader from ethernet is not supported on default device"
  end

  def LOAD_FROM_NO_BOOT_DSP_BY_BMC(params)
    params['dut'].power_cycle(params)
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'dsp_no')
  end
  ####################################################################################
  ####################################################################################

end

class BaseLoader
  attr_accessor :load_method

  include BootLoader
  
  def initialize(load_method=nil)
    if load_method
      @load_method = load_method
    else
      @load_method = method(:LOAD_NOTHING)
    end
  end

  def run(params)
    params['bootloader_class'] = self if !params.has_key? 'bootloader_class'
    @load_method.call params
    stop_at_boot_prompt params
    rescue Exception => e
      raise BootloaderException.new(e)
  end

  def create_bootloader_load_script_uart_spl(params)
    script = File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['bootloader_load_script_name'])
    File.open(script, "w") do |file|
      sleep 1  
      file.puts "#!/bin/bash"
      # Run stty to set the baud rate.
      file.puts "stty -F #{params['dut'].serial_port} #{params['dut'].serial_params['baud']}"
      # Send SPL as xmodem, 2 minute timeout.
      file.puts "/usr/bin/timeout 120 /usr/bin/sx -k --xmodem #{params['primary_bootloader']} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
      # If we timeout or don't return cleanly (transfer failed), return 1
      file.puts "if [ $? -ne 0 ]; then exit 1; fi"
      # Send U-Boot as ymodem, 4 minute timeout.
      file.puts "/usr/bin/timeout 240 /usr/bin/sb -kb --ymodem #{params['secondary_bootloader']} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
      # If we timeout or don't return cleanly (transfer failed), return 1
      file.puts "if [ $? -ne 0 ]; then exit 1; fi"
      # Send an echo to be sure that we will break into autoboot.
      file.puts "echo > #{params['dut'].serial_port}"
      # Return success.
      file.puts "exit 0"
    end
    File.chmod(0755, script)
  end

  def create_bootloader_load_script_uart_ti_min(params)
    script = File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['bootloader_load_script_name'])
    File.open(script, "w") do |file|
      sleep 1  
      file.puts "#!/bin/bash"
      # Run stty to set the baud rate.
      file.puts "stty -F #{params['dut'].serial_port} #{params['dut'].serial_params['baud']}"
      # Send u-boot-min as xmodem, 2 minute timeout.
      file.puts "/usr/bin/timeout 120 /usr/bin/sx -v -k --xmodem #{params['primary_bootloader']} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
      # If we timeout or don't return cleanly (transfer failed), return 1
      file.puts "if [ $? -ne 0 ]; then exit 1; fi"
      # Send an echo to be sure that we will break into autoboot.
      file.puts "echo > #{params['dut'].serial_port}"
      # Start loady
      file.puts "echo \"loady #{params['dut'].boot_load_address}\" > #{params['dut'].serial_port}"
      # Send U-Boot as ymodem, 4 minute timeout.
      file.puts "/usr/bin/timeout 240 /usr/bin/sb -v --ymodem #{params['secondary_bootloader']} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
      # Start it.
      file.puts "echo \"go #{params['dut'].boot_load_address}\" > #{params['dut'].serial_port}"
      # If we timeout or don't return cleanly (transfer failed), return 1
      file.puts "if [ $? -ne 0 ]; then exit 1; fi"
      # Send an echo to be sure that we will break into autoboot.
      file.puts "echo > #{params['dut'].serial_port}"
      # Return success.
      file.puts "exit 1"
    end
    File.chmod(0755, script)
  end

  def create_bootloader_load_script_uart_uboot(params)
    script = File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['bootloader_load_script_name'])
    File.open(script, "w") do |file|
      sleep 1
      file.puts "#!/bin/bash"
      # Run stty to set the baud rate.
      file.puts "stty -F #{params['dut'].serial_port} #{params['dut'].serial_params['baud']}"
      # Send SPL as xmodem, 2 minute timeout.
      file.puts "/usr/bin/timeout 120 /usr/bin/sx -k --xmodem #{params['secondary_bootloader']} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
      # If we timeout or don't return cleanly (transfer failed), return 1
      file.puts "if [ $? -ne 0 ]; then exit 1; fi"
      # Send an echo to be sure that we will break into autoboot.
      file.puts "echo > #{params['dut'].serial_port}"
      # Return success.
      file.puts "exit 0"
    end
    File.chmod(0755, script)
  end

  def run_bootloader_load_script(params)
    dut = params['dut']
    # Kill anything which has the serial port open already.
    3.times { break if kill_tasks_holding_serial_port(params) }

    # Make sure that we're ready to catch the board coming out of reset
    sleep 1
    tx_thread = Thread.new do
      params['server'].send_cmd(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['bootloader_load_script_name']), params['server'].prompt, 240)
    end
    if dut.params and dut.params.key? 'bmc_port'
      bmc_trigger_boot(dut, 'uart')
    else
      # Ensure the board is reset.
      dut.power_cycle(params)
    end
    tx_thread.join()
  end

  def bmc_get_version(dut)
    prompt = dut.params.key?('bmc_prompt') ? dut.params['bmc_prompt'] : />/
    dut.target.bmc.send_cmd(CmdTranslator::get_bmc_cmd({'cmd'=>'version', 'version'=>'1.0', 'platform'=>dut.name}), prompt, 3, false )
    @bmc_version = dut.target.bmc.response.to_s.match(/\[[\d\:]+\][^\d]+(\d\.[\d\.]+).+/m).captures[0]
    return @bmc_version
  end

  def bmc_trigger_boot(dut, device)
    case device.downcase
    when 'uart'
      cmd_key = "uart_bootmode"
    when 'dsp_no'
      cmd_key = "dsp_no_bootmode"
    when 'nand'
      cmd_key = "nand_bootmode"
    when 'spi'
      cmd_key = "spi_bootmode"
    else
      raise "The #{device} is not supported in bmc_trigger_boot"
    end

    prompt = dut.params.key?('bmc_prompt') ? dut.params['bmc_prompt'] : />/
    sleep 3
    dut.connect({'type'=>'bmc'})
    3.times {
      begin
        dut.target.bmc.send_cmd("\n\r", prompt, 2, false)
      rescue Exception => e
        puts "Timeout waiting for prompt"
      end
    }
    dut.target.bmc.send_cmd(CmdTranslator::get_bmc_cmd({'cmd'=>cmd_key, 'version'=>bmc_get_version(dut), 'platform'=>dut.name}), prompt, 3, false )
    dut.target.bmc.send_cmd(CmdTranslator::get_bmc_cmd({'cmd'=>'reboot', 'version'=>'1.0'}), prompt, 10, false )
  end

  def kill_tasks_holding_serial_port(params)
    params['server'].send_sudo_cmd("fuser #{params['dut'].serial_port} -k", params['server'].prompt, 5)
    sleep 1
    p=`fuser #{params['dut'].serial_port}`
    !p.match(/\d+/)
  end

  def stop_at_boot_prompt(params)
    dut = params['dut']
    dut.connect({'type'=>'serial'}) 
    b_prompt_th = Thread.new do
      dut.send_cmd("", dut.boot_prompt, 40, false)
    end
    200.times {
      dut.target.serial.puts(" ")
      dut.target.serial.flush
      s_time = Time.now()
      while Time.now() - s_time < 0.1
        #busy wait
      end
      break if !b_prompt_th.alive?
    }
    b_prompt_th.join()
    raise "Failed to load bootloader" if dut.timeout?
  end

end

class DSPOnlyLoader < BaseLoader

  def initialize(load_method=nil)
    super(load_method)
  end

  def stop_at_boot_prompt(params)
  end

end


