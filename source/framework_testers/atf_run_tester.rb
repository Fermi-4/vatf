
$:.unshift(File.dirname(__FILE__) + '/../') 
require 'atf_session_runner'
#main execution file


def run_session 
  options = CmdLineParser.parse(["-u ch","-s 1","-t 1","-r X:/gtsystst_tp/Utils/rtpwiz/test/test.mdb","-v X:/gtsystst_tp/TestPlans/", "-b C:/vatf/bench.rb"]) #getting the test session's parameters
  session_iter_completed = 0
  session_runner = SessionHandler.new(options.rtp,options.drive,options.bench_path) #creating a session handler instance
  session_runner.start_session(options.tester.strip.gsub(" ","")) #running the test session
  1.upto(options.session_iterations) do |session_iter| 
    options.tests_to_run.each do |test| # running each test
      session_runner.init_test_iterations(test[0].to_i, session_iter, test[1]) 
    end
  session_iter_completed +=1
  end
  rescue Exception => e
    puts e.to_s
  ensure
    session_html = session_runner.save_session_results(session_iter_completed).gsub("/","\\")
    system("explorer #{session_html}")
end

run_session
