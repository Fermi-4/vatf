require 'apc_power_controller'
require '../equipment_info'

include TestEquipment

puts "starting controller"

te = EquipmentInfo.new("apc_power_controller", 0)
te.telnet_ip = '10.218.103.162'
te.telnet_port = 23
te.driver_class_name = "ApcPowerController"
te.telnet_login  = 'apc'
te.telnet_passwd = 'apc'

#apc = ApcPowerController.new("10.218.103.185", 23, "apc", "apc", "apcPow.log")
apc = ApcPowerController.new(te, "apcPow.log")

@output = ""
#apc.start_logger()
#apc.switch_on(1)
#sleep(4)
apc.reset(7)

 #apc.switch_off(1) 
 
 
apc.get_status(7)
#apc.reset(2, 1)
#apc.get_status(2)

print "done"

