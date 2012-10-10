module BootLoader

  ####################################################################################
  ###################### Define ways to load bootloader here #########################
  ####################################################################################
  def LOAD_NOTHING(params)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_SERIAL(params)
    params.merge!({'minicom_script_name' => 'uart-boot.minicom'})
    params['bootloader_class'].create_minicom_uart_script_spl(params)
    params['bootloader_class'].run_minicom_uart_script(params)
  end

  def LOAD_FROM_SERIAL_TI_MIN(params)
    params.merge!({'minicom_script_name' => 'uart-boot.minicom'})
    params['bootloader_class'].create_minicom_uart_script_ti_min(params)
    params['bootloader_class'].run_minicom_uart_script(params)
  end
  
  def LOAD_FROM_ETHERNET(params)
    raise "Loading bootloader from ethernet is not supported on default device"
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
  end

  def create_minicom_uart_script_spl(params)
    File.open(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['minicom_script_name']), "w") do |file|
      sleep 1  
      file.puts "timeout 180"
      file.puts "verbose on"
      file.puts "! /usr/bin/sx -v -k --xmodem #{params['primary_bootloader']}"
      file.puts "expect {"
      file.puts "    \"CCC\""
      file.puts "}"
      file.puts "! /usr/bin/sb -v  --ymodem #{params['secondary_bootloader']}"
      file.puts "expect {"
      file.puts "    \"stop autoboot\""
      file.puts "}"
      file.puts "send \"\""
      file.puts "send \"\""
      file.puts "expect {"
      file.puts "    \"#{params['dut'].boot_prompt.source}\""
      file.puts "}"
      file.puts "print \"\\nDone loading u-boot\\n\""
      file.puts "! killall -s SIGHUP minicom"
    end
  end

  def create_minicom_uart_script_ti_min(params)
    File.open(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['minicom_script_name']), "w") do |file|
      sleep 1  
      file.puts "timeout 180"
      file.puts "verbose on"
      file.puts "! /usr/bin/sx -v -k --xmodem #{params['primary_bootloader']}"
      file.puts "expect {"
      file.puts "    \"stop autoboot\""
      file.puts "}"
      file.puts "send \"\""
      file.puts "send \"loady #{params['dut'].boot_load_address}\""
      file.puts "! /usr/bin/sb -v  --ymodem #{params['secondary_bootloader']}"
      file.puts "expect {"
      file.puts "    \"#{params['dut'].first_boot_prompt.source}\""
      file.puts "}"
      file.puts "send \"go #{params['dut'].boot_load_address}\""
      file.puts "expect {"
      file.puts "    \"stop autoboot\""
      file.puts "}"
      file.puts "send \"\""
      file.puts "expect {"
      file.puts "    \"#{params['dut'].boot_prompt.source}\""
      file.puts "}"
      file.puts "print \"\\nDone loading u-boot\\n\""
      file.puts "! killall -s SIGHUP minicom"
    end
  end

  def run_minicom_uart_script(params)
    3.times { break if kill_pending_minicom_tasks(params) }  # Try to kill pending minicom tasks 3 times
    params['dut'].power_cycle(params)
    params['server'].send_cmd("cd #{File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'])}; minicom -D #{params['dut'].serial_port} -b #{params['dut'].serial_params['baud']} -S #{params['minicom_script_name']}", params['server'].prompt, 90)
  end

  def kill_pending_minicom_tasks(params)
    params['server'].send_sudo_cmd("fuser #{params['dut'].serial_port} -k", params['server'].prompt, 5)
    sleep 1
    p=`fuser #{params['dut'].serial_port}`
    !p.match(/\d+/)
  end

  def stop_at_boot_prompt(params)
    dut = params['dut']
    dut.connect({'type'=>'serial'}) if !dut.target.serial
    50.times { 
      dut.send_cmd("", dut.boot_prompt, 0.5, false)
      break if !dut.timeout?
    }
    raise "Failed to load bootloader" if dut.timeout?
  end

end


