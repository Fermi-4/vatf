require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxAm335xDriver < LinuxEquipmentDriver
    include BootLoader

    def set_api(dummy_var)
    end

  end #Class

  class LinuxAm335xSKDriver < LinuxAm335xDriver
  end #Class

end #Module



