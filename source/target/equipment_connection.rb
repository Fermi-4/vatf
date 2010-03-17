require 'rubygems'
require File.dirname(__FILE__)+'/telnet_equipment_connection'
require File.dirname(__FILE__)+'/serial_equipment_connection'

class EquipmentConnection
  attr_reader :default, :telnet, :serial

  def initialize(platform_info)
    @platform_info = platform_info
    @default = nil
    @telnet = nil
    @serial = nil
  end

  def connect(params)
    case params['type'].to_s.downcase.strip
    when 'telnet':
      @telnet = TelnetEquipmentConnection.new(@platform_info) 
      if @platform_info.driver_class_name.to_s.downcase.include?("wince")
        @telnet.connect
        @telnet.waitfor({'Match' => />/, 'Timeout'=> 10})
        #send_cmd("")
        sleep 1
      else
        @telnet.connect
      end
      
      @default = @telnet
    
    when 'serial':
      if @platform_info.serial_port.to_s.strip != ''
        @serial = SerialEquipmentConnection.new(@platform_info) 
        @serial.auto_update_response
        @default = @serial if !@default
      else
        @serial = SerialServerConnection.new(@platform_info)
        @default = @serial if !@default
      end
    else
      raise "Unknown connection type: #{params['type'].to_s}"
    end
  end

  def disconnect
    @telnet.disconnect if @telnet
    @serial.disconnect if @serial
  end

  def send_cmd(*params)
    @default.send_cmd(*params)
  end
  
  def response
    @default.response
  end
  
  def timeout?
    @default.timeout?
  end
  
  def update_response
    @default.update_response
  end
  
end


