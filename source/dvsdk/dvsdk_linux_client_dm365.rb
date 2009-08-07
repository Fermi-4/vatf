require File.dirname(__FILE__)+'/dvsdk_linux_client'

module DvsdkClientHandler
  class DvsdkLinuxClientDM365 < DvsdkLinuxClient
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @client_list = {'dvtb' =>  'DvtbLinuxClientDM365', 
                      'demo' =>  'DemoLinuxClientDM365',
                     }
    end
  end
end