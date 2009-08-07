# -*- coding: ISO-8859-1 -*-
require 'spectra_lab'

include TestEquipment

spectra_tester = SpectraLab.new(nil,'C:\spectra_log.txt')
spectra_tester.connect
spectra_tester.process_file('C:\Share\CLASSIC1_24kHz_m.wav')
puts spectra_tester.get_test_stat("sNr ")
puts spectra_tester.get_test_stats.to_s
spectra_tester.disconnect


