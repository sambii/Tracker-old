# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SupportMailer < ActionMailer::Base
  # removed because test database is empty when this is called
  # default from: ServerConfig.first.support_email, to: ServerConfig.first.support_email

  def show(ex, req, sess)
    server_config = ServerConfig.first
    web_server_name = server_config.web_server_name
    Rails.logger.debug("*** support_mailer.rb Exception: #{ex.exception} #{ex.message}")
    Rails.logger.debug("*** support_mailer.rb Trace: #{ex.backtrace.join('/n')}")
    @ex = ex
    @req = req
    @sess = sess
    @server_config = server_config
    mail(from: get_support_email, to: get_support_email, subject: "exception for server: #{web_server_name}")
  end

  private

  def get_support_email
    scr = ServerConfig.first
    if scr
      return scr.support_email
    else
      raise "Error: Missing Server Config Record"
    end
  end

end
