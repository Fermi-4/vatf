require 'session_summary_writer'
require 'test_result_html'
require 'test_iterations_summary_writer'

include HTMLWriters
a = SessionSummaryHtml.new("C:\\html_session_summary_test_file.html","Test File","1220_EGW")
a.add_run_information_tables("A tester")
a.add_tests_info_table
a.add_test_group_row("Top Group","#FF0000")
a.add_test_group_row("Second Group","#00FF00")
a.add_test_group_row("Third Group","#0000FF")
a.add_test_rows([["1",["3","/switch_log.txt"],"a description",["4","/switch_log.txt"],1,"2","3","4"],
                 ["4",["6","/switch_log.txt"],"a description\nanother step",["7","/switch_log.txt"],2,"9","10","11"],
                 ["11",["13","/switch_log.txt"],"a description",["14","/switch_log.txt"],3,"16","17","18"]])
a.add_test_row(["1",["3","/switch_log.txt"],"a description",["4","/switch_log.txt"],4,"2","3","4"])
a.add_paragraph("a test paragraph\n with link:",nil,nil,"/switch_log.txt")
a.add_run_information("right now","never","off course","A very  very very very very very very very very very very very long path")
a.add_totals_information(0,1,2)
a.write_file

b = TestResultHtml.new("C:\\html_test_result.html","Test Result Test","64LC")
b.add_test_information_table("A Tester")
b.add_summaries_links("/html_session_summary_test_file.html","/html_test_iterations_summary.html")
b.add_logs_table
b.add_logs([["Video Switch","/switch_log.txt"], ["uut1","/html_test_file.html"], ["uut2","/switch_log.txt"]])
b.add_test_result_table
b.add_test_result("a test description\nanother description line\nanother description line",1,"Good it passed")
b.add_test_information("A Test Case","A Test Script.rb","describing the video test\nanother description line","Today","Tomorrow","I hope")
b.write_file

c = TestIterationsHtml.new("C:\\html_test_iterations_summary.html","Test Iterations Summary","64LC")
c.add_test_summary_info_tables("A Test Script.rb")
c.add_summary_link("/html_session_summary_test_file.html")
c.add_test_iterations_totals(3,4,5)
c.add_test_iterations_table
c.add_iterations_results([["first test\nanother first line","/html_test_result.html",1,"Good it passed"],["second test\nanother second line","/html_test_result.html",2,"Bad it Filed"],["second test\nanother line","/html_test_result.html",3,"Really Bad it skipped"]])
c.add_test_summary_info("Today","Tomorrow","I hope")
c.write_file
