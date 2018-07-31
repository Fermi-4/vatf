require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/../../site_info.rb'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxArm64Driver < LinuxEquipmentDriver

    class Arm64BootCmdStep < SystemLoader::UbootStep
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


    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.replace_step('boot_cmd', Arm64BootCmdStep.new)  if @system_loader.contains?('boot')
    end

  end
end
