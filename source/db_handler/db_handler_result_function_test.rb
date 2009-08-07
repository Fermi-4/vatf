require 'db_handler'

include ATFDBHandlers
puts "\n\n\n===============Testing result populating functions==============="
ahandler = AccessAtfDbHandler.new()
ahandler.connect_database("/Video.mdb")
test_sess_sum = [0,0,0]
0.upto(3)do |session_index|
  test_iter_sum = [0,0,0]
  0.upto(2) do |test_iter|
    tst_res = rand(3)+1
    case(tst_res)
      when 1
        test_iter_sum[0] += 1
        test_sess_sum[0] += 1
      when 2
        test_iter_sum[1] += 1
        test_sess_sum[1] += 1
      else
        test_iter_sum[2] += 1
        test_sess_sum[2] += 1 
    end  
    ahandler.set_test_tables(2)
    ahandler.set_test_result("test_session"+session_index.to_s+"test1_iter"+test_iter.to_s, tst_res , "Comment "+test_iter.to_s, "0", "C:\\html_test_result.html", Time.now - 8000, Time.now, test_iter)
  end
  ahandler.set_test_iterations_result("test1_summary"+session_index.to_s,test_iter_sum[0],test_iter_sum[1],test_iter_sum[2],"C:\\html_test_iterations.html",session_index,Time.now - 24000,Time.now)
  test_iter_sum = [0,0,0]
  0.upto(4) do |test_iter|
    tst_res = rand(3)+1
    case(tst_res)
      when 1
        test_iter_sum[0] += 1
        test_sess_sum[0] += 1
      when 2
        test_iter_sum[1] += 1
        test_sess_sum[1] += 1
      else
        test_iter_sum[2] += 1
        test_sess_sum[2] += 1 
    end  
    ahandler.set_test_tables(2)
    ahandler.set_test_result("test_session"+session_index.to_s+"test2_iter"+test_iter.to_s,tst_res,"Comment "+test_iter.to_s,"0","C:\\html_test_result.html", Time.now - 8000,Time.now,test_iter)
  end
  ahandler.set_test_iterations_result("test1_summary"+session_index.to_s,test_iter_sum[0],test_iter_sum[1],test_iter_sum[2],"C:\\html_test_iterations.html",session_index,Time.now - 32000,Time.now)
end
  ahandler.set_session_result("System test",test_sess_sum[0],test_sess_sum[1],test_sess_sum[2],"C:\\html_test_file.html",Time.now - 66000,Time.now,4)


puts "+++++++++++++++++++SECOND TIME AROUND++++++++++++++++++++++++++++"

#ahandler = AccessAtfDbHandler.new()
#ahandler.connect_database("C:\\EGW_1200_BFT.mdb")
test_sess_sum = [0,0,0]
0.upto(3)do |session_index|
  test_iter_sum = [0,0,0]
  0.upto(2) do |test_iter|
    tst_res = rand(3)+1
    case(tst_res)
      when 1
        test_iter_sum[0] += 1
        test_sess_sum[0] += 1
      when 2
        test_iter_sum[1] += 1
        test_sess_sum[1] += 1
      else
        test_iter_sum[2] += 1
        test_sess_sum[2] += 1 
    end  
    ahandler.set_test_tables(2)
    ahandler.set_test_result("test_session"+session_index.to_s+"test1_iter"+test_iter.to_s, tst_res , "Comment "+test_iter.to_s, "0", "C:\\html_test_result.html", Time.now - 8000, Time.now, test_iter)
  end
  ahandler.set_test_iterations_result("test1_summary"+session_index.to_s,test_iter_sum[0],test_iter_sum[1],test_iter_sum[2],"C:\\html_test_iterations.html",session_index,Time.now - 24000,Time.now)
  test_iter_sum = [0,0,0]
  0.upto(4) do |test_iter|
    tst_res = rand(3)+1
    case(tst_res)
      when 1
        test_iter_sum[0] += 1
        test_sess_sum[0] += 1
      when 2
        test_iter_sum[1] += 1
        test_sess_sum[1] += 1
      else
        test_iter_sum[2] += 1
        test_sess_sum[2] += 1 
    end  
    ahandler.set_test_tables(2)
    ahandler.set_test_result("test_session"+session_index.to_s+"test2_iter"+test_iter.to_s,tst_res,"Comment "+test_iter.to_s,"0","C:\\html_test_result.html", Time.now - 8000,Time.now,test_iter)
  end
  ahandler.set_test_iterations_result("test1_summary"+session_index.to_s,test_iter_sum[0],test_iter_sum[1],test_iter_sum[2],"C:\\html_test_iterations.html",session_index,Time.now - 32000,Time.now)
end
  ahandler.set_session_result("System test",test_sess_sum[0],test_sess_sum[1],test_sess_sum[2],"C:\\html_test_file.html",Time.now - 66000,Time.now,4)
