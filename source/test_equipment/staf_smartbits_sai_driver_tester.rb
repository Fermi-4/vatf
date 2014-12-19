require './db_handler/ruby_staf_handler'
require './test_equipment/staf_smartbits_sai_driver'
require './equipment_info'

include TestEquipment

puts "starting controller"

te = EquipmentInfo.new("staf_smartbits_sai_driver", "smartbits@1")
te.params = {'staf_ip' => '10.218.104.253'}
te.driver_class_name = "StafSmartbitsSaiDriver"

do_logger = nil

sai = StafSmartbitsSaiDriver.new(te, "/home/systest-s1/tempdown/sai_test/logger/smartBitsSai.log") if do_logger
sai = StafSmartbitsSaiDriver.new(te) if !do_logger

sai_config_file = "/home/systest-s1/tempdown/sai_test/eth1eth2_l_1GF_udp.sai"
FileUtils.cp(sai_config_file, sai.get_local_results_path)

@output = ""
sai.start_logger if do_logger

run_handle = sai.request_resource("eth1eth2_l_1GF_udp.sai", "360s")
sai.delete_old_results_files
sai.run_job(run_handle)
sai.get_results

sai.stop_logger if do_logger

print "done"

