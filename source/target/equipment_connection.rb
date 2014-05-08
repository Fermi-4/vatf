require 'rubygems'
require File.dirname(__FILE__)+'/telnet_equipment_connection'
require File.dirname(__FILE__)+'/serial_equipment_connection'
require File.dirname(__FILE__)+'/ccs_equipment_connection'

class EquipmentConnection
  attr_reader :default, :telnet, :serial, :ccs
  attr_accessor :platform_info
  def initialize(platform_info)
    @platform_info = platform_info
    @default = nil
    @telnet = nil
    @serial = nil
    @ccs    = nil
  end

  def connect(params)
    case params['type'].to_s.downcase.strip
    when 'telnet'
      if !@telnet || @telnet.closed?
        @telnet = TelnetEquipmentConnection.new(@platform_info) 
        @telnet.connect
        @telnet.start_listening
      else
        puts "Telnet connection already exists, using existing connection"
      end
      @default = @telnet if ((!@default) || params['force_connect'])            #change added 12-10-2011
    
    when 'serial'
      if !@serial || @serial.closed?
        if @platform_info.serial_port.to_s.strip != ''
          @serial = SerialEquipmentConnection.new(@platform_info) 
        else
          sleep 1
          @serial = SerialServerConnection.new(@platform_info)
        end
        @serial.start_listening
      else
        puts "Serial connection already exists, using existing connection"
      end
      @default = @serial if !@default || params['force_connect']
    
    when 'ccs'
      if !@ccs
        @ccs = BoardController::CcsController.new(@platform_info.params)
      else
        puts "CCS Controller already exists, using existing connection"
      end
    
    else
      raise "Unknown connection type: #{params['type'].to_s}"
    end
  end

  def disconnect(type='all')
    if type == 'telnet' || type == 'all'
    @telnet.disconnect if @telnet
    @telnet = nil
      @default = nil if type.downcase.strip == 'all' || !@serial
    end
    if type == 'serial' || type == 'all'
      @serial.disconnect if @serial
    @serial = nil
      @default = nil if type.downcase.strip == 'all' || !@telnet
    end
    if type == 'ccs' || type == 'all'
      @ccs.disconnect if @ccs
    @ccs = nil
  end
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
