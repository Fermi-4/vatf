require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxLegacyDriver < LinuxEquipmentDriver

    class LegacyTftpStep < SystemLoader::UbootStep
      def initialize
        super('legacy_tftp')
      end

      def run(params)
        self.send_cmd params, "setenv bootfile #{params['kernel_image_name']}", params['dut'].boot_prompt
        self.send_cmd params, "tftp ${loadaddr}", params['dut'].boot_prompt, 60
        raise "Failed to tftp kernel #{params['kernel_image_name']}" if params['dut'].response.match(/error/i)
      end
    end

    class LegacyBootCmdStep < UbootStep
      def initialize
        super('legacy_boot_cmd')
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
        append_text params, 'bootcmd', "bootm ${loadaddr} #{ramdisk_addr} #{dtb_addr};"
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      super
      if params['boot_cmds'].to_s == ''
        if @system_loader.contains?('kernel')
          @system_loader.insert_step_before('kernel', LegacyTftpStep.new)
          @system_loader.remove_step('kernel')
        end
        if @system_loader.contains?('boot_cmd')
          @system_loader.insert_step_before('boot_cmd', LegacyBootCmdStep.new)
          @system_loader.remove_step('boot_cmd')
        end
        @system_loader.remove_step('touch_cal') if @system_loader.contains?('touch_cal')
      end
    end
  end
end