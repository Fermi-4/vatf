require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
    include Log4r

    class ExablazeSwitchDriver
        Logger = Log4r::Logger
        PATCH = "patch"
        TAP = "tap"
        attr_reader :headers, :cookie, :uri, :http

        def initialize(platform_info, log_path = nil)
            platform_info.instance_variables.each {|var|
                if platform_info.instance_variable_get(var).to_s.size > 0
                  self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
                  self.instance_variable_set(var, platform_info.instance_variable_get(var))
                end
            }
            begin
                start_logger(log_path) if log_path
                log_info("Setting up connection to exablaze switch")
                @http_api_addr = @params['http_api_addr']
                @username = @params['username']
                @password = @params['password']
                @uri = URI.parse(@http_api_addr)
                @http = Net::HTTP.new(uri.host, uri.port)
            rescue Exception => err_msg
                raise "Error while connecting to switch, make sure API address, username and password are defined in bench file.\n#{err_msg}"
            end
            @headers = {}
            @cookie = ''        
        end

        # Sends http post request to switch with given body and 
        # headers containing the session id cookie
        def post (body) 
            return @http.post(@uri.request_uri, body, @headers)
        end
        
        # Gets the parsed json response body
        def get_response_body(res) 
            return JSON.parse(res.body)
        end

        # Updates global headers object with session id cookie if one was set
        def set_headers(res) 
            if (res.response['set-cookie'])
                @cookie = res.response['set-cookie'].split('; ')[0]
            end

            @headers = {
                "Cookie" => @cookie
            }
        end

        # Checks the response value from request to switch 
        def check_response (res, cmd) 
            res = get_response_body(res)

            if (res['error'] && res['error']['message'])
                log_error("EXABLAZE Error encountered with request: " + cmd.to_s + "=>" + res['error']['message'])
                raise "EXABLAZE Error encountered with request: " + cmd.to_s + "=>" + res['error']['message']
            elsif (res['result'] == false)
                log_error("EXABLAZE Request failed for request: " + cmd.to_s)
                raise "EXABLAZE Request failed for request: " + cmd.to_s    
            end
        end

        ###################################################################
        # Function takes in array of connections as input 
        # in the format of following example and configures switch to make them
        # 
        # Notes: 
        # For patching, use src_port / dest_port as port A/B
        #
        # For tapping, src_port is where you want to listen for traffic
        # and dest_port is where you want to be able to receive it.
        #
        # Direction by default taps into incoming traffic on src port
        # if specified to output then it taps into outgoing traffic
        # on src port 
        # 
        # connections = [
        #    {
        #       method: "patch",
        #       src_port: <port>,
        #       dest_port: <port>
        #    },
        #    {
        #       method: "tap",
        #       src_port: <port>,
        #       dest_port: <port>,
        #       direction: <input | output>
        #    },
        #    ...
        # ]
        # 
        # Returns:
        # 0 for success
        # Raises an exception for errors
        ###################################################################
        def make_connections(connections) 
            # Authenticate with switch
            log_info("Logging in...") 
            login_response = login()
            
            # Ensure valid login before making connections
            check_response(login_response, 'login')
            log_info("Successful login") 
        
            # Get session id cookie from login response and store for subsequent reqs
            set_headers(login_response)

            # For each desired connection, send request to switch and check repsonse 
            connections.each { |conn|
                log_info("Making connection: #{conn.to_s}")

                case conn["method"]                
                    when PATCH
                        res = create_patch(conn["src_port"], conn["dest_port"]) 
                    when TAP
                        res = create_tap(conn["src_port"], conn["dest_port"], conn["direction"])
                end
    
                check_response(res, conn)
                log_info("Successful connection: #{conn.to_s}") 
            }
            return 0
        end
            
        ###################################################################
        # Function takes in array of connections as input 
        # in the following format and destroys them:
        #
        # Notes: 
        # For patching, use src_port / dest_port as port A/B,
        # port order matters when deleting the configuration
        # 
        # connections = [
        #    {
        #       method: "patch",
        #       src_port: <port>,
        #       dest_port: <port>
        #    },
        #    {
        #       method: "tap",
        #       src_port: <port>,
        #       dest_port: <port>,
        #       direction: <input | output>
        #    },
        #    ...
        # ]
        #
        # Returns:
        # 0 for success
        # Raises an exception for errors
        ###################################################################
        def delete_connections(connections) 
            # Authenticate with switch
            log_info("Logging in...")
            login_response = login()
            
            # Ensure valid login before making connections
            check_response(login_response, 'login')
            log_info("Successful login") 

            # Get session id cookie from login response and store for subsequent reqs
            set_headers(login_response)
            
            # For each desired connection, send request to switch and check repsonse 
            connections.each { |conn|
                log_info("Deleting connection: #{conn.to_s}")
                
                case conn["method"]
                    when PATCH
                        res = delete_patch(conn["src_port"], conn["dest_port"]) 
                    when TAP
                        res = delete_tap(conn["src_port"], conn["dest_port"], conn["direction"])
                end

                check_response(res, conn)
                log_info("Successful deletion: #{conn.to_s}") 
            }
            return 0
        end

        # Send login request        
        def login() 
            login_request = {
                "method" => "login",
                "params" => {
                    "username" => "#{@username}",
                    "password" => "#{@password}"
                }
            }

            return post(login_request.to_json)
        end

        # Create a patch from port_a to port_b
        def create_patch(port_a, port_b) 
            create_patch_request = {
                "method" => "create_patch",
                "params" => {
                    "ports" => ["#{port_a}", "#{port_b}"]
                }
            }

            return post(create_patch_request.to_json)
        end

        # Delete a patch from port_a to port_b
        def delete_patch(port_a, port_b) 
            delete_patch_request = {
                "method" => "delete_patch",
                "params" => {
                    "ports" => ["#{port_a}", "#{port_b}"]
                }
            }

            return post(delete_patch_request.to_json)
        end

        # Create a tap listening on src_port, outputting on dest_port for given direction of traffic
        def create_tap(src_port, dest_port, direction) 
            create_tap_request = {
                "method" => "create_tap",
                "params" => {
                    "port" => "#{dest_port}",
                    "src_port" => "#{src_port}",
                    "direction" => "#{direction}"
                }
            }
            
            return post(create_tap_request.to_json)
        end
        
        # Delete a tap listening on src_port, outputting on dest_port for given direction of traffic
        def delete_tap(src_port, dest_port, direction) 
            delete_tap_request = {
                "method" => "delete_tap",
                "params" => {
                    "port" => "#{dest_port}",
                    "src_port" => "#{src_port}",
                    "direction" => "#{direction}"
                }
            }

            return post(delete_tap_request.to_json)
        end

        #Starts the logger for the session. Takes the log file path as parameter.
        # * file_path - the path to store the log
        def start_logger(file_path)
            if @exa_log
                stop_logger
            end

            Logger.new('exablaze_log')
            @exa_log_outputter = Log4r::FileOutputter.new("exablaze_log_out",{:filename => file_path.to_s , :truncate => false})
            @exa_log= Logger['exablaze_log']
            @exa_log.level = Log4r::DEBUG
            @exa_log.add  @exa_log_outputter
            @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
            @exa_log_outputter.formatter = @pattern_formatter
        end
    
        #Stops the logger.
        def stop_logger
            @exa_log_outputter = nil if @exa_log_outputter
            @exa_log = nil if @exa_log
        end

        def log_info(info)
            @exa_log.info(info) if @exa_log
        end
    
        def log_error(error)
            @exa_log.error(error) if @exa_log
        end
    end
end