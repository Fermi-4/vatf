require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class CentOSAMCDriver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('EquipmentDriver')
      @api_list.merge!({
        'vgdk' =>  'Cent0SEquipmentDriver', 
      })
    end
end
end