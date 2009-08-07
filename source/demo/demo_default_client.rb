
module DemoHandlers  
    class DemoDefaultClient
        def initialize(platform_info)
           platform_info.instance_variables.each {|var|
            if platform_info.instance_variable_get(var).to_s.size > 0   
              self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
              self.instance_variable_set(var, platform_info.instance_variable_get(var))
            end
           }
        end

        def start_logger(log_path)
            raise "Method NOT Supported"
        end
        
        def stop_logger
            raise "Method NOT Supported"
        end
        
        def connect
            raise "Method NOT Supported"
        end
        
        def disconnect
            raise "Method NOT Supported"
        end
        
        def wait_for_threads(timeout)
            raise "Method NOT Supported"
        end

        # Demo-Dependant Methods
  
        def encode(params)
            raise "Method NOT Supported"
        end

        def decode(params)
            raise "Method NOT Supported"
        end

        def encode_decode(params)
            raise "Method NOT Supported"
        end
		
        # Copy an image from the build server to the tftp server
        # Reboot the dut and load the image into it in the bootloader
        # Boots into the new image, leaving the user at the command prompt 
        # Required Params: 
        # 'image_path' must be defined in the params hash, this is the path to your build directory
        # 'tftp_path' must be defined in the params hash, this is the base path to your tftp server (where the files will be copied)
        # 'tftp_ip' must be defined in the params hash if you have any modules, this is the ip of your tftp server (where the files will be copied & the modules will be copied from)
        def boot(params)
          image_path = params['image_path']
          puts "\n\n====== uImage is at #{image_path} =========="
          boot_args = FrameworkConstants::Bootargs[params['platform'].downcase.strip]
          boot_args = params['bootargs'] if params['bootargs']
          tmp_path = "#{params['tester'].downcase}/#{params['target'].downcase}/#{params['platform'].downcase}"
          if image_path != nil && File.exists?(image_path) && get_image(image_path, params['samba_path'], params['server'], tmp_path) then
            boot_to_bootloader(params)
            #set bootloader env vars and tftp the image to the unit -- Note: add more commands here if you need to change the environment further
            @target.send_cmd("setenv serverip #{params['tftp_ip']}",@boot_prompt, 30)
            @target.send_cmd("setenv bootcmd 'dhcp;bootm'",@boot_prompt, 30)
            @target.send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 30)
            raise 'Unable to set bootfile' if @target.is_timeout
            @target.send_cmd("setenv nfs_root_path #{params['server'].telnet_ip}:#{params['server'].nfs_root_path}",@boot_prompt, 30)
            raise 'Unable to set nfs root path' if @target.is_timeout
            @target.send_cmd("setenv bootargs #{boot_args}",@boot_prompt, 30)
            raise 'Unable to set bootargs' if @target.is_timeout
            @target.send_cmd("saveenv",@boot_prompt, 10)
            raise 'Unable save environment' if @target.is_timeout
            @target.send_cmd('boot', /login/, 100)
            raise 'Unable to boot platform' if @target.is_timeout
            # command prompt context commands
            @target.send_cmd(@login, @prompt, 10) # login to the unit
            raise 'Unable to login' if @target.is_timeout
          else
            raise "image #{image_path} does not exist, unable to copy"
          end
          connect if self.respond_to?(:connect)
        end

        # stop the bootloader after a reboot
        def stop_boot
          0.upto 3 do
          @target.send_cmd("\e", @boot_prompt, 1)
          end
        end
        
        # Reboot the unit to the bootloader prompt
        def boot_to_bootloader(params = {'apc' => nil})
          puts 'rebooting DUT'
          if params['apc'] != nil
          puts 'Resetting DUT using APC'
          params['apc'].reset(@power_port)
          @target.send_cmd("\e", /U-Boot/, 3)
          else
          @target.send_cmd('reboot', /U-Boot/, 40)
          end
          # stop the autobooter from autobooting the box
          #0.upto 30 do
          0.upto 5 do
          @target.send_cmd("\n", @boot_prompt, 1)
          puts 'Sending esc character'
          sleep 1
          break if !@target.is_timeout
          end
          # now in the uboot prompt
        end
        
        # Boot to the login prompt (will NOT login for you)
        def boot_to_image(params = {'apc' => nil})
          if params['apc'] != nil
          params['apc'].reset(@power_port.to_s)
          else
          @target.send_cmd('reboot', /Hit any key to stop autoboot:/, 30)
          end
        end
        
        # Copy the image files and module.ko files from the build directory into the ftp directory
        def get_image(src, dst_folder, server, tmp_path)
          # puts "copying files from #{src} to #{dst_path}"
          
          # Copy images and modules (.ko) tftp server
          build_files = Array.new
          src_folder = File.dirname(src)
          BuildClient.dir_search(src_folder, build_files)
          dst_folder = "#{dst_folder}\\bin"
          tmp_path = "/#{tmp_path}"
          build_files.each {|f|
          dst_path   = dst_folder+"\\#{File.basename(f)}"    # This is the Windows'samba path
          if f == src 
            puts "copy from: #{f}"
            puts "copy to: #{dst_path}"
            BuildClient.copy(f, dst_path)
            raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
            #puts "#{server.nfs_root_path}#{tmp_path}/bin/#{File.basename(f)}"
            server.send_cmd("mkdir -p #{server.tftp_path}#{tmp_path}",server.prompt, 10)
            server.send_cmd("mv -f #{server.nfs_root_path.sub(/(\\|\/)$/,'')}#{tmp_path}/bin/#{File.basename(f)} #{server.tftp_path}#{tmp_path}", server.prompt, 10)
          elsif File.extname(f) == '.ko'
            BuildClient.copy(f, dst_path) 
          end
          
          }
          true 
        end
    end
end

