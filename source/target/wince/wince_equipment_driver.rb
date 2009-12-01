require File.dirname(__FILE__)+'/../equipment_driver'

module Equipment

  class WinceEquipmentDriver < EquipmentDriver

    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
      
  end
  
end