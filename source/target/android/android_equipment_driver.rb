require File.dirname(__FILE__)+'/../linux/linux_equipment_driver'
require File.dirname(__FILE__)+'/../linux/boot_loader'
require File.dirname(__FILE__)+'/../linux/system_loader'

module Equipment
  include SystemLoader
  
  class AndroidEquipmentDriver < LinuxEquipmentDriver
    @@boot_info = Hash.new('')
    
#    @@boot_info = {'dra72x-evm'=> 'init=/init rootfstype=ext4 rootwait drm.rnodes=1 androidboot.selinux=permissive snd.slots_reserved=1,1 snd-soc-core.pmdown_time=-1 uio_pdrv_genirq.of_id=generic-uio console=ttyS0,115200'\
#                                  ' androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard console=ttyS0,115200 androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard',
#                   'dra7xx-evm'=> 'init=/init rootfstype=ext4 rootwait drm.rnodes=1 androidboot.selinux=permissive snd.slots_reserved=1,1 snd-soc-core.pmdown_time=-1 uio_pdrv_genirq.of_id=generic-uio console=ttyS0,115200'\
#                                  ' androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard console=ttyS0,115200 androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard'}

    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args += " androidboot.serialno=#{platform_info.board_id}"
      @bootdev_table = Hash.new { |h,k| h[k] = k }
      @bootdev_table['rawmmc-emmc'] = 'emmc' 
    end

    def set_systemloader(params)
      if params['var_use_default_env'].to_s == '4'
        @system_loader = SystemLoader::FastbootFlashSystemLoader.new
      else
        super(params)
      end
    end

    def poweroff(params=nil)
      send_cmd("sync",@prompt,120)
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

    # Update primary and secondary bootloader 
    def update_bootloader(params)
      return if @updated_bootloader
      raise "Only (q)spi|rawmmc-emmc boot is supported for Android" if !params['primary_bootloader_dev'].to_s.match(/spi|rawmmc-emmc/) || !params['secondary_bootloader_dev'].to_s.match(/spi|rawmmc-emmc/)
      ub_params = params.dup
      init_loader = SystemLoader::UbootFlashBootloaderSystemLoader.new()        
      ub_params['mmcdev'] = 1 if params['primary_bootloader_dev'].to_s.match(/rawmmc-emmc/)
      init_loader.run ub_params
      SysBootModule::set_sysboot(params['dut'], SysBootModule::get_sysboot_setting(params['dut'], @bootdev_table[params['primary_bootloader_dev']]))
      @boot_loader = nil
      boot_to_bootloader params
    end
    
    def recover_bootloader(params)
      raise "Only (q)spi|rawmmc-emmc boot is supported for Android" if !params['primary_bootloader_dev'].to_s.match(/spi|rawmmc-emmc/) || !params['secondary_bootloader_dev'].to_s.match(/spi|rawmmc-emmc/)
      ub_params = params.dup
      init_loader = SystemLoader::UbootFlashBootloaderSystemLoader.new()        
      SysBootModule::reset_sysboot(params['dut'])
      ub_params['primary_bootloader_dev'] = SysBootModule.get_default_bootmedia(params['dut'].name)
      ub_params['secondary_bootloader_dev'] = SysBootModule.get_default_bootmedia(params['dut'].name)
      ub_params['primary_bootloader_dst_dev'] = params['primary_bootloader_dev']
      ub_params['secondary_bootloader_dst_dev'] = params['secondary_bootloader_dev']
      raise "Bootloader cannot be recovered from failing device(s), #{params['primary_bootloader_dev']} and #{params['secondary_bootloader_dev']} are also the recovery devices" if ub_params['primary_bootloader_dev'] == params['primary_bootloader_dev'] || ub_params['secondary_bootloader_dev'] == params['secondary_bootloader_dev']
      msg = "Failed to boot to bootloader from #{params['primary_bootloader_dev']}, trying to recover from #{SysBootModule.get_default_bootmedia(params['dut'].name)}"
      puts msg
      log_info(msg)
      @boot_loader = nil
      boot_to_bootloader(ub_params)
      ub_params['mmcdev'] = 1 if params['primary_bootloader_dev'].to_s.match(/rawmmc-emmc/)
      init_loader.run ub_params
      SysBootModule::set_sysboot(params['dut'], SysBootModule::get_sysboot_setting(params['dut'], @bootdev_table[params['primary_bootloader_dev']]))
      @boot_loader = nil
      boot_to_bootloader params
      @updated_bootloader = true
    end
    
    def set_fastboot_partitions(params)
      send_cmd('setenv partitions $partitions_android', @boot_prompt)
    end

    def set_os_bootcmd(params)
      send_cmd("setenv bootcmd 'run emmc_android_boot'", @boot_prompt)
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
