require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxDm365Driver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientDM365', 
        'demo' =>  'DemoLinuxClientDM365',
        'dmai' =>  'DmaiLinuxClientDM365',
      })
    end
    
  end
end