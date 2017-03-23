module ATFDBHandlers
=begin
  Base Data handler class.
=end
  class BaseATFDataHandler
    
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
    
    def split_with_escape(expression, delimiter)
        rtn = []
        if expression then
          expression.scan(/(?:(?:\\#{delimiter})|(?:[^#{delimiter}]))+/).each do |x|
          rtn << x.gsub("\\#{delimiter}", delimiter.to_s) 	
          end
        end
        return rtn
      end

      #Creates a class with name class_name, whose attributes are the comma delimited values in class_attr_array
      def create_param_class(class_name, class_attr_array)    
        klass = silent_const_assignment(class_name,Class.new)
        if class_attr_array.is_a?(String)
          test_params = split_with_escape(class_attr_array.strip, ',')
          attr_hash = Hash.new()
          test_params.each do |param|
            if param.strip.length > 0
              parse_param = split_with_escape(param.strip, '=')
              attr_hash[parse_param[0].strip.downcase]= split_with_escape(parse_param[1], ';')
            end      
          end
          if attr_hash.keys.length > 0
            klass.class_eval do
              attr_reader *attr_hash.keys
              define_method(:initialize)do
                attr_hash.each do |at_name,at_val|
                instance_variable_set("@#{at_name}",at_val)
                end
              end
            end
          end
        end 
      end
      
      #Constructor of the class takes 1 or no arguments
    def initialize (type = nil, staf_srv_name = nil) 
      staf_handle = STAFHandle.new("staf_xml") 
      @staf_service_name = staf_srv_name
      staf_req = staf_handle.submit("local","VAR","GET SHARED VAR auto/tee/monitor") 
      if(staf_req.rc == 0)
        @monitor = staf_req.result
      else
        @monitor = nil
      end
      @staf_handle = nil
      rescue
        puts "STAF handle not initialized"
    end
    
    def monitor_log(message)
      if(@monitor != nil)
        staf_handle = STAFHandle.new("staf_xml") 
        staf_handle.submit("local","#{@monitor}","LOG MESSAGE '#{message}' NAME #{@staf_service_name}_status")
      else
        puts "STAF monitor not set"
      end
    end
    
    #Creates an object whose properties are vaariables and classes with the test cases parameters
    def get_test_parameters(tcase_attr, parms_chan = @db_tcase["params_chan"], parms_equip = @db_tcase["params_equip"], parms_control = @db_tcase["params_control"], additional_parameters = {})
      create_param_class("ParamsChan", parms_chan)
      create_param_class("ParamsEquip", parms_equip)
      create_param_class("ParamsControl", parms_control)
      test_param_klass = silent_const_assignment("TestParameters",Class.new)
      # tcase_attr = @db_tcase
      img_path = get_image_path
      staf_srv_name = @staf_service_name
      test_param_klass.class_eval do
        attr_reader :params_chan, :params_equip, :params_control
        attr_reader *tcase_attr.keys
        attr_reader *additional_parameters.keys
        attr_accessor :image_path, :platform, :target
        define_method(:initialize) do
          @params_chan = ParamsChan.new()  
          @params_equip = ParamsEquip.new()
          @params_control = ParamsControl.new()
          @staf_handle = STAFHandle.new("staf_tc") if defined?(STAFHandle)
		  @image_path = {}
          tcase_attr.each do |tc_attr, val|
            next if tc_attr.to_s.match(/params_{0,1}(Equip|Chan|Control)/i) 
            instance_variable_set("@#{tc_attr}",val)
          end
          additional_parameters.each do |param_name, param_val|
            next if !param_val
            instance_variable_set("@#{param_name}",param_val)
          end
          if !img_path && @staf_handle
            staf_req = @staf_handle.submit("local","VAR","GET SHARED VAR #{staf_srv_name ? staf_srv_name+'/' : ''}auto/sw_assets/kernel") 
            if(staf_req.rc == 0)
              @image_path['kernel']= staf_req.result
            end
          else
            @image_path['kernel'] = img_path 
          end
        end
	          
      def method_missing(sym, *args, &block)
        return send(sym) if respond_to?(sym)
        if @staf_handle
          raise UndefinedSwAsset.new("Undefined sw asset named #{sym}")
        end
        super
      end
		
      def instance_variable_defined?(sym)
        super(sym) || create_w_staf(sym)
      end
      
      def instance_variable_get(sym)
        super(sym) if instance_variable_defined?(sym)
      end
        
      def respond_to?(method_sym, include_private = false)
        super(method_sym, include_private) || create_w_staf(method_sym)
      end
          
      def create_w_staf(sym)
        if @staf_handle
          symbol_prep = sym.to_s.gsub(/^[:@]+/,'')
          instance_result = (@staf_handle.submit("local","VAR","GET SHARED VAR #{@staf_service_name ? @staf_service_name+'/' : ''}auto/sw_assets/#{symbol_prep}")) 
          instance_result = (@staf_handle.submit("local","VAR","GET SHARED VAR #{@staf_service_name ? @staf_service_name+'/' : ''}auto/tee/#{symbol_prep}")) if instance_result.rc != 0
          if instance_result.rc == 0
            self.class.send(:attr_accessor, symbol_prep)
            instance_variable_set("@#{symbol_prep}",instance_result.result)
            return instance_result.result
          end
        end
        nil
      end
        
      end
      TestParameters.new() 
    end

  end
end
