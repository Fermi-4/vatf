require 'mkmf'

dir_config('staf')
have_library('STAF', 'STAFRegister')
create_makefile("STAFHandle")
