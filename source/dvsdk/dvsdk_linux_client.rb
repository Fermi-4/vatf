require File.dirname(__FILE__)+'/dvtb/dvtb'
require File.dirname(__FILE__)+'/demo/demo'

module DvsdkClientHandler
  class DvsdkLinuxClient
    def initialize(platform_info, log_path)
      @platform_info = platform_info
      @log_path = log_path
      @client_list = {}
    end
    
    def set_interface(iface_type)
      @dvsdk_client = nil
      @dvsdk_client = Object.const_get(@client_list[iface_type]).new(@platform_info,@log_path) if @client_list[iface_type]
      rescue Exception => e
        raise e.to_s+"\n Unable to start #{iface_type} interface with #{@platform_info.name} #{@platform_info.id}. Verify communication channel and settings"
    end
    
    def connect
      @dvsdk_client.connect if @dvsdk_client
    end
    
    def start_logger
    end
    
    def disconnect
      @dvsdk_client.disconnect if @dvsdk_client
    end
    
    def method_missing(sym, *args, &block)
      @dvsdk_client.send(sym, *args, &block) 
    end
    
    def respond_to?(*args)
      @dvsdk_client.respond_to?(*args)
    end
      
  end
end
