require File.dirname(__FILE__)+'/dvsdk_linux_client'

module DvsdkClientHandler
  class DvsdkLinuxClientDM646x < DvsdkLinuxClient
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @client_list = {'dvtb' =>  'DvtbLinuxClientDM646x', 
                      'demo' =>  'DemoLinuxClientDM646x',
                     }
    end
  end
end