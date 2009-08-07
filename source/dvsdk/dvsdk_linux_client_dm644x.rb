require File.dirname(__FILE__)+'/dvsdk_linux_client'

module DvsdkClientHandler
  class DvsdkLinuxClientDM644x < DvsdkLinuxClient
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @client_list = {'dvtb' =>  'DvtbLinuxClientDM644x', 
                      'demo' =>  'DemoLinuxClientDM644x',
                     }
    end
  end
end