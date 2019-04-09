require File.dirname(__FILE__)+'/../linux/linux_equipment_driver'
require File.dirname(__FILE__)+'/../linux/boot_loader'
require File.dirname(__FILE__)+'/../linux/system_loader'

module Equipment
  include SystemLoader
  
  class AndroidEquipmentDriver < LinuxEquipmentDriver
    @@android_boot_info = Hash.new('')
    
#    @@android_boot_info = {'dra72x-evm'=> 'init=/init rootfstype=ext4 rootwait drm.rnodes=1 androidboot.selinux=permissive snd.slots_reserved=1,1 snd-soc-core.pmdown_time=-1 uio_pdrv_genirq.of_id=generic-uio console=ttyS0,115200'\
#                                  ' androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard console=ttyS0,115200 androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard',
#                   'dra7xx-evm'=> 'init=/init rootfstype=ext4 rootwait drm.rnodes=1 androidboot.selinux=permissive snd.slots_reserved=1,1 snd-soc-core.pmdown_time=-1 uio_pdrv_genirq.of_id=generic-uio console=ttyS0,115200'\
#                                  ' androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard console=ttyS0,115200 androidboot.console=ttyS0 androidboot.hardware=jacinto6evmboard'}

    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @boot_args = @@android_boot_info[@name]
      @boot_args += ' sysrq_always_enabled'
      @boot_args += " androidboot.serialno=#{platform_info.board_id}"
      @bootdev_table = Hash.new { |h,k| h[k] = k }
      @bootdev_table['rawmmc-emmc'] = 'emmc'
      @proxy_info = ''
      ENV.each { |k,v| @proxy_info += " #{k}='#{v}'" if k.match(/_proxy/i) }
    end

    def set_android_tools(params)
      @server = params['server'] if params['server']
      if @params && @params['lxc-info']
        lxc_create_p = @params['lxc-info']
        lxc_create_p.merge!(params['lxc-info']) if params['lxc-info']
        create_lxc_container(lxc_create_p)
        clean_cmd="sudo -S lxc-stop -n #{@lxc_container} 2>&1 << EOF
#{@server.telnet_passwd}
EOF
sudo lxc-destroy -n #{@lxc_container}
"
        ObjectSpace.define_finalizer(self, lambda {|object_id| `#{clean_cmd}`})
        lxc_path = "/var/lib/lxc/#{@lxc_container}/rootfs#{params['workdir']}"
        lxc_config_cmd("mkdir -p #{lxc_path}")
        start_lxc_container({"lxc.mount.entry" => "#{params['workdir']}  #{lxc_path} none bind 0 0"})
        lxc_container_cmd("apt-get update", /.*/, 300)
        if params['adb']
          @adb = "#{@proxy_info} lxc-attach -n #{@lxc_container} -- #{File.realpath(params['adb'])}"
        else
          lxc_container_cmd("apt-get install -y android-tools-adb android-tools-fastboot", /.*/, 300)
          @adb = "#{@proxy_info} lxc-attach -n #{@lxc_container} -- adb"
        end
        lxc_container_cmd("apt-get install -y wget zip unzip usbutils pkg-config", /.*/, 300)
        add_device_to_lxc_container(@params['lxc-info']['adb-device'])
      else
        @adb =  params['adb'] if params['adb']
      end
    end
    
    def set_systemloader(params)
      if params['var_use_default_env'].to_s == '4'
        @system_loader = SystemLoader::FastbootFlashSystemLoader.new
      else
        super(params)
      end
      if params.has_key?("autologin")
        @system_loader.replace_step('boot', BootAutologinStep.new)
      end
    end

    def poweroff(params=nil)
      send_cmd("sync",@prompt,120)
    end

    # Send command to an android device
    def send_adb_cmd (cmd)
      send_host_sudo_cmd("#{@adb} -s #{@board_id} #{cmd}", 'ADB')
    end
    
    def send_host_cmd(cmd, endpoint='Host')
      log_info("#{endpoint}-Cmd: #{cmd} 2>&1")
      response = `#{cmd} 2>&1`
      log_info("#{endpoint}-Response: "+response)
      response
    end
    
    def send_host_sudo_cmd(command, expected_match=/.*/ ,timeout=30, options='-S')
      cmd=Array(command)
      cmd << '' if cmd.length < 2
      begin
        @timeout = false
        @response = ''
        log_info("Host-Cmd: sudo #{options} #{cmd*','}")
        @response = `sudo #{options} #{cmd[0]} 2>&1 << EOF
#{@server.telnet_passwd}
EOF
#{cmd[1..-1]*"\n"}
`
        puts @response
        log_info('Host-Response: '+@response)
        @response
      rescue Exception => e
        puts "TIMEOUT executing #{cmd}"
        log_error("On command "+cmd.to_s+"\n"+e.to_s+"Target: \n" + @response.to_s)
      end
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
      send_cmd("setenv bootcmd 'run findfdt; run emmc_android_boot'", @boot_prompt)
    end

    def get_android_version()
      return @android_version if @android_version
      raise "Unable to get android version since Android has not booted up" if !send_adb_cmd("get-state").match(/device/i)
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


    def lxc_config_cmd(cmd, e_re=/.*/, timeout=10)
      response = send_host_sudo_cmd(cmd, e_re, timeout, '-S')
      raise "Command #{cmd} failed, expected #{e_re} and got #{response}" if !/#{e_re}/.match(response)
      response
    end

    def create_lxc_container(params={})
      if @lxc_container
        stop_lxc_container()
        destroy_lxc_container()
      end
      containers = send_host_sudo_cmd("lxc-ls", /.*/, 10,'')
      if /#{params['name']}/i.match(containers)
        stop_lxc_container(params['name'])
        destroy_lxc_container(params['name'])
      end
        
      @lxc_container = params['name']
      c_params = {'template'=>'ubuntu', 'release' => 'xenial', 'packages' => ['systemd'], 'arch' => 'amd64'}
      c_params.merge!(params['config']) if params['config']
      lxc_config_cmd("#{@proxy_info} lxc-create -t #{c_params['template']} -n  #{@lxc_container} -- --release #{c_params['release']} --packages #{Array(c_params['packages']).join(',')} --arch #{c_params['arch']}", /.*/, 60)
      lxc_config_cmd("lxc-ls",  /#{@lxc_container}/i, 10)
    end
    
    def start_lxc_container(cfg={})
      config_val = ''
      cfg.each {|k,v| config_val += "-s #{k}='#{v}'"} 
      lxc_config_cmd("lxc-start #{config_val} -n  #{@lxc_container} -d", /.*/, 300)
      lxc_config_cmd("lxc-info -n  #{@lxc_container}", /State:\s+RUNNING/i, 10)
      sleep(10) #wait for container to boot completely
    end
    
    def add_device_to_lxc_container(device)
      lxc_config_cmd("lxc-device -n  #{@lxc_container} add #{File.realpath(device)} #{File.realpath(device)}", /.*/, 60)
    end
    
    def lxc_container_cmd(cmd, e_re, timeout=10)
      lxc_config_cmd("#{@proxy_info} lxc-attach -n  #{@lxc_container} -- #{cmd}", e_re, timeout)
    end
    
    def stop_lxc_container(container=@lxc_container)
      lxc_config_cmd("lxc-stop -n  #{container}", /.*/, 60)
      lxc_config_cmd("lxc-info -n  #{container}", /State:\s+STOPPED|#{container}\s+doesn't\s+exist/i, 10)
    end
    
    def destroy_lxc_container(container=@lxc_container)
      lxc_config_cmd("lxc-destroy -n  #{container}", /Destroyed\s+container\s+#{container}|Container\s+is\s+not\s+defined/i, 60)
      @lxc_container = nil
    end
    
    def add_adb_device()
      add_device_to_lxc_container(@params['lxc-info']['adb-device']) if @lxc_container && @params && @params['lxc-info'] && @params['lxc-info']['adb-device'] && File.exists?(@params['lxc-info']['adb-device']) 
    end

    def get_fastboot_media_type()
      return 'emmc_user'
    end
      
  end
  
end
