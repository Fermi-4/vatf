require File.dirname(__FILE__)+'/db_handler/db_handlers'
require File.dirname(__FILE__)+'/equipment_info'
require File.dirname(__FILE__)+'/lib/os_func'
require File.dirname(__FILE__)+'/html_writers/html_writers'
require 'optparse'
require 'ostruct'
require File.dirname(__FILE__)+'/framework_constants'
require File.dirname(__FILE__)+'/connection_equipment/connection_equipment'
require 'fileutils'
require File.dirname(__FILE__)+'/connection_handler'
require File.dirname(__FILE__)+'/power_handler'
require File.dirname(__FILE__)+'/usb_switch_handler'
require File.dirname(__FILE__)+'/media_equipment/media_equipment'
require File.dirname(__FILE__)+'/test_equipment/test_equipment'
# require File.dirname(__FILE__)+'/rubyclr'
require File.dirname(__FILE__)+'/file_converters/file_converters'
# require File.dirname(__FILE__)+'/win_forms/win_forms'
require 'find'
require 'facets'
require File.dirname(__FILE__)+'/target/targets'
require File.dirname(__FILE__)+'/external_systems/external_systems'
require 'net/smtp'
require File.dirname(__FILE__)+'/site_info'
require File.dirname(__FILE__)+'/lib/pass_criteria'
require 'socket'

module Find
  def file(*paths)
    find(*paths) { |path| return path if yield path }
  end
  module_function :file

  def files(*paths)
    result = []
    find(*paths) { |path| result = result | [path] if yield path }
    result
  end
  module_function :files
end

=begin
  This class is used to parse the command line and store the session parameter
=end
class CmdLineParser
    #
    # Return a structure describing the options.
    #
    include OsFunctions

    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      options = OpenStruct.new
      options.rtp = nil
      options.session_iterations = 1
      options.tests_to_run = [['all', 1]]
      options.tester = Socket.gethostname
      options.drive = nil
      options.bench_path = SiteInfo::BENCH_FILE
      options.results_base_dir = SiteInfo::LOGS_FOLDER
      options.results_base_url = SiteInfo::LOGS_SERVER
      options.platform = nil
      options.num_fails_to_reboot = nil
      options.target_source_drive = nil
      options.email = nil
      options.release_assets = {}
      options.browser = true
      options.results_file = SiteInfo::RESULTS_FILE
      options.staf_service_name = nil

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

        opts.on("-v drive","=MANDATORY","view drive letter, i.e x:") do |drive|
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

        opts.on("-o","do NOT open browser with results html at the end of the test session") do
          options.browser = false
        end

        opts.on("-m","=OPTIONAL","specifies the e-mail address(es) to send the test results summary at the end of the test execution. Separate multiple address w/ semicolons") do |email_addr|
          options.email = email_addr
        end

        opts.on("-r path","=MANDATORY","a semicolon combination of paths to rtp(s), i.e. [binary_path##sourcepath::]C:\\an_rtp.mdb; and a string of structure image_path::level:=areas, i.e myTargetImage::sanity:=[usb,nand,video]") do |path|
          options.rtp = {}
          rtp_array = path.split(';')
          rtp_array.each do |val|
            if val.include?(":=")
                level_plus_areas = val.split(':=')
                level = level_plus_areas[0].strip
                areas = level_plus_areas[1].strip.gsub(/[\s\[\]]/,'').split(',')
                options.rtp[level] = {'test_areas' => areas}
            else
                rtp_paths = val.strip.gsub(/[\s\[\]]/,'').split(',')
                rtp_paths.each do |current_path|
                  options.rtp[current_path] = {'test_areas' => current_path}
                end
            end
          end
        end

        opts.on("-a","=OPTIONAL","Specifies the information regarding any asset(s) required to run a test. The sytanx used is a semicolon separated set of <asset name>=<asset information> pairs") do |assets|
          assets_array = assets.split(/(?<!\\)[;]/)
          assets_array.each do |current_asset|
            asset_info = current_asset.split(/(?<!\\)[=]/)
            options.release_assets[asset_info[0].strip] = asset_info[1].strip.gsub(/\\(?=[=:;,])/,"")
          end
        end

        opts.on("-x","=OPTIONAL","specifies the number of consecutive failed or skipped tests that causes a dut reboot (if supported in test script). If this value is not specified then the system is never rebooted by the VATF") do |num_fails|
          options.num_fails_to_reboot = num_fails.to_i
        end

        opts.on("-f","=OPTIONAL","specifies the path where the results will be saved when working with xml files as test data") do |res_file|
          options.results_file = res_file
        end

        opts.on("-l","=OPTIONAL","specifies the URL where that can be used to access the files specified by -d") do |base_url|
          options.results_base_url = base_url
        end

        opts.on("-w","=OPTIONAL","specifies the name of STAF service that is calling vatf") do |base_url|
          options.staf_service_name = base_url
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

     if !options.rtp || !options.drive #|| !options.tests_to_run || !options.tester
        puts opts
        exit
     end

     options.rtp.each do |rtp_key, rtp_val|
      if rtp_val['test_areas'].kind_of?(Array) && (!options.release_assets['kernel'] || !options.platform)
        puts "Argument -p missing or image path not specified for #{rtp_key}:=#{rtp_val['test_areas'].to_s}"
        puts opts
        exit
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
      params = {'rtp_path' =>nil, 'view_drive' => nil, 'bench_path' => nil, 'results_path' => nil, 'results_server' => nil}.merge(req_params)
      raise "Required parameter missing in #{self.class.to_s}::initialize" if params.has_value?(nil)
      params = params.merge({'target_source_drive' => nil, 'consec_non_pass' => nil, 'multi_sess_sum' => nil, 'platform' => nil, 'release_assets' => {}, 'results_file' => nil, 'staf_service_name' => nil}.merge(opt_params))
      @cli_params = params
      begin
        require params['bench_path'].gsub(/\.\w*$/,"")
      rescue Exception=>e
        puts "Problem while trying to load bench file #{params['bench_path']}."
        puts "Verify that file #{params['bench_path']} exists, and does not contain errors." 
        puts e.to_s+"\n"+e.backtrace.to_s
	exit(1)
      end
      @view_drive = params['view_drive']
      @target_source_drive = params['view_drive']
      @target_source_drive = params['target_source_drive'] if params['target_source_drive']
      @session_results_base_directory = params['results_path'].strip.gsub("\\","/").sub(/(\\|\/)$/,'') if params['results_path']
      @session_results_base_url = @session_results_base_directory
      @session_results_base_url = params['results_server'].strip.gsub("\\","/").sub(/(\\|\/)$/,'') if params['results_server']
      FileUtils.mkdir_p(@session_results_base_directory) unless File.exists?(@session_results_base_directory)
      @rtp_path = params['rtp_path']
      case File.extname(@rtp_path)
        when ".xml"
            @rtp_db = XMLAtfDbHandler.new("xml", params['results_file'], params['staf_service_name'])
            @db_type = "xml"
        when ".mdb"
            @rtp_db = AccessAtfDbHandler.new()
        else
      end
      @rtp_db.connect_database(@rtp_path)
      @multi_session_summary = params['multi_sess_sum']
      @multi_session_link = @multi_session_summary
      @multi_session_link = @multi_session_summary.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"") if params['multi_sess_sum']
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
      @session_dir = File.join(@session_results_base_directory,tester+@session_start_time.strftime("%m_%d_%Y_%H_%M_%S"))
      FileUtils.mkdir_p(@session_dir) unless File.exists?(@session_dir)
      @session_html_path = File.join(@session_dir,"session.html")
      @session_html_url = @session_html_path.sub(@session_results_base_directory,@session_results_base_url)
      @target_name = @rtp_db.get_target.to_s
      @target_name = @cli_params['release'] if @cli_params['release']
      @session_html = SessionSummaryHtml.new(@session_html_path," Session "+@session_start_time.strftime("%m_%d_%Y_%H_%M_%S"),@target_name)
      @session_html.add_run_information_tables(@tester)
      @session_html.add_multisession_summary_link(@multi_session_link) if @multi_session_summary
      @session_html.add_tests_info_table
    end

    #This function initializes the iterations variables and iterations result counter for a test. Takes test_case_id the caseID of the test that will be run (number),
    #session_iter the session iteration number (number), and num_test_iterations the number of iterations to be run for this test (number).
    def init_test_iterations(test_case_id, session_iter, num_test_iterations)
        @non_existent_tests = Hash.new
		if @rtp_db.test_exists(test_case_id)
        @session_iter = session_iter
        @test_id = test_case_id
        @test_iterations_start_time = Time.now
        @test_iter_sum = [0,0,0]
        @files_dir = File.join(@session_dir,"files/session_iteration_"+@session_iter.to_s+"/test_"+test_case_id.to_s)
        FileUtils.mkdir_p(@files_dir) unless File.exists?(@files_dir)
        @test_iter_summary_html_path = File.join(@files_dir,"iterZummary.html")
        @test_iter_summary_html = TestIterationsHtml.new(@test_iter_summary_html_path,"Test Iterations Summary", @target_name)
        @test_iter_summary_html.add_test_summary_info_tables(test_case_id.to_s)
        @test_iter_summary_html.add_summary_link(@session_html_url.sub(/http:\/\//i,""), @multi_session_link)
        @test_iter_summary_html.add_test_iterations_table
        1.upto(num_test_iterations) do |test_iter| #running the number of iterations defined for this test
          puts "\n\nRunning Test #{test_case_id.to_s} test iteration #{test_iter.to_s} session iteration #{@session_iter.to_s}"
          if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
            @rtp_db.monitor_log("Running Test #{test_case_id.to_s} test iteration #{test_iter.to_s} session iteration #{@session_iter.to_s}")
          end
          start_test(test_iter) 
          sleep 1 #Added because some platforms can not handle a fast disconnections->connections operation
        end
      else
        @non_existent_tests[test_case_id]= test_case_id.to_s+", "
      end
      rescue Exception => e
        puts e.to_s+"\n"+e.backtrace.to_s
      ensure
          save_iterations_result if @rtp_db.test_exists(test_case_id)

    end

    #This function starts the test. Takes iter the test iteration number (number)
    def start_test(iter)
      @current_test_iteration = iter
      @test_start_time = Time.now
      @test_result = TestResult.new
      @rtp_db.set_test_tables(@test_id)
      test_result_html_path = File.join(@files_dir,/[\\\/]*(\w+)\.*\w*$/.match(@rtp_db.get_test_script)[1].to_s+"_#{iter.to_s}.html")
      @results_html_file = TestResultHtml.new(test_result_html_path,"Test Result",@target_name.to_s)
      @results_html_file.add_test_information_table(@tester)
      @results_html_file.add_summaries_links(@session_html_url.sub(/http:\/\//i,""), @test_iter_summary_html_path.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,""), @multi_session_link)
      @results_html_file.add_logs_table
      @results_html_file.add_test_result_table
      @equipment = Hash.new
      @connection_handler = ConnectionHandler.new(@files_dir)
      @power_handler = PowerHandler.new()
      @usb_switch_handler = UsbSwitchHandler.new()
      @logs_array = Array.new
      temp_params = @cli_params.clone
      temp_params.delete('release_assets')
      @test_params = @rtp_db.get_test_parameters(temp_params.merge(@cli_params['release_assets']))
      @test_params.image_path = @test_params.image_path.merge(@cli_params['release_assets']) if @test_params.image_path
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
        case(@db_type)
          when "xml"
            config_file = @rtp_db.get_config_script.split(";")
          else
            config_file = File.new(@view_drive+@rtp_db.get_config_script,"r")
        end
        equipment_list = Hash.new{|h,k| h[k] = Hash.new}
        config_file.each do |line|
            raise "platform has not been specified in test matrix!!" if line.downcase.include?("<platform>") && !@rtp_db.get_platform && !@cli_params['platform']
            line.sub!(/<platform>/i, @cli_params['platform'] ? @cli_params['platform'] : @rtp_db.get_platform.to_s)
            config_matches = /^([^#]+)=([^#]+)/i.match(line.strip)
            if config_matches && (var, e_type = config_matches.captures)[1]
                var = var.strip
                e_type = e_type.strip
                equip_class_type, equip_id = /([\w-]+)(?:[",\s]+([\w-]+)){0,1}/i.match(e_type).captures
                equip_class_type = equip_class_type.downcase.strip
                equip_id = equip_id.to_s.downcase.strip
                if(!equipment_list[equip_class_type][equip_id])
                  equipment_list[equip_class_type][equip_id] = []
                end
                equipment_list[equip_class_type][equip_id] << var
            end
          end
        rescue Exception => e
          raise e.to_s+"\n"+e.backtrace.to_s+"\nVerify that #{@rtp_db.get_config_script} contains valid bench file entries"
      end
      vatf_default_features=$LOADED_FEATURES.dup
      begin
        current_etype = ''
        eq_id = ''
        current_instance = ''
        current_var = ''
        equipment_list.each do |equip_type, equip_info|
          current_etype = equip_type
          assets_caps = $equipment_table[equip_type].keys.clone.sort.reverse
          equip_info.keys.sort.reverse.each do |req_caps|
            equip_info[req_caps].each_with_index do |test_vars, i|
              current_var = test_vars
              current_instance = i
              equip_log = File.join(@files_dir,test_vars.strip+"_"+iter.to_s+"_log.txt")
              eq_id = req_caps
              if !$equipment_table[equip_type][eq_id] || !$equipment_table[equip_type][eq_id][i]
                assets_caps.each do |current_asset_caps|
                  if req_caps == '' || (current_asset_caps.downcase.split('_') & req_caps.split('_')).sort == req_caps.split('_').sort
                    eq_id = current_asset_caps
                    break
                  end
                end
              end
              raise "Unable to find asset #{equip_type} with #{req_caps} capabilities" if !$equipment_table[equip_type][eq_id] || !$equipment_table[equip_type][eq_id][i]
              if $equipment_table[equip_type][eq_id][i].driver_class_name
                  if $equipment_table[equip_type][eq_id][i].driver_class_name.strip.downcase != 'operaforclr'
                      @equipment[test_vars] = Object.const_get($equipment_table[equip_type][eq_id][i].driver_class_name).new($equipment_table[equip_type][eq_id][i],equip_log)
                  else
                      @equipment[test_vars] = Object.const_get($equipment_table[equip_type][eq_id][i].driver_class_name).new($equipment_table[equip_type][eq_id][i].telnet_ip)
                  end
              else
                  @equipment[test_vars] = test_vars
              end
              @connection_handler.load_switch_connections(@equipment[test_vars],equip_type,eq_id, i, iter)
              @power_handler.load_power_ports($equipment_table[equip_type][eq_id][i].power_port)
              if $equipment_table[equip_type][eq_id][i].params
                $equipment_table[equip_type][eq_id][i].params.each do |key,val|
                  next if !key.match(/^usb.*_port$/i)
                  @usb_switch_handler.load_usb_ports(val)
                end
              end
              @logs_array << [test_vars, equip_log.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"")] if $equipment_table[equip_type][eq_id][i].driver_class_name && $equipment_table[equip_type][eq_id][i].driver_class_name.strip.downcase != 'operaforclr'
            end
          end
        end
        rescue Exception => e
            raise e.to_s+"\n"+e.backtrace.to_s+"\n Unable to assign equipment #{current_etype}, #{eq_id} entry #{current_instance} to #{current_var}. Verify that #{@rtp_db.get_config_script} contains valid bench file entries; that you can communicate with #{current_etype}, #{eq_id} entry #{current_instance}; and that #{current_etype}, #{eq_id} entry #{current_instance} IO information is correct."
      end
      @connection_handler.media_switches.each{|key,val| @logs_array << ["MediaSwitch"+key.to_s, val[1].sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"")]}
      test_script_found = false
      #require @view_drive+@rtp_db.get_test_script.gsub(".rb","")
      load File.join(@view_drive,@rtp_db.get_test_script)
      t_setup = Time.now.to_s
      puts "\n===== Calling "+@rtp_db.get_test_script+"'s setup() at time "+t_setup
      if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
        @rtp_db.monitor_log("\n===== Calling #{@rtp_db.get_test_script}'s setup() at time #{t_setup}")
      end
      setup 
      t_run = Time.now.to_s
      puts "\n===== Calling "+@rtp_db.get_test_script+"'s run() at time "+t_run
      if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
       @rtp_db.monitor_log("\n===== Calling #{@rtp_db.get_test_script}'s run() at time #{t_run}")
      end
      run
      test_script_found = true
      case(@test_result.result)
        when FrameworkConstants::Result[:pass]
          @test_iter_sum[0] += 1
          @test_sess_sum[0] += 1
          @consecutive_non_passed_tests = 0
        when FrameworkConstants::Result[:fail]
          @test_iter_sum[1] += 1
          @test_sess_sum[1] += 1
          @consecutive_non_passed_tests += 1
        when FrameworkConstants::Result[:ns]
          @test_iter_sum[2] += 1
          @test_sess_sum[2] += 1
      end
      html_result = @test_result.comment
      rescue Exception => e
        html_result = e.to_s+" "+e.backtrace.to_s.gsub(/\s+/," ")
        puts html_result.to_s
        html_result.gsub!(/[<>]+/,"")
        @test_iter_sum[2] += 1
        @test_sess_sum[2] += 1
        @consecutive_non_passed_tests += 1 if @test_params.auto
        @test_result.result = FrameworkConstants::Result[:blk]
        @test_result.comment = e.to_s.gsub(/[\s<>]+/," ")
        raise
      ensure
        @old_keys = @new_keys
        @test_ended = Time.now
        config_file.close if config_file && !is_db_type_xml?(@db_type)
        @rtp_db.set_test_result(@rtp_db.get_test_script, @test_result.result, @test_result.comment, @test_result.perf_data, "0",test_result_html_path.sub(@session_results_base_directory,@session_results_base_url), @test_start_time, @test_ended, iter, @tester.to_s, @test_params.platform, @test_params.target) 
        @results_html_file.add_logs(@logs_array)
        @results_html_file.add_test_result(@rtp_db.get_test_description.to_s, @test_result.result, html_result)
        @results_html_file.add_test_information(@rtp_db.get_test_id.to_s, @rtp_db.get_test_script.to_s, @rtp_db.get_test_description.to_s, @test_start_time.strftime("%m/%d/%Y  %I:%M%p"), @test_ended.strftime("%m/%d/%Y  %I:%M%p"), @test_ended.strftime("%m/%d/%Y  %I:%M%p"))
        @results_html_file.write_file
        @test_iter_summary_html.add_iterations_result(["Iteration "+iter.to_s, test_result_html_path.sub(@session_results_base_directory,@session_results_base_url).sub("\\","/").sub(/http:\/\//i,""), @test_result.result, @test_result.comment])
        t_clean = Time.now.to_s
        puts "===== Calling "+@rtp_db.get_test_script+"'s clean() at time "+t_clean
        if (is_db_type_xml?(@db_type) && @rtp_db.is_staf_enabled)
          @rtp_db.monitor_log("===== Calling #{@rtp_db.get_test_script}'s clean() at time #{t_clean}")
        end
        clean if test_script_found
        @connection_handler.media_switches.each {|key,val| val[0].stop_logger} if @connection_handler
        @equipment.each_value do |val|
          # puts val.class.to_s+" = "+ObjectSpace.each_object(val.class){}.to_s  # DEBUG: Uncomment this line to get a print out of the number of test equipment objects
          val.stop_logger if val.respond_to?(:stop_logger)
          val.disconnect if val.respond_to?(:disconnect) && val.respond_to?(:stop_logger)
        end
        @connection_handler.disconnect if @connection_handler
        ($LOADED_FEATURES-vatf_default_features).each {|script| $LOADED_FEATURES.delete(script)}
    end

    #This function is used inside the test script to set the result for the test. Takes test_result the result of the test (FrameworkConstants::Result), and comment a comment associated with the test result (string) as parameters.
    def set_result(test_result, comment = nil, perf_data = nil, max_dev = 0.05)
      @test_result.result = test_result
      @test_result.comment = comment if comment
      @test_result.set_perf_data(perf_data)
      # Compare performance data with previous executions
      if @test_result.perf_data && !@test_result.perf_data.empty?
        p_result, p_comment = PassCriteria::is_performance_good_enough(@test_params.platform, @test_id, @test_result.perf_data, max_dev)
        if !p_result
          # Performance is not good enough
          @test_result.result = FrameworkConstants::Result[:fail]
          @test_result.comment = @test_result.comment + p_comment
        elsif p_result && p_comment
          @test_result.comment = @test_result.comment + p_comment
        end
      end
    end

    #This function saves the results for the multiple iterations ran for a given test.
    def save_iterations_result
      @test_iterations_ended = Time.now
      @test_iter_summary_html.add_test_summary_info(@test_iterations_start_time.strftime("%m/%d/%Y  %I:%M%p") , @test_iterations_ended.strftime("%m/%d/%Y  %I:%M%p"), @test_iterations_ended.strftime("%m/%d/%Y  %I:%M%p"))
      @test_iter_summary_html.add_test_iterations_totals(@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2])
      @test_iter_summary_html.write_file
      ensure
        test_iter_summ_html_path = @test_iter_summary_html_path.sub(@session_results_base_directory,@session_results_base_url).sub("\\","/").sub(/http:\/\//i,"")
        @rtp_db.set_test_iterations_result(@rtp_db.get_test_script,@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2],test_iter_summ_html_path,@session_iter,@test_iterations_start_time,@test_iterations_ended)
        @session_html.add_test_row([@session_iter.to_s,["Case ID: "+@rtp_db.get_test_id.to_s,test_iter_summ_html_path],@rtp_db.get_test_description,[@rtp_db.get_test_script.split(/[\\\/]/)[-1],"//"+@view_drive.gsub("\\","/")+@rtp_db.get_test_script.gsub("\\","/")],FrameworkConstants::Status[:complete],@test_iter_sum[0],@test_iter_sum[1],@test_iter_sum[2]])
    end

    #This function save the result associated with a session. Takes session_iter_completed the session iteration number completed (number)
    def save_session_results(session_iter_completed)
      @session_ended = Time.now

      if @non_existent_tests.values.length > 0
        @session_html.add_paragraph("Test case(s): "+@non_existent_tests.values.to_s+" do(es) not exist in the database",{:color => "#FF0000"})
      end
      release_assets = ''
      if @cli_params['release_assets'].empty?
        release_assets = "Assets Information In Database"
      else
        @cli_params['release_assets'].each{|asset_name, asset_val| release_assets+=asset_name+'='+asset_val+'\n'}
      end
      @session_html.add_run_information(@session_start_time.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @session_ended.strftime("%m/%d/%Y  %I:%M%p"), @rtp_path, @test_params.platform, release_assets)
      @session_html.add_totals_information(@test_sess_sum[0],@test_sess_sum[1],@test_sess_sum[2])
      @session_html.write_file
      ensure
        @rtp_db.set_session_result(@tester,@test_sess_sum[0],@test_sess_sum[1],@test_sess_sum[2],@session_html_url,@session_start_time,@session_ended,session_iter_completed,4)
        if !is_db_type_xml?(@db_type)
          @rtp_db.remove_connection if @rtp_db.connected?
        end
        return @test_sess_sum
    end

    #This function returns the path of the html page containing the results of the last test session excuted
    def get_session_html
        @session_html_url.to_s
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

	#This function uploads a file to the server and returns an array with the path of the file and the url of the file if successful, else return nil
    def upload_file(file_path)
      result = nil
      if File.exists?(file_path)
        server_dir = File.dirname(@files_dir)
        fpath = File.join(server_dir,File.basename(file_path))
		    FileUtils.cp(file_path,fpath)
		result = [fpath, fpath.sub(@session_results_base_directory,@session_results_base_url).sub("\\","/").sub(/http:\/\//i,"")]
      end
      result
    end

    # This function allows the user to add equipment to the @equipment hash within the test script.
    # The functions takes the desired handle specified by the user in equip_var and a boolean specifying if a link to
    # the log of the equipment should be created in the result html. The function yields a path where the equipment object can
    # create a log file and expects a reference to the new Equipment object as the result of the yield.
    # An example call would be like (NewEquipmentDriver and InfoObject are place holders for the equipment driver needed for an
    # equipment and the input parameters used by the constructor of the driver respectively)
    #
    #   equip_info = InfoObject.new
    #   add_equipment('test_equip') do |log_path|
    #     NewEquipmentDriver.new(equip_info,log_path)
    #   end
    #
    # After calling this function the new instantiated driver can be accessed with call to @equipment. For the example presented
    # before the equipment can accessed with @equipment['test_equip']
    def add_equipment(equip_var, link_log=true)
      raise "Could not add equipment, equipment hash already contains an equipment referenced with key #{equip_var}" if @equipment.has_key?(equip_var)
      equip_log = File.join(@files_dir,equip_var.strip+"_"+@current_test_iteration.to_s+"_log.txt")
      equip_object = yield equip_log
      @equipment[equip_var] = equip_object
      @logs_array << [equip_var, equip_log.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"")] if link_log
    end

    private
    class TestResult
      attr_accessor :result, :comment, :perf_data

      def initialize
        @result = FrameworkConstants::Result[:fail]
        @comment = "This is the default result comment. Use function set_result to set this comment"
        @perf_data = nil
      end

      def set_perf_data(data_vector=nil)
        if data_vector
          work_vector = data_vector
          work_vector = [work_vector] if !work_vector.kind_of?(Array)
          @perf_data = []
          work_vector.each do |current_data|
            if current_data.kind_of?(Hash)
               current_hash = {}
               current_data.each { |key, val|
                  if key.match(/^value/i)
                    current_hash.merge!(get_stat_values(val))
                  elsif key.match(/^name/i)
                    val = val[0..29]         # Testlink restrict metric names to 30 chars
                    val.gsub!(/\s/,'_')      # remove white spaces from metric names
                    val.gsub!(/[\/\\]/,'_')  # remove '/' and '\' from metric names
                    current_hash[key]=val
                  elsif key.match(/^units/i)
                    val = val[0..9]         # Testlink restrict metric units to 10 chars
                    current_hash[key]=val
                  else
                    current_hash[key]=val
                  end
               }
               @perf_data << current_hash if current_hash['s2']
            end
          end
          @perf_data = nil if @perf_data.empty?
        end
      end

      def get_stat_values(data)
        work_data = data
        work_data = [work_data] if !data.kind_of?(Array)
        return {} if work_data.empty?
        work_data.collect! do |current_item|
          return {} if !current_item.to_s.match(/[\d\.\+\-Ee]+/)
          current_item.to_f
        end
        s0 = work_data.length
        s1 = 0
        s2 = 0
        work_data.each do |current_item|
          s1+=current_item
          s2+=current_item**2
        end
        {'min' => work_data.min, 'max' => work_data.max, 's0' => s0, 's1' => s1, 's2' => s2}
      end
    end
end
