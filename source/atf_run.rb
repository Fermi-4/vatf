require File.dirname(__FILE__)+'/atf_session_runner'
require File.dirname(__FILE__)+'/test_areas'
require 'socket'

include TestAreas
# This function sends an e-mail w/ the test results if an e-mail address (option -m) was specified in the command line
    def send_email(subject, message, from, to, from_alias='TI Continuous Integration & Test System', to_alias='CI Users')
      msg = <<END_OF_MESSAGE
From: #{from_alias} <#{from}>
To: #{to_alias} <#{to}>
Subject: #{subject}

#{message}
END_OF_MESSAGE

      Net::SMTP.start(SiteInfo::SITE_MAIL_SERVER) do |smtp|
        smtp.send_message msg, from, to
      end
    end

#main execution file
def run_session
  options = CmdLineParser.parse(ARGV) #getting the test session's parameters
  frame_id = Socket.gethostname
  frame_id += '_' + options.staf_service_name if options.staf_service_name

  session_result_dir = options.results_base_dir+"/"+options.tester+"/"+frame_id+"/"
  session_result_server = options.results_base_url+"/"+options.tester+"/"+frame_id+"/"
  rtps = TestAreas::get_rtps(options.rtp, options.drive.sub(/(\\|\/)$/,'')+"/GoldenMatrices",options.results_base_dir+"/"+options.tester, options.platform)
  if rtps.length > 1 || options.rtp.values[0]['test_areas'].kind_of?(Array)
    multi_session_start_time = Time.now
  session_result_dir = options.results_base_dir.gsub('\\','/')+'/'+options.tester+"/"+frame_id+"/Multisession_"+multi_session_start_time.strftime("%m_%d_%Y_%H_%M_%S")
  session_result_server = session_result_dir.sub(options.results_base_dir.gsub('\\','/'),options.results_base_url)
  FileUtils.mkdir_p(session_result_dir)
  multi_session_html = session_result_dir+"/multisession.html"
  multi_session_html_writer = MultiSessionSummaryHtml.new(multi_session_html, "MultiSession Summary")
  multi_session_html_writer.add_summary_information_tables(options.tester)
  multi_session_html_writer.add_sessions_info_table
  multi_session_passed_total = 0
  multi_session_failed_total = 0
  multi_session_skip_total = 0
  end
  rtps.each do |current_rtp|
    begin
    session_iter_completed = 0
    session_runner = SessionHandler.new({'rtp_path' => current_rtp.path, 'view_drive' => options.drive, 'bench_path' => options.bench_path, 'results_path' => session_result_dir, 'results_server' => session_result_server}, {'target_source_drive' => options.target_source_drive, 'consec_non_pass' => options.num_fails_to_reboot, 'multi_sess_sum' => multi_session_html, 'platform' => options.platform, 'release_assets' => options.release_assets, 'email' => options.email,  'release' => options.release, 'results_file' => options.results_file, 'staf_service_name' => options.staf_service_name}) #creating a session handler instance
    session_runner.start_session(options.tester.strip.gsub(" ","").downcase) #running the test session
    1.upto(options.session_iterations) do |session_iter|
    options.tests_to_run.each do |test| # running each test
    if test[0] == 'all'
        session_runner.get_all_test_cases.each do |test_id|
        session_runner.init_test_iterations(test_id, session_iter, test[1])
      end
      else
      session_runner.init_test_iterations(test[0].to_i, session_iter, test[1])
      end
    end
    session_iter_completed +=1
    end
    rescue Exception => e
    puts e.backtrace.to_s
    ensure
    if session_runner
      session_results = session_runner.save_session_results(session_iter_completed)
      current_session_html = session_runner.get_session_html
      if !multi_session_html
      multi_session_html = current_session_html
      else
        multi_session_passed_total += session_results[0]
      multi_session_failed_total += session_results[1]
      multi_session_skip_total += session_results[2]
      multi_session_html_writer.add_session_row([[File.basename(current_rtp.path), current_session_html.gsub("\\","/")],session_results[0],session_results[1],session_results[2]])
      end
    end
    end
  end
  ensure
  if multi_session_html
      if rtps.length > 1 || options.rtp.values[0]['test_areas'].kind_of?(Array)
      multi_session_html_writer.add_totals_information(multi_session_passed_total, multi_session_failed_total, multi_session_skip_total)
      multi_session_html_writer.add_summary_information(multi_session_start_time, Time.now)
      multi_session_html_writer.write_file
    end
    if options.email
      email_to_list = options.email.split(%r{;\s*})
      #email_msg = "The CI Test Results for your test execution can be found at #{multi_session_html.gsub(/\//,'\\')} \n\nThanks for using TI's CI System"
      all_rtps = ''
      options.rtp.each do |rtp_key, rtp_val|
        all_rtps += "TestSuites--- #{rtp_val['test_areas'].inspect.to_s}\n"
      end
      email_msg = "The CI Test Results for your test execution can be found at #{multi_session_html.gsub(/\//,'\\')} \n" +
      "\nHere are some options in your commands\n" +
      "\nPlatform--- #{options.platform}" +
      "\nRelease--- #{options.release}" +
      "\n#{all_rtps}\n" +
      "\nThanks for using TI's CI System"
      send_email('CI Test Results', email_msg, 'VATF@ti.com', email_to_list)
    else
      if(options.browser)
        sep = "/"
        sep = "\\" if RbConfig::CONFIG["arch"].match(/win\d{2}/i)
        if OsFunctions::is_windows?
          system("explorer #{multi_session_html.gsub(options.results_base_dir,options.results_base_url).gsub(/\\|\//,sep)}")
        elsif OsFunctions::is_linux?
          system("firefox #{multi_session_html.gsub(options.results_base_dir,options.results_base_url).gsub(/\\|\//,sep)} &")
        end
      end
    end
  end
end

run_session
