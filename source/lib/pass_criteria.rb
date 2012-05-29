require 'net/http'

module PassCriteria
	# Compares  performance with best performance for platform in test database
  def self.is_performance_good_enough(platform, testcase_id, perf_data, max_dev=0.05)
    pass = true
    msg  = ''
    return [true, nil] if defined? skip_perf_comparison
    perf_data.each do |metric|
      op = get_perf_comparison_operator(testcase_id, metric['name'])
      op = overwrite_perf_comparison_operator(testcase_id, metric['name']) if defined? overwrite_perf_comparison_operator
      data = get_perf_value(platform, testcase_id, metric['name'], op)
      data = overwrite_perf_value(platform, testcase_id, metric['name'], op, data) if defined? overwrite_perf_value
      return [true, 'Performance data was NOT compared'] if !data
      case op
      when 'max'
        if metric['max'] < (data * (1-max_dev))
          pass = false
          msg = msg + ", #{metric['name']}: #{metric['max']} < #{data}"
        end
      when 'min'
        if metric['min'] > (data * (1+max_dev))
          pass = false
          msg = msg + ", #{metric['name']}: #{metric['min']} > #{data}"
        end
      when 'avg'
        metric_avg = metric['s1']/metric['s0']
        if metric_avg < (data * (1-max_dev))
          pass = false
          msg = msg + ", #{metric['name']}: #{metric_avg} < #{data}"
        end
      end
    end
    return [pass, msg]
  end

  # Returns operator (min, max, avg) to use to compare performance data
  # 
  def self.get_perf_comparison_operator(testcase_id, metric_name)
    op = 'max' # Assume max as default comparison operator
    # Overwrite based on metric_name.
    case metric_name
    when /lat_/, /cpu_*load/, /packet_*loss/, /jitter/, /power/
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

  def self.get_perf_value(platform, testcase_id, metric_name, operator)
    host, port = SiteInfo::ANALYTICS_SERVER.split(':')
    port = port ? port.to_i : 3000      # ANALYTICS_SERVER runs on port 3000 by default
    response = Net::HTTP.get(host, "/passcriteria/#{platform}/#{testcase_id}/#{metric_name}", port)
    data = response.match(/#{operator}=([\d\.]+)/).captures[0]
    return data.to_f
  rescue
    return nil
  end

end
