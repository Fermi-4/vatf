require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxTCI6614Driver < LinuxEquipmentDriver
    class KeystoneExtrasStep < SystemLoader::UbootStep
      def initialize
        super('keystone_boot')
      end

      def run(params)
        setup_params(params)
        write_bootloader_to_nand_via_mtdparts(params)
        params['dut'].power_cycle
        params['dut'].stop_boot()
        @@uboot_version = nil
        get_uboot_version params
      end
      
      def load_file_from_eth_now(params, load_addr, filename)
        tftp_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>'tftp', 'version'=>@@uboot_version})
        self.send_cmd(params, "#{tftp_cmd} #{load_addr} #{params['server'].telnet_ip}:#{filename}", @boot_prompt, 60)
      end
      
    
    def write_bootloader_to_nand_via_mtdparts(params)
     
      #set mtd partition names
      self.send_cmd(params,"setenv mtdparts mtdparts=#{params['mtdparts']}",@boot_prompt, 10) 
      
      # write new U-Boot to NAND
      self.send_cmd(params,"mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      load_file_from_eth_now(params, params['mem_addr'].to_s(16), params['secondary_bootloader_image_name'])
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
      send_cmd("mw.b #{params['mem_addr'].to_s(16) } 0xFF #{params['size'].to_s(16)}", @boot_prompt, 20)
      load_file_from_eth_now(params, params['mem_addr'].to_s(16), params['secondary_bootloader_image_name'])
      send_cmd("nand erase clean #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 40)
      send_cmd("nand write #{params['mem_addr'].to_s(16)} #{params['offset'].to_s(16)} #{params['size'].to_s(16)}", @boot_prompt, 60)
      
      # Next, run any EVM-specific commands, if needed
      if defined? params['extra_cmds']
        params['extra_cmds'].each {|cmd|
          send_cmd("#{cmd}",@boot_prompt, 60)
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

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.insert_step_before('kernel', KeystoneExtrasStep.new)
    end
     
    def set_bootloader(params)
      @boot_loader = BaseLoader.new 
    end
  end
end
