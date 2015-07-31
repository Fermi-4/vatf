require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
MEGABYTE = 1024.0 * 1024.0
module Equipment
  class LinuxTCI6638Driver < LinuxEquipmentDriver
    class Keystone2ExtrasStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_boot')
      end

      def run(params)
        puts "In keystone2_boot step"
        sleep 5
        setup_params(params)
        if params['secondary_bootloader'] != ''
          if params['secdev'] == true 
            write_bootloader_to_nand(params)
          else
            write_bootloader_to_spi_nor(params)
          end
          stop_boot(params)
          if params['secdev'] == true 
            send_cmd params, "run sec_bm_install"
          end
          @@uboot_version = nil      
        end
        case params['fs_type']
        when /ramfs/i
          self.send_cmd params, "setenv boot ramfs"
        when /ubifs/i
          self.send_cmd params, "setenv boot ubi"
        when /nfs/i
          self.send_cmd params, "setenv boot ubi"
        end
      end

      def write_bootloader_to_spi_nor(params)     
        # write new U-Boot to NOR
        self.send_cmd(params,"sf probe", @boot_prompt, 20)
        self.load_file_from_eth_now(params, params['mem_addr'], params['secondary_bootloader_image_name'])
        self.send_cmd(params,"sf erase 0 0x100000", @boot_prompt, 60)
        self.send_cmd(params,"sf write #{params['mem_addr']} 0 ${filesize}", @boot_prompt, 60)
        self.send_cmd(params,"reset", /.*/, 1)
      end
      
      def write_bootloader_to_nand(params)
        self.load_file_from_eth_now(params, params['mem_addr'], params['secondary_bootloader_image_name'])
        self.send_cmd(params,"run burn_uboot_nand",@boot_prompt, 60)
        self.send_cmd(params,"reset", /.*/, 1)
      end
      
      def bytesToMeg(bytes)
        bytes /  MEGABYTE  
      end  
      
      def setup_params(params=nil)
        params['mem_addr'] = "${addr_uboot}"
        params['nand_eraseblock_size'] = 0x800 # which is page size for tci6638 
        case params['fs_type']
        when /ramfs/i
          fs_sizeMB = bytesToMeg(File.size(File.new(params['fs']))).to_i
          params['fs_size'] = fs_sizeMB + 5
          puts " fs filesize is #{params['fs_size']}"
          params['fs_options'] = " rdinit=/sbin/init initrd=0x802000000,#{params['fs_size']}M"
          params['ram_id'] = 0
        when /nfs/i
          params['fs_options'] = ",v3,tcp,rsize=4096,wsize=4096 rootfstype=nfs"
        end
        params['extra_cmds'] = []
        params['extra_cmds'] << "saveenv"
      end
      def stop_boot(params)
        50.times  { 
          begin
            self.send_cmd(params, "", @boot_prompt, 0.5)
          rescue
           # do nothing
          end
          break if !params['dut'].timeout?
        }
        raise "Failed to load bootloader" if params['dut'].timeout?
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
          when 'ubi'
            load_skern_from_ubi params
          when 'none'
            # Do nothing
          else
            raise "Don't know how to load skern from #{params['skern_dev']}"
        end
      end
      private
      def load_skern_from_eth(params)
        load_file_from_eth params, params['_env']['mon_addr'], params['skern_image_name']
      end
    
      def load_skern_from_ubi(params)
        append_text params, 'bootcmd', "ubifsload #{params['_env']['mon_addr']} #{params['skern_image_name']};"
      end
   
    end

    class Keystone2Setup10gStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_boot')
      end
      def run(params)
        send_cmd params, "setenv run_fdt_1 'fdt addr ${addr_fdt}; fdt set /soc/netcp@2f00000 status \"ok\"' "
        send_cmd params, "setenv run_fdt_2 'fdt set /soc/netcp@2f00000/cpswx@2f00000/slaves/slave0 link-interface <11>'"
        send_cmd params, "setenv run_fdt_3 'fdt set /soc/netcp@2f00000/cpswx@2f00000/slaves/slave1 link-interface <11>'"
      end
    end
    
    class Keystone2SetRamfsStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_set_ramfs')
      end
      def run(params)
        params['ram_id'] = "" if !params['ram_id']
        params['fs_options'] = "" if !params['fs_options']
        case params['fs_src_dev']
        when /eth/i
          load_file_from_eth params, params['_env']['ramdisk_loadaddr'], params['fs_image_name']
        else
          raise "Don't know how to get ramfs image from #{params['fs_src_dev']}"
        end
        append_text params, 'bootargs', "root=/dev/ram#{params['ram_id']} rw#{params['fs_options']} "
      end
    end
    class Keystone2InstallMon < SystemLoader::UbootStep
      def initialize
        super('install_mon')
      end
      def run(params)
        append_text params, 'bootcmd', "mon_install #{params['_env']['mon_addr']};"
      end
    end

    class Keystone2UBIStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_ubi_boot')
      end

      def run(params)
        write_ubi_image_to_nand_via_mtdparts(params)
      end
      
      def write_ubi_image_to_nand_via_mtdparts(params)
        ubi_filesize = File.size(params['kernel']).to_s(16)
        puts " >>> UBI filesize is #{ubi_filesize}"
        self.send_cmd(params,"nand erase.part ubifs", @boot_prompt, 20)
        self.load_file_from_eth_now(params,params['_env']['kernel_loadaddr'],params['kernel_image_name'],600)
        self.send_cmd(params,"nand write #{params['_env']['kernel_loadaddr']} ubifs 0x#{ubi_filesize}", @boot_prompt, 600)
      end
    end
    
    class Keystone2UBIBootCmdStep < SystemLoader::UbootStep
    def initialize
      super('keystone2_ubi_boot_cmd')
    end

    def run(params)
      send_cmd params, "setenv boot ubi"
      send_cmd params, "setenv no_post 1"
    end
    end

     class Keystone2UBI10gBootCmdStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_ubi_boot_cmd')
      end

      def run(params)
        send_cmd params, "setenv bootcmd 'run init_${boot} get_fdt_${boot} get_mon_${boot} get_kern_${boot} run_mon run_fdt_1 run_fdt_2 run_fdt_3 run_kern'"
      end
    end
    
    class Keystone2ramfsBootCmdStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_ramfs_boot_cmd')
      end

      def run(params)
        send_cmd params, "setenv bootcmd 'tftp #{params['_env']['kernel_loadaddr']} #{params['kernel_image_name']}; tftp #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']}; \
tftp #{params['_env']['ramdisk_loadaddr']} #{params['fs_image_name']}; tftp #{params['_env']['mon_addr']} #{params['skern_image_name']};\
mon_install #{params['_env']['mon_addr']}; if iminfo #{params['_env']['kernel_loadaddr']}; then bootm #{params['_env']['kernel_loadaddr']} - #{params['_env']['dtb_loadaddr']};\
else bootz #{params['_env']['kernel_loadaddr']} - #{params['_env']['dtb_loadaddr']}; fi'"
      end
    end

     class Keystone2ramfs10gBootCmdStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_ramfs_boot_cmd')
      end

      def run(params)
        send_cmd params, "setenv bootcmd 'tftp #{params['_env']['kernel_loadaddr']} #{params['kernel_image_name']};tftp #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']}; tftp #{params['_env']['ramdisk_loadaddr']} #{params['fs_image_name']};tftp #{params['_env']['mon_addr']} #{params['skern_image_name']};mon_install #{params['_env']['mon_addr']};run init_${boot} get_fdt_${boot} get_mon_${boot} get_kern_${boot} run_mon run_fdt_1 run_fdt_2 run_fdt_3 run_kern'"
      end
    end
    
    class Keystone2nfsBootCmdStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_nfs_boot_cmd')
      end

      def run(params)
        send_cmd params, "setenv bootcmd 'tftp #{params['_env']['kernel_loadaddr']} #{params['kernel_image_name']}; tftp #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']}; \
tftp #{params['_env']['mon_addr']} #{params['skern_image_name']};\
mon_install #{params['_env']['mon_addr']}; if iminfo #{params['_env']['kernel_loadaddr']}; then bootm #{params['_env']['kernel_loadaddr']} - #{params['_env']['dtb_loadaddr']};\
else bootz #{params['_env']['kernel_loadaddr']} - #{params['_env']['dtb_loadaddr']}; fi'"
      end
    end

     class Keystone2nfs10gBootCmdStep < SystemLoader::UbootStep
      def initialize
        super('keystone2_nfs_boot_cmd')
      end

      def run(params)
        send_cmd params, "setenv bootcmd 'tftp #{params['_env']['kernel_loadaddr']} #{params['kernel_image_name']}; tftp #{params['_env']['dtb_loadaddr']} #{params['dtb_image_name']}; \
tftp #{params['_env']['mon_addr']} #{params['skern_image_name']};\
mon_install #{params['_env']['mon_addr']}; run init_${boot} get_fdt_${boot} get_mon_${boot} get_kern_${boot} run_mon run_fdt_1 run_fdt_2 run_fdt_3 run_kern'"
      end
    end

    class Keystone2SecBMInstall < SystemLoader::UbootStep
      def initialize
        super('keystone2_sec_bm_install')
      end

      def run(params)
        send_cmd params, "run sec_bm_install"
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
      if @id.include? "10g"
        puts "This is a Eth 10g test"
        params['10g'] = true
      end

      if params.has_key?("var_use_default_env")
      # do nothing
      else
          if params['secdev'] == true
            @system_loader.insert_step_before('prep', Keystone2SecBMInstall.new)
          end
          @system_loader.insert_step_before('kernel', Keystone2ExtrasStep.new)
          @system_loader.insert_step_before('kernel', SetDefaultEnvStep.new)
          @system_loader.insert_step_before('kernel', PrepStep.new)
          @system_loader.insert_step_before('kernel', SetIpStep.new)
          if params['10g'] == true
            @system_loader.insert_step_before('kernel', Keystone2Setup10gStep.new)
          end
          @system_loader.insert_step_before('fs', SkernStep.new)
          @system_loader.insert_step_before('boot', SaveEnvStep.new)
          @system_loader.insert_step_before('fs', Keystone2InstallMon.new)
          case params['fs_type']
          when /ramfs/i
            puts "*********** Setting system loader to ramfs "
            if params['10g'] == true
              @system_loader.replace_step('boot_cmd', Keystone2ramfs10gBootCmdStep.new)
            else
              @system_loader.replace_step('boot_cmd', Keystone2ramfsBootCmdStep.new)
            end
            @system_loader.replace_step('fs', Keystone2SetRamfsStep.new)
          when /ubifs/i
            puts "*********** Setting system loader to ubifs "
            @system_loader.insert_step_before('kernel', Keystone2UBIStep.new)
            if params['10g'] == true
              @system_loader.replace_step('boot_cmd', Keystone2UBI10gBootCmdStep.new)
            else
              @system_loader.replace_step('boot_cmd', Keystone2UBIBootCmdStep.new)
              @system_loader.insert_step_before('keystone2_ubi_boot_cmd', SetDefaultEnvStep.new)
            end
            @system_loader.remove_step('kernel')
            @system_loader.remove_step('dtb')
            @system_loader.remove_step('fs')
            @system_loader.remove_step('skern')
          when /nfs/i
            puts "*********** Setting system loader to nfs "
            if params['10g'] == true
              @system_loader.replace_step('boot_cmd', Keystone2nfs10gBootCmdStep.new)
            else
              @system_loader.replace_step('boot_cmd', Keystone2nfsBootCmdStep.new)
            end
          end
      end
    end

    def set_boot_env (params)
      params['bootargs'] = @boot_args if !params['bootargs']
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      params.each{|k,v| puts "#{k}:#{v}"}
      @system_loader.remove_step('boot')
      @boot_loader.run params
      @system_loader.run params
    end
    
    def boot_to_bootloader(params=nil)
      set_bootloader(params) if !@boot_loader
      set_systemloader(params) if !@system_loader
      begin
        @boot_loader.run params
      rescue 
        puts "Existing U-Boot failed to boot. Cannot proceed .."
        return
      end
      if params['secdev'] == true
        @system_loader.run_step('keystone2_sec_bm_install',params)
      end
      @system_loader.run_step('prep',params)
      @system_loader.run_step('setip',params)
      @system_loader.run_step('keystone2_boot',params)
    end
    
end
end
