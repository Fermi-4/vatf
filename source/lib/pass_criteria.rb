require 'net/http'

module PassCriteria
  # Compares  performance against historical performance for (testplan, testcase, metric) tuple
  # perf_data = [{perf elements}], where perf elements is a hash with following keys:
  # {'name' => "string"
  #  'value' => []
  #  'units'  => "string"
  #  'significant_difference'  => optional param, defaults to 1, signals what's considered a significant change
  #                             in absolute terms.
  # }
  def self.is_performance_good_enough(project_id, testplan_id, testcase_id, perf_data, max_dev=0.05)
    pass = true
    msg  = ''
    return [true, nil, true] if defined? skip_perf_comparison
    perf_data.each do |metric|
      significant_difference = 1
      significant_difference = metric['significant_difference'] if metric.has_key? 'significant_difference'
      metric['name'].gsub!(/\s/,'_')
      op = get_perf_comparison_operator(testcase_id, metric['name'])
      op = overwrite_perf_comparison_operator(testcase_id, metric['name']) if defined? overwrite_perf_comparison_operator
      data = get_perf_value(project_id, testplan_id, testcase_id, metric['name'], op)
      return [true, "Performance data was NOT compared, #{data}", true] if data.class == String and ! defined? overwrite_perf_value
      data = overwrite_perf_value(testplan_id, testcase_id, metric['name'], op, data) if defined? overwrite_perf_value
      metric_avg = metric['s1']/metric['s0']
      # Indicate outlier sample is outside 5 stddev window
      diff = (metric_avg - data[0]).abs
      if diff > 10 * data[1] and diff > significant_difference and diff > (data[0] * 10 * max_dev).abs
        return [false, ". #{metric['name']} contains outlier samples outside 10 stdev window. measured value=#{metric_avg}, historical mean=#{data[0]}, std=#{data[1]}. Please check your setup. Performance data won't be saved", false]
      end

      case op
      when 'max' # more is better
        benchmark = data[0] - 2*data[1]
        benchmark = data[0] * (1-max_dev) if (data[0] / data[1] > 100) # Don't use stddev if stddev is too small
        if metric_avg < benchmark
          pass = false
          msg = msg + ", #{metric['name']} out of expected range: #{metric_avg} < #{data[0]} - #{data[1]}"
        end
      when 'min' # less is better
        benchmark = data[0] + 2*data[1]
        benchmark = data[0] * (1+max_dev) if (data[0] / data[1] > 100) # Don't use stddev if stddev is too small
        if metric_avg > benchmark
          pass = false
          msg = msg + ", #{metric['name']} out of expected range: #{metric_avg} > #{data[0]} + #{data[1]}"
        end
      end
      
      if pass == false and metric.has_key? 'significant_difference' and diff <= significant_difference
        pass = true 
        msg = msg + ", but, #{metric['name']} within expected range set by significant_difference."
      end
    end

    return [pass, msg, true]
  end

  # Returns operator (min, max) to use to compare performance data
  # 'min' indicates that the lower the number the better the performanace, 'max' is the opposite
  def self.get_perf_comparison_operator(testcase_id, metric_name)
    op = 'max' # Assume max as default comparison operator
    # Overwrite based on metric_name.
    case metric_name.downcase
    when /lat_/, /cpu_*load/, /sr_\d+load/, /packet_*loss/, /jitter/, /power/, /boottime/, /latency/, /_time/
      op = 'min'
    end
    # Add new entries to overwrite defaults if required. For example:
    # case testcase_id
    # when 123456789
    #   case metric_name
    #   when 'X'
    #     op = 'min'
    #   end
    # end
    return op
  end

  def self.get_perf_value(project_id, testplan_id, testcase_id, metric_name, operator)
    puts "testplan:#{testplan_id}, testcase:#{testcase_id}, metric:#{metric_name}, op:#{operator}"
    analytics_server = SiteInfo::ANALYTICS_SERVER[project_id]
    return "Analytics server is not configured. Check you site_info.rb file and make sure you are using latest DownwardTranslator.xsl" if ! analytics_server.match(/:/)
    host, port = analytics_server.split(':')
    port = port ? port.to_i : 3000      # ANALYTICS_SERVER runs on port 3000 by default
    connection = Net::HTTP.new(host, port, nil)
    resp = connection.get("/#{project_id}/performance/passcriteria/#{testplan_id}/#{testcase_id}/#{metric_name}/")
    response = resp.body
    if resp.code != "200"
      response = Net::HTTP.get(host, "/#{project_id}/performance/passcriteria/#{testplan_id}/#{testcase_id}/#{metric_name}/", port)
    end
    s0 = response.match(/samples=([\-\d\.]+)/).captures[0].to_f
    data = []
    if s0 > 3
      s1 = response.match(/s1=([\-\d\.]+)/).captures[0].to_f
      s2 = response.match(/s2=([\-\d\.]+)/).captures[0].to_f
      data << s1/s0
      val = (s0*s2 - s1**2)
      val = 0 if val < 0 and val > -1
      data << Math.sqrt(val / (s0 * (s0-1)));
    else
      return "Too few samples available"
    end
    return data
    rescue Exception => e
      puts e.to_s+"\n"+e.backtrace.to_s
      puts "response=#{response}"
      return "Error trying to get perf data. Make sure your testplan follows naming convention established for your project.\n#{e.to_s}"
  end

end
