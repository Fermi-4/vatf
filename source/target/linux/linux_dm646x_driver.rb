require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxDm646xDriver < BaseDriver
  
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientDM646x', 
        'demo' =>  'DemoLinuxClientDM646x',
        'dmai' =>  'DmaiLinuxClientDM646x',
      })
    end
    
  end
end