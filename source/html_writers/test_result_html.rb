require File.dirname(__FILE__)+'/html_file_writer'
require File.dirname(__FILE__)+'/../framework_constants'

module HTMLWriters
=begin
    This class is used to create an ATF test result html page. inherits from ATFHtmlFile class.
=end
  class TestResultHtml < ATFHtmlFile
      private
      #Creates an array whose values are the test's general information. Takes test_case the test case identification (string), test_script the name of the test script runned (string), 
      #test_description a description of the test(string), test_started the date when the test started (string), test_completed date when the test finished (string),and report_generated date when the report was generated (string).
      def add_run_info(test_case, test_script, test_description, test_started, test_completed, report_generated)
        run_info_array = Array.new
        run_info_array << [["Test Case",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_case,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Test Script",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_script,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Test Description",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_description,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Test Started",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_started,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Test Completed",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_completed,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Report Generated",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[report_generated,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
      end
        
      public
      #Constructor of the class. Takes file_path the path of the html file to be created (string), window_header the html's window title (string), and the target the uut release name (string) as parameters.
      def initialize(file_path, window_header, target)
        super(file_path, window_header)
        add_text_title("Texas Instruments Test Results")
        table1_id = add_table([["Target",{:bgcolor => "navy"},{:color => "white", :size => "4"}]])
        add_rows_to_table(table1_id,[[[target,{:bgcolor => "white"},{:size => "4"}]]])
        add_paragraph("")
      end
      
      #This function creates a table with the test's general information. Takes tester the tester identification (string)
      def add_test_information_table(tester)
        @test_info_table_id = add_table([["Tester",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[tester,{:bgcolor => "white", :align => "left"},{:size => "4"}]])
        add_paragraph("")
      end
      
      #This function adds the test information to the table created by add_test_information_table. Takes test_case the test case identification (string), test_script the name of the test script runned (string), 
      #test_description a description of the test(string), test_started the date when the test started (string), test_completed date when the test finished (string),and report_generated date when the report was generated (string). 
      def add_test_information(test_case, test_script, test_description, test_started, test_complete,report_generated)
        add_rows_to_table(@test_info_table_id,add_run_info(test_case,test_script,test_description.to_s.split(/(\r|\n)+/)[0],test_started,test_complete,report_generated))
      end
      
      #This function adds a link to the Session summary html page.Takes the url to the session page, the url to the iteration summary page as parameters, and optionally a link to the multissession page
      def add_summaries_links(session_link, iteration_link, multi_session_link = nil)
        add_paragraph("Multisession Summary",{:size => "6"},{:align => "center"},multi_session_link) if multi_session_link
        add_paragraph("Session Summary",{:size => "6"},{:align => "center"},session_link)
        add_paragraph("Test Iterations Summary",{:size => "4"},{:align => "center"},iteration_link)
      end
      
      #This function adds a table that will contain the logs of the equipments used during the test
      def add_logs_table
        @logs_table_id =  add_table([["Equipment Logs",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white" ,:size => "4"}]])
        add_paragraph("")
      end
      
      #This function adds the logs to a table created with add_logs_table that contains the links to the logs captured during the test. Takes equipment_logs an array of tuples [equipment name(string), log url(string)] as parameter.
      def add_logs(equipment_logs)
        equipment_log_array = Array.new
        0.step(equipment_logs.length-1,2) do |index|
           equipment_log_array << if equipment_logs[index+1]
                                    [[equipment_logs[index][0],{:width => "50%"},nil,equipment_logs[index][1]],
                                    [equipment_logs[index+1][0],{:width => "50%"},nil,equipment_logs[index+1][1]]]
                                  else
                                    [[equipment_logs[index][0],{:colspan => "2"},nil,equipment_logs[index][1]]]
                                  end
        end
        add_rows_to_table(@logs_table_id,equipment_log_array)
      end
      
      #This function adds the test result table to the test's html result files.
      def add_test_result_table
        @test_result_table_id = add_table([["Test",{:bgcolor => "navy", :align => "center"}, {:color => "white" ,:size => "4"}],
                              ["Result",{:bgcolor => "navy", :align => "center"}, {:color => "white" ,:size => "4"}],
                              ["Comment",{:bgcolor => "navy", :align => "center"}, {:color => "white" ,:size => "4"}]])
      end
      
      #This function adds row the table created with the add_test_result_table function
      #Takes test_identifier a description or test id (string), test_result the result of the test (FrameworkConstants::Result), test_comment a comment associated with this result (string) as parameter.
      def add_test_result(test_identifier, test_result, test_comment)
        status_color = case(test_result)
            when FrameworkConstants::Result[:pass]
              ["PASSED","#00FF00"]
            when FrameworkConstants::Result[:fail]
              ["FAILED","#FF0000"]
            else
              ["SKIPPED","#FFFF00"] 
          end   
        add_row_to_table(@test_result_table_id,[test_identifier, [status_color[0],{:bgcolor => status_color[1]}], test_comment])
      end

  end
  
end
