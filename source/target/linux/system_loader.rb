require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../site_info.rb'
require "open3"

module SystemLoader

  class SystemloaderException < Exception
    def initialize(e=nil)
      super()
      set_backtrace(e.backtrace.insert(0,e.to_s)) if e
    end
  end
  
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
      sleep 0.001 
      params['dut'].send_cmd(cmd, expect, timeout, check_cmd_echo)
      raise "Error executing #{cmd}" if raise_on_error and params['dut'].timeout?
    end

    def get_uboot_version(params)
      return @@uboot_version if @@uboot_version
      5.times {
        params['dut'].send_cmd("", params['dut'].boot_prompt, 3, false)
        break if !params['dut'].timeout?
      }
      raise "Trying to load system before #{params['dut'].name} is at boot prompt" if params['dut'].timeout?
      params['dut'].send_cmd("version", params['dut'].boot_prompt, 10)
      @@uboot_version = /U-Boot\s+([\d\.]+)/.match(params['dut'].response).captures[0]
      raise "Could not find uboot version" if @@uboot_version == nil
      puts "\nuboot version = #{@@uboot_version}\n\n"
      return @@uboot_version
    end

    def get_environment(params)
      params['_env'] = {}
      3.times do
        send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'printenv', 'version'=>@@uboot_version}), params['dut'].boot_prompt, 10, true, false
        break if ! params['dut'].timeout?
        sleep 1
      end
      raise "Error executing printenv" if params['dut'].timeout?
      params['dut'].response.split(/[\r\n]+/).each { |env_str| params['_env'].store(*(env_str.split('=',2))) if env_str.include?('=') }
      # Determine kernel loadaddr
      load_addr = '${loadaddr}'
      fit_loadaddr = '0xc0000000'
      case params['dut'].response
      when /kernel_addr=[\da-fA-Fx]+/
        load_addr = '${kernel_addr}'
      when /addr_kernel=[\da-fA-Fx]+/
        load_addr = '${addr_kernel}'
      when /addr_kern=[\da-fA-Fx]+/
        load_addr = '${addr_kern}'
      end
      case params['dut'].response
      when /fit_loadaddr=[\da-fA-Fx]+/
        fit_loadaddr = '${fit_loadaddr}'
      end
      params['_env']['kernel_loadaddr'] = load_addr
      params['_env']['loadaddr'] = load_addr
      params['_env']['fitaddr'] = fit_loadaddr
      params['_env']['overlayaddr'] = '${overlayaddr}'
      # filesize will be updated to the size of file which was just loaded
      params['_env']['filesize'] = '${filesize}'
      params['_env']['initramfs'] = '${_initramfs}'

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
      else
        load_ramdisk_addr = '0x84000000'
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
      send_cmd params, "#{CmdTranslator::get_uboot_cmd({'cmd'=>'printenv', 'version'=>@@uboot_version})} #{env_var}"
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
        file.puts "sleep 1"
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
      raise "run_serial_load_script: Transfer failed" if (params['server'].response.match(/Transfer\s+incomplete/i) || !params['server'].response.match(/Transfer\s+complete/i))
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
        self.send_cmd(params, "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}", params['dut'].boot_prompt, timeout)
        raise "load_file_from_eth_now failed to load #{filename}" if params['dut'].response.match(/error/i)
    end

    def load_file_from_mmc_now(params, load_addr, filename, timeout=60)
      raise "load_file_from_mmc_now: no filename is provided." if !filename
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      self.send_cmd(params, "#{mmc_init_cmd}; fatload mmc #{params['_env']['mmcdev']} #{load_addr} #{filename} ", params['dut'].boot_prompt, timeout)
    end

    def load_file_from_rawmmc_now(params, load_addr, blk_num, cnt, timeout=60)
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      self.send_cmd(params, "#{mmc_init_cmd}; mmc dev #{params['_env']['mmcdev']}; mmc read #{load_addr} #{blk_num} #{cnt}", params['dut'].boot_prompt, timeout)
      raise "rawmmc read failed" if !params['dut'].response.match(/read:\s+OK/i)
    end

    def load_file_from_usbmsc_now(params, load_addr, filename, timeout=60)
      raise "load_file_from_usbmsc_now: no filename is provided." if !filename
      init_usbmsc(params, timeout)
      self.send_cmd(params, "fatload usb #{params['_env']['usbdev']} #{load_addr} #{filename} ", params['dut'].boot_prompt, timeout)
    end

    def erase_mtd(params, dev, mtd_loc, size, timeout=60)
      aligned_size = get_aligned_size params, size, dev
      self.send_cmd(params, "mtd erase #{dev} #{mtd_loc} #{aligned_size}", params['dut'].boot_prompt, timeout)
      raise "erase_mtd failed!" if !params['dut'].response.match(/Erasing/) or params['dut'].response.match(/error/i)
    end

    # The erase size returned is in decimal format
    def get_nand_sector_size(params)
      self.send_cmd(params, "nand info", params['dut'].boot_prompt, 10)
      # "sector size 128 KiB"
      sectorsize = /sector\s*size\s+([0-9]+)\s*KiB/im.match(params['dut'].response).captures[0]
      sectorsize = sectorsize.to_i * 1024
      return sectorsize
    end

    def get_nor_sector_size(params)
      self.send_cmd(params, "mtd list", params['dut'].boot_prompt, 10)
      # "block size: 0x40000 bytes"
      sectorsize_h = /nor0\s*.*?block\s+size:\s*(0x\h+)\s*bytes/im.match(params['dut'].response).captures[0]
      sectorsize = sectorsize_h.to_i(16)
      return sectorsize
    end

    def get_aligned_size(params, size, dev='nand')
      if dev == 'nand'
        sector_size = get_nand_sector_size params
      elsif dev == 'nor0'
        sector_size = get_nor_sector_size params
      end
      # sector_size is in decimal format
      # size passed here is in hex format
      roundup_size = (size.to_i(16).to_f / sector_size.to_f).ceil * sector_size.to_f
      roundup_size = roundup_size.to_i.to_s(16)
      # return in hex format
      return roundup_size
    end

    def erase_nand(params, nand_loc, size, timeout=60)
      if nand_loc.match(/^0x|^\d+/)
        aligned_size = get_aligned_size params, size
        self.send_cmd(params, "nand erase #{nand_loc} #{aligned_size}", params['dut'].boot_prompt, timeout)
      else
        self.send_cmd(params, "nand erase.part #{nand_loc} ", params['dut'].boot_prompt, timeout)
      end
      raise "erase_nand failed!" if !params['dut'].response.match(/OK/) 
    end

    def write_file_to_mtd(params, dev, mem_addr, mtd_loc, size, timeout=60)
      aligned_size = get_aligned_size params, size, dev
      self.send_cmd(params, "mtd write #{dev} #{mem_addr} #{mtd_loc} #{aligned_size}", params['dut'].boot_prompt, timeout)
      raise "write to mtd failed!" if !params['dut'].response.match(/writing/i) or params['dut'].response.match(/error/i) 
    end

    def write_file_to_nand(params, mem_addr, nand_loc, size, timeout=60)
      aligned_size = get_aligned_size params, size
      self.send_cmd(params, "nand write #{mem_addr} #{nand_loc} #{aligned_size}", params['dut'].boot_prompt, timeout)
      raise "write to nand failed!" if !params['dut'].response.match(/bytes\s+written:\s+OK/i) 
    end

    def load_file_from_nand(params, mem_addr, nand_loc, timeout=60)
      self.send_cmd(params, "nand read #{mem_addr} #{nand_loc} ", params['dut'].boot_prompt, timeout)
      raise "read from nand failed!" if !params['dut'].response.match(/bytes\s+read:\s+OK/i) 
    end

    def probe_spi(params, dev, timeout=60)
      case dev.downcase
        when 'spi'
          key = 'spi_sf_probe'
        when /ospi|qspi/
          key = 'qspi_sf_probe'
      end
      sf_probe_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>key, 'version'=>@@uboot_version, 'platform'=>params['dut'].name}) 
      self.send_cmd(params, sf_probe_cmd, params['dut'].boot_prompt, timeout)
      raise "sf probe failed!" if !params['dut'].response.match(/SF:\s+Detected/i)
    end

    def erase_spi(params, dev, spi_loc, size, timeout=60)
      # workaround for LCPD-6981
      if !params.include?("spi_erase_size")
        spi_erase_size = get_spi_erasesize params, dev
        params['spi_erase_size'] = spi_erase_size
      else
        spi_erase_size = params['spi_erase_size']
      end
      # spi_erase_size is in decimal format
      # size passed here is in hex format
      roundup_size = (size.to_i(16).to_f / spi_erase_size.to_f).ceil * spi_erase_size.to_f 
      roundup_size = roundup_size.to_i.to_s(16)
      self.send_cmd(params, "sf erase #{spi_loc} #{roundup_size}", params['dut'].boot_prompt, timeout)
      raise "erase_spi failed!" if !params['dut'].response.match(/OK/) 
    end

    # The erase size returned is in decimal format
    def get_spi_erasesize(params, dev)
      probe_spi(params, dev)
      erasesize = /erase\s*size\s+([0-9]+)\s*KiB,/im.match(params['dut'].response).captures[0]
      erasesize = erasesize.to_i * 1024
      return erasesize
    end

    def write_file_to_spi(params, mem_addr, spi_loc, size, timeout=60)
      self.send_cmd(params, "sf write #{mem_addr} #{spi_loc} #{size}", params['dut'].boot_prompt, timeout)
      raise "write to spi failed!" if !params['dut'].response.match(/written:\s+OK/i) 
    end

    def load_file_from_spi(params, mem_addr, spi_loc, timeout=60)
      self.send_cmd(params, "sf read #{mem_addr} #{spi_loc} ", params['dut'].boot_prompt, timeout)
      raise "read from spi failed!" if !params['dut'].response.match(/read:\s+OK/i) 
    end

    def fatwrite(params, interface, dev, mem_addr, filename, filesize, timeout)
      self.send_cmd(params, "fatwrite #{interface} #{dev} #{mem_addr} #{filename} #{filesize}", params['dut'].boot_prompt, timeout)
      raise "fatwrite to #{interface} failed! Please make sure there is FAT partition in #{interface} device!" if !params['dut'].response.match(/bytes\s+written/i)
    end

    def write_file_to_mmc_boot(params, mem_addr, filename, filesize, timeout)    
      fatwrite(params, "mmc", "#{params['_env']['mmcdev']}:1", mem_addr, filename, filesize, timeout)
    end

    def write_file_to_usbmsc_boot(params, mem_addr, filename, filesize, timeout)    
      init_usbmsc(params, timeout)
      fatwrite(params, "usb", "#{params['_env']['usbdev']}:1", mem_addr, filename, filesize, timeout)
    end

    def write_file_to_rawmmc(params, mem_addr, blk_num, filesize, timeout)    
      cnt = get_blk_cnt(filesize, 512)
      if params['bootpart']
        self.send_cmd(params, "mmc dev #{params['_env']['mmcdev']} #{params['bootpart']}; mmc write #{mem_addr} #{blk_num} #{cnt}", params['dut'].boot_prompt, timeout) 
      else
        self.send_cmd(params, "mmc dev #{params['_env']['mmcdev']}; mmc write #{mem_addr} #{blk_num} #{cnt}", params['dut'].boot_prompt, timeout)
      end
      raise "write rawmmc failed!" if !params['dut'].response.match(/written:\s+OK/i)
    end

    def init_usbmsc(params, timeout)
      usb_init_cmd = "usb stop; usb start"
      self.send_cmd(params, "#{usb_init_cmd}", params['dut'].boot_prompt, timeout)
      raise "No usbmsc device being found" if ! params['dut'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
    end

    # filesize: in hex
    # blk_len: in decimal
    # return: in hex
    def get_blk_cnt(filesize, blk_len)
      b = (filesize.to_i(16).to_f / blk_len.to_f).ceil
      cnt = "0x" + b.to_s(16)
      return cnt
    end

    def get_filesize(params, timeout)
      self.send_cmd(params, "print filesize", params['dut'].boot_prompt, timeout)
      size = /filesize\s*=\s*(\h+)/im.match(params['dut'].response).captures[0]
      return size
    end

    def flash_run(params, part, timeout)
      case params["#{part}_src_dev"]
      when 'mmc'
        load_file_from_mmc_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
      when 'usbmsc'
        load_file_from_usbmsc_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
      when 'eth'
        load_file_from_eth_now params, params['_env']['loadaddr'], params["#{part}_image_name"], 600
      else
        raise "Unsupported src_dev -- " + params["#{part}_src_dev"] + " for flashing"
      end
      
      txed_size = get_filesize(params, 10)

      case params["#{part}_dst_dev"] ? params["#{part}_dst_dev"] : params["#{part}_dev"]
      when 'nand'
        erase_nand params, params["nand_#{part}_loc"], txed_size, timeout
        write_file_to_nand params, params['_env']['loadaddr'], params["nand_#{part}_loc"], txed_size, timeout
      when /hflash/ # hyperflash 
        erase_mtd params, 'nor0', params["hflash_#{part}_loc"], txed_size, timeout
        write_file_to_mtd params, 'nor0', params['_env']['loadaddr'], params["hflash_#{part}_loc"], txed_size, timeout
      when /spi/ # 'ospi' or 'qspi' or 'spi'
        # Only call probe_spi once due to LCPD-6981
        if params["#{part}_dst_dev"]
          probe_spi params, params["#{part}_dst_dev"], timeout
          erase_spi params, params["#{part}_dst_dev"], params["spi_#{part}_loc"], txed_size, timeout
        else
          probe_spi params, params["#{part}_dev"], timeout
          erase_spi params, params["#{part}_dev"], params["spi_#{part}_loc"], txed_size, timeout
        end
        write_file_to_spi params, params['_env']['loadaddr'], params["spi_#{part}_loc"], txed_size, timeout
      when /rawmmc/ # 'rawmmc-emmc' or 'rawmmc-mmc'
        write_file_to_rawmmc params, params['_env']['loadaddr'], params["rawmmc_#{part}_loc"], txed_size, timeout
      when 'mmc'
        if part.match(/initial_bootloader/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], "tiboot3.bin", txed_size, timeout
        elsif part.match(/sysfw/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], 'sysfw.itb', txed_size, timeout
        elsif part.match(/primary_bootloader/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], CmdTranslator::get_uboot_cmd({'cmd'=>'primary_bootloader_filename', 'version'=>@@uboot_version, 'platform'=>params['dut'].name}), txed_size, timeout
        elsif part.match(/secondary_bootloader/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], "u-boot.img", txed_size, timeout
        elsif part.match(/kernel/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], File.basename(params['kernel_image_name']), txed_size, timeout
        elsif part.match(/dtb/)
          write_file_to_mmc_boot params, params['_env']['loadaddr'], File.basename(params['dtb_image_name']), txed_size, timeout
        end
      when 'usbmsc'
        init_usbmsc(params, timeout)
        if part.match(/primary_bootloader/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], "MLO", txed_size, timeout
        elsif part.match(/secondary_bootloader/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], "u-boot.img", txed_size, timeout
        elsif part.match(/kernel/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], File.basename(params['kernel_image_name']), txed_size, timeout
        elsif part.match(/dtb/)
          write_file_to_usbmsc_boot params, params['_env']['loadaddr'], File.basename(params['dtb_image_name']), txed_size, timeout
        end
      else
        raise "Unsupported dst dev: " + params["#{part}_dev"]
      end
    end

  end

  class FlashBootloaderStep < UbootStep
    def initialize
      super('flash_bootloader')
    end

    def run(params)
      flash_run(params, "sysfw", 60) if params['sysfw'] != ''
      flash_run(params, "initial_bootloader", 60) if params['initial_bootloader'] != ''
      flash_run(params, "primary_bootloader", 60) if params['primary_bootloader'] != ''
      flash_run(params, "secondary_bootloader", 60) if params['secondary_bootloader'] != ''
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
      flash_run(params, "dtb", 120)
    end

  end

  class FlashFSStep < UbootStep
    def initialize
      super('flash_fs')
    end

    def run(params)
      flash_run(params, "fs", 1200)
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
      send_cmd params, "setenv mmcdev '#{params['mmcdev']}'", nil, 2, false, false if params.has_key?('mmcdev')
      send_cmd params, 'setenv _initramfs -'
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
        3.times do |trial|
          begin
            send_cmd params, "dhcp", /DHCP client bound to address.*#{params['dut'].boot_prompt}/im, 40
            break
          rescue Exception => e
            params['dut'].send_abort()
            if trial == 2
              new_e = Exception.new(e.inspect+"\nFailed to dhcp from bootloader")
              new_e.set_backtrace(e.backtrace)
              raise new_e
            end
          end
        end
      end
    end
  end

  class KernelStep < UbootStep
    def initialize
      super('kernel')
    end

    def run(params)
      case params['kernel_dev']
      when 'mmc'
        load_kernel_from_mmc params
      when 'rawmmc'
        load_kernel_from_rawmmc params
      when 'usbmsc'
        load_kernel_from_usbmsc params
      when 'nand'
        load_kernel_from_nand params
      when /spi/ # 'qspi' or 'spi' or 'ospi'
        load_kernel_from_spi params
      when 'eth'
        load_kernel_from_eth params
      when 'ubi'
        load_kernel_from_ubi params
      when 'serial', 'uart'
        load_kernel_from_serial params
      else
        raise "Don't know how to load kernel from #{params['kernel_dev']}"
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
      load_file_from_usbmsc_now params, params['_env']['kernel_loadaddr'], File.basename(params['kernel_image_name'])
    end

    def load_kernel_from_nand(params)
      load_file_from_nand params, params['_env']['kernel_loadaddr'], params["nand_kernel_loc"]
    end

    def load_kernel_from_spi(params)
      # Only call probe_spi once due to LCPD-6981
      probe_spi params, params["kernel_dev"]
      load_file_from_spi params, params['_env']['kernel_loadaddr'], params["spi_kernel_loc"]
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
      case params['dtb_dev']
      when 'mmc'
        load_dtb_from_mmc params
      when 'rawmmc'
        load_dtb_from_rawmmc params
      when 'usbmsc'
        load_dtb_from_usbmsc params
      when 'nand'
        load_dtb_from_nand params
      when /spi/
        load_dtb_from_spi params
      when 'eth'
        load_dtb_from_eth params
      when 'ubi'
        load_dtb_from_ubi params
      when 'serial', 'uart'
        load_dtb_from_serial params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load dtb from #{params['dtb_dev']}"
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
      load_file_from_usbmsc_now params, params['_env']['dtb_loadaddr'], File.basename(params['dtb_image_name'])
    end

    def load_dtb_from_nand(params)
      load_file_from_nand params, params['_env']['dtb_loadaddr'], params["nand_dtb_loc"]
    end

    def load_dtb_from_spi(params)
      # Only call probe_spi once due to LCPD-6981
      probe_spi params, params["dtb_dev"]
      load_file_from_spi params, params['_env']['dtb_loadaddr'], params["spi_dtb_loc"]
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

  class DTBOStep < UbootStep
    def initialize
      super('dtbo')
    end

    def run(params)
      resize_already = false
      params.select{|k| k.match /dtbo_\d+$/}.each {|key,value|
        case params['dtb_dev']
        when 'mmc'
          load_dtbo_from_mmc params, params[key+'_image_name']
        when 'eth'
          load_dtbo_from_eth params, params[key+'_image_name']
        else
          next
        end
        self.send_cmd(params, "fdt address #{params['_env']['dtb_loadaddr']};fdt resize 0x100000", params['dut'].boot_prompt, 10) if !resize_already
        resize_already = true
        self.send_cmd(params, "fdt apply #{params['_env']['overlayaddr']}", params['dut'].boot_prompt, 10)
      }
    end

    private
    def load_dtbo_from_mmc(params, filename)
      load_file_from_mmc params, params['_env']['overlayaddr'], filename
    end

    def load_dtbo_from_eth(params, filename)
      load_file_from_eth_now params, params['_env']['overlayaddr'], filename
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

  class PmmcStep < SystemLoader::UbootStep
    def initialize
      super('pmmc')
    end
    def run(params)
      case params['pmmc_dev']
      when 'eth'
        load_pmmc_from_eth params
      when 'ubi'
        load_pmmc_from_ubi params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load pmmc from #{params['pmmc_dev']}"
      end
      if params['pmmc_dev'] != 'none'
        pmmc_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'run_pmmc', 'version'=>@@uboot_version})
        self.send_cmd(params, pmmc_cmd, params['dut'].boot_prompt, 60)
      end
    end

    private
    def load_pmmc_from_eth(params)
      load_file_from_eth_now params, '${loadaddr}', params['pmmc_image_name']
    end

    def load_pmmc_from_ubi(params)
      self.send_cmd(params, "ubifsload ${loadaddr} #{params['pmmc_image_name']}", params['dut'].boot_prompt, 60)
    end

  end

  class AtfStep < SystemLoader::UbootStep
    def initialize
      super('atf')
    end
    def run(params)
      case params['atf_dev']
      when 'eth'
        load_atf_from_eth params
      when 'ubi'
        load_atf_from_ubi params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load atf from #{params['atf_dev']}"
      end
    end

    private
    def load_atf_from_eth(params)
      load_file_from_eth_now params, '0x70000000', params['atf_image_name']
    end

    def load_atf_from_ubi(params)
      self.send_cmd(params, "ubifsload 0x70000000 #{params['atf_image_name']}", params['dut'].boot_prompt, 60)
    end

  end


  class TeeosStep < SystemLoader::UbootStep
    def initialize
      super('teeos')
    end
    def run(params)
      case params['teeos_dev']
      when 'eth'
        load_teeos_from_eth params
      when 'ubi'
        load_teeos_from_ubi params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load teeos from #{params['teeos_dev']}"
      end
    end

    private
    def load_teeos_from_eth(params)
      load_file_from_eth_now params, '${tee_loadaddr}', params['teeos_image_name']
    end

    def load_teeos_from_ubi(params)
      self.send_cmd(params, "ubifsload ${tee_loadaddr} #{params['teeos_image_name']}", params['dut'].boot_prompt, 60)
    end

  end

  class LinuxSystemStep < SystemLoader::UbootStep
    def initialize
      super('linux_system')
    end
    def run(params)
      case params['linux_system_dev']
      when 'eth'
        load_linux_system_from_eth params
      when 'ubi'
        load_linux_system_from_ubi params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load linux_system from #{params['linux_system_dev']}"
      end
    end

    private
    def load_linux_system_from_eth(params)
      load_file_from_eth_now params, '0x80000000', params['linux_system_image_name']
    end

    def load_linux_system_from_ubi(params)
      self.send_cmd(params, "ubifsload 0x80000000 #{params['linux_system_image_name']}", params['dut'].boot_prompt, 60)
    end

  end


  class FitImageStep < SystemLoader::UbootStep
    def initialize
      super('fitimage')
    end
    def run(params)
      fit_config = "#" + "${fdtfile}#{params['fit_config_suffix']}"
      fit_boot_cmd = "run findfdt; run get_overlaystring; printenv; iminfo #{params['_env']['fitaddr']}; run run_fit;"
      if params['dut'].name == 'k2e-hsevm'
        # TODO: remove once findfdt is defined in k2e-hsevm boot environment
        fit_boot_cmd = "bootm #{params['_env']['fitaddr']}#keystone-k2e-evm.dtb;"
      end
      case params['fit_dev']
      when 'eth'
        load_fit_from_eth params
        append_text params, 'bootcmd', fit_boot_cmd
      when 'ubi'
        load_fit_from_ubi params
        append_text params, 'bootcmd', fit_boot_cmd
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load FitImage from #{params['fit_dev']}"
      end
    end

    private
    def load_fit_from_eth(params)
      load_file_from_eth_now params, params['_env']['fitaddr'], params['fit_image_name'], 180
    end

    def load_fit_from_ubi(params)
      self.send_cmd(params, "ubifsload #{params['_env']['fitaddr']} #{params['fit_image_name']}", params['dut'].boot_prompt, 180)
    end

  end

  class InitRamfsStep < SystemLoader::UbootStep
    def initialize
      super('initramfs')
    end
    def run(params)
        case params['initramfs_dev']
        when 'eth'
          load_initramfs_from_eth params
          send_cmd params, "setenv _initramfs #{params['_env']['ramdisk_loadaddr']}:#{params['_env']['filesize']}"
        when 'ubi'
          load_initramfs_from_ubi params
          send_cmd params, "setenv _initramfs #{params['_env']['ramdisk_loadaddr']}:#{params['_env']['filesize']}"
        when 'none'
          # Do nothing
        else
          raise "Don't know how to load initramfs from #{params['initramfs_dev']}"
      end
    end
    private
    def load_initramfs_from_eth(params)
      load_file_from_eth_now params, params['_env']['ramdisk_loadaddr'], params['initramfs_image_name']
    end

    def load_initramfs_from_ubi(params)
      append_text params, 'bootcmd', "ubifsload #{params['_env']['ramdisk_loadaddr']} #{params['initramfs_image_name']};"
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
      get_nand_pagesize(params)
      append_text params, 'bootargs', "rootfstype=ubifs root=#{params['ubi_root']} rootflags=sync rw ubi.mtd=#{params["nand_fs_loc"]},#{params['nand_eraseblock_size'].to_i}"
    end
    
    def get_nand_pagesize(params)
      return if params.has_key?('nand_eraseblock_size') and params['nand_eraseblock_size'] != ''
      send_cmd params, "nand info"
      pagesize = /Page\s+size\s+([0-9]+)\s*b/im.match(params['dut'].response).captures[0]
      params['nand_eraseblock_size'] = pagesize
    end

    def set_ramfs(params)
      # Avoid relocation of ramfs and device tree data
      send_cmd params, "setenv initrd_high '0xffffffff'"
      send_cmd params, "setenv fdt_high '0x88000000'"
      
      case params['fs_dev']
      when /eth/i
        load_file_from_eth_now params, params['_env']['ramdisk_loadaddr'], params['fs_image_name'], 600  if params['fs_image_name'] && params['fs_image_name'] != ''
        send_cmd params, "setenv _initramfs #{params['_env']['ramdisk_loadaddr']}:#{params['_env']['filesize']}"
      when /mmc/i
        load_file_from_mmc params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
        send_cmd params, "setenv _initramfs #{params['_env']['ramdisk_loadaddr']}:#{params['_env']['filesize']}"
      else
        raise "Don't know how to get ramfs image from #{params['fs_dev']}"
      end
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'ramfs_bootargs', 'version'=>@@uboot_version, 'platform'=>params['dut'].name})
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
      send_cmd params, "printenv", params['dut'].boot_prompt, 10, true, false
    end
  end

  class SetDefaultEnvStep < UbootStep
    def initialize
      super('set_default_env')
    end

    def run(params)
      get_uboot_version params
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'env default', 'version'=>@@uboot_version})
      send_cmd params, "printenv", params['dut'].boot_prompt, 10, true, false
    end
  end
  
  class SetExtraArgsStep < UbootStep
    def initialize
      super('set_extra_args')
    end

    def run(params)
      if params.has_key?("bootargs_append")
        send_cmd params, "setenv extraargs #{CmdTranslator::get_uboot_cmd({'cmd'=>params['bootargs_append'], 'version'=>@@uboot_version, 'platform'=>params['dut'].name})}",params['dut'].boot_prompt,10
        # add extraargs to bootargs for all lines with bootm
        send_cmd params, "printenv", params['dut'].boot_prompt, 10, true, false
        params['dut'].response.split(/\n/).each {|line|
          if line.match(/boot[mzi]\s+/)
            varname = line.split('=')[0]
            varvalue = line.sub(varname + '=', '')
            newvalue = varvalue.gsub(/bootm\s+/, "setenv bootargs ${bootargs} ${extraargs}; bootm ")
            newvalue = newvalue.gsub(/bootz\s+/, "setenv bootargs ${bootargs} ${extraargs}; bootz ")
            newvalue = newvalue.gsub(/booti\s+/, "setenv bootargs ${bootargs} ${extraargs}; booti ")
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
      ramdisk_addr = params['_env']['initramfs']
      dtb_addr     = ''
      dtb_addr = params['_env']['dtb_loadaddr'] if params['dtb_image_name'].strip != ''
      append_text params, 'bootcmd', "if iminfo #{params['_env']['kernel_loadaddr']}; then bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr};"\
                                     " else bootz #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; fi"
    end
  end

  class Arm64BootCmdStep < UbootStep
    def initialize
      super('arm64_boot_cmd')
    end

    def run(params)
      ramdisk_addr = params['_env']['initramfs']
      dtb_addr     = ''
      dtb_addr = params['_env']['dtb_loadaddr'] if params['dtb_image_name'].strip != ''
      append_text params, 'bootcmd', "if iminfo #{params['_env']['kernel_loadaddr']}; then bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr};"\
                                     " else booti #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; fi"
    end
  end

  class BootStep < UbootStep
    def initialize
      super('boot')
    end

    def run(params)
      boot_timeout = params['var_boot_timeout'] ? params['var_boot_timeout'].to_i : 210

      params['dut'].target.default = params['dut'].target.serial
      send_cmd params, "boot", params['dut'].login_prompt, boot_timeout, true, false

      params['dut'].boot_log = params['dut'].response
      raise "DUT rebooted while Starting Kernel" if params['dut'].boot_log.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
      params['dut'].check_for_boot_errors()
      if params['dut'].timeout?
        params['dut'].log_info("Collecting kernel traces via sysrq...")
        params['dut'].send_sysrq('t')
        params['dut'].send_sysrq('l')
        params['dut'].send_sysrq('w')
      end
      3.times {
        send_cmd params, params['dut'].login, params['dut'].prompt, 40, false, false # login to the unit
        break if !params['dut'].timeout?
      }
      raise "Error executing boot" if params['dut'].timeout?
    end

  end

  class BootAutologinStep < UbootStep
    def initialize
      super('boot_autologin')
    end

    def run(params)
      boot_timeout = params['var_boot_timeout'] ? params['var_boot_timeout'].to_i : 210

      send_cmd params, "boot", /.*/, 1, true, false
      params['dut'].target.default = params['dut'].target.serial
      send_cmd params, "", params['dut'].prompt, boot_timeout, true, false

      params['dut'].boot_log = params['dut'].response
      raise "DUT rebooted while Starting Kernel" if params['dut'].boot_log.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
      params['dut'].check_for_boot_errors()
      if params['dut'].timeout?
        params['dut'].log_info("Collecting kernel traces via sysrq...")
        params['dut'].send_sysrq('t')
        params['dut'].send_sysrq('l')
        params['dut'].send_sysrq('w')
        raise "Error executing boot"
      end
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
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'get_clk_info', 'version'=>@@uboot_version, 'platform'=>params['dut'].name})
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

  class InstallK2SecBMStep < UbootStep
    def initialize
      super('install_k2_sec_bm')
    end

    def run(params)
      get_uboot_version params if !@@uboot_version
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'k2_sec_bm_install', 'version'=>@@uboot_version, 'platform'=>params['dut'].name}), params['dut'].boot_prompt
    end

  end

  class GenerateRandomMacStep < UbootStep
    def initialize
      super('gen_random_mac')
    end

    def run(params)
      mac=[]
      6.times do mac << rand(255).to_s(16) end
      macstr= mac*":"
      send_cmd params, "setenv ethaddr #{macstr}"
    end
  end
  
  class ResetMd5InfoStep < UbootStep
    def initialize
      super('reset_md5_info_env')
    end

    def run(params)
      get_environment(params)
      params['_env'].each do |k,v|
        send_cmd params, "setenv #{k}" if k.end_with?('_md5')
      end
      send_cmd params, "saveenv"
    end
  end

  class OverwriteFindfdtStep < UbootStep
    def initialize
      super('overwrite_findfdt_step')
    end

    def run(params)
      send_cmd params, "setenv findfdt \"setenv name_fdt #{params['dtb_image_name']}\"" if params['dtb_image_name'].to_s != ''
    end
  end

  class LoadRemoteProcStep < UbootStep
    def initialize
      super('load_remoteproc_step')
    end

    def run(params)
      if params['start_remoteproc_cmd'].to_s != ''
         remoteproc_start_cmd=params['start_remoteproc_cmd']
         send_cmd params, "#{remoteproc_start_cmd}"
      end
    end
  end


  class StartSimulatorStep < Step
    attr_reader :simulator_socket, :simulator_stdin, :simulator_stdout, :simulator_stderr, :simulator_thread
    def initialize
      super('start_simulator')
      @simulator_socket_regex=/Opened listening socket on port (\d+) for virtual terminal usart0/
    end

    def log_data(params, msg)
      Kernel.print msg
      params['server'].log_info("SIMULATOR: #{msg}")
    end

    def stop_at_boot_prompt(params)
      dut = params['dut']
      dut.connect({'type'=>'serial'})
      b_prompt_th = Thread.new do
        dut.send_cmd("", dut.boot_prompt, 40, false)
      end
      2400.times {
        dut.target.serial.puts(" ")
        dut.target.serial.flush
        s_time = Time.now()
        while Time.now() - s_time < 0.1
          #busy wait
        end
        break if !b_prompt_th.alive?
      }
      b_prompt_th.join()
      raise "Failed to load bootloader" if dut.target.bootloader.timeout?
    end

    def run(params)
      begin
        log_data(params, "Sleeping 2 secs to avoid Simulator init errors\n")
        sleep 2
        Timeout::timeout(240) {
          @simulator_response = ''
          @simulator_stdin, @simulator_stdout, @simulator_stderr, @simulator_thread = Open3.popen3('sh 2>&1')
          log_data(params, "Parsing parameters\n")
          cmd="#{params['dut'].params['simulator_startup_cmd']} "
          script_file = params['dut'].params['simulator_python_script']
          cmd += script_file
          cmd += " @@atf #{params['atf']}" if params.key?('atf') and params['atf'].to_s != ''
          cmd += " @@atf_fdt #{params['atf_fdt']}" if params.key?('atf_fdt') and params['atf_fdt'].to_s != ''
          cmd += " @@dmsc #{params['dmsc']}" if params.key?('dmsc') and params['dmsc'].to_s != ''
          cmd += " @@tee #{params['teeos']}" if params.key?('teeos') and params['teeos'].to_s != ''
          cmd += " @@linux_system #{params['linux_system']}" if params.key?('linux_system') and params['linux_system'].to_s != ''
          cmd += "'" if cmd.match(/'/)
          log_data(params, "Starting simulator with command:\n#{cmd}\n")
          @simulator_stdin.puts("#{cmd}")
          sleep 1
          while !@simulator_response.match(@simulator_socket_regex)
            if !@simulator_stdout.eof?
              last_read = @simulator_stdout.read_nonblock(1024)
              log_data(params, last_read)
              @simulator_response += last_read
           end
          end
          log_data(params, "Simulator started at socket #{@simulator_response.match(@simulator_socket_regex).captures[0]}\n")
          @simulator_socket = @simulator_response.match(@simulator_socket_regex).captures[0]
          params['dut'].target.platform_info.serial_server_port = @simulator_socket
          stop_at_boot_prompt(params)
        }
      rescue Timeout::Error => e
        puts "TIMEOUT Starting Simulator"
        Process.kill("KILL", @simulator_thread.pid)
        raise "TIMEOUT Starting Simulator.\n#{@simulator_response}"
      end

    end

  end

  class StartFastbootStep < UbootStep
    def initialize
      super('start_fastboot')
    end

    def run(params)
      fb_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'start_fastboot',
                                    'version'=>@@uboot_version,
                                    'platform' => params['dut'].name})
      send_cmd params, fb_cmd, nil, 2, true, false
      raise "Unable to start fastboot" if !params['dut'].timeout?
    end
  end

  class FastbootStep < UbootStep
    @@updated_imgs = {}
    @@must_flash = false
    def initialize(name='')
      super(name)
      @partition_tx_table = Hash.new {|h,k| h[k] = k}
      @partition_tx_table.merge!({
        'primary_bootloader'   => 'xloader',
        'secondary_bootloader' => 'bootloader',
        'dtb'                  => 'environment',
        })
    end

    def fastboot_cmd(params, cmd, timeout=20, expect=/OKAY.*finished.\s*total\s*time:[^\r\n]+/im, raise_on_error=true)
      params['server'].send_sudo_cmd("ANDROID_PRODUCT_OUT=#{params['workdir']}/tar_folder #{params['fastboot']} -s #{params['dut'].board_id} #{cmd}", expect, timeout)
      if raise_on_error && params['server'].timeout?
        send_cmd params, "\x03", nil, 20, false
        @@updated_imgs.each do |i_name, i_md5|
          send_cmd params, "setenv #{i_name} #{i_md5}" 
        end
        send_cmd params, "saveenv" if  @@updated_imgs.length > 0
        raise "Error executing #{cmd}" 
      end
      params['server'].response
    end

    def should_flash?(params, part)
      params['server'].send_cmd("md5sum #{params[part]} | cut -d' ' -f 1")
      @@must_flash || (params['_env']["#{part}_md5"] != params['server'].response.strip)
    end

    def flash_run(params, part, timeout=60)
      if should_flash?(params, part)
        fastboot_cmd(params, "flash #{@partition_tx_table[part]} #{params[part]}", timeout, /OKAY.*OKAY.*finished.\s*total\s*time:[^\r\n]+/im)
        params['server'].send_cmd("md5sum #{params[part]} | cut -d' ' -f 1")
        @@updated_imgs["#{part}_md5"] = params['server'].response.strip
      end
    end
    
    def erase_partition(params, part, timeout=20)
      if params.has_key?(part) && params[part] == nil && params['_env']["#{part}_md5"] != 'nil' 
        fastboot_cmd(params, "erase #{@partition_tx_table[part]}", timeout, /OKAY.*OKAY.*finished.\s*total\s*time:[^\r\n]+/im, false)
        @@updated_imgs["#{part}_md5"] = 'nil'
      end
    end

    def resize_image(params, orig_image, new_image)
      result = nil
      resized_data= "#{params['workdir']}/#{new_image}"
      raw_data = "#{params['workdir']}/#{File.basename(orig_image)}.raw"
      data_dir = "#{params['workdir']}/data"
      if params['make_fs'] && params['simg2img']
        data_size = 0
        begin
          params['server'].send_cmd("#{params['fastboot']} getvar userdata_size", /finished.*total\s*time:[^\r\n]+/)
          data_size = params['server'].response.match(/userdata_size:([^\r\n]+)/im).captures[0].to_i
          if data_size > 0
            params['server'].send_cmd("rm -rf #{data_dir} #{raw_data} #{resized_data}",/.*/,60)
            if params['server'].response == ''
              params['server'].send_cmd("mkdir #{data_dir}",/.*/,10)
              if params['server'].response == ''
                params['server'].send_cmd("#{params['simg2img']} #{orig_image} #{raw_data}",/.*/,60)
                if params['server'].response == ''
                  params['server'].send_sudo_cmd("mount -o loop -o grpid -t ext4 #{raw_data} #{data_dir}")
                  if params['server'].response == ''
                    params['server'].send_cmd("#{params['make_fs']} -s -l #{data_size}K -a data #{resized_data} #{data_dir}/",/.*/,60)
                    if !params['server'].response.match(/error/im)
                      result = resized_data
                    end
                    params['server'].send_cmd("sync",/.*/,60)
                    params['server'].send_sudo_cmd("umount #{data_dir}")
                    params['server'].send_cmd("sync",/.*/,60)
                  end
                end
              end
            end
          end
        rescue Exception => e
          puts e.to_s
          params['server'].log_error(e.to_s)
        end
      end
      result
    end
  end

  class FastbootResetEnvStep < FastbootStep
    def initialize
      super('fastboot_reset_env')
    end

    def run(params)
      if @@must_flash || params['run_fastboot.sh']
        send_cmd params, "env default -f -a", params['dut'].boot_prompt
        params['dut'].set_fastboot_partitions(params)
      end
      if @@must_flash || params['_env']['serial#'] != params['dut'].board_id || params['run_fastboot.sh']
        raise "Error: Must define board_id in the dut section at the bench file" if !params['dut'].respond_to? :board_id
        send_cmd params, "setenv serial# #{params['dut'].board_id}", params['dut'].boot_prompt
        send_cmd params, "saveenv", params['dut'].boot_prompt
      end
    end
  end

  class FastbootRunScript < FastbootStep
    def initialize
      super('fastboot_run_fastboot.sh')
    end

    def run(params)
      if params['run_fastboot.sh']
        this_sysboot = SysBootModule::get_sysboot_setting(params['dut'], params['dut'].get_fastboot_media_type())
        SysBootModule::set_sysboot(params['dut'], this_sysboot)
        params['server'].send_cmd("cd #{params['fastboot_path']}; ./fastboot.sh", /OKAY.*finished.\s*total\s*time:[^\r\n]+/im, 700)
        raise "Error: Host timed out running #{File.join(params['fastboot_path'], 'fastboot.sh')}" if params['server'].timeout?
        @@updated_imgs['tarball_md5'] = params['tarball_md5']
      end
    end
  end

  class SetOSBootcmdStep < UbootStep
    def initialize
      super('os_bootcmd')
    end

    def run(params)
      params['dut'].set_os_bootcmd(params)
    end
  end

  class StopFastbootStep < FastbootStep
    def initialize
      super('stop_fastboot')
    end

    def run(params)
      @@must_flash = false
      send_cmd params, "\x03", nil, 20, false
    end
  end

  class FastbootCreatePartitionsStep < FastbootStep
    def initialize
      super('fastboot_create_partitions')
    end
    
    def run(params)
      if @@must_flash
        fastboot_cmd(params, 'oem format')
      end
    end
  end

  class CheckFastbootRequiredStep < UbootStep
    def initialize
      super('check_fastboot_required')
    end

    def run(params)
      send_cmd params, "printenv tarball_md5", params['dut'].boot_prompt
      match = params['dut'].response.match(/tarball_md5=([a-f0-9]+)/)
      if match && match[1] == params['tarball_md5'].strip
        params['run_fastboot.sh'] = false
      else
        params['run_fastboot.sh'] = true
      end
      rescue Exception => e
         params['dut'].recover_bootloader(params)
         params['run_fastboot.sh'] = true
      ensure
        get_environment(params)
    end
  end


  class GptWriteStep < UbootStep
    def initialize
      super('gpt_write')
    end

    def run(params)
      if params['run_fastboot.sh']
        send_cmd params, "gpt write mmc 0 $partitions_android", params['dut'].boot_prompt, 30 # TODO: Replace mmc 0 with dynamic logic
      end
    end
  end

  class FastbootSetBootloaderTargetStep < FastbootStep
    def initialize
      super('fastboot_set_flash_target')
    end

    def run(params)
      dev_table = Hash.new() { |h,k| h[k] = k }
      dev_table['qspi'] = 'spi'
      dev_table['emmc'] = nil
      dev_table['rawmmc-emmc'] = nil
      if @@must_flash && params['primary_bootloader'].to_s != '' && params['secondary_bootloader'].to_s != ''
        flash_dev = params['primary_bootloader_dev'].sub('none','') != '' ? params['primary_bootloader_dev'] : params['secondary_bootloader_dev'].sub('none','') != '' ? params['secondary_bootloader_dev'] : nil
        raise "bootloader tartget was not specified" if !flash_dev
        fastboot_cmd(params, "oem #{dev_table[flash_dev]}") if dev_table[flash_dev]
      end
    end
  end

  class FastbootPrepBootloaderStep < FastbootStep
    def initialize
      super('fastboot_prep_bootloader')
    end

    def run(params)
      get_environment(params)
      if params['primary_bootloader'].to_s != '' && params['secondary_bootloader'].to_s != '' && 
        (should_flash?(params, 'primary_bootloader') || should_flash?(params, 'secondary_bootloader')) && !params['run_fastboot.sh']
        @@must_flash = true
        params['dut'].update_bootloader(params)
      end
    end
  end

  class FastbootFlashBootloaderStep < FastbootStep
    def initialize
      super('fastboot_flash_bootloader')
    end

    def run(params)
      flash_run(params, 'primary_bootloader') if params['primary_bootloader'].to_s != ''
      flash_run(params, 'secondary_bootloader') if params['secondary_bootloader'].to_s != ''
    end
  end
  
  class FastbootRebootBootloaderStep < FastbootStep
    def initialize
      super('fastboot_reboot_bootloader')
    end

    def run(params)
      params['dut'].boot_to_bootloader(params) if @@must_flash
    end
  end
  
  class FastbootFlashBootPartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_boot_partition')
    end

    def run(params)
      flash_run(params, 'boot') if params['boot'].to_s != ''
    end
  end
  
  class FastbootFlashDTBStep < FastbootStep
    def initialize
      super('fastboot_flash_dtb')
    end

    def run(params)
      erase_partition(params, 'dtb', timeout=20)
      flash_run(params, 'dtb') if params['dtb'].to_s != ''
    end
  end

  class FastbootFlashRecoveryPartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_recovery_partition')
    end

    def run(params)
      flash_run(params, 'recovery') if params['recovery'].to_s != ''
    end
  end

  class FastbootFlashSystemPartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_system_partition')
    end

    def run(params)
      flash_run(params, 'system', 180) if params['system'].to_s != ''
    end
  end

  class FastbootFlashCachePartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_cache_partition')
    end

    def run(params)
      flash_run(params, 'cache') if params['cache'].to_s != ''
    end
  end

  class FastbootFlashUserDataPartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_userdata_partition')
    end

    def run(params)
      if params['userdata'].to_s != ''
        #new_image = resize_image(params, params['userdata'], 'resized_userdata.img')
        #params['userdata'] = new_image if new_image
        flash_run(params, 'userdata', 300)
      end
    end
  end

  class FastbootFlashVendorPartitionStep < FastbootStep
    def initialize
      super('fastboot_flash_vendor_partition')
    end

    def run(params)
      if params['vendor'].to_s != ''
        flash_run(params, 'vendor')
      end
    end
  end

  class SaveImagesInfo < FastbootStep
    def initialize
      super('save_images_info')
    end
    
    def run(params)
      @@updated_imgs.each do |i_name, i_md5|
        send_cmd params, "setenv #{i_name} #{i_md5}" 
      end
      send_cmd params, "saveenv" if  @@updated_imgs.length > 0
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
      rescue Exception => e
        raise SystemloaderException.new(e)
    end
  end

  class UbootSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( PmmcStep.new )
      add_step( KernelStep.new )
      add_step( DTBStep.new )
      add_step( DTBOStep.new )
      add_step( SkernStep.new )
      add_step( InitRamfsStep.new )
      add_step( FSStep.new )
      add_step( BootCmdStep.new )
      add_step( BoardInfoStep.new )
      add_step( TouchCalStep.new )
      add_step( BootStep.new )
    end

  end

  class AtfSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( SetIpStep.new )
      add_step( AtfStep.new )
      add_step( TeeosStep.new )
      add_step( LinuxSystemStep.new )
      add_step( BoardInfoStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootKernelSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( PmmcStep.new )
      add_step( KernelStep.new )
      add_step( DTBStep.new )
      add_step( DTBOStep.new )
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


  class UbootFitSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( PmmcStep.new )
      add_step( InitRamfsStep.new )
      add_step( FSStep.new )
      add_step( FitImageStep.new )
      add_step( BoardInfoStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootFlashBootloaderSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( ResetMd5InfoStep.new )
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( BoardInfoStep.new )
      add_step( FlashBootloaderStep.new )
    end

  end

  class UbootFlashKernelSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( ResetMd5InfoStep.new )
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( BoardInfoStep.new )
      add_step( FlashKernelStep.new )
      add_step( FlashDTBStep.new )
    end

  end

  class UbootFlashFSSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( ResetMd5InfoStep.new )
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( BoardInfoStep.new )
      add_step( FlashFSStep.new )
    end

  end

  class UbootFlashBootloaderKernelSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( ResetMd5InfoStep.new )
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashBootloaderStep.new )
      add_step( FlashKernelStep.new )
      add_step( FlashDTBStep.new )
    end

  end

  class UbootFlashAllSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( ResetMd5InfoStep.new )
      add_step( PrepStep.new )
      add_step( SetIpStep.new )
      add_step( FlashBootloaderStep.new )
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

  class SimulatorSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( StartSimulatorStep.new )
      add_step( BoardInfoStep.new )
      add_step( OverwriteFindfdtStep.new )
      add_step( LoadRemoteProcStep.new )
      add_step( BootStep.new )
    end

  end

  class FastbootFlashSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( FastbootPrepBootloaderStep.new )
      add_step( FastbootResetEnvStep.new )
      add_step( FastbootRebootBootloaderStep.new )
      add_step( StartFastbootStep.new )
      add_step( FastbootCreatePartitionsStep.new)
      add_step( FastbootSetBootloaderTargetStep.new )
      add_step( FastbootFlashBootloaderStep.new )
      add_step( StopFastbootStep.new )
      add_step( FastbootRebootBootloaderStep.new )
      add_step( StartFastbootStep.new )
      add_step( FastbootCreatePartitionsStep.new)
      add_step( FastbootFlashBootPartitionStep.new )
      add_step( FastbootFlashDTBStep.new )
      add_step( FastbootFlashRecoveryPartitionStep.new )
      add_step( FastbootFlashSystemPartitionStep.new )
      add_step( FastbootFlashVendorPartitionStep.new )
      add_step( FastbootFlashUserDataPartitionStep.new )
      add_step( FastbootFlashCachePartitionStep.new )
      add_step( StopFastbootStep.new )
      add_step( SaveImagesInfo.new )
      add_step( BoardInfoStep.new )
      add_step( SetOSBootcmdStep.new )
      add_step( BootStep.new )
    end

  end

  class FastbootScriptSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( CheckFastbootRequiredStep.new )
      add_step( FastbootResetEnvStep.new )
      add_step( GptWriteStep.new)
      add_step( SaveEnvStep.new)
      add_step( StartFastbootStep.new )
      add_step( FastbootRunScript.new )
      add_step( StopFastbootStep.new )
      add_step( SaveImagesInfo.new )
      add_step( PowerCycleStep.new )
      add_step( BootStep.new )
    end

  end

end
