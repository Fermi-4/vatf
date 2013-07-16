require 'delegate'

module Equipment

  class BaseDriver < SimpleDelegator  

    def initialize(platform_info, log_path)
      @platform_info = platform_info
      @log_path      = log_path 
      @iface = ''
      super(Object.new)
    end
    
    def set_api(iface_type)
      if !__getobj__ || @iface != iface_type
      	self.__setobj__(Object.const_get(@api_list[iface_type]).new(@platform_info,@log_path))
        @iface=iface_type
      end 
      rescue Exception => e
        raise e.backtrace.to_s+"\n Unable to start #{iface_type} interface with #{@platform_info.name} #{@platform_info.id}. Verify communication channel and settings"
    end
     
    def instance_variable_defined?(symbol)
      __getobj__.instance_variable_defined?(symbol)
    end   
  end

  def get_random_mac_address(locally_administered=true)
    msb=32
    msb=0 if !locally_administered
    "%02x:%02x:%02x:%02x:%02x:%02x"%[msb,rand(256),rand(256),rand(256),rand(256),rand(256)]
  end

end
