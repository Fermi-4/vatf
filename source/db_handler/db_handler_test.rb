require 'db_handler'

include ATFDBHandlers
ahandler = AccessAtfDbHandler.new()
ahandler.connect_database("demo_objective_quality_6446.mdb")
ahandler.get_tcase_tables(6)
puts "tcase attributes"
puts ahandler.db_tcase.attribute_names
puts "\n\ntresult attributes"
puts ahandler.db_tresult.attribute_names
puts "\n\nttestrun attributes"
puts ahandler.db_ttest_run.attribute_names
puts "\n\nttestfile attributes"
puts ahandler.db_ttest_file.attribute_names
puts "\n\ntfile attributes"
puts ahandler.db_tfile.attribute_names

ahandler.db_tcase.description = "test description"
ahandler.db_tresult.caseID = 6
ahandler.db_tresult.passed = false
ahandler.db_tresult.results = "a test result"
puts "ttest_run id is"+ahandler.db_ttest_run.testRunID.to_s
ahandler.db_ttest_run.testList = "from test"
ahandler.db_ttest_run.save
puts "ttest_run id is"+ahandler.db_ttest_run.testRunID.to_s
ahandler.db_ttest_file.testRunID = ahandler.db_ttest_run.testRunID
ahandler.db_ttest_file.testFile = "a test file"
ahandler.db_ttest_file.save
ahandler.db_tresult.testFileID = ahandler.db_ttest_file.testFileID
ahandler.db_tfile.platform = "a test platform"
ahandler.db_tfile.filesetID = 0
ahandler.db_tfile.imageType = "other"
ahandler.db_tfile.target = "*"
ahandler.db_tfile.os = "*"
ahandler.db_tfile.dsp = "*"
ahandler.db_tfile.micro = "*"
ahandler.db_tfile.microType = "*"
ahandler.db_tfile.custom = "*"
ahandler.save_tables
test_params = ahandler.get_test_parameters
test_params.instance_variables.each { |var| puts var.to_s+' = '+test_params.instance_variable_get(var).to_s } 
puts "These are the params_chan values"
test_params.params_chan.instance_variables.each { |var| puts var.to_s+' = '+test_params.params_chan.instance_variable_get(var).to_s }

puts "\n\n\n==========SECOND TIME AROUND================="
ahandler.connect_database("demo_objective_quality_6446.mdb")
ahandler.get_tcase_tables(6)
ahandler.db_tcase.description = "test description"
ahandler.db_tresult.caseID = 6
ahandler.db_tresult.passed = false
ahandler.db_tresult.results = "a test result"
puts ahandler.db_ttest_run.attribute_names
ahandler.db_ttest_run.testList = "from test"
ahandler.db_ttest_run.save
ahandler.db_ttest_file.testRunID = ahandler.db_ttest_run.testRunID
ahandler.db_ttest_file.testFile = "a test file"
ahandler.db_ttest_file.save
ahandler.db_tresult.testFileID = ahandler.db_ttest_file.testFileID
ahandler.db_tfile.platform = "a test platform"
ahandler.db_tfile.filesetID = 0
ahandler.db_tfile.imageType = "other"
ahandler.db_tfile.target = "*"
ahandler.db_tfile.os = "*"
ahandler.db_tfile.dsp = "*"
ahandler.db_tfile.micro = "*"
ahandler.db_tfile.microType = "*"
ahandler.db_tfile.custom = "*"
ahandler.save_tables
test_params = ahandler.get_test_parameters
test_params.instance_variables.each { |var| puts var.to_s+' = '+test_params.instance_variable_get(var).to_s } 
puts "These are the params_chan values"
test_params.params_chan.instance_variables.each { |var| puts var.to_s+' = '+test_params.params_chan.instance_variable_get(var).to_s }


puts "Getting a list of all the test cases in the test matrix"
ahandler.get_tcases_ids.each{|id| puts id.to_s}