require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxDm357Driver < BaseDriver
  
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientDM357', 
        'demo' =>  'DemoLinuxClientDM357',
      })
    end
    
  end
end