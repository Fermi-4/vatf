module STAF
  class STAFResult
    def initialize(rc, result)
      @rc = rc;
      @result = result;
    end

    attr_reader :rc, :result;
    
    def self.unmarshall_response(response)
      keys = []
      values = []
      map = {}
      response.scan(/\{:\d+::12:display-name@SDT.+?key@SDT\/\$S:\d+:(\w+?)(?::[:\w]+)*@SDT/m) {|key| keys << key.flatten[0]}
      raw_values = response.scan(/%:\d+::\d+:.+?@SDT(.+)$/m).flatten[0].split(/@SDT/)
      raw_values.each {|val| values << /\/\$S:\d+:(.+)/m.match(val).captures[0]}
      keys.each_index {|i| map[keys[i]] = values[i]}
      map
    end
  end
end

