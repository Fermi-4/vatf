require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxTCI6614Driver < LinuxEquipmentDriver

    def set_api(dummy_var)
    end
    
    def get_boot_cmd(params)
    cmds = []
    if !params['dtb_file']
      cmds << " "
    else
      addr_fdt = '0x80000200'
      setup_bootfile(params['dtb_file'],params)
      # get_bootfile(addr_fdt)
      setup_bootfile(params['image_path'],params)
      addr_kernel = '0x88000000'
      # get_bootfile(addr_kernel)
      cmds << "setenv serverip #{params['server'].telnet_ip}"
      cmds << "set path_kernel #{params['target'].downcase.strip}/#{params['platform'].downcase.strip}/#{File.basename(params['image_path'])}"
      cmds << "set path_fdt #{params['target'].downcase.strip}/#{params['platform'].downcase.strip}/#{File.basename(params['dtb_file'])}"
      cmds << "set \"update_fdt_kernel setenv bootfile ${path_fdt}; tftp ${addr_fdt}; setenv bootfile ${path_kernel}; tftp ${addr_kernel}\""
      cmds << "setenv bootcmd 'run update_fdt_kernel ; bootm #{addr_kernel} - #{addr_fdt}'"
      bootargs = params['bootargs'] ? "setenv bootargs #{params['bootargs']}" : "setenv bootargs #{@boot_args} root=/dev/nfs nfsroot=${nfs_root_path},v3,tcp rw"
      cmds << bootargs
    end
      cmds
    end
    
    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader(params=nil)
      connect({'type'=>'serial'}) if !@target.serial
      # Make the code backward compatible, previous API used optional power_handler object as first parameter 
      @power_handler = params if ((!params.instance_of? Hash) and params.respond_to?(:reset) and params.respond_to?(:switch_on))  
      @power_handler = params['power_handler'] if !@power_handler
      if @power_port !=nil and params.instance_of? Hash and params['secondary_bootloader']
        # 08/16/2012: This code will not work if @power_port is not set since 'reset' does not work on tci6614's version of U-Boot
        params['nand_loader'] = method( :write_bootloader_to_nand_via_mtdparts )
        super
        sleep 120 # Wait in case no_post is set to 1 on existing U-Boot env
        params['mem_addr'] = 0x88000000 
        params['nand_eraseblock_size'] = 0x800 # which is page size for tci6614
        params['mtdparts'] = "davinci_nand.0:1024k(bootloader),512k(params),4096k(kernel),-(filesystem)"
        params['offset'] = 0
        # Calculate bytes to be written (in hex)
        params['size'] = get_write_mem_size(params['secondary_bootloader'],params['nand_eraseblock_size'])
        params['extra_cmds'] = []
        params['extra_cmds'] << "oob fmt #{params['offset'].to_s(16)} #{params['size'].to_s(16)}"
        params['extra_cmds'] << "setenv no_post 1"
        params['extra_cmds'] << "saveenv"
        load_bootloader_from_nand(params)
        super
      else
        super
      end
      
    end
    
  end
end
