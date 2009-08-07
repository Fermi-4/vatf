require 'dbi'
require 'active_record'
require 'framework_constants'

module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class BaseATFDbHandler
    private
      @db_path
      @db_type 
    
    #Function used to assign a name created dynamically. Turns off VERBOSE to disable warnings,
    #User must make sure name used is not already assigned to another class.  
    def silent_const_assignment(class_name, klass)
      warn_level = $VERBOSE
      $VERBOSE = nil
      assigned_klass = Object.const_set class_name, klass
      $VERBOSE = warn_level
      assigned_klass
    end
    
    #Creates a class class_name, that inherits from superclass, and executes block
    def create_class(class_name, superclass, &block)  
      klass = Class.new superclass, &block
      silent_const_assignment(class_name, klass)
    end
      
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
