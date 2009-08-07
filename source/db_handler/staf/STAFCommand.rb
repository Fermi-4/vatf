#
# StafCommand class
#
#require 'staf/STAFHandle'
#require 'staf/STAFResult'

module STAF
  STAF_CMD  = '/usr/local/staf/bin/staf'
  STAF_DOES_NOT_EXIST = 48
  TEST_HOST = 'local'
  
  LOG_SVC     = 'log'
  FS_SVC      = 'fs'
  HELP_SVC    = 'help'
  PROCESS_SVC = 'process'
  MONITOR_SVC = 'monitor'
  HANDLE_SVC  = 'handle'

  ERROR_LEVEL = 'Error'
  START_LEVEL = 'Start'
  STOP_LEVEL  = 'Stop'

  PASS_LEVEL  = 'Pass'
  FAIL_LEVEL  = 'Fail'

  class STAFCommand
    def initialize(host, service, request,handle=nil)
      @retVal = Array.new
      if(handle == nil)
	@handle = STAFHandle.new('RubyStaf');
      else
	@handle = handle
      end
      
      if !$stderr.closed?
        $stderr.puts "#{$0}: DEBUG: Calling STAFHandle::submit(#{host}, #{service}, #{request})" if $opt_debug
      end
      @retVal = @handle.submit(host, service, request) unless $opt_nodo
      if (@retVal.rc == 0) && block_given?
        @retVal.result.each { |val| yield val }
      end

      if !$stderr.closed?
        $stderr.puts "#{$0}: DEBUG: return code: #{rc}" if $opt_debug
      end
      !@retVal.rc
    end

    def each
      @retVal.result.each {|val| yield val}
    end

    def rc
      @retVal.rc
    end

    def result
      @retVal.result
    end

    def errorMsg
      return "" if @rc == nil
      retval = @handle.submit('local', HELP_SVC, "error #{@rc}")
      return retval.result
    end
  end
end
