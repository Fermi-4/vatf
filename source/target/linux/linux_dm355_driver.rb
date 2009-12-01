require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxDm355Driver < BaseDriver
  
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientDM355', 
        'demo' =>  'DemoLinuxClientDM355',
        'dmai' =>  'DmaiLinuxClientDM355',
      })
    end
    
  end
end