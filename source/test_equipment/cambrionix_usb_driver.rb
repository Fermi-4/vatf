require File.dirname(__FILE__)+'/../lib/jsonrpctcp'
require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class controls cambrionix Relay http://www.robot-electronics.co.uk/htm/eth_rly16tech.htm
  class CambrionixUsbDriver
    Logger = Log4r::Logger

    def initialize(platform_info, log_path = nil)
      platform_info.instance_variables.each {|var|
        if platform_info.instance_variable_get(var).to_s.size > 0
          self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
          self.instance_variable_set(var, platform_info.instance_variable_get(var))
        end
      }
      @host = @telnet_ip  != nil ? @telnet_ip : "localhost"
      @port = @telnet_port != nil ? @telnet_port : 43424
      begin
        start_logger(log_path) if log_path
        log_info("Connecting to cbrx daemon") if @cbrx_log
        @client = Jsonrpctcp::Client.new(@host, @port)
        @device_id = @params['id']
      rescue RPCException => err_msg
        log_info("Error while connecting to cbrx daemon.\n#{err_msg}") if @cbrx_log
        @client = nil
      rescue Exception => err_msg
        log_info("Error while connecting to cbrx daemon.\nMake sure params{'id'}"\
          "is defined in the bench file.\n#{err_msg}") if @cbrx_log
        @client = nil
      end
    end

    def login
    end

    def logout
    end

    # Enable USB Port
    # * port - the port to enable
    def enable_port(port)
      _send('cbrx_connection_set', "Port.#{port}.mode", 's')
    end

    # Disable USB Port
    # * port - the port to disable
    def disable_port(port)
      _send('cbrx_connection_set', "Port.#{port}.mode", 'o')
    end

    # Cycle (disable, enable) the specified port
    # * address - the usb port to cycle
    # * waittime - how long to wait between cycling (default: 5 seconds)
    def reset(port, waittime=5)
      disable_port(port)
      sleep(waittime)
      enable_port(port)
      sleep(waittime)
    end

    # Get USB Port flags as defined by Cambrionix API
    # * port - the port to get flags for
    # Port flags separated by spaces.
    # O S B I P C F are mutually exclusive
    # O = USB port Off
    # S = USB port in Sync mode
    # B = USB port in Biased mode
    # I = USB port in charge mode and Idle
    # P = USB port in charge mode and Profiling
    # C = USB port in charge mode and Charging
    # F = USB port in charge mode and has Finished charging
    # A D are mutually exclusive
    # A = a USB device is Attached to this USB port
    # D = Detached, no USB device is attached
    # E = Errors are present
    # R = system has been Rebooted
    # r = Vbus is being reset during mode change
    def get_port_flags(port)
      r = _send('cbrx_connection_get', "Port.#{port}.Flags")
      r['result']
    end

    def is_device_attached?(port)
      flags = get_port_flags(port)
      flags =~ /A/
    end

    def method_missing(method, *args)
      if @client
        _send(method, args)
      end
    end


    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
      if @cbrx_log
        stop_logger
      end
      Logger.new('cambrionix_log')
      @cbrx_log_outputter = Log4r::FileOutputter.new("cambrionix_log_out",{:filename => file_path.to_s , :truncate => false})
      @cbrx_log= Logger['cambrionix_log']
      @cbrx_log.level = Log4r::DEBUG
      @cbrx_log.add  @cbrx_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @cbrx_log_outputter.formatter = @pattern_formatter
    end

    #Stops the logger.
    def stop_logger
        @cbrx_log_outputter = nil if @cbrx_log_outputter
        @cbrx_log = nil if @cbrx_log
    end

    private
    def _send(method, *args)
      if @client
        begin
          @client.open_connection(@device_id)
          log_info("Calling #{method} #{args}") if @cbrx_log
          response = @client.public_send(method, args)
          log_info("Response: #{response}") if @cbrx_log
          response
        ensure
          @client.close_connection()
        end
      end
    end

    def log_info(info)
      @cbrx_log.info(info) if @cbrx_log
    end

    def log_error(error)
      @cbrx_log.error(error) if @cbrx_log
    end

    def disconnect()
    end

  end
end