require File.dirname(__FILE__)+'/../equipment_driver'

module Equipment

  class AndroidEquipmentDriver < EquipmentDriver
    
    @@boot_info = {'am3517-evm' => 'console=ttyO2,115200n8 androidboot.console=ttyO2 mem=256M rootfstype=ext3 rootdelay=1 init=/init ip=dhcp rw root=/dev/nfs nfsroot=${nfs_root_path},nolock mpurate=600 omap_vout.vid1_static_vrfb_alloc=y vram="8M" omapfb.vram=0:8M',
                   'am37x-evm' => 'console=ttyO0,115200n8 androidboot.console=ttyO0 mem=256M rootfstype=ext3 rootdelay=1 init=/init ip=dhcp rw root=/dev/nfs nfsroot=${nfs_root_path},nolock mpurate=1000 omap_vout.vid1_static_vrfb_alloc=y vram="8M" omapfb.vram=0:8M'}    

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
      tftp_path = params['server'].tftp_path
      tftp_ip = params['server'].telnet_ip
      nfs_root = params['nfs_root']
      @boot_args = params['bootargs'] if params['bootargs']
      tmp_path = File.join(params['tester'].downcase.strip,params['target'].downcase.strip,params['platform'].downcase.strip)
      if image_path != nil && File.exists?(image_path) && get_image(image_path, params['server'],tmp_path) then
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
        send_cmd('boot', "enabling adb", 120)
        raise 'Unable to boot platform or platform took more than 2 minutes to boot' if timeout?
        sleep(4)
        send_host_cmd("adb kill-server")
        send_host_cmd("adb start-server")
        dev_resp = send_host_cmd("adb devices")
        current_devs = dev_resp.scan(/(\S+)\s+device$/)
        if !current_devs.flatten.include?(@board_id.strip)
          if @usb_ip
            send_cmd("ifconfig usb0 #{@telnet_ip} netmask 255.255.255.224 up", @prompt, 10)
            raise 'Unable to configure usb connection to platform' if timeout?
            send_host_cmd("ifconfig usb0 #{@usb_ip} netmask 255.255.255.224 up", params['server'].telnet_passwd)
            send_host_cmd("route add #{@usb_ip} dev usb0", params['server'].telnet_passwd)
            send_host_cmd("export ADBHOST=#{@usb_ip}; adb kill-server; adb start-server" )
          elsif @telnet_ip
            send_cmd("setprop service.adb.tcp.port 5555")
            send_cmd("stop adbd")
            send_cmd("start adbd")
            send_host_cmd("export ADBHOST=#{@telnet_ip};adb kill-server;adb start-server")
          end
          begin
            Timeout::timeout(5) do
              send_adb_cmd("wait-for-device")
            end
            rescue Timeout::Error => e
              raise "Unable to connect to device #{@name} id #{@board_id}\n"+e.backtrace.to_s
          end
        end
      else
        raise "image #{image_path} does not exist, unable to copy"
      end
      begin
        Timeout::timeout(600) do
          response = send_adb_cmd("logcat -d")
          while(!response.match(/bootCompleted/m)) do
            response = send_adb_cmd("logcat -d")
            sleep(1)
          end
        end
        rescue Timeout::Error => e
          raise "device #{@name} id #{@board_id} has not finished booting after 600 sec\n"+e.backtrace.to_s
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

    # Send command to an android device
    def send_adb_cmd (cmd)  
      send_host_cmd("adb -s #{@board_id} #{cmd}", 'ADB')
    end
    
    def send_host_cmd(cmd, endpoint='Host')
      log_info("#{endpoint}-Cmd: #{cmd} 2>&1")
      response = `#{cmd} 2>&1`
      log_info("#{endpoint}-Response: "+response)
      response
    end
      
  end
  
end
