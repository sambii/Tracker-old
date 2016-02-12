class UserMailer < ActionMailer::Base
  default :from => get_support_email

  def welcome_user(user)
    @user = user
    @school = user.school
    @server_config = get_server_config
    mail(to: @user.email, subject: "Welcome to the #{@school.name} #{@server_config.server_name}.")
  end

  def changed_user_password(user)
    @user = user
    @school = user.school
    @server_config = get_server_config
    mail(to: @user.email, subject: "Password change for #{@school.name} #{@server_config.server_name}.")
  end

end
