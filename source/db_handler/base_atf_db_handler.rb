require 'dbi'
require 'active_record'
require File.dirname(__FILE__)+'/../framework_constants'
require File.dirname(__FILE__)+'/base_handler'

module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class BaseATFDbHandler < BaseATFDataHandler

    private
      @db_path
      @db_type 

    public
    
      #Constructor of the class takes 1 or no arguments
      def initialize (type = nil) 
        if !type
          @db_type = "msaccess"
        else
          @db_type = type.downcase  
        end    
      end
      
      #Connects to the database, and returns a handle to the connection
      def connect_database(path)
        @db_path = path
        @bb = ActiveRecord::Base.establish_connection(:dsn => "driver=Microsoft Access Driver (*.mdb)", :adapter => @db_type, :mode => "ODBC",:database => @db_path)
        
        rescue DBI::DatabaseError => e
          puts "An error occurred opening the database "+@db_path
          puts "Error code: #{e.err}"
          puts "Error message: #{e.errstr}"
          @db_handle = nil
          raise
      end
      def remove_connection()
        ActiveRecord::Base.remove_connection()
        rescue DBI::DatabaseError => e
          puts "An error occurred closing the database "+@db_path
          puts "Error code: #{e.err}"
          puts "Error message: #{e.errstr}"
          @db_handle = nil
          raise
      end
      def connected?
        ActiveRecord::Base.connected?
      end
  end
end
