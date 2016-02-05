class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class MyFormatter
  def call(severity, timestamp, progname, msg)
    sevstring =sprintf("%-5s","#{severity}")
    "[#{timestamp}] #{msg.strip}\n"
  end
end
  
Rails.logger.formatter = MyFormatter.new
