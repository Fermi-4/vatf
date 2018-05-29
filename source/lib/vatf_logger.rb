require 'log4r'
require 'log4r/outputter/fileoutputter'


module Log4r
  class RawFormatter < Formatter
    def format(event)
      sprintf("%s", event.data)
    end
  end
end


module VatfLog

  include Log4r

  #Starts the logger for the session. Takes the log file path as parameter.

  class RawVatfLogger

    def initialize(file_path, log_name)
      if @targetc_log
        stop_logger
      end
      Log4r::Logger.new(log_name)
      @targetc_log_outputter = Log4r::FileOutputter.new(log_name,{:filename => file_path.to_s , :truncate => false})
      @targetc_log = Log4r::Logger[log_name]
      @targetc_log.level = Log4r::DEBUG
      @targetc_log.add  @targetc_log_outputter
      @pattern_formatter = Log4r::RawFormatter.new()
      @targetc_log_outputter.formatter = @pattern_formatter
    end

    def stop_logger
      @targetc_log_outputter = nil if @targetc_log_outputter
      @targetc_log = nil if @targetc_log
    end

    def log_warning(warning)
        @targetc_log.warn(warning) if @targetc_log
    end

    def log_info(info)
      z= info.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.info(z) if @targetc_log
    end

    def log_error(error)
      z= error.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.error(z) if @targetc_log
    end

    def log_debug(debug_info)
      z= debug_info.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.debug(z) if @targetc_log
    end
  end

end