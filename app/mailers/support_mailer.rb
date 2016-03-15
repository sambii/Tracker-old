# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SupportMailer < ActionMailer::Base
  default :from => ServerConfig.first.support_email

  def show(except)
    server_url = ServerConfig.first.server_url
    server_url = request.base_url if server_url.blank?
    mail(subject: "exception for server: #{server_url}")
    @e = except
  end
end
