require File.dirname(__FILE__)+'/../base_driver'

module Equipment
  class WinceOmapl13xDriver < BaseDriver
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @api_list      = Hash.new('WinceEquipmentDriver')
      @api_list.merge!({
      })
    end
    
  end
end