class UserMailer < ActionMailer::Base

  default :from => ServerConfig.find(2).support_email

  def welcome_user(user, school, server_config)
    @user = user
    @server_config = server_config
    if @user.school_id.present?
      @school_name = school.name
    else
      @school_name = ''
    end
    mail(to: @user.email, subject: "Welcome to the #{@school_name} #{@server_config.server_name}.") if @user.email.present?
  end

  def changed_user_password(user, school, server_config)
    @user = user
    @server_config = server_config
    if @user.school_id.present?
      @school_name = school.name
    else
      @school_name = ''
    end
    mail(to: @user.email, subject: "Password change for #{@school_name} #{@server_config.server_name}.") if @user.email.present?
  end

end
