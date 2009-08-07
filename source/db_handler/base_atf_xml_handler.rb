require 'rexml/document'
require 'framework_constants'
require 'db_handler/ruby_staf_handler'
module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class BaseATFXmlHandler 
    include REXML 
    attr_accessor :db_type 
    private
      @xml_path
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
 
    end
      
      #Connects to the database, and returns a handle to the connection
    def connect_database(path)
      @xml_path = path
      @bb = REXML::Document.new(File.open(path,'r'))
      test = Hash.from_xml(@bb.root.to_s)
      @test_data = recompose_hash(test, Hash.new)

      rescue 
        puts "An error occurred opening the input XML file "+ @xml_path
        raise
    end
      
    def recompose_hash(in_hash, out_hash)
      in_hash.each_pair {|k,v|
      out_hash[k] = strip_cdata(v) if v.is_a? String
      out_hash[k] = v.each_pair{|vk,vv| recompose_hash(v, Hash.new)} if v.is_a? Hash
      out_hash[k] = v.each{|elem| recompose_hash(elem, Hash.new)} if v.is_a? Array
      }
      out_hash
    end

    def strip_cdata (e)
      e.gsub!(/^\<!\[CDATA\[/,"")
      e.gsub!(/\n/,"")
      e.gsub!(/\]\]\>$/,"")
      
    end
  end
end
