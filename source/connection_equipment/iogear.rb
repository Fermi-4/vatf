require 'socket'
require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require File.dirname(__FILE__)+'/video_switch'

module ConnectionEquipment
  include Log4r

  class IOGearHDMISwitch < BaseDigitalVideoSwitch
    Logger = Log4r::Logger
    def initialize(platform_info, log_path = nil)
        platform_info.instance_variables.each {|var|
           if platform_info.instance_variable_get(var).to_s.size > 0
               self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
               self.instance_variable_set(var, platform_info.instance_variable_get(var))
           end
        }
        start_logger(log_path) if log_path
        log_info("Starting target session") if @sw_log
        result = _send_cmd("swmode default")
        log_info("Could not disable power on detect #{result}") if !result.match(/.*?Command OK/)
    end

    def login
    end

    def logout
    end

    def connect_video_audio(inp=0, out=nil)
        connect_video(inp, 1)
    end

    # Connect input inp to output
    # * address - the port/sw to turn ON
    def connect_video(inp=0, out=nil)
        if !_switch('i', "%02d"%inp, 1)
           raise "Swithching video #{inp} failed"
        end
    end

    # Turns OFF/Open the Relay at the specified address
    # * address - the port/reay to turn OFF
    def connect_audio(inp=0, out=nil)
        connect_video(inp, 1)
    end

    # Disconnect video an audio from the output
    def disconnect_video_audio(output_ranges=nil)
        connect_video(output_ranges, 1)
        if !_switch('-', '', 1)
           raise "Swithching video #{output_ranges} failed"
        end
    end

    # Disconnect video from the output
    def disconnect_video(output_ranges=nil)
        disconnect_video_audio(output_ranges)
    end

    # Disconnect audio from the output
    def disconnect_audio(output_ranges=nil)
        disconnect_video_audio(output_ranges)
    end

    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
        if @sw_log
          stop_logger
        end
        Logger.new('iogear_log')
        @sw_log_outputter = Log4r::FileOutputter.new("iogear_log_out",{:filename => file_path.to_s , :truncate => false})
        @sw_log= Logger['iogear_log']
        @sw_log.level = Log4r::DEBUG
        @sw_log.add  @sw_log_outputter
        @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
        @sw_log_outputter.formatter = @pattern_formatter
    end

    #Stops the logger.
    def stop_logger
        @sw_log_outputter = nil if @sw_log_outputter
        @sw_log = nil if @sw_log
    end

    private

    def _switch(typ, inp, out)
        expected_res = /.*?Command OK/
        cmd="sw #{typ}#{inp}"
        result = _send_cmd(cmd)
        return result.match(/.*?Command OK/)
    end

    def log_info(info)
        @sw_log.info(info) if @sw_log
    end

    def log_error(error)
        @sw_log.error(error) if @sw_log
    end

    def disconnect()

    end
    
    def _send_cmd(cmd)
        result = ''
        log_info("Cmd: #{cmd}")
        conn = SerialPort.new(@serial_port, @serial_params)
        conn.read_timeout = 125
        conn.write(cmd+"\r")
        sleep 0.5
        while !conn.eof?
            result += conn.read_nonblock(1024)
        end
        log_info("Result: #{result}")
        return result
        ensure
           if conn
               conn.write("\r")
               conn.close()
           end
    end

  end
end

