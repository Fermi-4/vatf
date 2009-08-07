require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module MediaEquipment
  include Log4r
 
  class DvdPlayer
     Logger = Log4r::Logger
    public

      #Starts the logger for the session. Takes the log file path as parameter.
      def start_logger(file_path)
        if @dvd_log
          stop_logger
        end
        Logger.new('dvd_log')
        @dvd_log_outputter = Log4r::FileOutputter.new("dvd_log_out",{:filename => file_path.to_s , :truncate => false})
        @dvd_log = Logger['dvd_log']
        @dvd_log.level = Log4r::DEBUG
        @dvd_log.add  @dvd_log_outputter
        @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
        @dvd_log_outputter.formatter = @pattern_formatter     
      end
      
      #Stops the logger.
      def stop_logger
          @dvd_log_outputter = nil 
          @dvd_log = nil
      end
      
       #Closes the telnet connection with the dvd
      def disconnect
        @streamSock.close if @streamSock
        ensure
        @streamSock = nil
      end
       
  private
      def log_info(info)
		  @dvd_log.info(info) if @dvd_log
	  end
	  
	  def log_error(error)
		  @dvd_log.error(error) if @dvd_log
	  end
  end

end     

