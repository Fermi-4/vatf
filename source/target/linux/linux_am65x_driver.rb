require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/../../site_info.rb'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxArm64Driver < LinuxEquipmentDriver

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      super(params)
      @system_loader.replace_step('boot_cmd', SystemLoader::Arm64BootCmdStep.new)  if @system_loader.contains?('boot') || @system_loader.contains?('boot_autologin')
    end

  end
end
