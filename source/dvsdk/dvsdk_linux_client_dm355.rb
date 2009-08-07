require File.dirname(__FILE__)+'/dvsdk_linux_client'

module DvsdkClientHandler
  class DvsdkLinuxClientDM355 < DvsdkLinuxClient
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
      @client_list = {'dvtb' =>  'DvtbLinuxClientDM355', 
                      'demo' =>  'DemoLinuxClientDM355',
                     }
    end
  end
end