require 'rubygems'
require File.dirname(__FILE__)+'/telnet_equipment_connection'
require File.dirname(__FILE__)+'/serial_equipment_connection'

class EquipmentConnection
  attr_reader :default, :telnet, :serial

  def initialize(platform_info)
    @default = nil
    @telnet = nil
    @serial = nil
    
    if platform_info.telnet_ip.to_s.strip != ''
      @telnet = TelnetEquipmentConnection.new(platform_info) 
      @default = @telnet
    end
    
    if platform_info.serial_port.to_s.strip != ''
      @serial = SerialEquipmentConnection.new(platform_info) 
      @default = @serial if !@default
    end
    
  end

  def connect
    conn_response = @telnet.connect if @telnet
    conn_response = @serial.connect if @serial
	conn_response
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
end


