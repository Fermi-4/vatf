# staf_smartbits_sai_driver.rb v1.00
# Copyright: 11/24/2014 Texas Instruments Inc.

require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class is meant to interact with the SAI job queuing STAF service to run SAI jobs on a Smartbits Chassis.
  # The interactions from this driver can be logged using Log4r functionality
  class StafSmartbitsSaiDriver
    Logger = Log4r::Logger 
    #attr_accessor :host, :port
    
    #initialize the ip, service id, and log path
    # The first variable must be a hash that defines
    # * platform_info - REQUIRED - Equipment set used for defining this instance
    # * log_path - the path for the log file (default - nil ie. do not log)
    # Variables that need to be defined under params
    # * staf_ip - REQUIRED - the ip address of the host PC running the STAF job queuing service
    # * service_id - REQUIRED - the instance name of the STAF job queueing service on the host (e.g. smartbits@1)
    
    def initialize(platform_info, log_path = nil)
      platform_info.instance_variables.each {|var|
       	if platform_info.instance_variable_get(var).to_s.size > 0   
          self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
          self.instance_variable_set(var, platform_info.instance_variable_get(var))
        end
      }
      @host_ip = @params['staf_ip']
      @service_id = platform_info.id
      @unique_path_id = rand(36**8).to_s(36).strip
      @results_directory_path
      @smartbits_chassis_ip
      @staf_handle
      start_logger(log_path) if log_path
      log_info("Starting target session") if @smartbits_log
      start_staf
      set_chassis_ip
      set_local_results_path
      @results_file = File.join(@results_directory_path,"sai_results.txt")
      @packet_rate_file = File.join(@results_directory_path,"sai_packet_rate.csv")
      @transfer_results_file = File.join(@results_directory_path,"transfer.txt")
      @run_progress_file = File.join(@results_directory_path,"run_status.txt")
		end
    
    # Sets the SmartBits chassis IP address retrieved from the STAF SAI queuing service.
    def set_chassis_ip
      @smartbits_chassis_ip = sai_submit("CHASSISIP")
    end
    
    # Returns the SmartBits chassis IP address.
    # This IP address is used when creating the SAI configuration file.
    def get_chassis_ip
      @smartbits_chassis_ip
    end
    
    # Sets the local result path.
    def set_local_results_path
      @results_directory_path = File.join(get_results_data_dir_root,"#{@service_id}-#{@unique_path_id}")
      # Create local directory for SAI result files
      FileUtils.mkdir_p(@results_directory_path)
    end
    
    # Returns the local result path.
    def get_local_results_path
      @results_directory_path
    end
    
    # Returns the port information of the SmartBits chassis that will have SAI jobs submitted to it.
    # This port information can be used when creating the SAI configuration file.
    def get_port_info
      sai_submit("PORTINFO")
    end
    
    # Returns a list of request handles from the SAI job queuing service that have not yet acquired the resource.
    def get_pending_requests
      sai_submit("LISTPENDING")
    end
		
    # Returns the status and resource information for the Smartbits resource.
    def get_resource_info
      sai_submit("QUERY")
    end
    
    #Returns the handle that will be used to run the job once the resouce is available.
    #The calling routine should assume a time out has occurred if no handle information is retuned by this method.
    # * config_file - the name and extension of the SAI configuration file (e.g. eth1_eth2_1GF_udp.sai)
    # * wait_resource_timeout - The maximum time allowed to wait for the resource before returning (default = 24 hours).
    def request_resource(config_file, wait_resource_timeout = "24h")
      raw_response = sai_submit("REQUEST CONFIGFILE #{config_file} REMOTERESULTSPATH #{@results_directory_path} TIMEOUT #{wait_resource_timeout}")
      response_items = raw_response.split(":")
      # Return just the request handle from the STAF response
      return response_items[response_items.length - 1]
    end
    
    #Run the SAI job using handle from request_resource. Returns blank when job completes. Result files are copied to REMOTERESULTSPATH directory.
    #The calling routine should parse the run_status.txt file from the REMOTERESUILTSPATH directory to determine if the job ran successfully.
    # * handle - the handle of the job that has acquired the SmartBits resource. The handle would be what is returned by the request_resource method.
    # * wait_run_timeout - The maximum time allowed to wait for the job to run before returning (default = 12 hours).
    def run_job(handle, wait_run_timeout = "12h")
      sai_submit("RUN HANDLE #{handle} TIMEOUT #{wait_run_timeout}")
    end
    
    #Returns a listing of the file that is piped to during the SAI command run on the SAI job queuing host.
    # * handle - the handle of the job that has acquired the SmartBits resource. The handle would be what is returned by the request_resource method.
    def get_run_progress(handle)
      sai_submit("RUNSTATUS HANDLE #{handle}")
    end
    
    #Removes a request that has acquired the resource but is not yet running. Returns blank if successful.
    # * handle - the handle of the job that has acquired the SmartBits resource.
    def release_resource(handle)
      sai_submit("RELEASE HANDLE #{handle}")
    end
    
    #Removes a pending request that has not yest acquired the resource. Returns blank if successful.
    # * handle - the handle of the request that is pending.
    def cancel_request(handle)
      items = handle.split("_")
      reqnum = items[items.lenth -1]
      sai_submit("CANCEL REQNUM #{req_num}")
    end
    
    #Aborts a running job. Returns blank if successful. Returns blank if successful.
    # * handle - the handle of the job that has acquired the SmartBits resource and is running.
    def abort_job(handle)
      scrubbed_handle = handle.gsub(" (running)", "")
      sai_submit("ABORT HANDLE #{scrubbed_handle}")
    end
    
    # Returns the version number of the Smartbits STAF service.
    def get_version
      sai_submit("VERSION")
    end
    
    # Returns the list of supported request commands for Smartbits STAF service.
    def get_help
      sai_submit("HELP")
    end
    
    # Returns the name of the file that will be used to store the SAI results.
    def get_results_file_name
      @results_file_name
    end
    
    # Returns the contents of the results file.
    def get_results
      get_file_contents(@results_file) if File.exists?(@results_file)
    end
    
    # Returns the contents of the packet rate csv file.
    def get_packet_results
      get_file_contents(@packet_rate_file) if File.exists?(@packet_rate_file)
    end
    
    # Returns the contents of the transfer result file.
    def get_transfer_results
      get_file_contents(@transfer_results_file) if File.exists?(@transfer_results_file)
    end
    
    # Returns the contents of the run status file.
    def get_final_run_status
      get_file_contents(@run_progress_file) if File.exists?(@run_progress_file)
    end
    
    # Delete the old SAI results files.
    def delete_old_results_files
      FileUtils.rm(@results_file) if File.exists?(@results_file)
      FileUtils.rm(@packet_rate_file) if File.exists?(@packet_rate_file)
      FileUtils.rm(@transfer_results_file) if File.exists?(@transfer_results_file)
      FileUtils.rm(@run_progress_file) if File.exists?(@run_progress_file)
    end
    
    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
      if @smartbits_log
        stop_logger
      end
      Logger.new('smartbits_log')
      @smartbits_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @smartbits_log = Logger['smartbits_log']
      @smartbits_log.level = Log4r::DEBUG
      @smartbits_log.add  @smartbits_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @smartbits_log_outputter.formatter = @pattern_formatter     
    end
    
    # logs into the staf service and registers the apc with the given telnet_login & password and id
    def start_staf
      @staf_handle = STAFHandle.new("staf_ruby_smartbits")
    end
    
    #Stops the logger.
    def stop_logger
        @smartbits_log_outputter = nil if @dvtbc_log_outputter
        @smartbits_log = nil if @smartbits_log
    end
    
    private
    
    def get_results_data_dir_root
      temp = File.join(staf_local_submit("get system var STAF/DataDir"), "tmp")
    end
    
    def log_info(info)
      @smartbits_log.info(info) if @smartbits_log
    end
    
    def log_error(error)
      @smartbits_log.error(error) if @smartbits_log
    end
    
    def log_info(debug_info)
      @smartbits_log.info(debug_info) if @smartbits_log
    end
     
    def sai_submit(command)
      log_info('Cmd: ' + command)
      staf_result = @staf_handle.submit(@host_ip,@service_id,command)
      log_info('Result: ' + staf_result.result)
      puts staf_result.result
      staf_result.result
    end
    
    def staf_local_submit(command)
      log_info('Cmd: ' + command)
      staf_result = @staf_handle.submit("local","var",command)
      log_info('Result: ' + staf_result.result)
      puts staf_result.result
      staf_result.result
    end
    
    def get_file_contents(file_path_name)
      File.open(file_path_name) do |fd|
        fd.readlines()
      end
    end
    
  end
end

