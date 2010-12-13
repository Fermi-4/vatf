require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/build_client'
module Equipment
  class LinuxEquipmentDriver < EquipmentDriver
 
		@@boot_info = {'dm355'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                   'dm365' => 'init=/init console=ttyS0,115200n8 noinitd ip=dhcp rw root=/dev/nfs nfsroot=${nfs_root_path},nolock mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4'}
    
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
      #samba_path = params['samba_path'] 
			#nfs_path   = params['nfs_path']
			nfs_root	=params['nfs_root']
      #boot_args = SiteInfo::Bootargs[params['platform'].downcase.strip]
      @boot_args = params['bootargs'] if params['bootargs']
			tmp_path = File.join(params['tester'].downcase.strip,params['target'].downcase.strip,params['platform'].downcase.strip)
      #tmp_path = "#{params['tester'].downcase.strip}/#{params['target'].downcase.strip}/#{params['platform'].downcase.strip}"
		
      if image_path != nil && File.exists?(image_path) && get_image(image_path, params['server'], tmp_path) then
        boot_to_bootloader()
        #set bootloader env vars and tftp the image to the unit -- Note: add more commands here if you need to change the environment further
        send_cmd("setenv serverip #{tftp_ip}",@boot_prompt, 10)
        send_cmd("setenv bootcmd 'dhcp;bootm'",@boot_prompt, 10)
        send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 10)
        raise 'Unable to set bootfile' if timeout?
        send_cmd("setenv nfs_root_path #{nfs_root}",@boot_prompt, 10)
        raise 'Unable to set nfs root path' if timeout?
        send_cmd("setenv bootargs #{@boot_args}",@boot_prompt, 10)
        raise 'Unable to set bootargs' if timeout?
        send_cmd("saveenv",@boot_prompt, 10)
        raise 'Unable save environment' if timeout?
        send_cmd("printenv", @boot_prompt, 20)
        send_cmd('boot', /login/, 120)
        raise 'Unable to boot platform or platform took more than 2 minutes to boot' if timeout?
        # command prompt context commands
        send_cmd(@login, @prompt, 10) # login to the unit
        raise 'Unable to login' if timeout?
      else
        raise "image #{image_path} does not exist, unable to copy"
      end
    end

    # stop the bootloader after a reboot
    def stop_boot()
      0.upto 3 do
        send_cmd("\e", @boot_prompt, 1)
      end
    end
    
    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader()
      puts 'rebooting DUT'
			if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
        send_cmd("\e", /(U-Boot)|(#{@boot_prompt})/, 3)
      else
        send_cmd('reboot', /U-Boot/, 40)
      end
      # stop the autobooter from autobooting the box
      0.upto 5 do
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
    def get_image(src_folder, server, tmp_path)
      dst_path = File.join(server.tftp_path, tmp_path)
      if src_folder != dst_path
        raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
        server.send_sudo_cmd("mkdir -p -m 777 #{dst_path}") if !File.exists?(dst_path)
        if File.file?(src_folder)
          FileUtils.cp(src_folder, dst_path)
        else 
          FileUtils.cp_r(File.join(src_folder,'.'), dst_path)
        end
      end
      true 
    end
  
    # Copy the image files and module.ko files from the build directory into the ftp directory
    def get_image2(src_win, dst_folder_win, server, dst_linux, nfs_path)
      # Copy images and modules (.ko) tftp server
      @build_files = Array.new
      src_folder = File.dirname(src_win)
      BuildClient.dir_search(src_folder, @build_files)
      dst_linux = "/#{dst_linux}" if !(/^\//.match(dst_linux))
      @build_files.each {|f|
        dst_path   = dst_folder_win+"\\#{File.basename(f)}"    # This is the Windows'samba path
        if f.gsub(/\\/,'/') == src_win.gsub(/\\/,'/') 
          #puts "copy from: #{f}"
          #puts "copy to: #{dst_path}"
          BuildClient.copy(f, dst_path)
          server.send_sudo_cmd("chmod -R 0777 #{nfs_path}/../../../..",server.prompt, 10)
          raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
          server.send_cmd("mkdir -p -m 777 #{server.tftp_path}#{dst_linux}",server.prompt, 10)
          server.send_cmd("mv -f #{nfs_path}/#{File.basename(f)} #{server.tftp_path}#{dst_linux}", server.prompt, 10)
        elsif File.extname(f) == '.ko'
          BuildClient.copy(f, dst_path) 
        end
      }
      true 
    end
    
    def send_sudo_cmd(cmd, expected_match=/.*/, timeout=30)
      send_cmd("sudo #{cmd}", /(Password)|(#{expected_match})/im, timeout) 		
      if response.include?('assword')
        send_cmd(@telnet_passwd,expected_match,timeout, false)
        raise 'Unable to send command as sudo' if timeout?
      end
    end

      
  end
  
end
