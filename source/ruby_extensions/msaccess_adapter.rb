require 'active_record/connection_adapters/abstract_adapter'

require 'bigdecimal'
require 'bigdecimal/util'

# msaccess_adapter.rb -- ActiveRecord adapter for Microsoft Access
#
# Author: Too ashamed to accept is using access
# Date:   10/14/2004
#


module ActiveRecord
  class Base
    class << self
      attr_accessor :pluralize_table_names
    end
    self.pluralize_table_names = false
    
    def self.msaccess_connection(config) #:nodoc:
      require_library_or_gem 'dbi' unless self.class.const_defined?(:DBI)
      
      config = config.symbolize_keys

      mode        = config[:mode] ? config[:mode].to_s.upcase : 'ODBC'
      username    = config[:username] ? config[:username].to_s : ''
      password    = config[:password] ? config[:password].to_s : ''
	  
	  raise ArgumentError, "Missing DSN. Argument ':dsn' must be set in order for this adapter to work." unless config.has_key?(:dsn)
	  raise ArgumentError, "Missing Database. Argument ':database' must be set in order for this adapter to work." unless config.has_key?(:database)
	  dsn       = config[:dsn]
	  database = config[:database]
	  driver_url = "DBI:#{mode}:#{dsn};dbq=#{database}"
      conn      = DBI.connect(driver_url, username, password)
      ConnectionAdapters::MSAccessAdapter.new(conn, logger, [driver_url, username, password])
    end
  end # class Base

  module ConnectionAdapters
    class MSAccessColumn < Column# :nodoc:
      attr_reader :identity, :is_special

      def initialize(name, default, sql_type = nil, identity = false, null = true) # TODO: check ok to remove scale_value = 0
        super(name, default, sql_type, null)
		    @identity = identity
        @is_special = sql_type =~ /text|ntext|image/i
        # TODO: check ok to remove @scale = scale_value
        # SQL Server only supports limits on *char and float types
        @limit = nil unless @type == :float or @type == :string
      end

      def simplified_type(field_type)
        case field_type
          when /money/i             then :decimal
          when /image/i             then :binary
          when /bit/i               then :boolean
          when /uniqueidentifier/i  then :string
          else super
        end
      end

      def type_cast(value)
        return nil if value.nil?
        case type
        when :datetime  then cast_to_datetime(value)
        when :timestamp then cast_to_time(value)
        when :time      then cast_to_time(value)
        when :date      then cast_to_datetime(value)
        when :boolean   then value == true or (value =~ /^t(rue)?$/i) == 0 or value.to_s == '1'
        else super
        end
      end
      
      def cast_to_time(value)
        return value if value.is_a?(Time)
        time_array = ParseDate.parsedate(value)
        Time.send(Base.default_timezone, *time_array) rescue nil
      end

      def cast_to_datetime(value)
        return value.to_time if value.is_a?(DBI::Timestamp)
        if value.is_a?(Time)
          if value.year != 0 and value.month != 0 and value.day != 0
            return value
          else
            return Time.mktime(2000, 1, 1, value.hour, value.min, value.sec) rescue nil
          end
        end
   
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        end
        
        return cast_to_time(value) if value.is_a?(Date) or value.is_a?(String) rescue nil
        value
      end
      
      # TODO: Find less hack way to convert DateTime objects into Times
      
      def self.string_to_time(value)
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        else
          super
        end
      end

      # These methods will only allow the adapter to insert binary data with a length of 7K or less
      # because of a SQL Server statement length policy.
      def self.string_to_binary(value)
        value.gsub(/(\r|\n|\0|\x1a)/) do
          case $1
            when "\r"   then  "%00"
            when "\n"   then  "%01"
            when "\0"   then  "%02"
            when "\x1a" then  "%03"
          end
        end
      end

      def self.binary_to_string(value)
        value.gsub(/(%00|%01|%02|%03)/) do
          case $1
            when "%00"    then  "\r"
            when "%01"    then  "\n"
            when "%02\0"  then  "\0"
            when "%03"    then  "\x1a"
          end
        end
      end
    end

    #Microsoft access database adapter class.
    class MSAccessAdapter < AbstractAdapter
    
      def initialize(connection, logger, connection_options=nil)
        super(connection, logger)
        @connection_options = connection_options
      end

      def native_database_types
        {
          :primary_key => "COUNTER NOT NULL PRIMARY KEY",
          :string      => { :name => "varchar", :limit => 255  },
          :text        => { :name => "text" },
          :integer     => { :name => "number", :limit => 4 },
          :float       => { :name => "number", :limit => 8 },
          :decimal     => { :name => "number", :limit => 16 },
          :datetime    => { :name => "datetime" },
          :timestamp   => { :name => "datetime" },
          :time        => { :name => "datetime" },
          :date        => { :name => "datetime" },
          :binary      => { :name => "image"},
          :boolean     => { :name => "bit"}
        }
      end

      def adapter_name
        'MSAccess'
      end
      
      def supports_migrations? #:nodoc:
        false
      end

      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        return super unless type.to_s == 'integer'

        if limit.nil? || limit == 4
          'integer'
        elsif limit < 4
          'smallint'
        else
          'bigint'
        end
      end

      # CONNECTION MANAGEMENT ====================================#

      # Returns true if the connection is active.
      def active?
        @connection.ping
      end

      # Reconnects to the database, returns false if no connection could be made.
      def reconnect!
        disconnect!
        @connection = DBI.connect(*@connection_options)
      rescue DBI::DatabaseError => e
        @logger.warn "#{adapter_name} reconnection failed: #{e.message}" if @logger
        false
      end
      
      # Disconnects from the database
      
      def disconnect!
        @connection.disconnect rescue nil
      end

      def columns(table_name, name = nil)
       
        return [] if table_name.blank?
        table_name = table_name.to_s if table_name.is_a?(Symbol)
        table_name = table_name.split('.')[-1] unless table_name.nil?
        table_name = table_name.gsub(/[\[\]]/, '')
        result = @connection.columns(table_name)
        columns = []
        result.each do |field|
		  default = field.include?('default') ? field.default : nil 
          is_identity = field.type_name == "COUNTER"
          is_nullable = field.nullable == "1"
		  type = "#{field.type_name}(#{field.precision})"
          columns << MSAccessColumn.new(field.name, default, type, is_identity, is_nullable)
        end
        columns
      end

      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        execute(sql, name)
        select_one("SELECT @@IDENTITY AS Ident")["Ident"]
      end

      def update(sql, name = nil)
        execute(sql, name) do |handle|
          handle.rows
        end || select_one("SELECT @@ROWCOUNT AS AffectedRows")["AffectedRows"]        
      end
      
      alias_method :delete, :update

      def execute(sql, name = nil)
        if sql =~ /^\s*INSERT/i && (table_name = query_requires_identity_insert?(sql))
          log(sql, name) do
            with_identity_insert_enabled(table_name) do 
              @connection.execute(sql) do |handle|
                yield(handle) if block_given?
              end
            end
          end
        else
          log(sql, name) do
            @connection.execute(sql) do |handle|
              yield(handle) if block_given?
            end
          end
        end
      end

     # def begin_db_transaction
       #execute("BEGIN TRANSACTION")
      #end

      #def commit_db_transaction
        #execute("COMMIT TRANSACTION")
     # end

     # def rollback_db_transaction
        #execute("ROLLBACK TRANSACTION")
     # end

      def quote(value, column = nil)
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when TrueClass             then '1'
          when FalseClass            then '0'
          when Time, DateTime        then "'#{value.strftime("%m/%d/%Y %I:%M:%S%p")}'"
          when Date                  then "'#{value.strftime("%m/%d/%Y")}'"
          else                       super
        end
      end

      def quote_string(string)
        string.gsub(/\'/, "''")
      end

      def quote_column_name(name)
        "[#{name}]"
      end

      def add_limit_offset!(sql, options)
      
        if options[:limit] and options[:offset]
          total_rows = @connection.select_all("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")[0][:TotalRows].to_i
          if (options[:limit] + options[:offset]) >= total_rows
            options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
          end
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT#{$1} TOP #{options[:limit] + options[:offset]} ")
          sql << ") AS tmp1"
          if options[:order]
            options[:order] = options[:order].split(',').map do |field|
              parts = field.split(" ")
              tc = parts[0]
              if sql =~ /\.\[/ and tc =~ /\./ # if column quoting used in query
                tc.gsub!(/\./, '\\.\\[')
                tc << '\\]'
              end
              if sql =~ /#{tc} AS (t\d_r\d\d?)/
                parts[0] = $1
              elsif parts[0] =~ /\w+\.(\w+)/
                parts[0] = $1
              end
              parts.join(' ')
            end.join(', ')
            sql << " ORDER BY #{change_order_direction(options[:order])}) AS tmp2 ORDER BY #{options[:order]}"
          else
            sql << " ) AS tmp2"
          end
        elsif sql !~ /^\s*SELECT (@@|COUNT\()/i
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i) do
            "SELECT#{$1} TOP #{options[:limit]}"
          end unless options[:limit].nil?
        end
      end
=begin
      def recreate_database(name)
        puts "Not supported in Jet engine  for MS Access"
		nil
      end

      def drop_database(name)
        puts "Not supported in Jet engine  for MS Access"
		nil
      end

      def create_database(name)
        puts "Not supported in Jet engine  for MS Access"
		nil
      end
  =end 
      def current_database
        @config[:database]
      end

      def tables(name = nil)
        @connection.tables
      end
=begin
      def indexes(table_name, name = nil)
        puts "Not supported in Jet engine  for MS Access"
		nil
      end
            
      def rename_table(name, new_name)
        puts "Not supported in MSAccess "
		nil
      end
      
      # Adds a new column to the named table.
      # See TableDefinition#column for details of the options you can use.
      def add_column(table_name, column_name, type, options = {})
        puts "Not supported in MSAccess "
		nil
      end
       
      def rename_column(table, column, new_column_name)
        puts "Not supported in MSAccess "
		nil
      end
      
      def change_column(table_name, column_name, type, options = {}) #:nodoc:
        puts "Not supported in MSAccess "
		nil
      end
      
      def remove_column(table_name, column_name)
        puts "Not supported in MSAccess "
		nil
      end
      
      def remove_default_constraint(table_name, column_name)
        puts "Not supported in MSAccess "
		nil
      end
      
      def remove_check_constraints(table_name, column_name)
        puts "Not supported in MSAccess "
		nil
      end
      
      def remove_index(table_name, options = {})
        puts "Not supported in MSAccess "
		nil
	  end
=end
      private 
        def select(sql, name = nil)
          repair_special_columns(sql)

          result = []          
          execute(sql) do |handle|
            handle.each do |row|
              row_hash = {}
              row.each_with_index do |value, i|
                if value.is_a? DBI::Timestamp
                  value = DateTime.new(value.year, value.month, value.day, value.hour, value.minute, value.sec)
                end
                row_hash[handle.column_names[i]] = value
              end
              result << row_hash
            end
          end
          result
        end

        # Turns IDENTITY_INSERT ON for table during execution of the block
        # N.B. This sets the state of IDENTITY_INSERT to OFF after the
        # block has been executed without regard to its previous state

        def with_identity_insert_enabled(table_name, &block)
          set_identity_insert(table_name, true)
          yield
        ensure
          set_identity_insert(table_name, false)  
        end
        
        def set_identity_insert(table_name, enable = true)
          execute "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
        rescue Exception => e
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"  
        end

        def get_table_name(sql)

          if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
            $1
          elsif sql =~ /from\s+([^\(\s]+)\s*/i
            $1
          else
            nil
          end
        end

        def identity_column(table_name)
          @table_columns = {} unless @table_columns
          @table_columns[table_name] = columns(table_name) if @table_columns[table_name] == nil
          @table_columns[table_name].each do |col|
            return col.name if col.identity
          end

          return nil
        end

        def query_requires_identity_insert?(sql)
          table_name = get_table_name(sql)
          id_column = identity_column(table_name)
          sql =~ /\[#{id_column}\]/ ? table_name : nil
        end

        def change_order_direction(order)
          order.split(",").collect {|fragment|
            case fragment
              when  /\bDESC\b/i     then fragment.gsub(/\bDESC\b/i, "ASC")
              when  /\bASC\b/i      then fragment.gsub(/\bASC\b/i, "DESC")
              else                  String.new(fragment).split(',').join(' DESC,') + ' DESC'
            end
          }.join(",")
        end

        def get_special_columns(table_name)
          special = []
          @table_columns ||= {}
          @table_columns[table_name] ||= columns(table_name)
          @table_columns[table_name].each do |col|
            special << col.name if col.is_special
          end
          special
        end

        def repair_special_columns(sql)
          special_cols = get_special_columns(get_table_name(sql))
          for col in special_cols.to_a
            sql.gsub!(Regexp.new(" #{col.to_s} = "), " #{col.to_s} LIKE ")
            sql.gsub!(/ORDER BY #{col.to_s}/i, '')
          end
          sql
        end

    end #class MSAccessAdapter < AbstractAdapter
  end #module ConnectionAdapters
end #module ActiveRecord
