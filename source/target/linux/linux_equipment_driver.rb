require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/build_client'
module Equipment
  class LinuxEquipmentDriver < EquipmentDriver
 
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
     'da850-omapl138-evm'  => 'console=ttyS2,115200n8 noinitrd ip=dhcp mem=32M ',
     'am3517-evm'  => 'console=ttyO2,115200n8 noinitrd ip=dhcp ',
     'dm814x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'dm816x-evm' => 'console=ttyO2,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'am387x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'am389x-evm' => 'console=ttyO2,115200n8 ip=dhcp  mem=166M earlyprink vram=50M ',
     'beagleboard' => 'console=ttyO2,115200n8 ip=dhcp ',
     'am335x-evm' => 'console=ttyO0,115200n8 ip=dhcp  mem=128M earlyprink ',
     'beaglebone' => 'console=ttyO0,115200n8 ip=dhcp earlyprink ',
     })
    
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args = @@boot_info[@name]
    end
    
    # Copy an image from the build server to the tftp server
    # Reboot the @and load the image into it in the bootloader
    # Boots into the new image, leaving the user at the command prompt 
    # Required Params: 
    # 'image_path' must be defined in the params hash, this is the path to your build directory
    # 'tftp_path' must be defined in the params hash, this is the base path to your tftp server (where the files will be copied)
    # 'tftp_ip' must be defined in the params hash if you have any modules, this is the ip of your tftp server (where the files will be copied & the modules will be copied from)
    def boot (params)
		  @power_handler = params['power_handler'] if !@power_handler
      image_path = params['image_path']
      puts "\n\n====== uImage is at #{image_path} =========="
      tftp_path  = params['server'].tftp_path
      tftp_ip    = params['server'].telnet_ip
      nfs_root	=params['nfs_root']
      @boot_args = params['bootargs'] if params['bootargs']
			tmp_path = File.join(params['tester'].downcase.strip,params['target'].downcase.strip,params['platform'].downcase.strip)
      
      if image_path == 'mmc' || ( image_path != nil && File.exists?(image_path) && get_image(image_path, params['server'], tmp_path) ) then
        boot_to_bootloader(params)
        connect({'type'=>'serial'}) if !@target.serial
        send_cmd("",@boot_prompt, 5)
        raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if timeout?
        send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 10) if image_path != 'mmc'
        send_cmd("setenv nfs_root_path #{nfs_root}",@boot_prompt, 10)
        raise 'Unable to set nfs root path' if timeout?
        #set bootloader env vars -- Note: add more commands here if you need to change the environment further
        get_boot_cmd(params).each {|cmd|
          send_cmd("#{cmd}",@boot_prompt, 10)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if timeout?
        }
        send_cmd("saveenv",@boot_prompt, 10) if !@name.match(/beagleboard/)
        raise 'Unable save environment' if timeout?
        send_cmd("printenv", @boot_prompt, 20)
        send_cmd("usb start", @boot_prompt, 30) if @name.match(/beagleboard/)
        send_cmd('boot', /#{@login_prompt}/, 600)
        raise 'Unable to boot platform or platform took more than 10 minutes to boot' if timeout?
        # command prompt context commands
        send_cmd(@login, @prompt, 10) # login to the unit
        raise 'Unable to login' if timeout?
      
      else
        raise "image #{image_path} does not exist, unable to copy"
      
      end
    end
    
    def get_boot_cmd(params)
      image_path = params['image_path']
      cmds = []
      if image_path == 'mmc' then
        cmds << "setenv mmc_load_uimage 'mmc rescan; fatload mmc 0 ${loadaddr} uImage'"
        cmds << "setenv bootcmd 'run mmc_load_uimage; bootm ${loadaddr}'"
        bootargs = params['bootargs'] ? "setenv bootargs #{@boot_args}" : "setenv bootargs #{@boot_args} root=/dev/mmcblk0p2 rw rootfstype=ext3 rootwait" 
        cmds << bootargs
      
      else
        cmds << "setenv bootcmd 'dhcp;bootm'"
        cmds << "setenv serverip '#{params['server'].telnet_ip}'"
        bootargs = params['bootargs'] ? "setenv bootargs #{@boot_args}" : "setenv bootargs #{@boot_args} root=/dev/nfs nfsroot=${nfs_root_path},nolock"
        cmds << bootargs
      end
      cmds
    end

    # stop the bootloader after a reboot
    def stop_boot()
      0.upto 3 do
        send_cmd("\e", @boot_prompt, 1)
      end
    end
    
    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      connect({'type'=>'serial'}) if !@target.serial
      # Make the code backward compatible. Previous API used optional power_handler object as first parameter 
      @power_handler = params if ((!params.instance_of? Hash) and params.respond_to?(:reset) and params.respond_to?(:switch_on))
      @power_handler = params['power_handler'] if !@power_handler
      
      puts 'rebooting DUT'
			if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
        send_cmd("\e", /(U-Boot)|(#{@boot_prompt})/, 3)
      else
        send_cmd('', /#{@login_prompt}/, 2)
        send_cmd(@login, @prompt, 10) if !timeout?   # login to the unit
        send_cmd('reboot', /U-Boot/, 40)
      end
      # stop the autobooter from autobooting the box
      0.upto 10 do
        send_cmd("\n", @boot_prompt, 1)
        puts 'Sending esc character'
        sleep 1
        break if !timeout?
      end
      # now in the uboot prompt
    end
    
    # Boot to the login prompt (will NOT login for you)
    def boot_to_image()
		  if @power_port !=nil
        puts 'Resetting @using power switch'
       @power_handler.reset(@power_port)
      else
        send_cmd('reboot', /Hit any key to stop autoboot:/, 30)
      end
    end
  
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
        send_cmd('', @prompt, 1)
        if timeout?
          # assume at u-boot prompt
          send_cmd('reset', /resetting/i, 3)
        else
          # at linux prompt
          send_cmd('reboot', /(Restarting|Rebooting|going\s+down)/i, 40)
        end
      end
    end
    
    def create_minicom_uart_script_spl(params)
      File.open(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],params['minicom_script_name']), "w") do |file|
        sleep 1  
        file.puts "timeout 180"
        file.puts "verbose on"
        file.puts "! /usr/bin/sx -v -k --xmodem #{params['primary_bootloader']}"
        file.puts "expect {"
        file.puts "    \"CCCCC\""
        file.puts "}"
        file.puts "! /usr/bin/sb -v  --ymodem #{params['secondary_bootloader']}"
        file.puts "expect {"
        file.puts "    \"stop autoboot\""
        file.puts "}"
        file.puts "send \"\""
        file.puts "expect {"
        file.puts "    \"#{@boot_prompt.source}\""
        file.puts "}"
        file.puts "print \"\\nDone loading u-boot\\n\""
        file.puts "! killall -s SIGHUP minicom"
      end
    end
    
    def load_bootloader_from_uart(params)
      server = params['server']
      power_cycle()
      params['minicom_script_name'] = 'uart-boot.minicom'
      puts "\nCreating minicom script\n" # Debug info
      params['minicom_script_generator'].call params
      puts "\nStarting minicom script\n" # Debug info
      server.send_cmd("cd #{File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'])}; minicom -D #{@serial_port} -b 115200 -S #{params['minicom_script_name']}", server.prompt, 90)
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
        file.puts "send \"loady #{@boot_load_address}\""
        file.puts "! /usr/bin/sb -v  --ymodem #{params['secondary_bootloader']}"
        file.puts "expect {"
        file.puts "    \"#{@first_boot_prompt.source}\""
        file.puts "}"
        file.puts "send \"go #{@boot_load_address}\""
        file.puts "expect {"
        file.puts "    \"stop autoboot\""
        file.puts "}"
        file.puts "send \"\""
        file.puts "expect {"
        file.puts "    \"#{@boot_prompt.source}\""
        file.puts "}"
        file.puts "print \"\\nDone loading u-boot\\n\""
        file.puts "! killall -s SIGHUP minicom"
      end
    end
      
  end
  
end
