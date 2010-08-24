require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxC6xDriver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('EquipmentDriver')
      @api_list.merge!({
        'linux-c6x' =>  'LinuxEquipmentDriver', 
      })
    end
    
  end
end