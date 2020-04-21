require File.dirname(__FILE__)+'/../../lib/sysboot'

module BootLoader

  class BootloaderException < Exception
    def initialize(*e)
      super()
      if e.length > 0
        set_backtrace(e[0].backtrace.insert(0,e[0].to_s))
        e[1..-1].each { |c_e| backtrace.insert(0,c_e.to_s) }
      end
    end
  end
  ####################################################################################
  ###################### Define ways to load bootloader here #########################
  ####################################################################################
  def SKIP_BOOTLOADER(params)
    puts "Skipping bootloader"
  end

  def LOAD_NOTHING(params)
    params['dut'].power_cycle(params)
  end

  def LOAD_FROM_SERIAL(params)
    puts "########LOAD_FROM_SERIAL########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'uart')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['bootloader_class'].load_uart_spl(params)
  end

  def LOAD_FROM_SERIAL_TI_MIN(params)
    puts "########LOAD_FROM_SERIAL_TI_MIN########"
    params['bootloader_class'].load_uart_ti_min(params)
  end

  def LOAD_FROM_SERIAL_TI_BOOT3(params)
    puts "########LOAD_FROM_SERIAL_TI_BOOT3########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'uart')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['bootloader_class'].load_uart_ti_boot3(params)
  end

  def LOAD_FROM_SERIAL_UBOOT(params)
    puts "########LOAD_FROM_SERIAL_UBOOT########"
    params['bootloader_class'].load_uart_uboot(params)
  end
  
  def LOAD_FROM_SERIAL_TI_OMAP(params)
    puts "########LOAD_FROM_SERIAL_TI_OMAP########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'uart')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    params['bootloader_class'].load_uart_ti_omap(params)
  end

  def LOAD_FROM_NAND_BY_BMC(params)
    puts "########LOAD_FROM_NAND_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'nand')
  end

  def LOAD_FROM_NAND(params)
    puts "########LOAD_FROM_NAND########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'nand')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    last_response = params['dut'].power_cycle(params)
    check_boot_media(params, 'nand', last_response)
  end

  def LOAD_FROM_HFLASH(params)
    puts "########LOAD_FROM_HFLASH########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'hflash')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    last_response = params['dut'].power_cycle(params)
    check_boot_media(params, 'nor', last_response)
  end

  def LOAD_FROM_QSPI_BY_BMC(params)
    puts "########LOAD_FROM_QSPI_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'qspi')
  end

  def LOAD_FROM_OSPI(params)
    puts "########LOAD_FROM_OSPI########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'ospi')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    early_conn_power_cycle(params, 'spi', 'c')
  end

  def LOAD_FROM_QSPI(params)
    puts "########LOAD_FROM_QSPI########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'qspi')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    early_conn_power_cycle(params, 'spi', 'c')
  end

  def LOAD_FROM_SPI_BY_BMC(params)
    puts "########LOAD_FROM_SPI_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'spi')
  end

  def LOAD_FROM_SPI(params)
    puts "########LOAD_FROM_SPI########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'spi')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    early_conn_power_cycle(params, 'spi', 'c')
  end

  def LOAD_FROM_EMMC(params)
    puts "########LOAD_FROM_EMMC########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'emmc')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    early_conn_power_cycle(params, CmdTranslator::get_uboot_cmd({'cmd'=>'emmcboot_expect', 'version'=>'0.0', 'platform'=>params['dut'].name}))
  end

  def LOAD_FROM_EMMC_USER(params)
    puts "########LOAD_FROM_EMMC########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'emmc_user')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    early_conn_power_cycle(params, CmdTranslator::get_uboot_cmd({'cmd'=>'emmcboot_expect', 'version'=>'0.0', 'platform'=>params['dut'].name}))
  end

  def LOAD_FROM_USBETH(params)
    puts "########LOAD_FROM_USBETH########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'usbeth')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    last_response = params['dut'].power_cycle(params)
    check_boot_media(params, 'usb eth', last_response)
  end

  def LOAD_FROM_USBMSC(params)
    puts "########LOAD_FROM_USBMSC########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'usbmsc')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    last_response = params['dut'].power_cycle(params)
    check_boot_media(params, 'usb', last_response)
  end

  def LOAD_FROM_ETHERNET(params)
    puts "########LOAD_FROM_ETHERNET#########"
    this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], 'eth')
    SysBootModule::set_sysboot(params['dut'], this_sysboot)
    last_response = params['dut'].power_cycle(params)
    check_boot_media(params, 'eth', last_response)
  end

  def LOAD_FROM_ETHERNET_BY_BMC(params)
    puts "########LOAD_FROM_ETHERNET_BY_BMC########"
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'eth')
  end

  def LOAD_FROM_NO_BOOT_DSP_BY_BMC(params)
    params['dut'].power_cycle(params)
    params['bootloader_class'].bmc_trigger_boot(params['dut'], 'dsp_no')
  end
  ####################################################################################
  ####################################################################################

  def check_boot_media(params, boot_media,  last_response='', timeout=5)
    params['dut'].connect({'type'=>'serial'})
    params['dut'].wait_for(/Trying\s+to\s+boot\s+from\s+[\w\s]+/i, timeout)
    if !params['dut'].timeout?
      raise "Failed to boot from #{boot_media}!" if !last_response.match(/Trying\s+to\s+boot\s+from.*?#{boot_media}/i) && (!params['dut'].response || !params['dut'].response.match(/#{boot_media}/i))
    end
  end
  
  def early_conn_power_cycle(params, media, stop_char=' ')
    b_thread = nil
    last_response = params['dut'].power_cycle(params) do
      params['dut'].connect({'type'=>'serial'})
      b_thread = Thread.new do
        200.times {
          params['dut'].target.serial.puts(stop_char)
          params['dut'].target.serial.flush
          s_time = Time.now()
          while Time.now() - s_time < 0.1
            #busy wait
          end
        }
      end
    end
    check_boot_media(params, media, last_response)
    b_thread.kill() if b_thread.alive?
  end
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
      if block_given?
        begin
          yield 
        rescue Exception => e2
          raise BootloaderException.new(e,e2)
        end
      else
        raise BootloaderException.new(e)
      end
  end

  def load_uart_spl(params)
    dut_load_prep(params)
    sleep 1
    params['server'].serial_load(
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['primary_bootloader'],
        'timeout' => 120
      },
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['secondary_bootloader'],
        'timeout' => 240,
        'load_cmd' => '/usr/bin/sb -kb --ymodem',
        'load_re' => /Bytes\s*Sent:\s*\d+\s/
      }
    )
    # Send an echo to be sure that we will break into autoboot.
    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
  end

  def load_uart_ti_min(params)
    dut_load_prep(params)
    sleep 1
    params['server'].serial_load(
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['primary_bootloader'],
        'timeout' => 120
      }
    )
    # Send an echo to be sure that we will break into autoboot.
    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
    # Start loady
    params['server'].send_cmd("echo \"loady #{params['dut'].boot_load_address}\" > #{params['dut'].serial_port}")
    params['server'].serial_load(
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['secondary_bootloader'],
        'timeout' => 240,
        'load_cmd' => '/usr/bin/sb -kb --ymodem',
        'load_re' => /Bytes\s*Sent:\s*\d+\s/
      }
    )
    # Start it.
    params['server'].send_cmd("echo \"go #{params['dut'].boot_load_address}\" > #{params['dut'].serial_port}")
    # Send an echo to be sure that we will break into autoboot.
    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
  end

  def load_uart_ti_boot3(params)
    dut_load_prep(params)
    sleep 1
    image_list = [
      { 
        'port' => params['dut'].params['bootloader_port'],
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['initial_bootloader'],
        'timeout' => 120
      }
    ]
    
    if params['sysfw'].to_s != ''
      image_list << { 
        'port' => params['dut'].params['bootloader_port'],
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['sysfw'],
        'timeout' => 240,
        'load_cmd' => '/usr/bin/sb -kb --ymodem'
      }
    end
      
    image_list << { 
      'port' => params['dut'].serial_port,
      'baudrate' => params['dut'].serial_params['baud'],
      'bin_path' => params['primary_bootloader'],
      'timeout' => 240,
      'load_cmd' => '/usr/bin/sb -kb --ymodem'
    }
      
    image_list << { 
      'port' => params['dut'].serial_port,
      'baudrate' => params['dut'].serial_params['baud'],
      'bin_path' => params['secondary_bootloader'],
      'timeout' => 240,
      'load_cmd' => '/usr/bin/sb -kb --ymodem',
      'load_re' => /Bytes\s*Sent:\s*\d+\s/
    }

    params['server'].serial_load(*image_list)
    # Send an echo to be sure that we will break into autoboot.
    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
  end

  def load_uart_uboot(params)
    dut_load_prep(params)
    sleep 1
    params['server'].serial_load(
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['secondary_bootloader'],
        'timeout' => 120,
        'load_re' => /Bytes\s*Sent:\s*\d+\s/
      }
    )
    # Send an echo to be sure that we will break into autoboot.
    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
  end

  def load_uart_ti_omap(params)
    dut_load_prep(params)
    sleep 1
    params['server'].send_cmd("/usr/bin/timeout 120 perl #{Dir.pwd}/target/utils/serial-boot.pl -p #{params['dut'].serial_port} -d0 -t40 -s #{params['primary_bootloader']} ", /.*/, 120)
    params['server'].serial_load(
      { 
        'port' => params['dut'].serial_port,
        'baudrate' => params['dut'].serial_params['baud'],
        'bin_path' => params['secondary_bootloader'],
        'timeout' => 240,
        'load_cmd' => '/usr/bin/sx -kb --ymodem',
        'load_re' => /Bytes\s*Sent:\s*\d+\s/
      }
    )

    params['server'].send_cmd("echo > #{params['dut'].serial_port}")
  end

  def dut_load_prep(params)
    dut = params['dut']
    # Kill anything which has the serial port open already.
    3.times { break if kill_tasks_holding_serial_port(params) }
    # Make sure that we're ready to catch the board coming out of reset
    sleep 1
    if dut.instance_variable_defined?(:@params) and dut.params.key? 'bmc_port' 
      bmc_set_boot(dut, 'uart')
      if dut.params.key? ('dut_soft_reboot') and dut.params['dut_soft_reboot'] == 1
        dut.power_cycle(params)
      else
        bmc_issue_boot(dut)
      end
    else
      # Ensure the board is reset.
      dut.power_cycle(params)
    end
  end

  def bmc_get_version(dut)
    prompt = dut.params.key?('bmc_prompt') ? dut.params['bmc_prompt'] : />/
    dut.target.bmc.send_cmd(CmdTranslator::get_bmc_cmd({'cmd'=>'version', 'version'=>'1.0', 'platform'=>dut.name}), /\[[\d\:]+\][^\d]+(\d\.[\d\.]+).+?#{prompt}/m, 3, false )
    @bmc_version = dut.target.bmc.response.to_s.match(/\[[\d\:]+\][^\d]+(\d\.[\d\.]+).+/m).captures[0]
    return @bmc_version
  end

  def bmc_set_boot(dut, device)
    case device.downcase
    when 'uart'
      cmd_key = "uart_bootmode"
    when 'dsp_no'
      cmd_key = "dsp_no_bootmode"
    when 'nand'
      cmd_key = "nand_bootmode"
    when 'spi'
      cmd_key = "spi_bootmode"
    when 'qspi'
      cmd_key = "qspi_bootmode"
    when 'eth'
      cmd_key = "eth_bootmode"
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
  end

  def bmc_issue_boot(dut)
    prompt = dut.params.key?('bmc_prompt') ? dut.params['bmc_prompt'] : />/
    dut.target.bmc.send_cmd(CmdTranslator::get_bmc_cmd({'cmd'=>'reboot', 'version'=>'1.0'}), prompt, 10, false )
  end

  def bmc_trigger_boot(dut, device)
    bmc_set_boot(dut, device)
    bmc_issue_boot(dut)
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
    300.times {
      dut.target.serial.puts(" ")
      dut.target.serial.flush
      s_time = Time.now()
      while Time.now() - s_time < 0.1
        #busy wait
      end
      break if !b_prompt_th.alive?
    }
    b_prompt_th.join()
    raise "Failed to load bootloader" if dut.target.bootloader.timeout?
  end

end

class DSPOnlyLoader < BaseLoader

  def initialize(load_method=nil)
    super(load_method)
  end

  def stop_at_boot_prompt(params)
  end

end

class SkipBootLoader < BaseLoader

  def initialize(load_method=nil)
    if load_method
      super(load_method)
    else
      super(method(:SKIP_BOOTLOADER))
    end
  end

  def stop_at_boot_prompt(params)
  end

end
