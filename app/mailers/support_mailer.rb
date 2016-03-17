# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SupportMailer < ActionMailer::Base
  default from: ServerConfig.first.support_email, to: ServerConfig.first.support_email

  def show(ex, req, sess)
    server_config = ServerConfig.first
    web_server_name = server_config.web_server_name
    Rails.logger.debug("*** support_mailer.rb Exception: #{ex.exception} #{ex.message}")
    Rails.logger.debug("*** support_mailer.rb Trace: #{ex.backtrace.join('/n')}")
    @ex = ex
    @req = req
    @sess = sess
    @server_config = server_config
    mail(subject: "exception for server: #{web_server_name}")
  end
end
