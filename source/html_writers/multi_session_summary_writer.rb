require File.dirname(__FILE__)+'/html_file_writer'
require File.dirname(__FILE__)+'/../framework_constants'

module HTMLWriters
=begin
    This class is used to create an ATF test session summary html page. inherits from ATFHtmlFile class.
=end
  class MultiSessionSummaryHtml < ATFHtmlFile
    private
        
        #Creates an array whose values are the session's general information. Takes the Date when the session started (string), date when the results where updated last(string), date when the report was generated, and
        #the path (string) of the directory where the test matrix is located as parameters.
        def add_run_info(run_started,last_update)
          run_info_array = Array.new
          run_info_array << [["MultiSession Started",{:bgcolor => "navy"},{:color => "white", :size => "4"}],[run_started,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
          run_info_array << [["MultiSession Ended",{:bgcolor => "navy"},{:color => "white", :size => "4"}],[last_update,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        end
        
    public
      #Constructor of the class. Takes file_path the path of the html file to be created (string), window_header the html's window title (string), and the target the uut release name (string) as parameters.
      def initialize(file_path, window_header)
        super(file_path, window_header)
        add_text_title("Texas Instruments Multiple Sessions Results")
        add_paragraph("")
      end
      
      #This function creates tables with the general information. Takes tester the name or id of the tester (string).
      def add_summary_information_tables(tester)
        @run_info_table_id = add_table([["Tester",{:bgcolor => "navy"},{:color => "white", :size => "4"}],[tester,{:bgcolor => "white", :align => "left"},{:size => "4"}]])
        add_paragraph("")
        add_paragraph("MultiSession Totals",{:size => "4"})
        @total_info_table_id = add_table([["Passed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],["Failed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],["Skipped",{:bgcolor => "navy"},{:color => "white", :size => "4"}]])
        add_paragraph("")
      end
      
      #This function add the session information to the table created by add_run_information_tables. Takes run_started the Date when the session started (string), last_update the date when the results where updated last(string), report_generated the date when the report was generated, and
      #test_matrix the path (string) of the directory where the test matrix is located as parameters.
      def add_summary_information(run_started, last_update)
        add_rows_to_table(@run_info_table_id, add_run_info(run_started,last_update))
      end
      
      #This function info the the total_info_table created in add_run_information_table. Takes num_passed the number of tests passed, num_failed the number of tests failed, and num_skipped the number of tests skipped as parameters. 
      def add_totals_information(num_passed, num_failed, num_skipped)
        precision_fmt = "%.2f"
        num_total = (num_passed + num_failed + num_skipped).to_f
        add_row_to_table(@total_info_table_id,[num_passed.to_s, num_failed.to_s, num_skipped.to_s])
        add_row_to_table(@total_info_table_id,["#{precision_fmt%(100*num_passed/num_total).to_s}%", "#{precision_fmt%(100*num_failed/num_total).to_s}%", "#{precision_fmt%(100*num_skipped/num_total).to_s}%"])        
      end
      
      # This created a table containing information of each test run in the session. Once this function is called test information can be added
      #using the add_test_group_row and add_test_rows functions.
      def add_sessions_info_table
        add_paragraph("Session Results",{:size => "4"})
        add_paragraph("")
        @tests_info_table = add_table([["File",{:bgcolor => "navy"},{:color => "white", :size => "4"}],
                                      ["Passed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],
                                      ["Failed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],
                                      ["Skipped",{:bgcolor => "navy"},{:color => "white", :size => "4"}]])
      end
      
      #This function adds a test group line to a table created with the add_tests_info_table function. Takes group_name the test group name (string), and group_color the row's background color (string of the form "#XXXXXX" where XXXXXX is the hex representation of the rgb values) as parameters.
      def add_session_group_row(group_name, group_color)
        add_row_to_table(@tests_info_table,[[group_name,{:bgcolor => group_color, :colspan => "4", :align => "left"}]])     
      end
      
      #This function adds test information rows to a table created with the add_tests_info_table function. Takes rows an array of rows that will be added to the table. Each row in the array
      #is an array with the following test information [test session iteration number; array containing [test html iterations summary name, url with html iterations summary]; 
      #test description; array containing [test file name, url to test file]; a value of the type FrameworkConstatns::Result passed, failed, or skipped, number of iterations passed; number of iterations failed; number of iterations skipped]
      def add_session_rows(rows)
        test_rows_array = Array.new
        rows.each do |val| 
          test_rows_array << [[val[0][0].to_s,{:bgcolor => "white"},{:color => "black"},val[0][1]],
                              val[1].to_s,
                              val[2].to_s,
                              val[3].to_s]
        end 
        add_rows_to_table(@tests_info_table,test_rows_array)
      end
      
      #This function adds a test information row to a table created with the add_tests_info_table function. Takes row 
      #an array with the following test information [test session iteration number; array containing [test html iterations summary name, url with html iterations summary]; 
      #test description; array containing [test file name, url to test file]; a value of the type FrameworkConstatns::Result passed, failed, or skipped, number of iterations passed; number of iterations failed; number of iterations skipped]
      def add_session_row(row)
        add_session_rows([row])
      end
  end

end
