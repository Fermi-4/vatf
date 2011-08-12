require 'rubygems'
require File.dirname(__FILE__)+'/telnet_equipment_connection'
require File.dirname(__FILE__)+'/serial_equipment_connection'

class EquipmentConnection
  attr_reader :default, :telnet, :serial
  attr_accessor :platform_info
  def initialize(platform_info)
    @platform_info = platform_info
    @default = nil
    @telnet = nil
    @serial = nil
  end

  def connect(params)
    case params['type'].to_s.downcase.strip
    when 'telnet'
      @telnet = TelnetEquipmentConnection.new(@platform_info) 
      if @platform_info.driver_class_name.to_s.downcase.include?("wince")
        @telnet.connect
        @telnet.waitfor({'Match' => />/, 'Timeout'=> 10})
        sleep 1
      else
        @telnet.connect
      end
	  @telnet.start_listening
      @default = @telnet
    
    when 'serial'
      if @platform_info.serial_port.to_s.strip != ''
        @serial = SerialEquipmentConnection.new(@platform_info) 
      else
        @serial = SerialServerConnection.new(@platform_info)
      end
	  @serial.start_listening
      @default = @serial if !@default
    else
      raise "Unknown connection type: #{params['type'].to_s}"
    end
  end

  def disconnect
    @telnet.disconnect if @telnet
    @serial.disconnect if @serial
    @default = nil
    @telnet = nil
    @serial = nil
  end

  def send_cmd(*params)
    # command        = params[0]
    # expected_match = params[1] #? params[1] : Regexp.new('.*')
    # timeout        = params[2] #? params[2] : 30
	# check_cmd_echo = params[3] #? params[3] : true
    # puts "equipment_connection: #{command}, #{expected_match}, #{timeout}, #{check_cmd_echo}" # TODO REMOVE DEBUG PRINT
    
	@default.send_cmd(*params)
	end
  
  def wait_for(*params)
    @default.wait_for(*params)
  end
  
  def read_for(*params)
    @default.read_for(*params)
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


