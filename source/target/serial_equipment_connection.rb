require 'rubygems'
require 'timeout'
require File.dirname(__FILE__)+'/base_listener'

class SerialEquipmentConnection < SerialBaseListenerClient
  
  def initialize(platform_info)
    super(platform_info)
    rescue Exception => e
      raise
  end

  def send_cmd(*params)
    command        = params[0]
    expected_match = params[1]  #? params[1] : Regexp.new('.*')
    timeout        = params[2]  #? params[2] : 30
    check_cmd_echo = params[3]  #? params[3] : true
    append_linefeed = params[4] #? params[4] : true
	
    @is_timeout = false
    listener = BaseListener.new(command, expected_match, check_cmd_echo)
    add_listener(listener)
    if append_linefeed
      super(command)
    else
      write(command)
    end
    status = Timeout::timeout(timeout) {
        while (!listener.match) 
            sleep 0.5
        end
    }
    rescue Timeout::Error => e
      log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s) if respond_to?(:log_error)
      @is_timeout = true
    rescue Exception => e
       Kernel.print e.to_s+"\n"+e.backtrace.to_s
       raise
    ensure
      @response = listener.response
      remove_listener(listener)
  end
  
  def response
    @response.to_s
  end
  
  def timeout?
    @is_timeout
  end
  
  def update_response
    @session_data
  end
end
