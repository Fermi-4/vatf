require 'net/http'

module PassCriteria
  # Compares  performance against historical performance for (testplan, testcase, metric) tuple
  def self.is_performance_good_enough(testplan_id, testcase_id, perf_data, max_dev=0.05)
    pass = true
    msg  = ''
    return [true, nil] if defined? skip_perf_comparison
    perf_data.each do |metric|
      metric['name'].gsub!(/\s/,'_')
      op = get_perf_comparison_operator(testcase_id, metric['name'])
      op = overwrite_perf_comparison_operator(testcase_id, metric['name']) if defined? overwrite_perf_comparison_operator
      data = get_perf_value(testplan_id, testcase_id, metric['name'], op)
      data = overwrite_perf_value(testplan_id, testcase_id, metric['name'], op, data) if defined? overwrite_perf_value
      return [true, 'Performance data was NOT compared'] if !data
      metric_avg = metric['s1']/metric['s0']
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
    end
    return [pass, msg]
  end

  # Returns operator (min, max) to use to compare performance data
  # 'min' indicates that the lower the number the better the performanace, 'max' is the opposite
  def self.get_perf_comparison_operator(testcase_id, metric_name)
    op = 'max' # Assume max as default comparison operator
    # Overwrite based on metric_name.
    case metric_name.downcase
    when /lat_/, /cpu_*load/, /sr_\d+load/, /packet_*loss/, /jitter/, /power/, /boottime/, /latency/
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

  def self.get_perf_value(testplan_id, testcase_id, metric_name, operator)
    puts "testplan:#{testplan_id}, testcase:#{testcase_id}, metric:#{metric_name}, op:#{operator}"
    host, port = SiteInfo::ANALYTICS_SERVER.split(':')
    port = port ? port.to_i : 3000      # ANALYTICS_SERVER runs on port 3000 by default
    connection = Net::HTTP.new(host, port, nil)
    response = connection.get("/performance/passcriteria/#{testplan_id}/#{testcase_id}/#{metric_name}/")
    if response.code != "200"
      response = Net::HTTP.get(host, "/performance/passcriteria/#{testplan_id}/#{testcase_id}/#{metric_name}/", port)
    end
    s0 = response.match(/samples=([\-\d\.]+)/).captures[0].to_f
    data = []
    if s0 > 1
      s1 = response.match(/s1=([\-\d\.]+)/).captures[0].to_f
      s2 = response.match(/s2=([\-\d\.]+)/).captures[0].to_f
      data << s1/s0
      data << Math.sqrt((s0*s2 - s1**2) / (s0 * (s0-1)));
    else
      data << response.match(/#{operator}=([\-\d\.]+)/).captures[0].to_f
      data << 1E-20 # Practically zero but allow division
    end
    return data
  rescue
    return nil
  end

end
