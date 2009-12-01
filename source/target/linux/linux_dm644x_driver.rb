require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxDm644xDriver < BaseDriver
  
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientDM644x', 
        'demo' =>  'DemoLinuxClientDM644x',
        'dmai' =>  'DmaiLinuxClientDM644x',
      })
    end
    
  end
end