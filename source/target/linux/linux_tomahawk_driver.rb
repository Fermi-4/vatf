require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxTomahawkDriver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('EquipmentDriver')
      @api_list.merge!({
        'vgdk' =>  'VgdkLinuxClientTomahawk', 
      })
    end
    
  end
end