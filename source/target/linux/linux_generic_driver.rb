require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class LinuxGenericDriver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('LinuxEquipmentDriver')
      @api_list.merge!({
      })
    end
    
  end
end
