require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require File.dirname(__FILE__)+'/../target/equipment_driver'

module TestEquipment
    include Log4r

    # This class controls TI's Automation Interface  https://github.com/cehh/automation_iface
    class AutomationInterfaceDriver < EquipmentDriver
        attr_reader :number_of_channels, :dut_power_domains, :dut_type

        def initialize(platform_info, log_path=nil)
            super(platform_info, log_path)
        end

        def set_dut_type(dut_type)
            @dut_type = dut_type
            robust_send_cmd("auto set dut #{@dut_type}", @prompt)
        end

        def login
        end

        def logout
        end

        def robust_send_cmd(cmd, expected_regex, timeout=120)
            connect({'type'=>'serial'}) if !@target.serial
            @target.serial.flush_input
            @target.serial.flush_output
            3.times {
                send_cmd(cmd, expected_regex, timeout, false)
                break if !timeout?
            }
            cmd_response = response()
            raise "AutomationInterfaceDriver: timeout while sending #{cmd}" if timeout?
            cmd_response
            ensure
                disconnect('serial') if @target.serial
        end

        def switch_on(address)
            _switch("ON", address) #Set relay to passive state
        end

        def switch_off(address)
            _switch("OFF", address) #Set relay to active state
        end

        # Cycle (switch_off, switch_on) the port/relay at the specified address
        # * address - the port/relay address to cycle
        # * waittime - how long to wait between cycling (default: 5 seconds)
        def reset(address, waittime=1)
            switch_off(address)
            sleep(waittime)
            switch_on(address)
        end

        def _switch(type, address)
            robust_send_cmd("auto power #{type}", @prompt)
        end

        def warm_reset(address=nil)
            robust_send_cmd("auto reset", @prompt)
        end

        def por(address=nil)
            robust_send_cmd("auto por", @prompt)
        end

        def sysboot(settings, address=nil)
            robust_send_cmd("auto sysboot #{settings}", @prompt)
        end

        def version()
            robust_send_cmd("version", @prompt)
        end

        def help()
            robust_send_cmd("help", @prompt)
        end

        ############################
        # Multimeter-related methods
        ############################
        def _reverse_translate_domain_names(domain)
            dict = {'dra71x-evm' => {},
                 }
            return dict[@dut_type][domain] if dict[@dut_type] and dict[@dut_type][domain]
            return domain.upcase
        end


        def configure_multimeter(power_info)
            @number_of_channels = [@params['number_of_channels'].to_i, power_info['power_domains'].length * 2].min
            @dut_power_domains = power_info['power_domains']
            @dut_type = power_info['dut_type']

            robust_send_cmd("auto set dut #{@dut_type}", @prompt)
        end

        #Function collects data from multimeter.
        # Input parameters:
        #    loop_count: Integer defining the number of times to perform channel measurements
        #    timeout: Integer defining the read timeout in sec
        # Return Parameter: Array containing all voltage reading for all domains.
        def get_multimeter_output(loop_count, timeout, delay_between_samples=10)
            h = Hash.new
            @dut_power_domains.each {|d|
                h["domain_" + d.upcase + "_volt_readings"] = Array.new()
                h["domain_" + d.upcase + "drop_volt_readings"] = Array.new()
                h["domain_" + d.upcase + "_current_readings"] = Array.new()
                h["domain_" + d.upcase + "_power_readings"] = Array.new()
            }
            cmd_response = robust_send_cmd("auto measure power #{loop_count} #{delay_between_samples}", @prompt, loop_count.to_i*delay_between_samples.to_i + 10)
            cmd_response.scan(/^\|\s*\d+\s*\|\s*(\w+)\s*\|\s*([\d\.\-]+)\s*\|\s*([\d\.\-]+)\s*\|\s*([\d\.\-]+)\s*\|\s*([\d\.]+)\s*\|/).each{|data|
                puts "domain \t drop V \t volt \t current \t power"
                puts "#{data[0]} \t #{data[1]} \t #{data[2]} \t #{data[3]} \t #{data[4]}"
                if @dut_power_domains.include?(_reverse_translate_domain_names(data[0]))
                    h["domain_"+ _reverse_translate_domain_names(data[0]) + "drop_volt_readings"] << data[1].to_f * 10**-6
                    h["domain_"+ _reverse_translate_domain_names(data[0]) + "_volt_readings"]  << data[2].to_f
                    h["domain_"+ _reverse_translate_domain_names(data[0]) + "_current_readings"] << data[3].to_f * 10**-3
                    h["domain_"+ _reverse_translate_domain_names(data[0]) + "_power_readings"] << data[4].to_f
                else
                    puts "domain #{data[0]} not is evms data, skipping ..."
                end
            }
            h
        end

    end

end
