require 'bench'

$equipment_table.each {|ename,evalue|
  evalue.each{|eid, einst|
    puts "equipment " + einst.name
    puts einst.id
    puts einst.telnet_ip
    puts einst.telnet_port
    puts einst.pm_port
    puts einst.video_inputs.each{|switchid , einfo| puts }
    puts einst.video_outputs.each{|switchid , einfo| puts }
    puts einst.audio_inputs.each{|switchid , einfo| puts }
    puts einst.audio_outputs.each{|switchid , einfo| puts }
    puts einst.driver_class_name
    puts "####################"
  }
}