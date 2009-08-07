require 'db_handler/db_handlers'
require 'equipment_info'
require 'html_writers/html_writers'
require 'optparse'
require 'ostruct'
require 'framework_constants'
require 'connection_equipment/connection_equipment'
require 'fileutils'
require 'connection_handler'
require 'media_equipment/media_equipment'
require 'test_equipment/test_equipment'
require 'dvsdk/dvsdk'
require 'vgdk/vgdk'
require 'rubyclr'
require 'file_converters/file_converters'
require 'win_forms/win_forms'
require 'find'
require 'facets'
require 'target/lsp_target'
require 'external_systems/external_systems'
require 'net/smtp'
require 'site_info'

module Find
  def file(*paths)
    find(*paths) { |path| return path if yield path }
  end
  module_function :file
end

=begin
  This class is used to parse the command line and store the session parameter
=end
class CmdLineParser
    #
    # Return a structure describing the options.
    #
    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      options = OpenStruct.new
      options.rtp = nil
      options.session_iterations = 1
      options.tests_to_run = [['all', 1]]
      options.tester = 'testlink'
      options.drive = nil
      options.bench_path = "C:/VATF/bench.rb"
      options.results_base_dir = "//gtsnowball/System_Test/Automation/gtsystst_logs/video"
      options.platform = nil
      options.num_fails_to_reboot = nil
      options.target_source_drive = nil
      options.email = nil
      options.release = nil
      
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: atf_run.rb -u <user name> -v <view drive> -r <rtp path or image::level:=areas> [-s <n>] [-d <results directory>] [-b <bench file path>] [-p <platform>] [-x <np for reboot>] [-e <target code sources>] [-k <product version>] [-m <e-mail address>] -t <[tcaseID1,...,tcaseIDn]*n;tcaseIDx;....;tcaseID>"
        
        opts.separator " "
        opts.separator "Specific options:"
        
        opts.on("-u name","=OPTIONAL","Tester's name or Id") do |tster|
          options.tester = tster.strip
        end
        
        opts.on("-t tests","=OPTIONAL","Test cases to run, -t option format is one or more semicolon separated string of structure <tests cases to run>*<number of times to run each case>;.... where *<number of times to run each case> is optional and <test cases to run> can be an array of caseID i.e [caseID,caseID,...]") do |test_cases|
          options.tests_to_run = []
          tcase_array = test_cases.split(';')
          tcase_array.each do |val|
            test_param = val.split('*')
            iterations = 1
            iterations = test_param[1].to_i if test_param[1]
            tests_array = test_param[0].scan(/[^\s\*,\[\]]+/)
            tests_array.each do |test_range|
              if test_range.downcase == 'all'
                options.tests_to_run << ['all', iterations]
              else
                limits = test_range.split('-')
                start = limits[0].to_i
                options.tests_to_run << [start, iterations]
                while limits[1] && limits[1].to_i > start
                    start += 1
                    options.tests_to_run << [start, iterations]
                end
              end
            end
          end
        end
        
        opts.on("-e target source path","=OPTIONAL","Embedded target source path") do |path|
          options.target_source_drive = path.strip
        end
        
        opts.on("-v drive","=OPTIONAL","view drive letter, i.e x:") do |drive|
          options.drive = drive.strip
        end
        
        opts.on("-s n","=OPTIONAL","specifies the number of times this session will run all the tests") do |sess_iter|
          options.session_iterations = sess_iter.to_i
        end
        
        opts.on("-d","=OPTIONAL","specified the directory used to store the html results") do |res_dir|
          options.results_base_dir = res_dir.sub(/(\\|\/)$/,'')
        end
        
        opts.on("-b","=OPTIONAL","specifies the path of the bench.rb file") do |bnch_pth|
          options.bench_path = bnch_pth
        end 
        
        opts.on("-p","=OPTIONAL IF -r IS AN RTP PATH","specifies the platform type used for the tests, setting this parameter overrides the platform value specified in the matrix. Also, if this option is used the value must match a bench file entry") do |pltfrm|
          options.platform = pltfrm
        end
        
        opts.on("-k","=OPTIONAL IF -r IS AN RTP PATH","specifies the release to be tested. For instance, it could be the kernel version or a product/component version") do |release|
          options.release = release
        end
        
        opts.on("-m","=OPTIONAL","specifies the e-mail address(es) to send the test results summary at the end of the test execution. Separate multiple address w/ semicolons") do |email_addr|
          options.email = email_addr
        end
        
        opts.on("-r path","=MANDATORY","a semicolon combination of paths to rtp(s), i.e. [binary_path##sourcepath::]C:\\an_rtp.mdb; and a string of structure image_path::level:=areas, i.e myTargetImage::sanity:=[usb,nand,video]") do |path|
          options.rtp = Hash.new{|rtp_hash, rtp_key| rtp_hash[rtp_key] = Hash.new}
          rtp_array = path.split(';')
          rtp_array.each do |val|
            image_and_level_plus_areas = val.strip.split('::')
            image_and_level_plus_areas.insert(0,nil) if image_and_level_plus_areas.length < 2 
            image_and_source = [nil, nil]             
            image_and_source = image_and_level_plus_areas[0].split('##') if image_and_level_plus_areas[0]
            image = image_and_source[0] 
            sources = nil
            sources = image_and_source[1] if  image_and_source[1]
            level_and_areas = image_and_level_plus_areas[1]            
            if level_and_areas.include?(":=")
                level_plus_areas = level_and_areas.split(':=')
                level = level_plus_areas[0].strip
                areas = level_plus_areas[1].strip.gsub(/[\s\[\]]/,'').split(',')
                options.rtp[level][image] = {'sources' => sources, 'test_areas' => areas}
            else
                rtp_paths = level_and_areas.strip.gsub(/[\s\[\]]/,'').split(',')
                rtp_paths.each do |current_path| 
                  options.rtp[current_path][image] = {'sources' => sources, 'test_areas' => current_path}
                end
            end
          end
        end
        
        opts.on("-x","=OPTIONAL","specifies the number of consecutive failed or skipped tests that causes a dut reboot (if supported in test script). If this value is not specified then the system is never rebooted by the VATF") do |num_fails|
          options.num_fails_to_reboot = num_fails.to_i
        end
        
        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
     end   
     opts.parse!(args)
     
     if !options.rtp #|| !options.tests_to_run || !options.tester || !options.drive
        puts opts
        exit
     end
     
     options.rtp.each do |rtp_key, rtp_image|
      rtp_image.each do |rtp_image, rtp_val|
        if rtp_val['test_areas'].kind_of?(Array) && (!rtp_image || !options.platform)
          puts "Argument -p missing or image path not specified for #{rtp_image.to_s}###{rtp_val['sources']}::#{rtp_key}:=#{rtp_val['test_areas'].to_s}"
          puts opts
          exit
        end
      end
     end
     options

    end
end


=begin
  This class is used to run a test session.
=end
class SessionHandler
  public
    
    #Constructor of the class. Takes req_params a Hash containing: 
    #                 rtp_path the path to the release test plan used in this test session (string)
    #                 view_drive letter associated with the view where the test script will be taken from (string)
    #                 results_path the path where the files with the session results will be stored (string)
    #And optionally opt_prams a Hash containing the following optional parameters
    #                 consec_non_pass the number of consecutive test failures occurrences to reboot the system (integer) if given
    #                 multi_sess_sum path of the multisession html result page if any (String)
    #                 pltfrm the platform to be used for the test if given (string)
    #                 img path of the image that will be loaded to the board for testing if any (string).
    def initialize(req_params, opt_params)
      params = {'rtp_path' =>nil, 'view_drive' => nil, 'bench_path' => nil, 'results_path' => nil}.merge(req_params)
      raise "Required parameter missing in #{self.class.to_s}::initialize" if params.has_value?(nil)      
      params = params.merge({'target_source_drive' => nil, 'consec_non_pass' => nil, 'multi_sess_sum' => nil, 'platform' => nil, 'img' => nil}.merge(opt_params))
      @cli_params = params
      require params['bench_path'].gsub(/\.\w*$/,"")
      @view_drive = params['view_drive']
      @target_source_drive = params['view_drive']
      @target_source_drive = params['target_source_drive'] if params['target_source_drive']
      @session_results_base_directory = params['results_path'].strip.gsub("\\","/").sub(/(\\|\/)$/,'') if params['results_path']
      FileUtils.mkdir_p(@session_results_base_directory) unless File.exists?(@session_results_base_directory)     
      @rtp_path = params['rtp_path']
      case File.extname(@rtp_path)
        when ".xml"
            @rtp_db = XMLAtfDbHandler.new("xml")
            @db_type = "xml"
        when ".mdb"
            @rtp_db = AccessAtfDbHandler.new()
        else
      end
      @rtp_db.connect_database(@rtp_path)
      @multi_session_summary = params['multi_sess_sum']
      @image_path = params['img'].gsub(/\//,"\\") if params['img']
      @consecutive_non_pass_allowed = params['consec_non_pass']
      @consecutive_non_passed_tests = 0
      @old_keys = '';@new_keys = ''
    end
    
    #This function starts a test session initializes the results counter creates the files and directories to store the session results. Takes
    # tester the name or id of the tester (string).
    def start_session(tester)
      @tester = tester
      @session_start_time = Time.now
      @test_sess_sum = [0,0,0]
      @session_dir = @session_results_base_directory+'/'+tester+@session_start_time.strftime("%m_%d_%Y_%H_%M_%S")     
      FileUtils.mkdir_p(@session_dir) unless File.exists?(@session_dir)
      @session_html_path = @session_dir+"/session.html"
      @target_name = @rtp_db.get_target.to_s
      @target_name = @cli_params['release'] if @cli_params['release']
      @session_html = SessionSummaryHtml.new(@session_html_path," Session "+@session_start_time.strftime("%m_%d_%Y_%H_%M_%S"),@target_name)
      @session_html.add_run_information_tables(@tester)
      @session_html.add_multisession_summary_link(@multi_session_summary) if @multi_session_summary
      @session_html.add_tests_info_table
    end
    
    #This function initializes the iterations variables and iterations result counter for a test. Takes test_case_id the caseID of the test that will be run (number),
    #session_iter the session iteration number (number), and num_test_iterations the number of iterations to be run for this test (number).
    def init_test_iterations(test_case_id, session_iter, num_test_iterations)
        if @rtp_db.test_exists(test_case_id)
        @non_existent_tests = Hash.new
        @session_iter = session_iter
        @test_id = test_case_id
        @test_iterations_start_time = Time.now
        @test_iter_sum = [0,0,0]
        @files_dir = @session_dir+"/files/session_iteration_"+@session_iter.to_s+"/test_"+test_case_id.to_s
        FileUtils.mkdir_p(@files_dir) unless File.exists?(@files_dir)
        @test_iter_summary_html_path = @files_dir+"/iterZummary.html"
        @test_iter_summary_html = TestIterationsHtml.new(@test_iter_summary_html_path,"Test Iterations Summary", @target_name)
        @test_iter_summary_html.add_test_summary_info_tables(test_case_id.to_s)
        @test_iter_summary_html.add_summary_link(@session_html_path, @multi_session_summary)
        @test_iter_summary_html.add_test_iterations_table
        1.upto(num_test_iterations) do |test_iter| #running the number of iterations defined for this test
          puts "\n\nRunning Test #{test_case_id.to_s} test iteration #{test_iter.to_s} session iteration #{@session_iter.to_s}"
          if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
            @rtp_db.staf_handle.submit("local","MONITOR","LOG MESSAGE 'Running Test #{test_case_id.to_s} test iteration #{test_iter.to_s} session iteration #{@session_iter.to_s}' NAME test_status ")
          end
          start_test(test_iter) 
          sleep 1 #Added because some platforms can not handle a fast disconnections->connections operation
        end  
      else
        @non_existent_tests[test_case_id]= test_case_id.to_s+", "
      end
      rescue Exception => e
        puts e.to_s
      ensure
          save_iterations_result if @rtp_db.test_exists(test_case_id)  
          
    end
    
    #This function starts the test. Takes iter the test iteration number (number)
    def start_test(iter)
      @test_start_time = Time.now
      @test_result = [FrameworkConstants::Result[:fail],"This is the default result comment. Use function set_result to set this comment"]
      @rtp_db.set_test_tables(@test_id)
      test_result_html_path = @files_dir+"/"+/[\\\/]*(\w+)\.*\w*$/.match(@rtp_db.get_test_script)[1].to_s+"_#{iter.to_s}.html"
      @results_html_file = TestResultHtml.new(test_result_html_path,"Test Result",@target_name.to_s)
      @results_html_file.add_test_information_table(@tester)
      @results_html_file.add_summaries_links(@session_html_path, @test_iter_summary_html_path, @multi_session_summary)
      @results_html_file.add_logs_table
      @results_html_file.add_test_result_table  
      @equipment = Hash.new
      @connection_handler = ConnectionHandler.new(@files_dir)      
      logs_array = Array.new
      @test_params = @rtp_db.get_test_parameters
      @test_params.image_path = Hash.new{|img_hash,img_key| img_hash[img_key] = @image_path} if @image_path
      @test_params.platform = @cli_params['platform'] if @cli_params['platform']
      @test_params.target = @cli_params['release'] if @cli_params['release']
      
      # if auto flag is not set, do not run this test
      raise "The auto flag is not set. Assuming this test case is manual. Skip to next test case" if !@rtp_db.get_auto_flag
      
      if @consecutive_non_pass_allowed && @consecutive_non_pass_allowed <= @consecutive_non_passed_tests
         @old_keys = ''
         puts "#{@consecutive_non_passed_tests} consecutive tests have not passed setting system for reboot" 
         @consecutive_non_passed_tests = 0
      end
      
      begin
        var = ''
        e_type = ''
        case(@db_type)
          when "xml"
            config_file = @rtp_db.get_config_script.split(";")
          else
            config_file = File.new(@view_drive+@rtp_db.get_config_script,"r")
        end
        config_file.each do |line|
            raise "platform has not been specified in test matrix!!" if line.downcase.include?("<platform>") && !@rtp_db.get_platform && !@cli_params['platform']
            line.sub!(/<platform>/i, @cli_params['platform'] ? @cli_params['platform'] : @rtp_db.get_platform.to_s)
            config_matches = /^([^#]+)=([^#]+)/i.match(line.strip)
            if config_matches && (var, e_type = config_matches.captures)[1]
                var = var.strip
                e_type = e_type.strip
                equip_class_type, equip_id = /([\w-]+)[",\s]*([\w-]+)/i.match(e_type).captures
                equip_class_type = equip_class_type.downcase.strip
                equip_id = equip_id.to_i
                equip_log = @files_dir+"/"+var.strip+"_"+iter.to_s+"_log.txt"
                if $equipment_table[equip_class_type][equip_id].driver_class_name 
                    if Object.const_get($equipment_table[equip_class_type][equip_id].driver_class_name).method_defined?(:start_logger)            
                        @equipment[var] = Object.const_get($equipment_table[equip_class_type][equip_id].driver_class_name).new($equipment_table[equip_class_type][equip_id],equip_log)
                    else
                        @equipment[var] = Object.const_get($equipment_table[equip_class_type][equip_id].driver_class_name).new($equipment_table[equip_class_type][equip_id].telnet_ip)
                    end
                else
                    @equipment[var] = var
                end 
                @connection_handler.load_switch_connections(@equipment[var],equip_class_type,equip_id, iter)
                logs_array << [var, equip_log] if $equipment_table[equip_class_type][equip_id].driver_class_name && Object.const_get($equipment_table[equip_class_type][equip_id].driver_class_name).method_defined?(:start_logger)
            end
        end
        rescue Exception => e
            raise e.to_s+"\n Unable to assign equipment #{e_type} to #{var}. Verify that #{@rtp_db.get_config_script} contains valid bench file entries; that you can communicate with #{e_type}; and that #{e_type} IO information is correct."
      end
      @connection_handler.media_switches.each{|key,val| logs_array << ["MediaSwitch"+key.to_s, val[1]]}
      test_script_found = false
      #require @view_drive+@rtp_db.get_test_script.gsub(".rb","")
      load @view_drive+@rtp_db.get_test_script
      t_setup = Time.now.to_s
      puts "\n===== Calling "+@rtp_db.get_test_script+"'s setup() at time "+t_setup
      if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
        @rtp_db.staf_handle.submit("local","MONITOR","LOG MESSAGE '\n===== Calling #{@rtp_db.get_test_script}'s setup() at time #{t_setup}' NAME test_status ")
      end
      setup   
      t_run = Time.now.to_s
      puts "\n===== Calling "+@rtp_db.get_test_script+"'s run() at time "+t_run
      if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
       @rtp_db.staf_handle.submit("local","MONITOR","LOG MESSAGE '\n===== Calling #{@rtp_db.get_test_script}'s run() at time #{t_run}' NAME test_status ")
      end
      run
      test_script_found = true
      case(@test_result[0])
        when FrameworkConstants::Result[:pass]
          @test_iter_sum[0] += 1
          @test_sess_sum[0] += 1
          @consecutive_non_passed_tests = 0
        when FrameworkConstants::Result[:fail]
          @test_iter_sum[1] += 1
          @test_sess_sum[1] += 1
          @consecutive_non_passed_tests += 1
      end
      html_result = @test_result[1]
      rescue Exception => e
        @test_iter_sum[2] += 1
        @test_sess_sum[2] += 1
        @consecutive_non_passed_tests += 1 if @test_params.auto
        @test_result[0] = FrameworkConstants::Result[:blk]
        @test_result[1] = e.to_s.gsub(/\s+/," ")
        html_result = e.backtrace.to_s.gsub(/\s+/," ")
        puts html_result.to_s
        raise
      ensure
        @old_keys = @new_keys
        @test_ended = Time.now
        config_file.close if config_file && !is_db_type_xml?(@db_type)
        @rtp_db.set_test_result(@rtp_db.get_test_script, @test_result[0], @test_result[1],"0",@test_result_html_path, @test_start_time, @test_ended, iter, @tester.to_s, @test_params.platform, @test_params.target) 
        @results_html_file.add_logs(logs_array)
        @results_html_file.add_test_result(@rtp_db.get_test_description.to_s, @test_result[0], html_result)
        @results_html_file.add_test_information(@rtp_db.get_test_id.to_s, @rtp_db.get_test_script.to_s, @rtp_db.get_test_description.to_s, @test_start_time.strftime("%m/%d/%Y  %I:%M%p"), @test_ended.strftime("%m/%d/%Y  %I:%M%p"), @test_ended.strftime("%m/%d/%Y  %I:%M%p"))
        @results_html_file.write_file
        @test_iter_summary_html.add_iterations_result(["Iteration "+iter.to_s, test_result_html_path, @test_result[0], @test_result[1]])
        t_clean = Time.now.to_s
        puts "===== Calling "+@rtp_db.get_test_script+"'s clean() at time "+t_clean
        if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
          @rtp_db.staf_handle.submit("local","MONITOR","LOG MESSAGE '===== Calling #{@rtp_db.get_test_script}'s clean() at time #{t_clean}' NAME test_status")
        end
        clean if test_script_found
        @connection_handler.media_switches.each {|key,val| val[0].stop_logger} if @connection_handler
        @equipment.each_value do |val| 
          val.stop_logger if val.respond_to?(:stop_logger)
          val.disconnect if val.respond_to?(:disconnect) && val.respond_to?(:stop_logger)
#          puts val.class.to_s+" = "+ObjectSpace.each_object(val.class){}.to_s  # DEBUG: Uncomment this line to get a print out of the number of test equipment objects
        end
        @connection_handler.disconnect if @connection_handler

    end
    
    #This function is used inside the test script to set the result for the test. Takes test_result the result of the test (FrameworkConstants::Result), and comment a comment associated with the test result (string) as parameters.
    def set_result(test_result,comment = nil)
      @test_result[0] = test_result
      @test_result[1] = comment if comment
    end
    
    #This function saves the results for the multiple iterations ran for a given test.
    def save_iterations_result
      @test_iterations_ended = Time.now
      @test_iter_summary_html.add_test_summary_info(@test_iterations_start_time.strftime("%m/%d/%Y  %I:%M%p") , @test_iterations_ended.strftime("%m/%d/%Y  %I:%M%p"), @test_iterations_ended.strftime("%m/%d/%Y  %I:%M%p"))
      @test_iter_summary_html.add_test_iterations_totals(@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2])
      @test_iter_summary_html.write_file
      ensure
        test_iter_summ_html_path = @test_iter_summary_html_path.gsub("/","\\")
        @rtp_db.set_test_iterations_result(@rtp_db.get_test_script,@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2],test_iter_summ_html_path,@session_iter,@test_iterations_start_time,@test_iterations_ended)
        @session_html.add_test_row([@session_iter.to_s,["Case ID: "+@rtp_db.get_test_id.to_s,@test_iter_summary_html_path],@rtp_db.get_test_description,[@rtp_db.get_test_script.split(/[\\\/]/)[-1],"//"+@view_drive.gsub("\\","/")+@rtp_db.get_test_script.gsub("\\","/")],FrameworkConstants::Status[:complete],@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2]])
    end
    
    #This function save the result associated with a session. Takes session_iter_completed the session iteration number completed (number)
    def save_session_results(session_iter_completed)
      @session_ended = Time.now
   
      if @non_existent_tests.values.length > 0
        @session_html.add_paragraph("Test case(s): "+@non_existent_tests.values.to_s+" do(es) not exist in the database",{:color => "#FF0000"})
      end
      #@session_html.add_run_information(@session_start_time.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @rtp_path, @test_params.platform, @test_params.image_path['kernel'])
      @session_html.add_run_information(@session_start_time.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @rtp_path, @test_params.platform, (@image_path.to_s == ""? "Image Path In Database" : @image_path) )
      @session_html.add_totals_information(@test_sess_sum[0],@test_sess_sum[1],@test_sess_sum[2])
      @session_html.write_file
      ensure
        @rtp_db.set_session_result(@tester,@test_sess_sum[0],@test_sess_sum[1],@test_sess_sum[2],@session_html_path,@session_start_time,@session_ended,session_iter_completed,4)
        if !is_db_type_xml?(@db_type)
          @rtp_db.remove_connection if @rtp_db.connected?
        end
        return @test_sess_sum
    end
    
    #This function returns the path of the html page containing the results of the last test session excuted
    def get_session_html
        @session_html_path.to_s
    end
    
    #This function returns an array witth all the caseIDs contained in the test matrix
    def get_all_test_cases
        @rtp_db.get_tcases_ids
    end

    def is_db_type_xml?(db_type)
      if(db_type == "xml")
        return true
      else
        return false
      end
    end
 
    

end 


