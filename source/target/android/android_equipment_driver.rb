require File.dirname(__FILE__)+'/../equipment_driver'
require File.dirname(__FILE__)+'/../linux/boot_loader'
require File.dirname(__FILE__)+'/../linux/system_loader'

module Equipment
  include SystemLoader
  
  class AndroidBootStep < BootStep
    def run(params)
      send_cmd params, "boot", params['dut'].prompt, 180
    end
  end
  
  class AndroidFSStep < FSStep
    def set_mmcfs(params)
      append_text params, 'bootargs', "root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait "
    end
  end
  
  class AndroidEquipmentDriver < EquipmentDriver
    
    @@boot_info = {'am3517-evm' => 'console=ttyO2,115200n8 androidboot.console=ttyO2 mem=256M init=/init ip=dhcp rw mpurate=600 omap_vout.vid1_static_vrfb_alloc=y vram="8M" omapfb.vram=0:8M',
                   'am37x-evm' => 'console=ttyO0,115200n8 androidboot.console=ttyO0 mem=256M init=/init ip=dhcp omap_vout.vid1_static_vrfb_alloc=y vram=8M omapfb.vram=0:8M',
                   'ti816x-evm' => 'mem=166M@0x80000000 mem=768M@0x90000000 console=ttyO2,115200n8 androidboot.console=ttyO2 noinitrd ip=dhcp rw init=/init',
		           'ti814x-evm' => 'mem=128M console=ttyO0,115200n8 noinitrd ip=dhcp rw init=/init vram=50M',
		           'am335x-evm' => 'console=ttyO0,115200n8 androidboot.console=ttyO0 mem=256M init=/init ip=dhcp',
		           'am335x-sk' => 'console=ttyO0,115200n8 androidboot.console=ttyO0 mem=256M  init=/init ip=dhcp',
		           'beaglebone' => 'console=ttyO0,115200n8 androidboot.console=ttyO0 mem=256M init=/init ip=dhcp',
		           'flashboard' => 'console=ttyO2,115200n8 androidboot.console=ttyO2 mem=256M init=/init ip=dhcp omap_vout.vid1_static_vrfb_alloc=y vram=8M omapfb.vram=0:8M',
		           'beagleboard' => 'console=ttyO2,115200n8 androidboot.console=ttyO2 mem=256M init=/init ip=dhcp omap_vout.vid1_static_vrfb_alloc=y vram=8M omapfb.vram=0:8M omapdss.def_disp=dvi omapfb.mode=dvi:1024x768MR-16',}   

    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args = @@boot_info[@name]
      @boot_loader = nil
      @system_loader = nil
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
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.replace_step('boot', AndroidBootStep.new)
      @system_loader.replace_step('fs', AndroidFSStep.new)
    end
    
    def boot (params)
      @power_handler = params['power_handler'] if !@power_handler
      params['bootargs'] = @boot_args if !params['bootargs']
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @boot_loader.run params
      @system_loader.run params
      
      begin
        Timeout::timeout(600) do
          send_adb_cmd("wait-for-device")
        end
        rescue Timeout::Error => e
          raise "Unable to connect to device #{@name} id #{@board_id} after booting\n"+e.backtrace.to_s
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
    
    def boot_to_bootloader(params=nil)
      set_bootloader(params) if !@boot_loader
      @boot_loader.run params
    end
    
    def power_cycle(params)
      @power_handler = params['power_handler'] if !@power_handler
      if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
      else
        puts "Soft reboot..."
        connect({'type'=>'serial'}) if !target.serial
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
    
    def get_uboot_version(params=nil)
      return @uboot_version if @uboot_version
      if !at_prompt?({'prompt'=>@boot_prompt})
        puts "Not at uboot prompt, reboot to boot prompt...\n"
        boot_to_bootloader(params)
      end
      send_cmd("version", @boot_prompt, 10)
      @uboot_version = /U-Boot\s+([\d\.]+)\s*\(/.match(response).captures[0]
      raise "Could not find uboot version" if @uboot_version == nil
      puts "\nuboot version = #{@uboot_version}\n\n"
      return @uboot_version
    end

    def get_android_version()
      return @android_version if @android_version
      raise "Unable to get android version since Android has not booted up" if send_adb_cmd("get-state").strip.downcase != 'device'
      @android_version = send_adb_cmd("shell getprop ro.build.version.release")
      raise "Could not find android version" if @android_version.strip == ''
      puts "\nAndroid version = #{@android_version}\n\n"
      return @android_version
    end
    
    def at_prompt?(params)
      prompt = params['prompt']
      send_cmd("", prompt, 5)
      !timeout?
    end
      
  end
  
end
