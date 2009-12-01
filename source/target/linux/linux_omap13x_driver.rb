require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxOmapL13xDriver < BaseDriver
  
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
        'dvtb' =>  'DvtbLinuxClientOmapL13x', 
      })
    end
    
  end
end