require File.dirname(__FILE__)+'/linux_equipment_driver'

module Equipment
  class LinuxK2LDriver < LinuxEquipmentDriver
    # Select BootLoader's load_method based on params
    def set_bootloader(params)        
      power_cycle(params)
      super(params)
    end
  end
end
