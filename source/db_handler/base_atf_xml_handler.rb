require 'rexml/document'
require 'framework_constants'
require 'db_handler/ruby_staf_handler'
require File.dirname(__FILE__)+'/base_handler'

module ATFDBHandlers
=begin
  Base Database handler class.
=end
  class BaseATFXmlHandler < BaseATFDataHandler
    include REXML 
    attr_accessor :db_type, :staf_handle
    private
      @xml_path
      @db_type 
      
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
