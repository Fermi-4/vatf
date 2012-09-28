require 'net/http'

module PassCriteria
  #This hash contains dictionaries with syntax platform => {tc_id => <array of metrics>} for which the 1-sigma historical pass/fail criteria will not apply. In the distionary {platform,tc_id} is the platform-test_case_id (string-integer respectively)for which the array contains the metrics that will not be subject to the 1-sigma evaluation. This hash ideally should only include entries that are known to be outside the historical range, due to improvements in the release. 
  # A Dictionary example is 'am335x-sk' => {724121 => ['linpack']}
  SIGMA_EXEMPT_METRICS = {}

  # Compares  performance with best performance for platform in test database
  def self.is_performance_good_enough(platform, testcase_id, perf_data, max_dev=0.05)
    pass = true
    msg  = ''
    return [true, nil] if defined? skip_perf_comparison
    perf_data.each do |metric|
      metric['name'].gsub!(/\s/,'_')
      op = get_perf_comparison_operator(testcase_id, metric['name'])
      op = overwrite_perf_comparison_operator(testcase_id, metric['name']) if defined? overwrite_perf_comparison_operator
      data = get_perf_value(platform, testcase_id, metric['name'], op)
      data = overwrite_perf_value(platform, testcase_id, metric['name'], op, data) if defined? overwrite_perf_value
      return [true, 'Performance data was NOT compared'] if !data
      if data.length > 1 && (!SIGMA_EXEMPT_METRICS[platform] || !SIGMA_EXEMPT_METRICS[platform][testcase_id] || !SIGMA_EXEMPT_METRICS[platform][testcase_id].include?(metric['name']))
         if metric['max'] > data[0] + data[1] || metric['min'] < data[0] - data[1]
            pass = false
            msg = msg + ", #{metric['name']} out of expected range: max-> #{metric['max']} > #{data[0]} + #{data[1]} || min-> #{metric['min']} <  #{data[0]} - #{data[1]}"
         end
      else 
          case op
          when 'max'
            if metric['max'] < (data[0] * (1-max_dev))
              pass = false
              msg = msg + ", #{metric['name']}: #{metric['max']} < #{data[0]}"
            end
          when 'min'
            if metric['min'] > (data[0] * (1+max_dev))
              pass = false
              msg = msg + ", #{metric['name']}: #{metric['min']} > #{data[0]}"
            end
          when 'avg'
            metric_avg = metric['s1']/metric['s0']
            if metric_avg < (data[0] * (1-max_dev))
              pass = false
              msg = msg + ", #{metric['name']}: #{metric_avg} < #{data[0]}"
            end
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
    case metric_name.downcase
    when /lat_/, /cpu_*load/, /sr_\d+load/, /packet_*loss/, /jitter/, /power/, /boottime/
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
    s0 = response.match(/samples=([\-\d\.]+)/).captures[0].to_f
    data = []
    if s0 > 1
      s1 = response.match(/s1=([\-\d\.]+)/).captures[0].to_f
      s2 = response.match(/s2=([\-\d\.]+)/).captures[0].to_f
      data << s1/s0
      data << Math.sqrt((s0*s2 - s1**2) / (s0 * (s0-1)));
    else
      data << response.match(/#{operator}=([\-\d\.]+)/).captures[0].to_f
    end
    return data
  rescue
    return nil
  end

end
