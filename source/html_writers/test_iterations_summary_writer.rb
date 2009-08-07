require 'html_writers/html_file_writer'
require 'framework_constants'

module HTMLWriters 
=begin
    This class is used to create an ATF test result html page. inherits from ATFHtmlFile class.
=end
  class TestIterationsHtml < ATFHtmlFile
      private
      #Creates an array whose values are the test's general information. Takes test_script the name of the test script runned (string), 
      #test_started the date when the test started (string), test_completed date when the test finished (string),and report_generated date when the report was generated (string).
      def add_test_info(test_started, test_completed, report_generated)
        run_info_array = Array.new
        run_info_array << [["First Iter Started",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_started,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Last Iter Completed",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_completed,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
        run_info_array << [["Report Generated",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[report_generated,{:bgcolor => "white", :align => "left"},{:size => "4"}]]
      end
        
      public
      #Constructor of the class. Takes file_path the path of the html file to be created (string), window_header the html's window title (string), and the target the uut release name (string) as parameters.
      def initialize(file_path, window_header, target)
        super(file_path, window_header)
        add_text_title("Texas Instruments Test Iterations Summary")
        table1_id = add_table([["Target",{:bgcolor => "navy"},{:color => "white", :size => "4"}]])
        add_rows_to_table(table1_id,[[[target,{:bgcolor => "white"},{:size => "4"}]]])
        add_paragraph("")
      end
      
      #This function creates tables with the test's general information. Takes test_script the name of the test script runned (string). 
      def add_test_summary_info_tables(test_script)
        @summary_info_table_id = add_table([["Test Case",{:bgcolor => "navy", :width => "25%"},{:color => "white", :size => "4"}],[test_script,{:bgcolor => "white", :align => "left"},{:size => "4"}]])
        add_paragraph("")
        add_paragraph("Current Totals",{:size => "4"})
        @iter_totals_table_id = add_table([["Passed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],["Failed",{:bgcolor => "navy"},{:color => "white", :size => "4"}],["Skipped",{:bgcolor => "navy"},{:color => "white", :size => "4"}]])
        add_paragraph("")
      end
      
      #This functions add the summary information to the table created by add_test_summary_info_table. Takes test_started the date when the test started (string),
      #test_completed date when the test finished (string),and report_generated date when the report was generated (string).
      def add_test_summary_info(test_started, test_complete,report_generated)
        add_rows_to_table(@summary_info_table_id,add_test_info(test_started,test_complete,report_generated))
      end
      
      #This function adds information to the iter_totals_table created in add_test_summary_info_table. Takes num_passed number of iterations that passed, num_failed the number of iterations that
      #failed, and num_skipped that number of iterations that were skipped as parameters. 
      def add_test_iterations_totals(num_passed, num_failed, num_skipped)
        add_row_to_table(@iter_totals_table_id,[num_passed.to_s, num_failed.to_s, num_skipped.to_s])    
      end
      
      #This function adds a link to the Session summary html page
      def add_summary_link(summary_link, multi_session_link = nil)
        if multi_session_link
          multi_link = multi_session_link.to_s
          multi_link = '///'+multi_link if multi_link.match(/^\w/)
          add_paragraph("Multisession Summary",{:size => "6"},{:align => "center"},multi_link)
        end
        sum_link = summary_link
        sum_link = '///'+summary_link if summary_link.match(/^\w/)
        add_paragraph("Session Summary",{:size => "6"},{:align => "center"},sum_link)
      end
      
      #This functions adds a table that will contain the result of each iteration  of the tes.
      def add_test_iterations_table
        @iterations_table_id =  add_table([["Test Results",{:bgcolor => "navy", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]]) 
      end
      
      #This function adds rows to the table created with the add_test_iterations_table function
      #Takes an array of 4-tuples [[iteration identifier, iteration test result url, iteration result, test comment] ..........[iteration identifier, iteration test result url, iteration result, test comment]] as parameter.
      def add_iterations_results(test_iterations)
        test_rows_array = Array.new
        test_iterations.each do |val| 
          status_color = case(val[2])
            when FrameworkConstants::Result[:pass]
              ["PASSED","#00FF00"]
            when FrameworkConstants::Result[:fail]
              ["FAILED","#FF0000"]
            else
              ["SKIPPED","#FFFF00"] 
          end

          test_rows_array << [[val[0].to_s.split(/(\r|\n)+/)[0],{:bgcolor => "white"},{:color => "black"},val[1]],
                              [status_color[0],{:bgcolor => status_color[1]}],
                              val[3].to_s]
        end 
        add_rows_to_table(@iterations_table_id,test_rows_array)
      end
      
      #This function adds a row to the table created with the add_test_iterations_table function
      #Takes an array of 4 [iteration identifier, iteration test result url, iteration result, test comment] as parameter.
      def add_iterations_result(test_iteration)
        add_iterations_results([test_iteration])
      end

  end
end
