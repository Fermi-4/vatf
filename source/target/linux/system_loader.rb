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

    def send_cmd(params, cmd, expect=nil, timeout=20)
      expect = params['dut'].boot_prompt if !expect
      params['dut'].send_cmd(cmd, expect, timeout)
      raise "Error executing #{cmd}" if params['dut'].timeout?
    end

    def get_uboot_version(params)
      return @@uboot_version if @@uboot_version
      params['dut'].send_cmd("", params['dut'].boot_prompt, 5)
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
    end

    def append_text(params, env_var, text)
      send_cmd params, CmdTranslator::get_uboot_cmd({'cmd'=>'printenv', 'version'=>@@uboot_version})
      if !params['dut'].response.match(/^#{env_var}=.*#{text}.*/)
        send_cmd params, "setenv #{env_var} ''${#{env_var}}' #{text}'"
      end
    end

    def load_file_from_mmc(params, load_addr, filename)
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      append_text params, 'bootcmd', "#{mmc_init_cmd}; "
      append_text params, 'bootcmd', "fatload mmc #{params['_env']['mmcdev']} #{load_addr} #{filename}; "
    end

    def load_file_from_eth(params, load_addr, filename)
      tftp_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'tftp', 'version'=>@@uboot_version})
      append_text params, 'bootcmd', "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}; "
    end
    
    def load_file_from_eth_now(params, load_addr, filename, timeout=60)
        tftp_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'tftp', 'version'=>@@uboot_version})
        set_ipaddr(params)
        self.send_cmd(params, "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}", @boot_prompt, timeout)
        raise "load_file_from_eth_now failed to load #{filename}" if params['dut'].response.match(/error/i)
    end

    def load_file_from_mmc_now(params, load_addr, filename, timeout=60)
      raise "load_file_from_mmc_now: no filename is provided." if !filename
      mmc_init_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'mmc init', 'version'=>@@uboot_version})
      self.send_cmd(params, "#{mmc_init_cmd}; fatload mmc #{params['_env']['mmcdev']} #{load_addr} #{filename} ", @boot_prompt, timeout)
    end

    # if ipaddr was not set yet, set it using dhcp
    # TODO: if needed in the future, it can be set statically here.
    def set_ipaddr(params, static_ip=false)
        self.send_cmd params, "print ipaddr"
        if params['dut'].response.match(/error/i)
          if !static_ip
            self.send_cmd(params, "dhcp", @boot_prompt, 60)
          end
        end
    end

    def erase_nand(params, nand_loc, size, timeout=60)
      self.send_cmd(params, "nand erase #{nand_loc} #{size}", @boot_prompt, timeout)
      raise "erase_nand failed!" if !params['dut'].response.match(/100\%\s+complete/i) 
    end

    def write_file_to_nand(params, mem_addr, nand_loc, size, timeout=60)
      self.send_cmd(params, "nand write #{mem_addr} #{nand_loc} #{size}", @boot_prompt, timeout)
      raise "write to nand failed!" if !params['dut'].response.match(/bytes\s+written:\s+OK/i) 
    end

    def flash_run(params, part, timeout)
      case params["#{part}_src_dev"]
      when 'mmc'
        load_file_from_mmc_now params, params['_env']['loadaddr'], params["#{part}_image_name"]
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
      send_cmd params, "setenv bootargs '#{params['bootargs']} '"
      send_cmd params, "setenv bootcmd  ''"
      send_cmd params, "setenv autoload 'yes'"
      send_cmd params, "setenv serverip '#{params['server'].telnet_ip}'"
      if  params.has_key?'uboot_user_cmds'
        params['uboot_user_cmds'].each{|uboot_cmd|
          send_cmd params, uboot_cmd
        }
      end
      get_environment(params)
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
      when 'eth'
        load_kernel_from_eth params
      when 'ubi'
        load_kernel_from_ubi params
      else
        raise "Don't know how to load kernel from #{params['kernel_dev']}"
      end
    end

    private
    def load_kernel_from_mmc(params)
      load_file_from_mmc params, params['_env']['kernel_loadaddr'], params['kernel_image_name']
    end

    def load_kernel_from_eth(params)
      send_cmd params, "setenv serverip '#{params['server'].telnet_ip}'"
      append_text params, 'bootcmd', "dhcp #{params['_env']['kernel_loadaddr']} #{params['server'].telnet_ip}:#{params['kernel_image_name']}; "
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
      when 'eth'
        load_dtb_from_eth params
      when 'ubi'
        load_dtb_from_ubi params
      when 'none'
        # Do nothing
      else
        raise "Don't know how to load dtb from #{params['dtb_dev']}"
      end
    end

    private
    def load_dtb_from_mmc(params)
      load_file_from_mmc params, params['_env']['dtb_loadaddr'], params['dtb_image_name']
    end

    def load_dtb_from_eth(params)
      load_file_from_eth params, params['_env']['dtb_loadaddr'], params['dtb_image_name']
    end
    
    def load_dtb_from_ubi(params)
      append_text params, 'bootcmd', "ubifsload #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']};"
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
      params['fs_options'] = ",nolock" if !params['fs_options']
      append_text params, 'bootargs', "root=/dev/nfs rw nfsroot=#{params['nfs_path']}#{params['fs_options']} "
    end
    
    def set_ubifs(params)
      append_text params, 'bootargs', "rootfstype=ubifs root=#{params['ubi_root']} rootflags=sync rw ubi.mtd=#{params['ubi_mtd_partition']},#{params['nand_eraseblock_size'].to_i}"
    end
    
    def set_ramfs(params)
      # Make sure file have required headers (i.e. mkimage have been run)
      y=`mkimage -l /tftpboot/#{params['fs_image_name']}`
      if !y.match(/Image\s+Name:\s+Arago\s+Test\s+Image/i)
        ramdisk_image_name="#{File.dirname params['fs_image_name']}/uRamdisk"
        x=`mkimage -A arm -T ramdisk -C gzip -n 'Arago Test Image' -d /tftpboot/#{params['fs_image_name']} /tftpboot/#{ramdisk_image_name}`
        raise "Could not run mkimage on #{params['fs_image_name']}" if !x.match(/Image\s+Name:\s+Arago\s+Test\s+Image/i)
        params['fs_image_name']=ramdisk_image_name
      end

      # Avoid relocation of ramfs and device tree data
      send_cmd params, "setenv initrd_high '0xffffffff'"
      send_cmd params, "setenv fdt_high '0xffffffff'"
      
      case params['fs_dev']
      when /eth/i
        load_file_from_eth params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
      when /mmc/i
        load_file_from_mmc params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
      else
        raise "Don't know how to get ramfs image from #{params['fs_dev']}"
      end
      append_text params, 'bootargs', "root=/dev/ram rw "
    end
    
    def set_mmcfs(params)
      append_text params, 'bootargs', "root=/dev/mmcblk0p2 rw rootfstype=ext3 rootwait "
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
            send_cmd params, "setenv #{varname} \'#{newvalue}\'", params['dut'].boot_prompt, 10
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
                                     " else bootz #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr}; fi"
    end
  end

  class BootStep < UbootStep
    def initialize
      super('boot')
    end

    def run(params)
      send_cmd params, "boot", params['dut'].login_prompt, 300
      send_cmd params, params['dut'].login, params['dut'].prompt, 10 # login to the unit
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

    def run(params)
      @steps.each {|step| step.run(params)}
    end
  end

  class UbootSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( KernelStep.new )
      add_step( DTBStep.new )
      add_step( FSStep.new )
      add_step( BootCmdStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootDefaultEnvSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( SetDefaultEnvStep.new )
      add_step( BootStep.new )
    end

  end

  class UbootLetItGoSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( BootStep.new )
    end

  end

  class UbootFlashBootloaderSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( FlashPrimaryBootloaderStep.new )
      add_step( FlashSecondaryBootloaderStep.new )
    end

  end

  class UbootFlashKernelSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( FlashKernelStep.new )
    end

  end

  class UbootFlashFSSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( FlashFSStep.new )
    end

  end

  class UbootFlashAllSystemLoader < BaseSystemLoader
    attr_accessor :steps

    def initialize
      super
      add_step( PrepStep.new )
      add_step( FlashPrimaryBootloaderStep.new )
      add_step( FlashSecondaryBootloaderStep.new )
      add_step( FlashKernelStep.new )
      add_step( FlashFSStep.new )
    end

  end
end
