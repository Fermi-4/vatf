require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  class LinuxEquipmentDriver < EquipmentDriver
    attr_accessor :boot_loader, :system_loader, :boot_args

    include CmdTranslator
    include BootLoader
    include SystemLoader

    @uboot_version = nil
    @linux_version = nil
 
    @@boot_info = Hash.new('console=ttyS0,115200n8 ip=dhcp ').merge(
    {
     'dm355'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp  mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
     'dm355-evm'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp  mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
     'dm365'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'dm365-evm'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'dm368-evm'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp  mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
     'am3730' => 'console=ttyO0,115200n8 ip=dhcp ',
     'am37x-evm' => 'console=ttyO0,115200n8 ip=dhcp ',
     'dm3730' => 'console=ttyO0,115200n8 ip=dhcp ',
     'dm373x-evm' => 'console=ttyO0,115200n8 ip=dhcp ',
     'am1808'  => 'console=ttyS2,115200n8 noinitrd ip=dhcp ',
     'am180x-evm'  => 'console=ttyS2,115200n8 noinitrd ip=dhcp ',
     'am181x-evm'  => 'console=ttyS2,115200n8 noinitrd ip=dhcp ',
     'da850-omapl138-evm'  => 'console=ttyS2,115200n8 noinitrd ip=dhcp mem=32M ',
     'am3517-evm'  => 'console=ttyO2,115200n8 noinitrd ip=dhcp ',
     'dm814x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'dm816x-evm' => 'console=ttyO2,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'am387x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'dm385-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M',
     'ti813x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M',
     'am389x-evm' => 'console=ttyO2,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'beagleboard' => 'console=ttyO2,115200n8 ip=dhcp ',
     'am335x-evm' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     'am335x-sk' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     'beaglebone' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     'omap5-evm' => 'console=ttyO2,115200n8 ip=dhcp ',
     'tci6638-evm' => 'console=ttyS0,115200n8 rootwait=1 earlyprintk', 
     })
    
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args = @@boot_info[@name]
      @boot_loader = nil
      @system_loader = nil
      @updator = nil
    end
    
    def set_api(dummy_var)
      end
      
    # Select BootLoader's load_method based on params
    def set_bootloader(params)
      @boot_loader = case params['primary_bootloader_dev']
      when /uart/i
        BaseLoader.new method(:LOAD_FROM_SERIAL)
      when /eth/i
        BaseLoader.new method(:LOAD_FROM_ETHERNET)
      else
        BaseLoader.new 
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      if params.has_key?("var_use_default_env")
        @system_loader = SystemLoader::UbootDefaultEnvSystemLoader.new
      else
        @system_loader = SystemLoader::UbootSystemLoader.new
      end

      if params.has_key?("bootargs_append")
        @system_loader.insert_step_before('boot', SetExtraArgsStep.new) 
      end
    end

    # Update primary and secondary bootloader 
    def update_bootloader(params)
      set_bootloader(params) if !@boot_loader
      @updator = SystemLoader::UbootFlashBootloaderSystemLoader.new
      @boot_loader.run params
      @updator.run params
    end

    def update_kernel(params)
      set_bootloader(params) if !@boot_loader
      @updator = SystemLoader::UbootFlashKernelSystemLoader.new
      @boot_loader.run params
      @updator.run params
    end

    def update_fs(params)
      set_bootloader(params) if !@boot_loader
      @updator = SystemLoader::UbootFlashFSSystemLoader.new
      @boot_loader.run params
      @updator.run params
    end
    
    def update_all(params)
      set_bootloader(params) if !@boot_loader
      @system_loader = SystemLoader::UbootFlashAllSystemLoader.new
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
      return version
    end

    def at_prompt?(params)
      prompt = params['prompt']
      send_cmd("", prompt, 5)
      !timeout?
    end

    # stop the bootloader after a reboot
    def stop_boot()
      0.upto 30 do
        send_cmd("", @boot_prompt, 1)
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

    def power_cycle(params)
      @power_handler = params['power_handler'] if !@power_handler
      if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
      else
        puts "Soft reboot..."
        connect({'type'=>'serial'}) if !target.serial
        send_cmd(@login,@prompt, 3)
        send_cmd('', @prompt, 3)
        if timeout?
          # assume at u-boot prompt
          send_cmd('reset', /resetting/i, 3)
        else
          # at linux prompt
          send_cmd('reboot', /(Restarting|Rebooting|going\s+down)/i, 40)
        end
        disconnect({'type'=>'serial'})
      end
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
    
      
  end
  
end
