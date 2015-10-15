require File.dirname(__FILE__)+'/../../lib/cmd_translator'

module SystemLoader
  
  class Step
    attr_reader :name

    def initialize(name='')
      @name = name
    end

    def run(params)
    end

  end

  class UbootStep < Step
    @@uboot_version = nil

    def send_cmd(params, cmd, expect=nil, timeout=20, check_cmd_echo=true, raise_on_error=true)
      expect = params['dut'].boot_prompt if !expect
      params['dut'].send_cmd(cmd, expect, timeout, check_cmd_echo)
      raise "Error executing #{cmd}" if raise_on_error and params['dut'].timeout?
    end

    def get_uboot_version(params)
      return @@uboot_version if @@uboot_version
      params['dut'].send_cmd("", params['dut'].boot_prompt, 5, false)
      raise "Trying to load system before #{params['dut'].name} is at boot prompt" if params['dut'].timeout?
      params['dut'].send_cmd("version", params['dut'].boot_prompt, 10)
      @@uboot_version = /U-Boot\s+([\d\.]+)\s*/.match(params['dut'].response).captures[0]
      raise "Could not find uboot version" if @@uboot_version == nil
      puts "\nuboot version = #{@@uboot_version}\n\n"
      return @@uboot_version
    end

    def get_environment(params)
      params['_env'] = {}
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'printenv', 'version'=>@@uboot_version})
      # Determine kernel loadaddr
      load_addr = '${loadaddr}'
      case params['dut'].response
      when /kernel_addr=[\da-fA-Fx]+/
        load_addr = '${kernel_addr}'
      when /addr_kernel=[\da-fA-Fx]+/
        load_addr = '${addr_kernel}'
      when /addr_kern=[\da-fA-Fx]+/
        load_addr = '${addr_kern}'
      end
      params['_env']['kernel_loadaddr'] = load_addr
      params['_env']['loadaddr'] = load_addr

      # Determine dtb loadaddr
      load_dtb_addr = '${fdtaddr}'
      case params['dut'].response
      when /fdt_addr_r=[\da-fA-Fx]+/
        load_dtb_addr = '${fdt_addr_r}'
      when /addr_fdt=[\da-fA-Fx]+/
        load_dtb_addr = '${addr_fdt}'
      end
      params['_env']['dtb_loadaddr'] = load_dtb_addr
      # Determine ramdisk loadaddr
      load_ramdisk_addr = '${rdaddr}'
      case params['dut'].response
      when /ramdisk_addr=[\da-fA-Fx]+/
        load_ramdisk_addr = '${ramdisk_addr}'
      when /addr_fs=[\da-fA-Fx]+/
        load_ramdisk_addr = '${addr_fs}'
      end
      params['_env']['ramdisk_loadaddr'] = load_ramdisk_addr
      
      # Determine mon 
      mon_addr = '${addr_mon}'
      case params['dut'].response
      when /addr_mon=[\da-fA-Fx]+/
        mon_addr = '${addr_mon}'
      end
      params['_env']['mon_addr'] = mon_addr
      # Determine mmcdev
      mmcdev = '0'
      case params['dut'].response
      when /mmcdev/
        mmcdev = '${mmcdev}'
      end
      params['_env']['mmcdev'] = mmcdev
      # Determine usbdev
      usbdev = '0'
      case params['dut'].response
      when /usbdev/
        usbdev = '${usbdev}'
      end
      params['_env']['usbdev'] = usbdev
    end

    def append_text(params, env_var, text)
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'printenv', 'version'=>@@uboot_version})
      if !params['dut'].response.match(/^#{env_var}=.*#{text}.*/)
        send_cmd params, "setenv #{env_var} ''${#{env_var}}' #{text}'"
      end
    end

    def create_serial_load_script(params, load_address, filename, timeout)
      script = File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],'serial_load_script')
      File.open(script, "w") do |file|
        sleep 1  
        file.puts "#!/bin/bash"
        # Run stty to set the baud rate.
        file.puts "stty -F #{params['dut'].serial_port} #{params['dut'].serial_params['baud']}"
        file.puts "if [ $? -ne 0 ]; then exit 1; fi"
        # Start loady
        file.puts "echo \'loady #{load_address}\' > #{params['dut'].serial_port}"
        # Send kernel as ymodem, <timeout> timeout (in seconds).
        file.puts "/usr/bin/timeout #{timeout} /usr/bin/sb -v --ymodem #{filename} < #{params['dut'].serial_port} > #{params['dut'].serial_port}"
        # If we timeout or don't return cleanly (transfer failed), return 1
        file.puts "if [ $? -ne 0 ]; then exit 1; fi"
        # Return success.
        file.puts "exit 0"
      end
      File.chmod(0755, script)
    end
    
    def run_serial_load_script(params,timeout)
      # Disconnect serial prior to sending binaries through ymodem.
      serial_connected = false
      if params['dut'].target.serial
         params['dut'].disconnect('serial') 
         serial_connected = true
      end
      params['server'].send_cmd(File.join(SiteInfo::LINUX_TEMP_FOLDER,params['staf_service_name'],'serial_load_script'), params['server'].prompt, timeout) 
      params['dut'].connect({'type'=>'serial'}) if serial_connected
    end

    def load_file_from_mmc(params, load_addr, filename)
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      append_text params, 'bootcmd', "#{mmc_init_cmd}; "
      append_text params, 'bootcmd', "fatload mmc #{params['_env']['mmcdev']} #{load_addr} #{filename}; "
    end

    def load_file_from_usbmsc(params, load_addr, filename)
      usb_init_cmd = "usb stop; usb start"
      append_text params, 'bootcmd', "#{usb_init_cmd}; "
      append_text params, 'bootcmd', "load usb #{params['_env']['usbdev']} #{load_addr} #{filename}; "
    end

    def load_file_from_rawmmc(params, load_addr, blk_num, cnt)
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      append_text params, 'bootcmd', "#{mmc_init_cmd}; "
      append_text params, 'bootcmd', "mmc dev #{params['_env']['mmcdev']}; "
      append_text params, 'bootcmd', "mmc read #{load_addr} #{blk_num} #{cnt}; "
    end

    def load_file_from_serial_now(params, load_addr, filename, timeout)
      # create a file with required commands
      create_serial_load_script(params, load_addr, filename, timeout)
      # send file to serial port
      run_serial_load_script(params, timeout)
    end

    def load_file_from_eth(params, load_addr, filename)
      tftp_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'tftp', 'version'=>@@uboot_version})
      append_text params, 'bootcmd', "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}; "
    end
    
    def load_file_from_eth_now(params, load_addr, filename, timeout=60)
        tftp_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'tftp', 'version'=>@@uboot_version})
        self.send_cmd(params, "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}", @boot_prompt, timeout)
        raise "load_file_from_eth_now failed to load #{filename}" if params['dut'].response.match(/error/i)
    end

    def load_file_from_mmc_now(params, load_addr, filename, timeout=60)
      raise "load_file_from_mmc_now: no filename is provided." if !filename
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      self.send_cmd(params, "#{mmc_init_cmd}; fatload mmc #{params['_env']['mmcdev']} #{load_addr} #{filename} ", @boot_prompt, timeout)
    end

    def load_file_from_rawmmc_now(params, load_addr, blk_num, cnt, timeout=60)
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      self.send_cmd(params, "#{mmc_init_cmd}; mmc dev #{params['_env']['mmcdev']}; mmc read #{load_addr} #{blk_num} #{cnt}", @boot_prompt, timeout)
      raise "rawmmc read failed" if !params['dut'].response.match(/read:\s+OK/i)
    end

    def load_file_from_usbmsc_now(params, load_addr, filename, timeout=60)
      raise "load_file_from_usbmsc_now: no filename is provided." if !filename
      init_usbmsc(params, timeout)
      self.send_cmd(params, "#{usb_init_cmd}; fatload usb #{params['_env']['usbdev']} #{load_addr} #{filename} ", @boot_prompt, timeout)
    end

    def erase_nand(params, nand_loc, size, timeout=60)
      self.send_cmd(params, "nand erase #{nand_loc} #{size}", @boot_prompt, timeout)
      raise "erase_nand failed!" if !params['dut'].response.match(/100\%\s+complete/i) 
    end

    def write_file_to_nand(params, mem_addr, nand_loc, size, timeout=60)
      self.send_cmd(params, "nand write #{mem_addr} #{nand_loc} #{size}", @boot_prompt, timeout)
      raise "write to nand failed!" if !params['dut'].response.match(/bytes\s+written:\s+OK/i) 
    end

    def load_file_from_nand(params, mem_addr, nand_loc, timeout=60)
      self.send_cmd(params, "nand read #{mem_addr} #{nand_loc} ", @boot_prompt, timeout)
      raise "read from nand failed!" if !params['dut'].response.match(/bytes\s+read:\s+OK/i) 
    end

    def fatwrite(params, interface, dev, mem_addr, filename, filesize, timeout)
      self.send_cmd(params, "fatwrite #{interface} #{dev} #{mem_addr} #{filename} #{filesize}", @boot_prompt, timeout)
      raise "fatwrite to #{interface} failed! Please make sure there is FAT partition in #{interface} device!" if !params['dut'].response.match(/bytes\s+written/i)
    end

    def write_file_to_mmc_boot(params, mem_addr, filename, filesize, timeout)    
      fatwrite(params, "mmc", "#{params['_env']['mmcdev']}:1", mem_addr, filename, filesize, timeout)
    end

    def write_file_to_usbmsc_boot(params, mem_addr, filename, filesize, timeout)    
      init_usbmsc(params, timeout)
      fatwrite(params, "usb", "#{params['_env']['usbdev']}:1", mem_addr, filename, filesize, timeout)
    end

    def write_file_to_rawmmc(params, mem_addr, blk_num, cnt, timeout)    
      self.send_cmd(params, "mmc dev #{params['_env']['mmcdev']}; mmc write #{mem_addr} #{blk_num} #{cnt}", @boot_prompt, timeout)
      raise "write rawmmc failed!" if !params['dut'].response.match(/written:\s+OK/i)
    end

    def init_usbmsc(params, timeout)
      usb_init_cmd = "usb stop; usb start"
      self.send_cmd(params, "#{usb_init_cmd}", @boot_prompt, timeout)
      raise "No usbmsc device being found" if ! params['dut'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
    end

    def flash_run(params, part, timeout)
      case params["#{part}_src_dev"]
      when 'mmc'
        load_file_from_mmc_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
      when 'usbmsc'
        load_file_from_usbmsc_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
      when 'eth'
        load_file_from_eth_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
      else
        raise "Unsupported src_dev -- " + params["#{part}_src_dev"] + " for flashing"
      end
      
      # filesize will be updated to the size of file which was just loaded
      params['_env']['filesize'] = '${filesize}'

      case params["#{part}_dev"]
      when 'nand'
        erase_nand params, params["nand_#{part}_loc"], params['_env']['filesize'], timeout
        write_file_to_nand params, params['_env']['loadaddr'], params["nand_#{part}_loc"], params['_env']['filesize'], timeout
      when 'spi'
        #TODO: add erase_spi and write_file_to_spi functions
        erase_spi params, params["spi_#{part}_loc"], params['_env']['filesize'], timeout
        write_file_to_spi params, params['_env']['loadaddr'], params["spi_#{part}_loc"], params['_env']['filesize'], timeout
      when 'rawmmc'
        write_file_to_rawmmc params, params['_env']['loadaddr'], params["rawmmc_#{part}_loc"], params["rawmmc_#{part}_blkcnt"], timeout
      when 'mmc'
        if part.match(/primary_bootloader/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], "MLO", params['_env']['filesize'], timeout
        elsif part.match(/secondary_bootloader/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], "u-boot.img", params['_env']['filesize'], timeout
        elsif part.match(/kernel/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], File.basename(params['kernel_image_name']), params['_env']['filesize'], timeout
        elsif part.match(/dtb/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], File.basename(params['dtb_image_name']), params['_env']['filesize'], timeout
        end
      when 'usbmsc'
        init_usbmsc(params, timeout)
        if part.match(/primary_bootloader/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], "MLO", params['_env']['filesize'], timeout
        elsif part.match(/secondary_bootloader/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], "u-boot.img", params['_env']['filesize'], timeout
        elsif part.match(/kernel/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], File.basename(params['kernel_image_name']), params['_env']['filesize'], timeout
        elsif part.match(/dtb/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], File.basename(params['dtb_image_name']), params['_env']['filesize'], timeout
        end
      else
        raise "Unsupported dst dev: " + params["#{part}_dev"]
      end
    end

  end

  class FlashPrimaryBootloaderStep < UbootStep
    def initialize
      super('flash_primary_bootloader')
    end

    def run(params)
      flash_run(params, "primary_bootloader", 30)
    end

  end

  class FlashSecondaryBootloaderStep < UbootStep
    def initialize
      super('flash_secondary_bootloader')
    end

    def run(params)
      flash_run(params, "secondary_bootloader", 30)
    end

  end

  class FlashKernelStep < UbootStep
    def initialize
      super('flash_kernel')
    end

    def run(params)
      flash_run(params, "kernel", 60)
    end

  end

  class FlashDTBStep < UbootStep
    def initialize
      super('flash_dtb')
    end

    def run(params)
      flash_run(params, "dtb", 60)
    end

  end

  class FlashFSStep < UbootStep
    def initialize
      super('flash_fs')
    end

    def run(params)
      flash_run(params, "fs", 120)
    end

  end

  class PrepStep < UbootStep
    def initialize
      super('prep')
    end

    def run(params)
      get_uboot_version params
      send_cmd params, "setenv bootargs '#{params['bootargs']} '", nil, 2, false, false
      send_cmd params, "setenv bootcmd  ''", nil, 2, false, false
      send_cmd params, "setenv autoload 'no'", nil, 2, false, false
      send_cmd params, "setenv serverip '#{params['server'].telnet_ip}'", nil, 2, false, false
      if  params.has_key?'uboot_user_cmds'
        params['uboot_user_cmds'].each{|uboot_cmd|
          send_cmd params, uboot_cmd, nil, 2, false
        }
      end
      send_cmd params, "setenv mmcdev '#{params['mmcdev']} '", nil, 2, false, false if params.has_key?('mmcdev')
      get_environment(params)
    end
  end

  class SetIpStep < UbootStep
    def initialize
      super('setip')
    end

    def run(params)
      if params['dut'].instance_variable_defined?(:@telnet_ip) and params['dut'].telnet_ip.to_s != ''
        append_text params, 'bootargs', "ip=#{params['dut'].telnet_ip} "
        send_cmd params, "setenv ipaddr #{params['dut'].telnet_ip}"
      else
        append_text params, 'bootargs', "ip=:::::eth0:dhcp "
        send_cmd params, "setenv serverip '#{params['server'].telnet_ip}'", nil, 2, false, false
        send_cmd params, "setenv autoload 'no'", nil, 2, false, false
        send_cmd params, "dhcp", @boot_prompt, 60 
      end
    end
  end

  class KernelStep < UbootStep
    def initialize
      super('kernel')
    end

    def run(params)
      case params['kernel_src_dev']
      when 'mmc'
        load_kernel_from_mmc params
      when 'rawmmc'
        load_kernel_from_rawmmc params
      when 'usbmsc'
        load_kernel_from_usbmsc params
      when 'nand'
        load_kernel_from_nand params
      when 'eth'
        load_kernel_from_eth params
      when 'ubi'
        load_kernel_from_ubi params
      when 'serial'
        load_kernel_from_serial params
      else
        raise "Don't know how to load kernel from #{params['kernel_src_dev']}"
      end
    end

    private
    def load_kernel_from_mmc(params)
      load_file_from_mmc params, params['_env']['kernel_loadaddr'], File.basename(params['kernel_image_name'])
    end

    def load_kernel_from_rawmmc(params)
      load_file_from_rawmmc params, params['_env']['kernel_loadaddr'], params['rawmmc_kernel_loc'], params['rawmmc_kernel_blkcnt']
    end

    def load_kernel_from_usbmsc(params)
      load_file_from_usbmsc params, params['_env']['kernel_loadaddr'], File.basename(params['kernel_image_name'])
    end

    def load_kernel_from_nand(params)
      load_file_from_nand params, params['_env']['kernel_loadaddr'], params["nand_kernel_loc"]
    end

    def load_kernel_from_serial(params)
      load_file_from_serial_now params, params['_env']['kernel_loadaddr'], params['kernel'], 1720
    end

    def load_kernel_from_eth(params)
      load_file_from_eth_now params, params['_env']['kernel_loadaddr'], params['kernel_image_name']
    end
   
    def load_kernel_from_ubi(params)
      append_text params, 'bootcmd', "ubi part ubifs; ubifsmount boot; ubifsmount boot; ubifsload #{params['_env']['kernel_loadaddr']} #{params['kernel_image_name']}; "
    end
  
  end

  class DTBStep < UbootStep
    def initialize
      super('dtb')
    end

    def run(params)
      case params['dtb_src_dev']
      when 'mmc'
        load_dtb_from_mmc params
      when 'rawmmc'
        load_dtb_from_rawmmc params
      when 'usbmsc'
        load_dtb_from_usbmsc params
      when 'nand'
        load_dtb_from_nand params
      when 'eth'
        load_dtb_from_eth params
      when 'ubi'
        load_dtb_from_ubi params
      when 'serial'
        load_dtb_from_serial params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load dtb from #{params['dtb_src_dev']}"
      end
    end

    private
    def load_dtb_from_mmc(params)
      load_file_from_mmc params, params['_env']['dtb_loadaddr'], File.basename(params['dtb_image_name'])
    end

    def load_dtb_from_rawmmc(params)
      load_file_from_rawmmc params, params['_env']['dtb_loadaddr'], params['rawmmc_dtb_loc'], params['rawmmc_dtb_blkcnt']
    end

    def load_dtb_from_usbmsc(params)
      load_file_from_usbmsc params, params['_env']['dtb_loadaddr'], File.basename(params['dtb_image_name'])
    end

    def load_dtb_from_nand(params)
      load_file_from_nand params, params['_env']['dtb_loadaddr'], params["nand_dtb_loc"]
    end

    def load_dtb_from_serial(params)
      load_file_from_serial_now params, params['_env']['dtb_loadaddr'], params['dtb'],160
    end

    def load_dtb_from_eth(params)
      load_file_from_eth_now params, params['_env']['dtb_loadaddr'], params['dtb_image_name']
    end
    
    def load_dtb_from_ubi(params)
      append_text params, 'bootcmd', "ubifsload #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']};"
    end

  end

  class SkernStep < SystemLoader::UbootStep
    def initialize
      super('skern')
    end
    def run(params)
        case params['skern_dev']
        when 'eth'
          load_skern_from_eth params
          append_text params, 'bootcmd', "mon_install #{params['_env']['mon_addr']};"
        when 'ubi'
          load_skern_from_ubi params
          append_text params, 'bootcmd', "mon_install #{params['_env']['mon_addr']};"
        when 'none'
          # Do nothing
        else
          raise "Don't know how to load skern from #{params['skern_dev']}"
      end
    end
    private
    def load_skern_from_eth(params)
      load_file_from_eth_now params, params['_env']['mon_addr'], params['skern_image_name']
    end

    def load_skern_from_ubi(params)
      append_text params, 'bootcmd', "ubifsload #{params['_env']['mon_addr']} #{params['skern_image_name']};"
    end

  end

  class FSStep < UbootStep
    def initialize
      super('fs')
    end

    def run(params)
      case params['fs_type']
      when /nfs/i
        set_nfs params
      when /ramfs/i
        set_ramfs params
      when /mmcfs/i
        set_mmcfs params
      when /ubifs/i
        set_ubifs params
      else
        raise "Don't know how to set #{params['fs_type']} filesystem"
      end
    end
    
    private
    def set_nfs(params)
      raise "No NFS path is being specified!" if !params['nfs_path']
      params['fs_options'] = ",nolock,v3,tcp,rsize=4096,wsize=4096" if !params['fs_options']
      append_text params, 'bootargs', "root=/dev/nfs rw nfsroot=#{params['nfs_path']}#{params['fs_options']} "
    end
    
    def set_ubifs(params)
      append_text params, 'bootargs', "rootfstype=ubifs root=#{params['ubi_root']} rootflags=sync rw ubi.mtd=#{params['ubi_mtd_partition']},#{params['nand_eraseblock_size'].to_i}"
    end
    
    def set_ramfs(params)
      # Make sure file have required headers (i.e. mkimage have been run)
      fs_image_full_path = File.join(params['server'].tftp_path, params['fs_image_name'])
      y=`mkimage -l #{fs_image_full_path}`
      if !y.match(/Image\s+Name:\s+Arago\s+Test\s+Image/i)
        ramdisk_image_name="#{File.dirname params['fs_image_name']}/uRamdisk"
        x=`mkimage -A arm -T ramdisk -C gzip -n 'Arago Test Image' -d #{fs_image_full_path} #{File.join(params['server'].tftp_path, ramdisk_image_name)}`
        raise "Could not run mkimage on #{params['fs_image_name']}" if !x.match(/Image\s+Name:\s+Arago\s+Test\s+Image/i)
        params['fs_image_name']=ramdisk_image_name
      end

      # Avoid relocation of ramfs and device tree data
      send_cmd params, "setenv initrd_high '0xffffffff'"
      send_cmd params, "setenv fdt_high '0x88000000'"
      
      case params['fs_src_dev']
      when /eth/i
        load_file_from_eth_now params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
      when /mmc/i
        load_file_from_mmc params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
      else
        raise "Don't know how to get ramfs image from #{params['fs_src_dev']}"
      end
      append_text params, 'bootargs', "root=/dev/ram0 rw "
    end
    
   def set_mmcfs(params)
      begin
        if params['dut'].instance_variable_defined?(:@params) and params['dut'].params.key?('rootfs_partuuid') and params['dut'].params['rootfs_partuuid'].to_s != ""
          part_uuid = params['dut'].params['rootfs_partuuid'].to_s
        else
          part_uuid = get_part_uuid(params)
        end
        append_text params, 'bootargs', "root=PARTUUID=#{part_uuid} rw rootfstype=ext4 rootwait "

      rescue Exception => e
        puts "Back to old way since ... " + e.to_s
        append_text params, 'bootargs', "root=/dev/mmcblk0p2 rw rootfstype=ext3 rootwait "
      end
    end

    def translate_fsdev_interface(params)
      case params['fs_dev']
      when /mmc|emmc/i
        params['interface'] = 'mmc'
      when /usb|sata/i
        params['interface'] = 'scsi'
      else
        params['interface'] = params['fs_dev']
      end
    end

    def get_fs_part(params, fs_dev_ins)
      for i in 1..5
        send_cmd params, "ls #{params['interface']} #{fs_dev_ins}:#{i}"
        if params['dut'].response.match(/etc/i) and params['dut'].response.match(/dev/i)
          fs_part = i
          break
        end
      end
      return fs_part
    end

    def get_part_uuid(params)
      raise "The support for #{params['fs_dev']} is not added yet" if params['fs_dev'] != 'mmc'
      begin
        # hard-coded to 0 for now; we can get this value from evm_data later on if needed
        # dev_ins is which device instance to boot rootfs from, ex, 0 is for mmc and 1 is for emmc.
        fs_dev_ins = 0 
        translate_fsdev_interface(params)
        fs_part = get_fs_part(params, fs_dev_ins)
        this_cmd = "part uuid #{params['interface']} #{fs_dev_ins}:#{fs_part}"
        send_cmd params, this_cmd
        
        part_uuid = /#{this_cmd}.*?^\r*([\h\-]+).*?#{params['dut'].boot_prompt}/im.match(params['dut'].response).captures[0].strip
        raise "PARTUUID should not be empty" if part_uuid == ''

      rescue Exception => e
        puts "get_part_uuid: unable to get PARTUUID: " + e.to_s 
        raise
      end
  
      return part_uuid 
    end
    
  end
  
  class SaveEnvStep < UbootStep
    def initialize
      super('save_env')
    end

    def run(params)
      send_cmd params, "saveenv"
      send_cmd params, "printenv"
    end
  end

  class SetDefaultEnvStep < UbootStep
    def initialize
      super('set_default_env')
    end

    def run(params)
      get_uboot_version params
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'env default', 'version'=>@@uboot_version})
      send_cmd params, "printenv"
    end
  end
  
  class SetExtraArgsStep < UbootStep
    def initialize
      super('set_extra_args')
    end

    def run(params)
      if params.has_key?("bootargs_append")
        send_cmd params, "setenv extraargs #{CmdTranslator::get_uboot_cmd({'cmd'=>params['bootargs_append'], 'version'=>@@uboot_version, 'platform'=>params['dut'].name})}",params['dut'].boot_prompt,10
        send_cmd params, "printenv", params['dut'].boot_prompt, 10
        # add extraargs to bootargs for all lines with bootm
        params['dut'].response.split(/\n/).each {|line|
          if line.match(/boot[mz]\s+/)
            varname = line.split('=')[0]
            varvalue = line.sub(varname + '=', '')
            newvalue = varvalue.gsub(/bootm\s+/, "setenv bootargs ${bootargs} ${extraargs}; bootm ")
            newvalue = newvalue.gsub(/bootz\s+/, "setenv bootargs ${bootargs} ${extraargs}; bootz ")
            send_cmd params, "setenv #{varname.strip} \'#{newvalue.strip}\'", params['dut'].boot_prompt, 10
          end
        }
      end
    end
  end

  class BootCmdStep < UbootStep
    def initialize
      super('boot_cmd')
    end

    def run(params)
      ramdisk_addr = ''
      dtb_addr     = ''
      if params['dtb_image_name'].strip != '' && !params['fs_type'].match(/ramfs/i)
        ramdisk_addr = '-'
      elsif  params['fs_type'].match(/ramfs/i)
        ramdisk_addr = params['_env']['ramdisk_loadaddr']
      end
      dtb_addr = params['_env']['dtb_loadaddr'] if params['dtb_image_name'].strip != ''
      append_text params, 'bootcmd', "if iminfo #{params['_env']['kernel_loadaddr']}; then bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr};"\
                                     " else bootz #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; fi"
    end
  end

  class BootStep < UbootStep
    def initialize
      super('boot')
    end

    def run(params)
      boot_timeout = params['var_boot_timeout'] ? params['var_boot_timeout'].to_i : 210
      send_cmd params, "boot", params['dut'].login_prompt, boot_timeout
      params['dut'].boot_log = params['dut'].response
      raise "DUT rebooted while Starting Kernel" if params['dut'].boot_log.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
      check_for_boot_errors(params['dut'])
      send_cmd params, params['dut'].login, params['dut'].prompt, 10, false # login to the unit
    end

    def check_for_boot_errors(dut)
      errors = {
        'CPU failed to come online' => /\[[\s\d\.]+\]\s+.*CPU\d+:\s+failed to come online/i,
      }
      errors.each {|n,r|
        raise n if dut.boot_log.match(r)
      }
    end
  end

  class UserCmdsStep < UbootStep
    def initialize
      super('user_cmds')
    end

    def run(params)
      params['serverip'] = params['server'].telnet_ip
      File.open(params['boot_cmds'], "r") do |file_handle|
        file_handle.each_line do |line|
          next if line.strip.length == 0 or line.match(/^\s*#/)
          a = eval('['+line+']')
          send_cmd(params, *a)
        end
      end
      params['dut'].boot_log = params['dut'].response
      send_cmd params, params['dut'].login, params['dut'].prompt, 10, false # login to the unit
    end
  end
  
  class BoardInfoStep < UbootStep
    def initialize
      super('board_info')
    end

    def run(params)
      send_cmd params, 'version'
      send_cmd params, 'bdinfo'
    end
  end

  class PowerCycleStep < UbootStep
    def initialize
      super('power_cycle')
    end

    def run(params)
      params['dut'].disconnect('serial')
      params['dut'].boot_to_bootloader(params)
    end
  end

  class TouchCalStep < UbootStep
    def initialize
      super('touch_cal')
    end

    def run(params)
      case params['kernel_dev']
      when 'usbmsc'
        init_usbmsc(params, 20)
        write_file_to_usbmsc_boot params, params['_env']['loadaddr'], "ws-calibrate.rules", 4, 10
      else
        begin
          mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
          self.send_cmd(params, "#{mmc_init_cmd}; echo $?", /0[\0\n\r]+/m, 10, false)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], "ws-calibrate.rules", 4, 10
        rescue
          puts "WARNING...Could not fatwrite 'ws-calibrate.rules' to MMC boot partition!"
        end
      end
    end
  end

  class BaseSystemLoader < Step
    attr_accessor :steps

    def initialize
      super('load_system')
      @steps = []
    end

    def add_step(step)
      @steps << step
    end

    def run_step(stepname,params)
      @steps.each {|step| 
        if step.name == stepname.downcase.strip
          puts "Calling #{name} run() method"
          step.run(params)
        end 
      }
    end
    
    def insert_step_before(name, new_step)
      index = @steps.index {|step| step.name == name.downcase.strip}
      raise "#{name} step does not exist" if !index
      @steps.insert(index, new_step)
    end

    def remove_step(name)
      @steps.select! {|step| step.name != name.downcase.strip }
    end

    def get_step(name)
      @steps.select {|step| step.name == name.downcase.strip }
    end

    def replace_step(name, new_step)
      @steps.map! {|step| 
        if step.name == name.downcase.strip
          new_step
        else
          step 
        end
      }
    end

    def contains?(name)
      get_step(name).length > 0
    end

    def run(params)
      @steps.each {|step| step.run(params)}
    end
  end

  class UbootSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( KernelStep.new )
      add_step( DTBStep.new )
      add_step( SkernStep.new )
      add_step( FSStep.new )
      add_step( BootCmdStep.new )
      add_step( BoardInfoStep.new )
      add_step( TouchCalStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootDefaultEnvSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( SetDefaultEnvStep.new )
      add_step( SaveEnvStep.new )
      add_step( PowerCycleStep.new )
      add_step( BoardInfoStep.new )
      add_step( TouchCalStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootLetItGoSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( BoardInfoStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootFlashBootloaderSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashPrimaryBootloaderStep.new )
      add_step( FlashSecondaryBootloaderStep.new )
    end

  end

  class UbootFlashKernelSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashKernelStep.new )
      add_step( FlashDTBStep.new )
    end

  end

  class UbootFlashFSSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashFSStep.new )
    end

  end

  class UbootFlashAllSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashPrimaryBootloaderStep.new )
      add_step( FlashSecondaryBootloaderStep.new )
      add_step( FlashKernelStep.new )
      add_step( FlashDTBStep.new )
      add_step( FlashFSStep.new )
    end

  end

  class UbootUserSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( UserCmdsStep.new )
    end

  end
end
