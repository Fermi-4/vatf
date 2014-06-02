require 'rubygems'
require 'timeout'
require File.dirname(__FILE__)+'/base_listener'

class TcpIpEquipmentConnection < TcpIpBaseListenerClient
  attr_reader :tcp_ip
  def initialize(platform_info)
    super(platform_info)
    rescue Exception => e
      raise
  end

  def send_cmd(*params)
    command        = params[0]
    expected_match = params[1] ? params[1] : Regexp.new('.*')
    timeout        = params[2] ? params[2] : 30
    check_cmd_echo = params[3] != nil ? params[3] : true
    append_linefeed = params[4] != nil ? params[4] : true
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
            sleep 0.05
        end
    }
    rescue Timeout::Error => e
      @is_timeout = true
      raise
    rescue Exception => e
      Kernel.print e.to_s+"\n"+e.backtrace.to_s
      raise
    ensure
      @response = listener.response
      remove_listener(listener)
  end
  
  def wait_for(*params)
    expected_match = params[0] #? params[1] : Regexp.new('.*')
    timeout        = params[1] #? params[2] : 30
    @is_timeout = false
    listener = BaseListener.new('', expected_match, false)
    add_listener(listener)
    status = Timeout::timeout(timeout) {
        while (!listener.match) 
            sleep 0.05
        end
    }
    rescue Timeout::Error => e
      @is_timeout = true
      raise
    rescue Exception => e
       Kernel.print e.to_s+"\n"+e.backtrace.to_s
       raise
    ensure
      @response = listener.response
      remove_listener(listener)
  end
  
  def read_for(*params)
    time        = params[0] #? params[2] : 30
    listener = BaseListener.new('', expected_match, false)
    add_listener(listener)
    sleep time
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

  # Return true if c is a special regex character.
  # [  \ ^ $ . | ? * + (  )
  def regex_character(c)
    [91, 92, 94, 36, 46, 124, 63, 42, 43, 40, 41].include?(c.to_i)
  end
  
end

