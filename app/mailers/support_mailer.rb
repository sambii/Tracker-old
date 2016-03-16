# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SupportMailer < ActionMailer::Base
  default from: ServerConfig.first.support_email, to: ServerConfig.first.support_email

  def show(ex, req, sess)
    Rails.logger.debug("*** support_mailer.rb Exception: #{ex.exception} #{ex.message}")
    Rails.logger.debug("*** support_mailer.rb Trace: #{ex.backtrace.join('/n')}")
    server_url = ServerConfig.first.server_url
    server_url = req.base_url if server_url.blank?
    @ex = ex
    @req = req
    @sess = sess
    mail(subject: "exception for server: #{server_url}")
  end
end
