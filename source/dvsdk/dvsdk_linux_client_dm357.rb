require File.dirname(__FILE__)+'/dvsdk_linux_client'

module DvsdkClientHandler
  class DvsdkLinuxClientDM357 < DvsdkLinuxClient
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @client_list = {'dvtb' =>  'DvtbLinuxClientDM357', 
                      'demo' =>  'DemoLinuxClientDM357',
                     }
    end
  end
end