require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxTCI6614Driver < LinuxEquipmentDriver
    class KeystoneExtrasStep < SystemLoader::UbootStep
      def initialize
        super('keystone_boot')
      end

      def run(params)
        puts "In keystone_boot step"
        params['fs_options'] = ",v3,tcp"
        sleep 5
        if params['secondary_bootloader_image_name']
          setup_params(params)
          self.send_cmd params, "dhcp"
          ip_regex = Regexp.new(/DHCP\sclient\sbound\sto\saddress\s(?:\d{1,3}\.){3}\d{1,3}/)
          raise "Could not get IP addr from DHCP" if (ip_regex.match(params['dut'].response) == nil)
          write_bootloader_to_nand_via_mtdparts(params)
          params['dut'].power_cycle(params)
          params['dut'].stop_boot()
          @@uboot_version = nil      
        end
        
      end      
    
    def write_bootloader_to_nand_via_mtdparts(params)
     
      #set mtd partition names
      self.send_cmd(params,"setenv mtdparts mtdparts=#{params['mtdparts']}",@boot_prompt, 10) 
      
      # write new U-Boot to NAND
      self.send_cmd(params,"mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      self.load_file_from_eth_now(params, params['mem_addr'].to_s(16), params['secondary_bootloader_image_name'])
      self.send_cmd(params,"nand erase.part bootloader", @boot_prompt, 60)
      self.send_cmd(params,"nand write #{params['mem_addr'].to_s(16)} bootloader #{params['size'].to_s(16)}", @boot_prompt, 60)
      
      # Next, run any EVM-specific commands, if needed
      if defined? params['extra_cmds']
        params['extra_cmds'].each {|cmd|
          self.send_cmd(params,"#{cmd}",@boot_prompt, 60)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if params['dut'].timeout?
        }
      end
      begin
      self.send_cmd(params,"reset", @boot_prompt, 60)
      rescue Exception => e
         # do nothing
      end
    end
       
    def setup_params(params=nil)
        # sleep 120 # Wait in case no_post is set to 1 on existing U-Boot env
        params['mem_addr'] = 0x88000000 
        params['nand_eraseblock_size'] = 0x800 # which is page size for tci6614
        params['mtdparts'] = "davinci_nand.0:1024k(bootloader),512k(params),4096k(kernel),-(filesystem)"
        params['offset'] = 0
        if params['secdev'] == true 
          params['dtb_loadaddr'] = "0x87000200"
          params['fs_loadaddr'] = "0x92000000"
          params['keygen_loadaddr'] = "0x91000000"
        end
        # Calculate bytes to be written (in hex)
        params['size'] = params['dut'].get_write_mem_size(params['secondary_bootloader'],params['nand_eraseblock_size'])
        params['extra_cmds'] = []
        params['extra_cmds'] << "oob fmt #{params['offset'].to_s(16)} #{params['size'].to_s(16)}"
        params['extra_cmds'] << "setenv no_post 1"
        params['extra_cmds'] << "saveenv"
    end
    

     
    # This function assumes there is an existing U-Boot (secondary bootloader) on the board, writes the new U-Boot image to a specified NAND location and reboots the board.
    def write_bootloader_to_nand_min(params)

      # write new U-Boot to NAND
      self.send_cmd(params,"mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      self.load_file_from_eth_now(params, params['mem_addr'].to_s(16), params['secondary_bootloader_image_name'])
      self.send_cmd("nand erase clean #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 40)
      self.send_cmd("nand write #{params['mem_addr'].to_s(16)} #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 60)
      
      # Next, run any EVM-specific commands, if needed
      if defined? params['extra_cmds']
        params['extra_cmds'].each {|cmd|
          self.send_cmd("#{cmd}",@boot_prompt, 60)
          raise "Timeout waiting for bootloader prompt #{@boot_prompt}" if timeout?
        }
      end
      begin
      self.send_cmd(params,"reset", @boot_prompt, 60)
      rescue Exception => e
         # do nothing
      end
    end
     
    end

    class KeystoneUBIStep < SystemLoader::UbootStep
      def initialize
        super('keystone_ubi_boot')
      end

      def run(params)
        write_ubi_image_to_nand_via_mtdparts(params)
     end
      
      def write_ubi_image_to_nand_via_mtdparts(params)
        ubi_filesize = File.size(params['kernel']).to_s(16)
        puts "UBI filesize is #{ubi_filesize}"
        if params['secdev'] == true
            append_text params, 'bootargs', "root=/dev/ram0 rw console=ttyS0,115200n8 initrd=0x92000060,32M rdinit=/sbin/init ubi.mtd=2,2048"
        else
            append_text params, 'bootargs', "mem=512M rootwait=1 rootfstype=ubifs root=ubi0:rootfs rootflags=sync rw ubi.mtd=2,2048" 
        end
        self.send_cmd(params,"setenv mtdparts mtdparts=davinci_nand.0:1024k(bootloader),512k(params)ro,129536k(ubifs)", @boot_prompt, 20)
        self.send_cmd(params,"nand erase.part ubifs", @boot_prompt, 20)
        self.load_file_from_eth_now(params,params['_env']['kernel_loadaddr'],params['kernel_image_name'],600)
        self.send_cmd(params,"nand write #{params['_env']['kernel_loadaddr']} ubifs 0x#{ubi_filesize}", @boot_prompt, 600)
        params['kernel_image_name'] = 'uImage'
        params['kernel_dev'] = 'ubi'
      end
    end
    
    class KeystoneUBIBootCmdStep < SystemLoader::UbootStep
    def initialize
      super('keystone_ubi_boot_cmd')
    end

    def run(params)
    if params['secdev'] == true
        send_cmd params, "setenv ubiload 'ubi part ubifs;ubifsmount boot;ubifsload 0x81000000 secserver.dsp.bin ; load_dsp_magic 0x81000000;run verify_kernel verify_dtb verify_fs verify_load_keygen '"
        send_cmd params, "setenv bootcmd 'run ubiload boot_kernel'"
        send_cmd params, "setenv boot_kernel 'bootm 0x88000060 - 0x87000260'"
        send_cmd params, "setenv verify_dtb 'ubifsload #{params['dtb_loadaddr']} tci6614-evm.dtb; secure_srv #{params['dtb_loadaddr']}'"
        send_cmd params, "setenv verify_fs 'ubifsload #{params['fs_loadaddr']} fs.gz; secure_srv #{params['fs_loadaddr']}'"
        send_cmd params, "setenv verify_kernel 'ubifsload #{params['_env']['kernel_loadaddr']} uImage; secure_srv #{params['_env']['kernel_loadaddr']}'"
        send_cmd params, "setenv verify_load_keygen 'ubifsload #{params['keygen_loadaddr']} keygen.dsp.bin.sec;secure_srv #{params['keygen_loadaddr']};run_dsp_app 0x91000060; ubifsload 0x81000000 secserver.dsp.bin ; load_dsp_magic 0x81000000'"
      else
        send_cmd params, "setenv bootcmd 'ubi part ubifs; ubifsmount boot; ubifsload ${addr_kernel} uImage; ubifsload ${addr_fdt} tci6614-evm.dtb; bootm ${addr_kernel} - ${addr_fdt} '"
      end
    end
    end
    # reboot is needed the first time so user will be able to power cycle the board without corrupting the file system.
    class KeystoneUBIRebootStep < SystemLoader::UbootStep
    def initialize
      super('keystone_ubi_reboot')
    end

    def run(params)
      send_cmd params, "reboot", params['dut'].login_prompt, 180
      send_cmd params, params['dut'].login, params['dut'].prompt, 10 # login to the unit
    end
    end
     

 
  
    def set_bootloader(params)
      @boot_loader = BaseLoader.new 
    end
    
    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)  
      super    
      if @id.include? "secdev"
        puts "This is a secure device"
        params['secdev'] = true
      end
      if params.has_key?("var_use_default_env")
      # do nothing
      else
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.insert_step_before('kernel', KeystoneExtrasStep.new)
      @system_loader.insert_step_before('kernel', PrepStep.new)
      @system_loader.insert_step_before('boot', SaveEnvStep.new)
      if params['fs_type'] == 'ubifs'
        puts "*********** Setting system loader to UBI "
        @system_loader.insert_step_before('kernel', KeystoneUBIStep.new)
        @system_loader.remove_step('fs')
        @system_loader.replace_step('boot_cmd', KeystoneUBIBootCmdStep.new)
#        @system_loader.add_step(KeystoneUBIRebootStep.new)
      end
      end
    end

    def set_boot_env (params)
      params['bootargs'] = @boot_args if !params['bootargs']
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @system_loader.remove_step('boot')
      if params['fs_type'] == 'ubifs'
        @system_loader.remove_step('keystone_ubi_reboot')
      end
      @boot_loader.run params
      @system_loader.run params
    end
    
    def boot_to_bootloader(params=nil)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      @boot_loader.run params
      @system_loader.run_step('prep',params)
      @system_loader.run_step('keystone_boot',params)
    end
    
  end
end
