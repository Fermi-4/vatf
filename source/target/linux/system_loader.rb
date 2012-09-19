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
      end
      params['_env']['kernel_loadaddr'] = load_addr
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
      end
      params['_env']['ramdisk_loadaddr'] = load_ramdisk_addr
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

  end

  class PrepStep < UbootStep
    def initialize
      super('prep')
    end

    def run(params)
      get_uboot_version params
      send_cmd params, "setenv bootargs '#{params['bootargs']} '"
      send_cmd params, "setenv bootcmd  ''"
      send_cmd params, "setenv serverip '#{params['server'].telnet_ip}'"
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
      else
        raise "Don't know how to set #{params['fs_type']} filesystem"
      end
    end
    
    private
    def set_nfs(params)
      append_text params, 'bootargs', "root=/dev/nfs rw nfsroot=#{params['nfs_path']},nolock "
    end
    
    def set_ramfs(params)
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

  class BootStep < UbootStep
    def initialize
      super('boot')
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
      append_text params, 'bootcmd', "bootm #{params['_env']['kernel_loadaddr']} #{ramdisk_addr} #{dtb_addr} "
      send_cmd params, "boot", params['dut'].login_prompt, 180
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

    def insert_step_before(name, new_step)
      index = @steps.index {|step| step.name == name.downcase.strip}
      raise "#{name} step does not exist" if !index
      @steps.insert(index, new_step)
    end

    def remove_step(name)
      @steps.select! {|step| step.name != name.downcase.strip }
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
      add_step( BootStep.new )
    end

  end

end
