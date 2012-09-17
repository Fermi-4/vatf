require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  class LinuxEquipmentDriver < EquipmentDriver
    attr_accessor :boot_loader, :system_loader

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
     'am389x-evm' => 'console=ttyO2,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'beagleboard' => 'console=ttyO2,115200n8 ip=dhcp ',
     'am335x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=128M earlyprink ',
     'am335x-sk' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     'beaglebone' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     })
    
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args = @@boot_info[@name]
      @boot_loader = nil
      @system_loader = nil
    end
    
    def set_api(dummy_var)
      end
      
    # Select BootLoader's load_method based on params
    def set_bootloader(params)
      @boot_loader = case params['boot_dev']
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
      @system_loader = SystemLoader::UbootSystemLoader.new
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
      0.upto 3 do
        send_cmd("\e", @boot_prompt, 1)
      end
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

    def power_cycle
      if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
      else
        puts "Soft reboot..."
        send_cmd('', @prompt, 3)
        if timeout?
          # assume at u-boot prompt
          send_cmd('reset', /resetting/i, 3)
        else
          # at linux prompt
          send_cmd('reboot', /(Restarting|Rebooting|going\s+down)/i, 40)
        end
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
    
    def setup_bootfile(bootfile,params)
      tmp_path = File.join(params['target'].downcase.strip,params['platform'].downcase.strip)
      get_image(bootfile, params['server'], tmp_path)
      send_cmd("setenv bootfile #{tmp_path}/#{File.basename(bootfile)}",@boot_prompt, 10) 
      send_cmd("setenv serverip #{params['server'].telnet_ip}",@boot_prompt, 10) 
      send_cmd("saveenv",@boot_prompt, 10) 
      raise 'Unable save environment' if timeout?
      send_cmd("printenv", @boot_prompt, 20)
    end
    
    def load_bootloader_from_nand(params)
      params['nand_loader'].call params
    end
    
    # This function assumes there is an existing U-Boot (secondary bootloader) on the board, writes the new U-Boot image to a specified NAND location and reboots the board.
    def write_bootloader_to_nand_min(params)
      # get to existing U-Boot 
      connect({'type'=>'serial'}) if !@target.serial
      send_cmd("",@boot_prompt, 5)
      raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if timeout?
      
      # set U-Boot params to download file
      setup_bootfile(params['secondary_bootloader'],params)

      # write new U-Boot to NAND
      send_cmd("mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      send_cmd("dhcp", @boot_prompt, 60)
      send_cmd("nand erase clean #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 40)
      send_cmd("nand write #{params['mem_addr'].to_s(16)} #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 60)
      
      # Next, run any EVM-specific commands, if needed
      if defined? params['exra_cmds']
        params['extra_cmds'].each {|cmd|
          send_cmd("#{cmd}",@boot_prompt, 60)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if timeout?
        }
      end
      send_cmd("reset", @boot_prompt, 60)
    end
    
    def write_bootloader_to_nand_via_mtdparts(params)
      # get to existing U-Boot 
      connect({'type'=>'serial'}) if !@target.serial
      send_cmd("",@boot_prompt, 5)
      raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if timeout?
      
      #set mtd partition names
      send_cmd("setenv mtdparts mtdparts=#{params['mtdparts']}",@boot_prompt, 10) 
      
      # set U-Boot params to download file
      setup_bootfile(params['secondary_bootloader'],params)

      # write new U-Boot to NAND
      send_cmd("mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      send_cmd("dhcp", @boot_prompt, 60)
      send_cmd("nand erase.part bootloader", @boot_prompt, 60)
      send_cmd("nand write #{params['mem_addr'].to_s(16)} bootloader #{params['size'].to_s(16)}", @boot_prompt, 60)
      
      # Next, run any EVM-specific commands, if needed
      if defined? params['exra_cmds']
        params['extra_cmds'].each {|cmd|
          send_cmd("#{cmd}",@boot_prompt, 60)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if timeout?
        }
      end
      send_cmd("reset", @boot_prompt, 60)
    end
    
    def get_write_mem_size(filename,nand_eraseblock_size)
      filesize = File.size(File.new(filename))
      nand_eraseblock_size_in_dec = (nand_eraseblock_size.to_s(10).to_f)
      blocks_to_write = (filesize.to_f/nand_eraseblock_size_in_dec.to_f).ceil
      return (blocks_to_write*nand_eraseblock_size)
    end
    
      
  end
  
end
