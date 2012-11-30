require File.dirname(__FILE__)+'/base_atf_db_handler'

module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class AccessAtfDbHandler < BaseATFDbHandler
    attr_accessor :db_tcase, :db_tresult, :db_ttest_file, :db_ttest_run, :db_tfile, :db_tfileset
      
    public
      
      #Connects to the database, and returns a handle to the connection
      def connect_database(path)
        super(path)
        create_class("Tcase",ActiveRecord::Base)do
          set_primary_key "caseID"
        end
        create_class("Tresult",ActiveRecord::Base)do
          set_primary_key "resultID"
        end
        create_class("TtestFile",ActiveRecord::Base)do
          set_primary_key "testFileID"
          set_table_name "ttestfile"
        end
        create_class("TtestRun",ActiveRecord::Base)do
          set_primary_key "testRunID"
          set_table_name "ttestrun"
        end
        create_class("Tfile",ActiveRecord::Base)do
          set_primary_key "fileID"
        end
        create_class("Tfileset", ActiveRecord::Base)do
          set_primary_key "filesetID"
        end        
        
        rescue Exception => e
          puts "An error occurred opening the database"
          @db_handle = nil
          raise
      end
      
      def set_test_tables(test_id)
        if !@db_ttest_run
          if !@db_ttest_file
            get_tcase_tables(test_id)
          else
            iter_id = @db_ttest_file.testFileID
            get_tcase_tables(test_id,iter_id,@db_ttest_run.testRunID)
          end
        else
          session_id = @db_ttest_run.testRunID
          if !@db_ttest_file
            get_tcase_tables(test_id,nil,session_id)
          else
            iter_id = @db_ttest_file.testFileID
            get_tcase_tables(test_id,iter_id,session_id)
          end
        end
      end
      
      #Get or creates row objects from each table in the Matrix
      #To create a new row object set the respective id values to nil when calling the function
      def get_tcase_tables(tcase_id = nil, ttest_file_id = nil, ttest_run_id = nil, tresult_id = nil, tfile_id = nil, tfileset_id = nil)
        if tcase_id
          @db_tcase = Tcase.find(tcase_id)
        else
          @db_tcase = Tcase.new()
        end
        
        if tresult_id
          @db_tresult = Tresult.find(tresult_id)
        else
          @db_tresult = Tresult.new()
        end
        
        if ttest_file_id
          @db_ttest_file = TtestFile.find(ttest_file_id)
        else
          @db_ttest_file = TtestFile.new()
        end
        
        if ttest_run_id
          @db_ttest_run = TtestRun.find(ttest_run_id)
        else
          @db_ttest_run = TtestRun.new()
        end
        
        if tfile_id
          @db_tfile = Tfile.find(tfile_id)
        else
          @db_tfile = Tfile.new()
        end
        
        if tfileset_id
          @db_tfileset = Tfileset.find(tfileset_id)
        else
          @db_tfileset = Tfileset.new()
        end
        
        @db_tcase != nil
      end 
      
      def test_exists(test_id)
        Tcase.exists?(test_id)
      end
      
      #Saves changes in the tables
      def save_tables
       @db_tcase.save if @db_tcase 
       @db_tresult.save if @db_tresult 
       @db_ttest_file.save if @db_ttest_file 
       @db_ttest_run.save if @db_ttest_run 
       @db_tfile.save if @db_tfile
      end 
      
      def get_auto_flag
        @db_tcase.auto
      end
      
      #Returns the test script used to run the current test case
      def get_test_script
        @db_tcase.script
      end
      
      #Returns the test id of the current test
      def get_test_id
        @db_tcase.caseID.to_s
      end
      
      #Returns the testcase id of the current test
      def get_testcase_id
        @db_tcase.testcaseID.to_s
      end
      
      #Returns the configurations script of the current test
      def get_config_script
        @db_tcase.configID        
      end
      
      #Retunrs the test description of the current test
      def get_test_description
        @db_tcase.description
      end
      
      #Returns the image path from the cms database (must use image manager to add the appropiate tfile fields)
      def get_image_path
        @db_tfileset = Tfileset.find(:all)
        @db_tfileset = @db_tfileset.last # get the last filesetID (:last doesnt work in active record)
        # Get entries in tfile that match your id, platform, target, os, micro, dsp, microType, and custom for your particular test case
        image_tfile = Tfile.find(:all, 
          :conditions => "filesetID = #{@db_tfileset.filesetID} AND platform = '#{@db_tcase.platform}' AND target = '#{@db_tcase.target}' AND os = '#{@db_tcase.os}' AND micro = '#{@db_tcase.micro}' AND dsp = '#{@db_tcase.dsp}' AND microType = '#{@db_tcase.microType}' AND custom = '#{@db_tcase.custom}'")
        result = {}
        image_tfile.each{|current_tfile| result[current_tfile.imageType] = current_tfile.path}
        result
      end
      
      #Returns the target assinged to the current rtp
      def get_target
        if !@db_tcase
          @db_tcase = Tcase.find(:first)
        end
        @db_tcase.target
      end
      
      #Returns the platform assinged to the current rtp
      def get_platform
        if !@db_tcase
          @db_tcase = Tcase.find(:first)
        end
        @db_tcase.platform
      end

      #Returns the platform assinged to the current rtp
      def get_microType
        if !@db_tcase
          @db_tcase = Tcase.find(:first)
        end
        @db_tcase.microType
      end
      
      #Returns string built by concatenating all the keys
      def get_keys
          @db_tcase.target.to_s + @db_tcase.dsp.to_s + @db_tcase.micro.to_s + 
          @db_tcase.platform.to_s + @db_tcase.os.to_s + @db_tcase.custom.to_s + 
          @db_tcase.microType.to_s + @db_tcase.configID.to_s 
      end
      
	  #Returns an array containing the caseIDs of all the test cases in the test matrix
	  def get_tcases_ids
	     result = []
	     Tcase.find(:all, :select => "caseID").each {|test_case| result << test_case.caseID}
		 result
	  end
  		#Creates an object whose properties are vaariables and classes with the test cases parameters
      def get_test_parameters(additional_parameters = {})
        super(@db_tcase.attributes(), @db_tcase.paramsChan, @db_tcase.paramsEquip, @db_tcase.paramsControl, additional_parameters)
      end
      
      #Populates the results in the Tresult table and sets the result in Tcase (Pass,Fail,Cancel,Skip).
      #Takes test_name the test name (string), result the result of the test (FrameworkConstants::Result entry), result_comment a comment associated
      #with the test result (string), failed_at if the test failed and line number is known the line number (string), web_result_file path of the html result file of this result (string),
      #start_time the test's start time (Time), end_time the test completion time (Time), iter_num the iteration number if multiple iterations (number), tester the name of the tester (string),
      #and pltfrm the platform used for the test (string).	  
      def set_test_result(test_name, result, result_comment, perf_data, failed_at, html_result_file, start_time, end_time = Time.now, iter_num = 1, tester = "system test", pltfrm = nil, release=nil)
        @db_ttest_run.save if !@db_ttest_run.testRunID
        @db_ttest_file.save if !@db_ttest_file.testFileID
        @db_tresult.caseID = @db_tcase.caseID
        @db_tresult.testFileID = @db_ttest_file.testFileID
        case result
          when FrameworkConstants::Result[:pass]
            @db_tcase.status = FrameworkConstants::Result[:pass]
            @db_tresult.passed = true
            @db_tresult.skipped = false
          when FrameworkConstants::Result[:fail]
            @db_tresult.passed = false
            @db_tresult.skipped = false
            @db_tcase.status = FrameworkConstants::Result[:fail]
            @db_tresult.failedAt = failed_at 
          else
        end
        @db_tcase.TargetDate = Time.now
        @db_tcase.platform = pltfrm
        @db_tcase.target = release
        @db_tcase.Reserve2 = tester
        @db_tresult.results = result_comment
        @db_tcase.comments = result_comment
  #        @db_tresult.detailFile = html_result_file
  #        @db_tresult.number = 0 commented out due to change in the db schema
          if /[\\\/]*(\w+)\.*\w*$/ =~ test_name
            @db_tresult.nameBase = /[\\\/]*(\w+)\.*\w*$/.match(test_name)[1].to_s+"0"*(4-iter_num.to_s.length)+iter_num.to_s
          else
            @db_tresult.nameBase = test_name.to_s+"0"*(4-iter_num.to_s.length)+iter_num.to_s
          end
          @db_tresult.displayState = 4
          @db_tresult.seqNum = 1
          @db_tresult.generated = true
          @db_tresult.fileNum = 1
  #        @db_tresult.nGIFs = 0 commented out due schema change
          @db_tresult.phase = 0
          @db_tresult.dspImageID = 0
          @db_tresult.microImageID = 0
          @db_tresult.tester = tester
          @db_tresult.startTime = start_time
          @db_tresult.endTime = @db_tcase.Reserve1 = end_time
          @db_tresult.duration = end_time - start_time
        ensure
        @db_tcase.save
        @db_tresult.save        
      end
      
      #Populates the TTestFile table with the results of the iterations ran for one test in a session.
      #Takes test_name the test name (string), num_passed the number of test iterations that passed(number), num_failed the number of test iterations that failed(number),
      #num_skipped the number of test iterations that were skipped (number), iterations_summary_file path of the html iterations summary file (string),
      #start_time the first test iteration start time (Time), end_time the last test iteration completion time (Time), and iterations_have_completed 1 if iteration are done. 
      def set_test_iterations_result(test_name, num_passed, num_failed, num_skipped, iterations_summary_file, session_iteration, start_time, end_time = Time.now, iterations_have_completed = 1)
        @db_ttest_run.save if !@db_ttest_run.testRunID
        @db_ttest_file.testRunID = @db_ttest_run.testRunID
        @db_ttest_file.iter = 1
        @db_ttest_file.runIter = session_iteration
        if /[\\\/]*(\w+)\.*\w*$/ =~ test_name
          @db_ttest_file.nameBase = /[\\\/]*(\w+)\.*\w*$/.match(test_name)[1].to_s+"0"*(4-session_iteration.to_s.length)+session_iteration.to_s
        else
          @db_ttest_file.nameBase = test_name.to_s+"0"*(4-session_iteration.to_s.length)+session_iteration.to_s
        end
        @db_ttest_file.sumFile = iterations_summary_file
        @db_ttest_file.displayState = 4 
        @db_ttest_file.startTime = start_time
        @db_ttest_file.endTime = end_time
        @db_ttest_file.duration = end_time - start_time
        @db_ttest_file.nPassed = num_passed
        @db_ttest_file.nFailed = num_failed
        @db_ttest_file.nSkipped = num_skipped
        @db_ttest_run.iterComplete = @db_ttest_run.iter = iterations_have_completed
        @db_ttest_file.save
        @db_ttest_file = nil
      end
      
      #Populates the TTestRun table with the appropiate results for a test session.
      #Takes tester the id of the user (string), num_passed the number of tests that passed in the session (number), num_failed the number of tests that
      #failed in the session (number), num_skipped the number of tests that were skipped in the session (number), summary_html path to the html session summary
      #file (string), start_time the session's start time (Time), end_time time when the session ended (Time), session_iter number of session iterations
      #that were set to run (number), session_iter_completed number of session iterations that were completed  
      def set_session_result(tester, num_passed, num_failed, num_skipped, summary_html, start_time, end_time = Time.now, session_iter_completed = 1, state = 4)
        @db_ttest_run.testList = "fromMatrix"
        @db_ttest_run.displayState = state
        @db_ttest_run.currentTestFileID = 0
        @db_ttest_run.sumFile =  summary_html
        @db_ttest_run.tester = tester
        @db_ttest_run.startTime = start_time
        @db_ttest_run.endTime = end_time
        @db_ttest_run.duration = end_time.to_i.to_i
        @db_ttest_run.nPassed = num_passed
        @db_ttest_run.nFailed = num_failed
        @db_ttest_run.nSkipped = num_skipped
        @db_ttest_run.iterComplete = @db_ttest_run.iter = session_iter_completed
        @db_ttest_run.save
        @db_ttest_run = nil
      end
      
  end
end
