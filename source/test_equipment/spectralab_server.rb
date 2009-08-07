# -*- coding: ISO-8859-1 -*-

require 'drb/drb'
require 'optparse'
require 'ostruct'
require 'spectra_lab'


include TestEquipment

#Command Line parse class
class DemoCmdLineParser
    #
    # Return a structure describing the options.
    #
    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      options = OpenStruct.new
      options.ip_address = ""
      options.port = ""

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: spectralab_server -h server_ip_address -p server_port_number"
        
        opts.separator " "
        opts.separator "Specific options:"
        
        opts.on("-h server_ip_address","=MANDATORY","IP address used by the server") do |s_ip|
          options.ip_address = s_ip
        end
        
        opts.on("-p server_port_number","=MANDATORY","port number used by the server") do |s_port|
          options.port = s_port
        end
        
        opts.separator " "
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
     end   
     opts.parse!(args)
     options
    end
end

def run_server
   
  puts "Starting SpectraLab Server on " + Time.now.to_s
  options = DemoCmdLineParser.parse(ARGV)
  uri = "druby://"+options.ip_address+":"+options.port
  front_object = SpectraLab.new(nil,"SpectraLab_Server_log.txt")
  DRb.start_service(uri,front_object)
  $SAFE = 1   # disable eval() and friends
  # Wait for the drb server thread to finish before exiting.
  DRb.thread.join
   
end

run_server