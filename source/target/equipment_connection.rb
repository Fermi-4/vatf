require 'rubygems'
require File.dirname(__FILE__)+'/telnet_equipment_connection'
require File.dirname(__FILE__)+'/serial_equipment_connection'
require File.dirname(__FILE__)+'/ccs_equipment_connection'
require File.dirname(__FILE__)+'/tcp_ip_equipment_connection'

class EquipmentConnection
  attr_reader :telnet, :serial, :ccs, :tcp_ip, :bmc, :bootloader, :firmware
  attr_accessor :platform_info, :default
  def initialize(platform_info, log_path = nil)
    @platform_info = platform_info
    @default = nil
    @telnet = nil
    @serial = nil
    @bmc    = nil
    @ccs    = nil
    @tcp_ip = nil
    @bootloader = nil
    @firmware = nil
    @base_log_dir=File.dirname(log_path) if log_path
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
        if @base_log_dir
          @serial.start_listening { [@platform_info, File.join(@base_log_dir, @platform_info.serial_port.gsub(/\W/,'_'))]  }
        else
          @serial.start_listening
        end
      else
        puts "Serial connection already exists, using existing connection"
      end
      @default = @serial 

      if !@bootloader || @bootloader.closed?
        if @platform_info.params && @platform_info.params['bootloader_port'].to_s.strip != ''
          mod_platform_info = @platform_info.clone
          mod_platform_info.serial_port = @platform_info.params['bootloader_port']
          mod_platform_info.serial_params = @platform_info.params['bootloader_serial_params']
          mod_platform_info.prompt = @platform_info.params['bootloader_prompt']
          @bootloader = SerialEquipmentConnection.new(mod_platform_info)
          if @base_log_dir
            @bootloader.start_listening {[mod_platform_info, File.join(@base_log_dir, mod_platform_info.serial_port.gsub(/\W/,'_'))]}
          else
            @serial.start_listening
          end
        end
      end

      if !@firmware || @firmware.closed?
        if @platform_info.params && @platform_info.params['firmware_port'].to_s.strip != ''
          mod_platform_info = @platform_info.clone
          mod_platform_info.serial_port = @platform_info.params['firmware_port']
          mod_platform_info.serial_params = @platform_info.params['firmware_serial_params']
          mod_platform_info.prompt = @platform_info.params['firmware_prompt']
          @firmware = SerialEquipmentConnection.new(mod_platform_info)
          if @base_log_dir
            @firmware.start_listening { [mod_platform_info, File.join(@base_log_dir, mod_platform_info.serial_port.gsub(/\W/,'_'))] }
          else
            @serial.start_listening
          end
        end
      end

      @bootloader = @serial if !@bootloader
      @firmware = @serial if !@firmware

    when 'bmc'
      if !@bmc || @bmc.closed?
        if @platform_info.params['bmc_port'].to_s.strip != ''
          mod_platform_info = @platform_info.clone
          mod_platform_info.serial_port = @platform_info.params['bmc_port']
          mod_platform_info.prompt = @platform_info.params['bmc_prompt']
          @bmc = SerialEquipmentConnection.new(mod_platform_info)
        end
        if @base_log_dir
          @bmc.start_listening { [mod_platform_info, File.join(@base_log_dir, mod_platform_info.serial_port.gsub(/\W/,'_'))] }
        else
          @serial.start_listening
        end
      else
        puts "BMC connection already exists, using existing connection"
      end
      @default = @bmc if !@default || params['force_connect']

    when 'ccs'
      if !@ccs
        @ccs = BoardController::CcsController.new(@platform_info.params)
      else
        puts "CCS Controller already exists, using existing connection"
      end
      @default = @ccs if !@default || params['force_connect']

    when 'tcp_ip'
      if !@tcp_ip || @tcp_ip.closed?
        @tcp_ip = TcpIpEquipmentConnection.new(@platform_info) 
        @tcp_ip.start_listening
      else
        puts "tcp_ip connection already exists, using existing connection"
      end
      @default = @tcp_ip if !@default || params['force_connect']

    else
      raise "Unknown connection type: #{params['type'].to_s}"
    end
  end

  def disconnect(type='all')
    if type == 'telnet' || type == 'all'
      @telnet.disconnect if @telnet
      @default = nil if type.downcase.strip == 'all' || @default == @telnet
      @telnet = nil
    end
    if type == 'serial' || type == 'all'
      @serial.disconnect if @serial
      @bootloader.disconnect if @bootloader
      @firmware.disconnect if @firmware
      @default = nil if type.downcase.strip == 'all' || @default == @serial
      @serial = nil
      @bootloader = nil
      @firmware = nil
    end
    if type == 'bmc' || type == 'all'
      @bmc.disconnect if @bmc
      @default = nil if type.downcase.strip == 'all' || @default == @bmc
      @bmc = nil
    end
    if type == 'ccs' || type == 'all'
      @ccs.disconnect if @ccs
      @default = nil if type.downcase.strip == 'all' || @default == @ccs
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
    wait_on_for(@default,*params)
  end
  
  def read_for(*params)
    read_on_for(@default,*params)
  end

  def wait_on_for(conn, *params)
    conn.wait_for(*params)
  end

  def read_on_for(conn, *params)
    conn.read_for(*params)
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

  def get_raw_logs
    logs = []
    if @platform_info.serial_port
      logs << ['serial_raw', File.join(@base_log_dir, @platform_info.serial_port.gsub(/\W/,'_'))]
    end
    if @platform_info.params && @platform_info.params['bootloader_port']
      logs << ['bootloader_raw', File.join(@base_log_dir, @platform_info.params['bootloader_port'].gsub(/\W/,'_'))]
    end
    if @platform_info.params && @platform_info.params['firmware_port']
      logs << ['firmware_raw', File.join(@base_log_dir, @platform_info.params['firmware_port'].gsub(/\W/,'_'))]
    end
    return logs
  end
end
