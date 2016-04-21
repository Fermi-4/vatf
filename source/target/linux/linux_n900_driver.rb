require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  
  class LinuxN900Driver < LinuxEquipmentDriver
   
    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      super
      @system_loader.remove_step('setip')  if @system_loader.contains?('setip')
    end
  end
end

