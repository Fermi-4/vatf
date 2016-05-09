require 'socket'
require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require File.dirname(__FILE__)+'/video_switch'

module ConnectionEquipment
  include Log4r

  class KraymerHDMIVSSwitch < BaseDigitalVideoSwitch
    Logger = Log4r::Logger 
    def initialize(platform_info, log_path = nil)
        platform_info.instance_variables.each {|var|
            #if platform_info.instance_variable_get(var).kind_of?(String) && platform_info.instance_variable_get(var).to_s.size > 0
            if platform_info.instance_variable_get(var).to_s.size > 0   
               self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
               self.instance_variable_set(var, platform_info.instance_variable_get(var))
           end
        }
        @host = @telnet_ip
        @port = @telnet_port != nil ? @telnet_port : 5000
        @output = ""
        start_logger(log_path) if log_path
        log_info("Starting target session") if @sw_log
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
        if !_switch(0x01, inp, 1)
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
        connect_video(0x0, 0x0)
    end
    
    # Disconnect video from the output
    def disconnect_video(output_ranges=nil)
        connect_video(0x0, 0x0)
    end
    
    # Disconnect audio from the output
    def disconnect_audio(output_ranges=nil)
        connect_video(0x0, 0x0)
    end
    
    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
        if @sw_log
          stop_logger
        end
        Logger.new('devantech_log')
        @sw_log_outputter = Log4r::FileOutputter.new("devantech_log_out",{:filename => file_path.to_s , :truncate => false})
        @sw_log= Logger['devantech_log']
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
        result = nil
        status = 0x40
        cmd = 0x00
        instr = 0x80
        expected_res = [status | typ, instr | inp, instr | out, instr | 0x01].pack('c*')
        sock = TCPSocket.open(@host, @port)
        status = Timeout::timeout(10) {
          if sock == nil
            raise "Could not connect to Kraymer switch"
          end
          log_info("Cmd: #{[cmd | typ, instr |  inp, instr | out, instr | 0x01].map{|x| x.to_s(16)}.join}")
          sock.puts([cmd | typ, instr | inp, instr | out, instr | 0x01].pack('c*'))
          result = sock.read(4)
          log_info("Result: #{result.unpack('H*')}")
        }
        rescue Timeout::Error 
          raise "Timeout communicating with Kraymer switch"
        ensure
          sock.close() if sock

        return result == expected_res
    end
    
    def log_info(info)
      @sw_log.info(info) if @sw_log
    end

    def log_error(error)
      @sw_log.error(error) if @sw_log
    end
    
    def disconnect()
      
    end
    
  end
end

