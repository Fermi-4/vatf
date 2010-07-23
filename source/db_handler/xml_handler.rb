require File.dirname(__FILE__)+'/base_atf_xml_handler'
require 'activerecord'
module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class XMLAtfDbHandler < BaseATFXmlHandler
      
    public
      
      def initialize(type = nil, res_file = nil, staf_service_name = nil)
        super(type, staf_service_name)
        raise "Results file has not been specified" if !res_file
        @results_file = res_file
      end
      
      #Connects to the database, and returns a handle to the connection
      def connect_database(path)
        super(path)
        @db_tresult = {}     
        @db_tresult["test_session"] = []
        @db_tresult["test_session"] << {"logpath" => nil, "n_passed" => 0, "n_failed" => 0, "n_skipped" => 0, "testcase" => [], "start_time" => nil, "end_time" => nil}
        rescue Exception => e
          puts "An error occurred opening the database"
          @db_handle = nil
          raise
      end
      
      def set_test_tables(test_id)
        get_tcase_tables(test_id)
      end
      
      #Get or creates row objects from each table in the Matrix
      #To create a new row object set the respective id values to nil when calling the function
      def get_tcase_tables(tcase_id = nil, ttest_file_id = nil, ttest_run_id = nil, tresult_id = nil, tfile_id = nil, tfileset_id = nil)
        if(@test_data["test_session"]["testcase"].is_a? Array)
            @test_data["test_session"]["testcase"].length.times { |i|
                if (@test_data["test_session"]["testcase"][i]["id"].to_i == tcase_id)
                    @db_tcase = @test_data["test_session"]["testcase"][i]
                    @db_tcase["caseID"] = tcase_id
                end
            }
        else
            if (@test_data["test_session"]["testcase"]["id"].to_i == tcase_id)
                @db_tcase = @test_data["test_session"]["testcase"]
                @db_tcase["caseID"] = tcase_id
            end
        end
      end 
      
      def get_testcase_id()
      end
      
      def test_exists(test_id)
        if(@test_data["test_session"]["testcase"].is_a? Array)
            @test_data["test_session"]["testcase"].each { |elem|
            if (elem["id"].to_i == test_id.to_i)
                return true
            end
            }
            return false
        else
            if (@test_data["test_session"]["testcase"]["id"].to_i == test_id.to_i)
                return true
            else 
                return false
            end
        end
      end
      
      #Saves changes in the tables
      def save_tables
      end 
      
      def get_auto_flag
        @db_tcase["auto"]
      end
      
      #Returns the test script used to run the current test case
      def get_test_script
        @db_tcase["scripts"]
      end
      
      #Returns the test id of the current test
      def get_test_id
        @db_tcase["extid"].to_i
      end
      
      #Returns the testplan id for the current test session
      def get_test_plan_id
        @db_tcase["testplan_id"].to_i
      end
      
      #Returns the testcase id of the current test
      def get_testcase_id
        @db_tcase["id"].to_i
      end
      
      #Returns the configurations script of the current test
      def get_config_script
         @db_tcase["hw_assets_config"]
      end
      
      #Retunrs the test description of the current test
      def get_test_description
        @db_tcase["description"].to_s  
      end
      
      #Returns the image path from the cms database (must use image manager to add the appropiate tfile fields)
      def get_image_path
        @test_data["image_path"]
      end
      
      #Returns the target assinged to the current rtp
      def get_target
        @test_data["target"]
      end
      
      #Returns the platform assinged to the current rtp
      def get_platform
        @db_tcase["platform"]
      end

      #Returns the platform assinged to the current rtp
      def get_microType
      end
      
      #Returns string built by concatenating all the keys
      def get_keys
      end
      
      #Returns an array containing the caseIDs of all the test cases in the test matrix
      def get_tcases_ids
         result = []
         if(@test_data["test_session"]["testcase"].is_a? Hash)
            result << @test_data["test_session"]["testcase"]["id"].to_i  
         else
             @test_data["test_session"]["testcase"].each {|test_case| 
             result << test_case["id"].to_i         
            }
         end
         result
      end
      # Creates an object whose properties are vaariables and classes with the test cases parameters
      def get_test_parameters(additional_parameters = {})
        super(@db_tcase, @db_tcase["params_chan"], @db_tcase["params_equip"], @db_tcase["params_control"], additional_parameters)
      end
      
      #Populates the results in the Tresult table and sets the result in Tcase (Pass,Fail,Cancel,Skip).
      #Takes test_name the test name (string), result the result of the test (FrameworkConstants::Result entry), result_comment a comment associated
      #with the test result (string), failed_at if the test failed and line number is known the line number (string), web_result_file path of the html result file of this result (string),
      #start_time the test's start time (Time), end_time the test completion time (Time), iter_num the iteration number if multiple iterations (number), tester the name of the tester (string),
      #and pltfrm the platform used for the test (string).	  
      def set_test_result(test_name, result, result_comment, perf_data, failed_at, html_result_file, start_time, end_time = Time.now, iter_num = 1, tester = "system test", pltfrm = nil, release=nil)
        #results hash for this iteration
        @tc_iter_results = {}
        @tc_iter_results["iteration_id"] = iter_num
        case result
          when FrameworkConstants::Result[:pass]
            @tc_iter_results["passed"] = true
            @tc_iter_results["skipped"] = false
          when FrameworkConstants::Result[:fail]
            @tc_iter_results["passed"] = false
            @tc_iter_results["skipped"] = false
          else
        end
          @tc_iter_results["comments"] = result_comment
          @tc_iter_results["start_time"] = start_time.strftime("%Y-%m-%d %H:%M:%S")
          @tc_iter_results["end_time"] = end_time.strftime("%Y-%m-%d %H:%M:%S")
          if perf_data
            @tc_iter_results["performance"] = []
            perf_data.each do |current_data|
              @tc_iter_results["performance"] << PerfData.new(current_data)
            end
          end
        ensure
            @db_tresult["test_session"][0]["testcase"] << {"id" => @db_tcase["id"].to_s, "logpath" => nil, "comment" => nil, "start_time" => nil, "end_time" => nil, "status" => nil, "iter_complete" => nil, "test_iteration" => []}
            @db_tresult["test_session"][0]["testcase"].each { |tcase|
            if(tcase["id"] == @db_tcase["id"].to_s)
                tcase["test_iteration"] << @tc_iter_results      
            end
        }
      end
      
      #Populates the TTestFile table with the results of the iterations ran for one test in a session.
      #Takes test_name the test name (string), num_passed the number of test iterations that passed(number), num_failed the number of test iterations that failed(number),
      #num_skipped the number of test iterations that were skipped (number), iterations_summary_file path of the html iterations summary file (string),
      #start_time the first test iteration start time (Time), end_time the last test iteration completion time (Time), and iterations_have_completed 1 if iteration are done. 
      def set_test_iterations_result(test_name, num_passed, num_failed, num_skipped, iterations_summary_file, session_iteration, start_time, end_time = Time.now, iterations_have_completed = 1)
        @tc_results = {}
        @tc_results["id"] = @db_tcase["id"].to_i
        @tc_results["start_time"] = start_time.strftime("%Y-%m-%d %H:%M:%S")
        @tc_results["end_time"] = end_time.strftime("%Y-%m-%d %H:%M:%S")
        @tc_results["n_passed"] = num_passed
        @tc_results["n_failed"] = num_failed
        @tc_results["n_skipped"] = num_skipped
        @tc_results["iter_complete"] = iterations_have_completed
        ensure
        @db_tresult["test_session"][0]["testcase"].each  {|tcase|
            if(tcase["id"] == @db_tcase["id"].to_i)
                tcase["start_time"] = start_time.strftime("%Y-%m-%d %H:%M:%S")
                tcase["n_passed"] = num_passed
                tcase["n_failed"] = num_failed
                tcase["n_skipped"] = num_skipped   
                tcase["iter_complete"] = iterations_have_completed     
            end
        }
      end
      
      #Populates the TTestRun table with the appropiate results for a test session.
      #Takes tester the id of the user (string), num_passed the number of tests that passed in the session (number), num_failed the number of tests that
      #failed in the session (number), num_skipped the number of tests that were skipped in the session (number), summary_html path to the html session summary
      #file (string), start_time the session's start time (Time), end_time time when the session ended (Time), session_iter number of session iterations
      #that were set to run (number), session_iter_completed number of session iterations that were completed  
      def set_session_result(tester, num_passed, num_failed, num_skipped, summary_html, start_time, end_time = Time.now, session_iter_completed = 1, state = 4)
        @db_tresult["test_session"][0]["start_time"] = start_time.strftime("%Y-%m-%d %H:%M:%S")
        @db_tresult["test_session"][0]["end_time"] = end_time.strftime("%Y-%m-%d %H:%M:%S")
        @db_tresult["test_session"][0]["n_passed"] = num_passed
        @db_tresult["test_session"][0]["n_failed"] = num_failed
        @db_tresult["test_session"][0]["n_skipped"] = num_skipped
        @db_tresult["test_session"][0]["logpath"] = summary_html
        ensure
        outfile = File.new(@results_file,'w')
        # test = decompose_hash(@db_tresult, Hash.new)
        outfile.puts(@db_tresult.to_xml)
      end
      
    def decompose_hash(in_hash, out_hash)
       in_hash.each_pair {|k,v|
       out_hash[k] = add_cdata(v) if !v.is_a? Array
       out_hash[k] = v.each{|e| decompose_hash(e, e)} if v.is_a? Array
      }
      out_hash
    end

    def add_cdata (e)
      e.to_s
    end

    def is_staf_enabled
      if @staf_handle
        return true
      else
        return false
      end
    end
end

class UndefinedSwAsset < Exception
end

class PerfData < ActiveRecord::Base
  def initialize(attr)
    @attributes = attr
  end
  
  def to_xml(options = {})
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
      xml.data(@attributes)
  end
end
end
