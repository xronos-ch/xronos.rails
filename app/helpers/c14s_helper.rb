class CalibratedDate
  attr_accessor :bpc, :probability
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
end

module C14sHelper
  include Pagy::Frontend
  def calibrator(c14)
    if RUBY_PLATFORM =~ /darwin/
      calib = JSON.parse(`cd vendor/calibrator/bin/; ./calibrator_mac -b #{c14.bp} -s #{c14.std} -r`)
    elsif RUBY_PLATFORM =~ /linux/
      calib = JSON.parse(`cd vendor/calibrator/bin/; ./calibrator_linux -b #{c14.bp} -s #{c14.std} -r`)
    end
    chart_data = calib["date"]["bp"].zip(calib["date"]["probabilities"]).map{|k, v| {bp: k, probability: v}}

    Vega.lite
      .title({"text": c14.lab_identifier,
        "font": '"Raleway", Inter, Helvetica Neue, Helvetica, Nimbus Sans, FreeSans, Arial, Arimo, Liberation Sans, sans-serif',
        "subtitle": "Atmospheric data from Reimer et al. (2013)",
        "align": "right", "anchor": "end", "color": "#7A90A1", "subtitleColor": "#7A90A1"})
      .data(chart_data)
      .mark(type: "area", tooltip: true, "line": {strokeWidth: 4}, interpolate: "monotone")
      .encoding(
        x: {field: "bp", type: "quantitative", title: "Calibrated dates",
          axis: {grid: true, tickMinStep: 50}},
        y: {field: "probability", type: "quantitative"},
      )
  end

  ################################
  #### calibration with oxcal ####
  ################################

  def calibrate_from_external(c14_id)
  	@c14 = C14.find(c14_id)
    out="Options(){RawData=TRUE};Plot(){R_Date(\"#{@c14.id}\",#{@c14.bp},#{@c14.std});};"
    File.open('tmp/radon_calib.oxcal', 'w') {|f| f.write(out) }
    `vendor/oxcal/OxCalLinux tmp/radon_calib.oxcal`
    @log = File.read('tmp/radon_calib.log')
    @graph = File.read('tmp/radon_calib.js')
    @log=@log.split("\n")[6..-1].join("\n")
    result_lines=@log.scan(/\n/).length
    @result_lines=result_lines
    likelihood_start = @graph[/(likelihood.start=)(.*)(;)/,2].to_f
    #    @likelihood_start=Time.local(likelihood_start,1,1)
    @likelihood_start=Time.mktime(likelihood_start)
    @likelihood_res = @graph[/(likelihood.resolution=)(.*)(;)/,2].to_f

    likelihood_prob_string=@graph[/(likelihood.prob=\[)(.*)(\];)/,2]
    likelihood_prob_norm=@graph[/(likelihood.probNorm=)(.*)(;)/,2]
    likelihood_probs=likelihood_prob_string.split(', ').map{|prob| prob.to_f*likelihood_prob_norm.to_f}
    calib_cal_string=@graph[/(calib\[0\].rawcal=\[)(.*)(\];)/,2]
    @calib_cal=calib_cal_string.split(',').map{|prob| prob.to_f}
    calib_bp_string=@graph[/(calib\[0\].rawbp=\[)(.*)(\];)/,2]
    @calib_bp=calib_bp_string.split(',').map{|prob| prob.to_f}
    calib_sigma_string=@graph[/(calib\[0\].rawsigma=\[)(.*)(\];)/,2]
    @calib_sigma=calib_sigma_string.split(',').map{|prob| prob.to_f}

    timespan=likelihood_probs.length * @likelihood_res
    @likelihood_end = Time.mktime(likelihood_start+timespan)

    @calib_data=Array.new
    @calib_data[0]=@calib_cal
    @calib_data[1]=@calib_bp
    @calib_data[2]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] + pair[1] }
    @calib_data[3]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] - pair[1] }
    @calib_data=@calib_data.transpose

    @calib_data_out=String.new
    calib_data_out_tmp=Array.new
    calib_upper_out_tmp=Array.new
    calib_lower_out_tmp=Array.new

    @calib_data.each do |a|
      if ((a[0]>=likelihood_start) && ((likelihood_start + timespan) >=a[0]))
        calib_data_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[1].to_s + ']')
        calib_upper_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[2].to_s + ']')
        calib_lower_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[3].to_s + ']')
      end
    end
    @calib_data_out=calib_data_out_tmp.join(',')
    @calib_upper_out=calib_upper_out_tmp.join(',')
    @calib_lower_out=calib_lower_out_tmp.join(',')

    @data=likelihood_probs

    labels=likelihood_probs.length.times.collect { |x| (x * @likelihood_res +likelihood_start).round}

    result_one_sigma=@graph.scan(/ocd\[2\].likelihood.range\[1\](.*);/)
    result_one_sigma=result_one_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}
    one_sigma_dist=Array.new
    counter=0
    result_one_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        one_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    one_sigma_prob=Array.new
    one_sigma_dist.transpose.each_with_index do |one_sigma,i|
      one_sigma_prob[i]=one_sigma.include?(true) ? -(likelihood_probs.max/10) : 'null'
    end

    @one_sigma_range = one_sigma_prob

    result_two_sigma=@graph.scan(/ocd\[2\].likelihood.range\[2\](.*);/)
    result_two_sigma=result_two_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}

    two_sigma_dist=Array.new
    counter=0
    result_two_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        two_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    two_sigma_prob=Array.new
    two_sigma_dist.transpose.each_with_index do |two_sigma,i|
      two_sigma_prob[i]=two_sigma.include?(true) ? -(likelihood_probs.max/20) : 'null'
    end

    @two_sigma_range = two_sigma_prob

    @curve=@graph[/(calib\[0\].ref=\")(.*)(;\";)/,2]

    user_files_mask = File.join("#{Rails.root}/tmp/radon_calib*")

    user_files = Dir.glob(user_files_mask)

  end
  
  def calibrate
    @c14 = C14Measurement.find(params[:id])
    out="Options(){RawData=TRUE};Plot(){R_Date(\"#{@c14.id}\",#{@c14.bp},#{@c14.std});};"
    File.open('tmp/radon_calib.oxcal', 'w') {|f| f.write(out) }
    `vendor/oxcal/OxCalLinux tmp/radon_calib.oxcal`
    @log = File.read('tmp/radon_calib.log')
    @graph = File.read('tmp/radon_calib.js')
    @log=@log.split("\n")[6..-1].join("\n")
    result_lines=@log.scan(/\n/).length
    @result_lines=result_lines
    likelihood_start = @graph[/(likelihood.start=)(.*)(;)/,2].to_f
    #    @likelihood_start=Time.local(likelihood_start,1,1)
    @likelihood_start=Time.mktime(likelihood_start)
    @likelihood_res = @graph[/(likelihood.resolution=)(.*)(;)/,2].to_f

    likelihood_prob_string=@graph[/(likelihood.prob=\[)(.*)(\];)/,2]
    likelihood_prob_norm=@graph[/(likelihood.probNorm=)(.*)(;)/,2]
    likelihood_probs=likelihood_prob_string.split(', ').map{|prob| prob.to_f*likelihood_prob_norm.to_f}
    calib_cal_string=@graph[/(calib\[0\].rawcal=\[)(.*)(\];)/,2]
    @calib_cal=calib_cal_string.split(',').map{|prob| prob.to_f}
    calib_bp_string=@graph[/(calib\[0\].rawbp=\[)(.*)(\];)/,2]
    @calib_bp=calib_bp_string.split(',').map{|prob| prob.to_f}
    calib_sigma_string=@graph[/(calib\[0\].rawsigma=\[)(.*)(\];)/,2]
    @calib_sigma=calib_sigma_string.split(',').map{|prob| prob.to_f}

    timespan=likelihood_probs.length * @likelihood_res
    @likelihood_end = Time.mktime(likelihood_start+timespan)

    @calib_data=Array.new
    @calib_data[0]=@calib_cal
    @calib_data[1]=@calib_bp
    @calib_data[2]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] + pair[1] }
    @calib_data[3]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] - pair[1] }
    @calib_data=@calib_data.transpose

    @calib_data_out=String.new
    calib_data_out_tmp=Array.new
    calib_upper_out_tmp=Array.new
    calib_lower_out_tmp=Array.new

    @calib_data.each do |a|
      if ((a[0]>=likelihood_start) && ((likelihood_start + timespan) >=a[0]))
        calib_data_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[1].to_s + ']')
        calib_upper_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[2].to_s + ']')
        calib_lower_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[3].to_s + ']')
      end
    end
    @calib_data_out=calib_data_out_tmp.join(',')
    @calib_upper_out=calib_upper_out_tmp.join(',')
    @calib_lower_out=calib_lower_out_tmp.join(',')

    @data=likelihood_probs

    labels=likelihood_probs.length.times.collect { |x| (x * @likelihood_res +likelihood_start).round}

    result_one_sigma=@graph.scan(/ocd\[2\].likelihood.range\[1\](.*);/)
    result_one_sigma=result_one_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}
    one_sigma_dist=Array.new
    counter=0
    result_one_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        one_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    one_sigma_prob=Array.new
    one_sigma_dist.transpose.each_with_index do |one_sigma,i|
      one_sigma_prob[i]=one_sigma.include?(true) ? -(likelihood_probs.max/10) : 'null'
    end

    @one_sigma_range = one_sigma_prob

    result_two_sigma=@graph.scan(/ocd\[2\].likelihood.range\[2\](.*);/)
    result_two_sigma=result_two_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}

    two_sigma_dist=Array.new
    counter=0
    result_two_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        two_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    two_sigma_prob=Array.new
    two_sigma_dist.transpose.each_with_index do |two_sigma,i|
      two_sigma_prob[i]=two_sigma.include?(true) ? -(likelihood_probs.max/20) : 'null'
    end

    @two_sigma_range = two_sigma_prob

    @curve=@graph[/(calib\[0\].ref=\")(.*)(;\";)/,2]

    user_files_mask = File.join("#{Rails.root}/tmp/radon_calib*")

    user_files = Dir.glob(user_files_mask)

    render :layout => false
  end

  def calibrate_multi
    # params[:ids]=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]
    order=params[:sort_by]
    @c14s = C14Measurement.order(order).where(id: params[:ids])

    out="Options(){RawData=TRUE};Plot(){"
    @c14s.each do |c14|
      out << "R_Date(\"#{c14.id}\",#{c14.bp},#{c14.std});"
    end
    out << "};"
    File.open('tmp/radon_calib.oxcal', 'w') {|f| f.write(out) }
    `vendor/oxcal/OxCalLinux tmp/radon_calib.oxcal`

    @graph = File.read('tmp/radon_calib.js')
    first_c14_number=2
    @likelihood_start=[]
    @likelihood_res=[]
    @data=[]
    @likelihood_end=[]
    @one_sigma_range=[]
    @two_sigma_range=[]
    max_likelihood=[]

    @c14s.each_with_index do |c14,i|
      c14_prefix="ocd[#{(i+first_c14_number).to_s}]."

      likelihood_start = @graph[/(#{Regexp.escape(c14_prefix)}likelihood.start=)(.*)(;)/,2].to_f

      @likelihood_start[i]=Time.mktime(likelihood_start)
      @likelihood_res[i] = @graph[/(#{Regexp.escape(c14_prefix)}likelihood.resolution=)(.*)(;)/,2].to_f

      likelihood_prob_string=@graph[/(#{Regexp.escape(c14_prefix)}likelihood.prob=\[)(.*)(\];)/,2]
      likelihood_prob_norm=@graph[/(#{Regexp.escape(c14_prefix)}likelihood.probNorm=)(.*)(;)/,2]
      likelihood_probs=likelihood_prob_string.split(', ').map{|prob| prob.to_f*likelihood_prob_norm.to_f}

      timespan=likelihood_probs.length * @likelihood_res[i]
      @likelihood_end[i] = Time.mktime(likelihood_start+timespan)

      labels=likelihood_probs.length.times.collect { |x| (x * @likelihood_res[i] +likelihood_start).round}

      max_likelihood[i]=likelihood_probs.max

      tmp_data=[]

      likelihood_probs.each_with_index do |likelihood,index|
        if index==0
          tmp_data.push('{id: "' + Measurement.find_by(c14_id: c14.id).labnr.to_s + '", x: ' + (Time.mktime(labels[index]).to_i*1000).to_s + ',y:' + likelihood.to_s + '}')
        else
          tmp_data.push('{x: ' + (Time.mktime(labels[index]).to_i*1000).to_s + ', y:' + likelihood.to_s + '}')
        end
      end

      #@data[i]=likelihood_probs
      @data[i]=tmp_data

      result_one_sigma=@graph.scan(/#{Regexp.escape(c14_prefix)}likelihood.range\[1\](.*);/)

      result_one_sigma=result_one_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}

      one_sigma_dist=Array.new
      counter=0
      result_one_sigma.each do |range|
        unless range.blank?
          range = range.split(",").map{|value| value.to_f}
          one_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
          counter = counter + 1
        end
      end

      one_sigma_prob=Array.new
      one_sigma_dist.transpose.each_with_index do |one_sigma,index|
        one_sigma_prob[index]=one_sigma.include?(true) ? -(max_likelihood[i]/10) : 'null'
      end

      @one_sigma_range[i] = one_sigma_prob

      result_two_sigma=@graph.scan(/#{Regexp.escape(c14_prefix)}likelihood.range\[2\](.*);/)
      result_two_sigma=result_two_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}

      two_sigma_dist=Array.new
      counter=0
      result_two_sigma.each do |range|
        unless range.blank?
          range = range.split(",").map{|value| value.to_f}
          two_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
          counter = counter + 1
        end
      end
      two_sigma_prob=Array.new
      two_sigma_dist.transpose.each_with_index do |two_sigma,index|
        two_sigma_prob[index]=two_sigma.include?(true) ? -(max_likelihood[i]/20) : 'null'
      end

      @two_sigma_range[i] = two_sigma_prob

    end

    @curve=@graph[/(calib\[0\].ref=\")(.*)(;\";)/,2]

    user_files_mask = File.join("#{Rails.root}/tmp/radon_calib*")

    user_files = Dir.glob(user_files_mask)

    user_files.each do |file_location|
      File.delete(file_location)
    end

    @max_data=max_likelihood.max

    render :layout => false

  end

  def calibrate_sum
    # params[:ids]=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]
    order=params[:sort_by]
    @c14s = C14Measurement.order(order).where(id: params[:ids])
    # @c14_ids_string = @c14s.map(&:id).to_sentence
    out="Options(){RawData=TRUE};Plot(){Sum(){"
    @c14s.each do |c14|
      out << "R_Date(\"#{c14.id}\",#{c14.bp},#{c14.std});"
    end
    out << "};};"
    File.open('tmp/radon_calib.oxcal', 'w') {|f| f.write(out) }
    `vendor/oxcal/OxCalLinux tmp/radon_calib.oxcal`
    @log = File.read('tmp/radon_calib.log')
    @graph = File.read('tmp/radon_calib.js')
    @log=@log.split("\n")[6..-1].join("\n")
    result_lines=@log.scan(/\n/).length
    @result_lines=result_lines
    likelihood_start = @graph[/(ocd\[2\].likelihood.start=)(.*)(;)/,2].to_f
    # @likelihood_start=Time.local(likelihood_start,1,1)
    @likelihood_start=Time.mktime(likelihood_start)
    @likelihood_res = @graph[/(ocd\[2\].likelihood.resolution=)(.*)(;)/,2].to_f

    likelihood_prob_string=@graph[/(ocd\[2\].likelihood.prob=\[)(.*)(\];)/,2]
    likelihood_prob_norm=@graph[/(ocd\[2\].likelihood.probNorm=)(.*)(;)/,2]
    likelihood_probs=likelihood_prob_string.split(', ').map{|prob| prob.to_f*likelihood_prob_norm.to_f}
    calib_cal_string=@graph[/(calib\[0\].rawcal=\[)(.*)(\];)/,2]
    @calib_cal=calib_cal_string.split(',').map{|prob| prob.to_f}
    calib_bp_string=@graph[/(calib\[0\].rawbp=\[)(.*)(\];)/,2]
    @calib_bp=calib_bp_string.split(',').map{|prob| prob.to_f}
    calib_sigma_string=@graph[/(calib\[0\].rawsigma=\[)(.*)(\];)/,2]
    @calib_sigma=calib_sigma_string.split(',').map{|prob| prob.to_f}

    timespan=likelihood_probs.length * @likelihood_res
    @likelihood_end = Time.mktime(likelihood_start+timespan)

    @calib_data=Array.new
    @calib_data[0]=@calib_cal
    @calib_data[1]=@calib_bp
    @calib_data[2]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] + pair[1] }
    @calib_data[3]=@calib_bp.zip(@calib_sigma).map{ |pair| pair[0] - pair[1] }
    @calib_data=@calib_data.transpose

    @calib_data_out=String.new
    calib_data_out_tmp=Array.new
    calib_upper_out_tmp=Array.new
    calib_lower_out_tmp=Array.new

    @calib_data.each do |a|
      if ((a[0]>=likelihood_start) && ((likelihood_start + timespan) >=a[0]))
        calib_data_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[1].to_s + ']')
        calib_upper_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[2].to_s + ']')
        calib_lower_out_tmp.push('[' + (Time.mktime(a[0]).to_i*1000).to_s + ', ' + a[3].to_s + ']')
      end
    end
    @calib_data_out=calib_data_out_tmp.join(',')
    @calib_upper_out=calib_upper_out_tmp.join(',')
    @calib_lower_out=calib_lower_out_tmp.join(',')

    @data=likelihood_probs

    labels=likelihood_probs.length.times.collect { |x| (x * @likelihood_res +likelihood_start).round}

    result_one_sigma=@graph.scan(/ocd\[2\].likelihood.range\[1\](.*);/)
    result_one_sigma=result_one_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}
    one_sigma_dist=Array.new
    counter=0
    result_one_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        one_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    one_sigma_prob=Array.new
    one_sigma_dist.transpose.each_with_index do |one_sigma,i|
      one_sigma_prob[i]=one_sigma.include?(true) ? -(likelihood_probs.max/10) : 'null'
    end

    @one_sigma_range = one_sigma_prob

    result_two_sigma=@graph.scan(/ocd\[2\].likelihood.range\[2\](.*);/)
    result_two_sigma=result_two_sigma.collect{|x| x.to_s[/\[.*?\].*\[(.*?)\]/,1]}

    two_sigma_dist=Array.new
    counter=0
    result_two_sigma.each do |range|
      unless range.blank?
        range = range.split(",").map{|value| value.to_f}
        two_sigma_dist[counter] = labels.map{|label| label.between?(range[0],range[1])}
        counter = counter + 1
      end
    end
    two_sigma_prob=Array.new
    two_sigma_dist.transpose.each_with_index do |two_sigma,i|
      two_sigma_prob[i]=two_sigma.include?(true) ? -(likelihood_probs.max/20) : 'null'
    end

    @two_sigma_range = two_sigma_prob

    @curve=@graph[/(calib\[0\].ref=\")(.*)(;\";)/,2]

    user_files_mask = File.join("#{Rails.root}/tmp/radon_calib*")

    user_files = Dir.glob(user_files_mask)

    user_files.each do |file_location|
      File.delete(file_location)
    end

    render :layout => false

  end

end
