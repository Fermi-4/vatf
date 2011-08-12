require 'ti_power_controller'
require '../equipment_info'

include TestEquipment

puts "Reseting the  controller"

te = EquipmentInfo.new("ti_power_controller", 0)
te.driver_class_name = "TiPowerController"

ti = TiPowerController.new()

#ti.switch_on(1)
#sleep(10)
#ti.switch_off(1) 
ti.reset(4,10);

print "done"

