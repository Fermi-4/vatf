# Copyright (C) 2015 Hector Sanjuan
# Copyright (C) 2019 Texas Instruments

# This file is part of Jsonrpctcp.

# Jsonrpctcp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Jsonrpctcp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Jsonrpctcp.  If not, see <http://www.gnu.org/licenses/>

require 'socket'
require 'json'

module Jsonrpctcp
# A custom exception for the library
  class RPCException < Exception
  end

  # A custom error for the library
  class RPCError < StandardError
    attr_reader :code, :message, :source_object
    # RPC erros allow quick access to the code, the message and the
    # source error object returned by the server
    # @param message [String] Error message
    # @param code [Fixnum] Error code
    # @param source [Hash] Original error object
    def initialize(message, code, source)
      @code = code
      @message = message
      @source_object = hash
    end

    # Creates a RPCError directly from a RPC response
    # @param r [Hash] a parsed response
    def self.from_rpc_response(r)
      if r.nil? || !r.is_a?(Hash)
        return RPCError.new("Empty response",
                            nil,
                            {})
      else
        return RPCError.new(r['error']['message'],
                            r['error']['code'],
                            r)
      end
    end
  end


  # The JSON-RPC client
  class Client
    attr_reader :host, :port, :handle

    # Initialize
    # @param host [String] a hostname or IP
    # @param port [String,Fixnum] a port number
    def initialize(host, port)
      @host = host
      @port = port
      @handle = nil
    end

    def open_connection(unit_id)
      sleep 1
      response = process_call("cbrx_connection_open", [unit_id])
      @handle = response['result'] if response && response['result']
      sleep 1
    end

    def close_connection()
      if @handle
        sleep 1
        response = process_call("cbrx_connection_close", [@handle])
        @handle = nil
        sleep 1
      end
    end

    # @return [TrueClass,FalseClass] returns whether a
    #                                response does not have an error key
    def self.success?(response)
      return !Client.is_error?(response)
    end

    # @return [TrueClass,FalseClass] returns whether a
    #                                response does have an error key
    def self.is_error?(response)
      return !response || !response.is_a?(Hash) || response.has_key?('error')
    end

    # Allows to call RPC methods as if they were defined functions:
    # client.mymethod(...)
    # @param method [Symbol] A RPC method name
    # @param args [Array] The arguments for the method are passed as
    #                     parameters to the function
    def method_missing(method, *args)
      raise "Error: connection not open. Call open_connection(unit_id) first" if !@handle
      args.insert(0, @handle).flatten!
      return process_call(method, args)
    end

    # Calls an RPC methods in the client[:mymethod, "arg1",...] fashion
    # @param method [Symbol] A RPC method name
    # @param args [Array] The arguments for the method are passed as
    #                     parameters to the function
    def [](method, *args)
      raise "Error: connection not open. Call open_connection(unit_id) first" if !@handle
      args.insert(0, @handle).flatten!
      return process_call(method, args)
    end

    # Generate a message id - currently the current time
    # @return [Fixnum] A time-based id
    def self.gen_id
      Time.now.to_i
    end

    private

    def process_call(method, args)
      call_obj = {
        'jsonrpc' => '2.0',
        'method' => method,
        'params' => args,
        'id' => Client.gen_id
      }

      call_obj_json = call_obj.to_json
      begin
        puts "tosend:#{call_obj_json}"
        socket = TCPSocket.open(@host, @port)
        socket.write(call_obj_json)
        sleep 0.5
        socket.close_write()
        response = socket.read()
        puts "Gotraw:#{response}##"
        parsed_response = JSON.load(response)
      rescue JSON::ParserError
        raise RPCException.new("RPC response could not be parsed")
      ensure
        socket.close() if socket
      end

      if Client.is_error?(parsed_response)
        raise RPCError.from_rpc_response(parsed_response)
      else
        return parsed_response
      end
    end
  end
end
