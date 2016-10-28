require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  class LinuxEquipmentDriver < EquipmentDriver
    attr_accessor :boot_loader, :system_loader, :boot_args, :boot_log

    include CmdTranslator
    include BootLoader
    include SystemLoader

    @uboot_version = nil
    @linux_version = nil
 
    @@boot_info = Hash.new('console=ttyO0,115200n8 ').merge(
    {
     'dm355'  => 'console=ttyO0,115200n8  mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
     'dm355-evm'  => 'console=ttyO0,115200n8  mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
     'dm365'  => 'console=ttyO0,115200n8  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'dm365-evm'  => 'console=ttyO0,115200n8  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'dm368-evm'  => 'console=ttyO0,115200n8  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'am3730' => 'console=ttyO0,115200n8 ',
     'am37x-evm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 ',
     'dm3730' => 'console=ttyO0,115200n8 ',
     'dm373x-evm' => 'console=ttyO0,115200n8 ',
     'am1808'  => 'console=ttyO2,115200n8  ',
     'am180x-evm'  => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 ',
     'am181x-evm'  => 'console=ttyO2,115200n8  ',
     'da850-omapl138-evm'  => 'console=ttyO2,115200n8  mem=32M ',
     'am3517-evm'  => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 ',
     'dm814x-evm' => 'console=ttyO0,115200n8 mem=166M earlyprintk=serial,ttyO0,115200n8 vram=50M ',
     'dm816x-evm' => 'console=ttyO2,115200n8 mem=166M earlyprintki=ttyO2,115200n8 vram=50M ',
     'am387x-evm' => 'console=ttyO0,115200n8 mem=166M earlyprintk=serial,ttyO0,115200n8 vram=50M ',
     'dm385-evm' => 'console=ttyO0,115200n8  mem=166M earlyprintk=serial,ttyO0,115200n8 vram=50M',
     'ti813x-evm' => 'console=ttyO0,115200n8 mem=166M earlyprintk=serial,ttyO0,115200n8 vram=50M',
     'am389x-evm' => 'console=ttyO2,115200n8 mem=166M earlyprintk=serial,ttyO2,115200n8 vram=50M ',
     'beagleboard' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'beagleboard-vanilla' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'am57xx-evm' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'am572x-idk' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'am571x-idk' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'am335x-evm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait ',
     'am335x-ice' => 'console=ttyO3,115200n8 earlyprintk=serial,ttyO3,115200n8 rootwait ',
     'am335x-sk' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'beaglebone' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'beaglebone-black' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'omap5-evm' => 'console=ttyO2,115200n8 earlyprintk=serial,ttyO2,115200n8 rootwait',
     'dra7xx-evm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'dra71x-evm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'dra72x-evm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'am43xx-gpevm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'am437x-sk' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'am43xx-epos' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'am437x-idk' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'craneboard' => 'console=ttyO2,115200n8 earlyprintk=serial,ttyO2,115200n8 rootwait nohlt',
     'pandaboard-es' => 'console=ttyO2,115200n8 vram=16M earlyprintk=serial,ttyO2,115200n8 rootwait',
     'pandaboard-vanilla' => 'console=ttyO2,115200n8 vram=16M earlyprintk=serial,ttyO2,115200n8 rootwait',
     'sdp4430' => 'console=ttyO2,115200n8 vram=16M earlyprintk=serial,ttyO2,115200n8 rootwait',
     'sdp2430' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'sdp3430' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'n900' => 'console=ttyO2,57600n8 vram=16M earlyprintk=serial,ttyO2,115200n8 rootwait',
     'ldp3430' => 'console=ttyO2,115200n8 earlyprintk=serial,ttyO2,115200n8 rootwait',
     'k2hk-evm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'k2l-evm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'k2e-evm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'k2g-evm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'dra7xx-hsevm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'dra72x-hsevm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'am43xx-hsevm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     'am57xx-hsevm' => 'console=ttyO2,115200n8  earlyprintk=serial,ttyO2,115200n8 rootwait',
     'am335x-hsevm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'dra71x-hsevm' => 'console=ttyO0,115200n8 earlyprintk=serial,ttyO0,115200n8 rootwait',
     'k2e-hsevm' => 'console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200n8 rootwait',
     })
    
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      if @boot_prompt
        @boot_prompt = /#{@boot_prompt}|=>/
      else
        @boot_prompt = /=>/
      end
      @boot_args = @@boot_info[@name]
      @boot_loader = nil
      @system_loader = nil
      @updator = nil
    end
    
    def set_api(dummy_var)
      end
      
    # Select BootLoader's load_method based on params
    def set_bootloader(params)        
      SysBootModule::reset_sysboot(params['dut']) 
      @boot_loader = case params['primary_bootloader_dev']
      when /uart/i
        BaseLoader.new method( get_uart_boot_method(@name) )
      when /ethernet/i
        BaseLoader.new method(:LOAD_FROM_ETHERNET)
      when /usbeth/i
        BaseLoader.new method(:LOAD_FROM_USBETH)
      when /usbmsc/i
        BaseLoader.new method(:LOAD_FROM_USBMSC)
      when /emmc/i #'rawmmc-emmc' or 'emmc'
        BaseLoader.new method(:LOAD_FROM_EMMC)
      when /nand/i
        BaseLoader.new method( get_nand_boot_method(@name) )
      when /qspi/i
        BaseLoader.new method( get_qspi_boot_method(@name) )
      when /^spi/i
        BaseLoader.new method( get_spi_boot_method(@name) )
      when /no-boot/i
        puts "*** Note: DUT boot mode will be changed via BMC commands. ***"
        DSPOnlyLoader.new method( get_no_boot_method(@name) )
      else
        BaseLoader.new 
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      if params['boot_cmds'].to_s != ''
        @system_loader = SystemLoader::UbootUserSystemLoader.new
        return
      elsif params['systemloader_class']
        @system_loader = params['systemloader_class'].new
      elsif params['var_use_default_env'].to_s == '1'
        @system_loader = SystemLoader::UbootDefaultEnvSystemLoader.new
      elsif params['var_use_default_env'].to_s == '2'
        @system_loader = SystemLoader::UbootLetItGoSystemLoader.new
      elsif params['fit_dev'] != 'none'
        @system_loader = SystemLoader::UbootFitSystemLoader.new
      elsif params['secondary_bootloader_dev'].to_s == 'no-boot'
        @system_loader = SystemLoader::BaseSystemLoader.new
      else
        @system_loader = SystemLoader::UbootSystemLoader.new
        if params['fs_dev'].downcase == 'nand' 
          @system_loader.insert_step_before('pmmc', FlashFSStep.new)
        end
        if params['skip_touchcal'].to_s == '1'
          @system_loader.remove_step('touch_cal')
        end
        if params['var_use_default_env'].to_s == '3'
          @system_loader.insert_step_before('prep', SetDefaultEnvStep.new) 
        end
      end

      if params.has_key?("bootargs_append")
        @system_loader.insert_step_before('boot', SetExtraArgsStep.new) 
      end

      if params.has_key?("autologin")
        @system_loader.replace_step('boot', BootAutologinStep.new)
      end

      if params['dut'].name.match(/k2.+\-hs/)
        @system_loader.insert_step_before('setip', InstallK2SecBMStep.new)
      end

    end

    # Update primary and secondary bootloader 
    def update_bootloader(params)
      # Since we don't know if the primary_bootloader_dev boot works, do not call set_bootloader.
      # Instead, just power cycle the board. Here, we assume the board can boot from default media.
      # After the board boot to uboot, then we can update primary_bootloader_dev
      SysBootModule::reset_sysboot(params['dut'])
      @boot_loader = BaseLoader.new 
      set_systemloader(params.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderSystemLoader})) if !@system_loader
      @boot_loader.run params
      if params['dut'].name.match(/k2.+\-hs/)
        @system_loader.insert_step_before('setip', InstallK2SecBMStep.new)
      end
      @system_loader.run params
    end

    # Update both kernel and dtb
    def update_kernel(params)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params.merge({'systemloader_class' => SystemLoader::UbootFlashKernelSystemLoader})) if !@system_loader
      @boot_loader.run params
      @system_loader.run params
    end

    def update_fs(params)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params.merge({'systemloader_class' => SystemLoader::UbootFlashFSSystemLoader})) if !@system_loader
      @boot_loader.run params
      @system_loader.run params
    end
    
    def update_all(params)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params.merge({'systemloader_class' => SystemLoader::UbootFlashAllSystemLoader})) if !@system_loader
      @boot_loader.run params
      @system_loader.run params
    end

    # Take the DUT from power on to system prompt
    def boot (params)
      @power_handler = params['power_handler'] if !@power_handler
      params['bootargs'] = @boot_args if !params['bootargs']
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @boot_loader.run params
      @system_loader.run params
    end
    
    def set_boot_env (params)
      @power_handler = params['power_handler'] if !@power_handler
      params['bootargs'] = @boot_args if !params['bootargs']
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @system_loader.remove_step('boot')
      @boot_loader.run params
      @system_loader.run params
    end

    def get_linux_version()
      return @linux_version if @linux_version
      raise "Unable to get linux version since Dut is not at linux prompt!" if !at_prompt?({'prompt'=>@prompt})
      send_cmd("cat /proc/version", @prompt, 10)
      version = /Linux\s+version\s+([\d\.]+)\s*/.match(response).captures[0]
      raise "Could not find linux version" if version == nil
      puts "\nlinux version = #{version}\n\n"
      @linux_version = version
      return version
    end

    def at_prompt?(params)
      prompt = params['prompt']
      wait_time = params['wait'] ? params['wait'] : 2
      3.times {
        send_cmd("#check prompt", prompt, wait_time)
        break if !timeout?
      }
      !timeout?
    end

    def at_login_prompt?()
      send_cmd("#check prompt", /(#{@login_prompt}|[Pp]assword)/, 3)
      return false if timeout?
      send_cmd(" ", /#{@login_prompt}/, 5) if response.match(/[Pp]assword/)
      return true
    end

    # stop the bootloader after a reboot
    def stop_boot(seconds=30)
      0.upto seconds do
        send_cmd(" ", @boot_prompt, 1)
        break if !timeout?
      end
      raise "Failed to load bootloader" if timeout?
    end
    
    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      set_bootloader(params) if !@boot_loader
      @boot_loader.run params
    end
  
    def send_sudo_cmd(cmd, expected_match=/.*/, timeout=30)
      send_cmd("sudo #{cmd}", /(Password)|(#{expected_match})/im, timeout) 		
      if response.include?('assword')
        send_cmd(@telnet_passwd,expected_match,timeout, false)
        raise 'Unable to send command as sudo' if timeout?
      end
    end

    # Send Break (Ctrl+a,f), then sysrq key to trigger sysrq
    # Ref: https://www.kernel.org/doc/Documentation/sysrq.txt 
    # Often used command keys:
    # 't' - Will dump a list of current tasks and their information to your console.
    # 'l' - Shows a stack backtrace for all active CPUs.
    # 'w' - Dumps tasks that are in uninterruptable (blocked) state.
    # 'd' - Shows all locks that are held.
    def send_sysrq(key='h', read_time=10)
      thr = Thread.new { @target.read_on_for(@target.serial, read_time) }
      @target.serial.break(1)
      @target.serial.puts(key)
      thr.join()
      log_info(@target.serial.response)
      @target.serial.response
      rescue Exception => e
        log_info("Problem occurred while executing sysrq\n" + e.to_s)
    end

    # Send abort (Control-C)
    def send_abort(read_time=10)
      thr = Thread.new { @target.read_on_for(@target.serial, read_time) }
      @target.serial.write("\C-c\n")
      thr.join()
      log_info(@target.serial.response)
      @target.serial.response
      rescue Exception => e
        log_info("Problem occurred while sending Control-#{key}\n" + e.to_s)
    end

    def power_cycle(params)
      @power_handler = params['power_handler'] if !@power_handler
      connected = true
      begin
        connect({'type'=>'serial'}) if !target.serial
        send_cmd(@login,@prompt, 3) if at_login_prompt?
      rescue Exception => e
        raise e if !@power_port
        log_info("Problems while trying to connect to the board...\n" \
                 "#{e.to_s}\nWill try to connect again after power cycle...")
        connected = false
      end
      if @power_port !=nil
        puts 'Resetting @using power switch'
        poweroff(params) if connected && at_prompt?({'prompt'=>@prompt})
        disconnect('serial')
        @power_handler.reset(@power_port)
        trials = 0
        while (@serial_port && !File.exist?(@serial_port) && trials < 600)
          sleep 0.1
          trials += 1
        end
        raise "Unable to detect serial node for the dut" if trials >= 600
      else
        puts "Soft reboot..."
        send_cmd('#check prompt', @prompt, 3)
        if timeout?
          # assume at u-boot prompt
          send_cmd('reset', /resetting/i, 3)
        else
          # at linux prompt
          send_cmd('reboot', /(Restarting|Rebooting|going\s+down)/i, 40)
        end
        disconnect('serial')
      end
    end

    # Gracefully bring down the system to avoid FS corruption
    def poweroff(params=nil)
      send_cmd("sync;poweroff",/System halted|System will go to power_off|Power down|reboot: Power/i,120)
    end

    def shutdown(params)
      @power_handler = params['power_handler'] if !@power_handler
      connected = true
      begin
        connect({'type'=>'serial'}) if !target.serial
        send_cmd(@login,@prompt, 3) if at_login_prompt?
      rescue Exception => e
        raise e if !@power_port
        log_info("Problems while trying to connect to the board...\n" \
                 "#{e.to_s}\nWill try to connect again after power cycle...")
        connected = false
      end
      if @power_port !=nil
        puts 'Shuting down using power switch'
        poweroff(params) if connected && at_prompt?({'prompt'=>@prompt})
        disconnect('serial')
        @power_handler.switch_off(@power_port)
      end
    end

    def check_for_boot_errors(params=nil)
      errors = {
        'CPU failed to come online' => /\[[\s\d\.]+\]\s+.*CPU\d+:\s+failed to come online/i,
        'Kernel Oops' => /Internal error: Oops/i,
        'NFS Failure' => /Unable to mount root fs via NFS/i,
      }
      errors.each {|n,r|
        raise n if boot_log.match(r)
      }
    end
    
    ###############################################################################################
    ### keeping the methods defined below here for now. These are mainly used by LSP/u-boot scripts
    ###############################################################################################

    # Copy the image files and module.ko files from the build directory into the ftp directory
    def get_image(src_file, server, tmp_path)
      dst_path = File.join(server.tftp_path, tmp_path)
      if src_file != dst_path
        raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
        server.send_sudo_cmd("mkdir -p -m 777 #{dst_path}") if !File.exists?(dst_path)
        if File.file?(src_file)
          FileUtils.cp(src_file, dst_path)
        else 
          FileUtils.cp_r(File.join(src_file,'.'), dst_path)
        end
      end
      true 
    end
    
    
    ###############################################################################################
    ### keeping the methods defined below here for now. These are mainly used by linux_tci6614 driver.
    ###############################################################################################
    
    def get_write_mem_size(filename,nand_eraseblock_size)
      filesize = File.size(File.new(filename))
      nand_eraseblock_size_in_dec = (nand_eraseblock_size.to_s(10).to_f)
      blocks_to_write = (filesize.to_f/nand_eraseblock_size_in_dec.to_f).ceil
      return (blocks_to_write*nand_eraseblock_size)
    end
    
    def reset_sysboot(dut)
      SysBootModule::reset_sysboot(dut) 
    end 
  end
  
  
end
