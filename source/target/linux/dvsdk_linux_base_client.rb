module DvsdkHandlers
  class DvsdkLinuxBaseListener
    attr_reader :match, :cmd, :expect, :response_buffer
    def initialize(cmd,expect)
        first_cmd_word = cmd.split(/\s/)[0].to_s
        i = 0
        first_cmd_word.each_byte {|c| 
          first_cmd_word[i] = '.'  if c.to_i < 32
          i+=1
        }
        @cmd = Regexp.new(first_cmd_word)
        @expect = /#{expect}/m
        @response_buffer = ''
        @match = false
    end
    
    def process_response(data)
      @response_buffer += data
    end
    
    def match
      @match = true   if @response_buffer.index(@expect) && @response_buffer.index(/#{@cmd}.+?#{@expect}/m)
      @match
    end
  end
  
  class DvsdkLinuxBaseClient < Equipment::LinuxEquipmentDriver
    include Log4r  
    attr_accessor :host, :port, :waittime
    attr_reader :response, :is_timeout
    
    def initialize(platform_info, log_path = nil)
      @listeners = Array.new
      @keep_listening = true
      @remaining_data = ''
      super(platform_info, log_path)
      start_listening
      rescue Exception => e
        log_info("Initialize: "+e.to_s)
        raise
    end
    
    def add_listener(listener)
      @listeners << listener
    end
    
    def remove_listener(listener)
      @listeners.delete(listener)
    end
    
    def notify_listeners(data)
      @listeners.each {|listener|
        listener.process_response(data)
      }
      @remaining_data += data
      log_info("Target: " + @remaining_data.slice!(/.*[\r\n]+/m)) if @remaining_data[/.*[\r\n]+/m]
    end
    
    def start_listening
      @listen_thread = Thread.new {
        while @keep_listening 
          if !@target.telnet.eof?
            last_read = @target.telnet.preprocess(@target.telnet.readpartial(524288))
            print last_read 
            notify_listeners(last_read)
          end
        end
      }		
    end
    
    def stop_listening
      @keep_listening = false
      @listen_thread.join(5)
    end

    def send_cmd(command)
      log_info("Host test: " + command)
      @target.telnet.puts(command)
    end

    def disconnect
      stop_listening 
      super
    end
    
    
        
  end
  
end