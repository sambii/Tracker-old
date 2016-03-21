class UserMailer < ActionMailer::Base

  # removed because test database is empty when this is called
  # default :from => ServerConfig.first.support_email

  def welcome_user(user, school, server_config)
    @user = user
    @server_config = server_config
    if @user.school_id.present?
      @school_name = school.name
    else
      @school_name = ''
    end
    mail(from: get_support_email, to: @user.email, subject: "Welcome to the #{@school_name} #{@server_config.server_name}.") if @user.email.present?
  end

  def changed_user_password(user, school, server_config)
    @user = user
    @server_config = server_config
    if @user.school_id.present?
      @school_name = school.name
    else
      @school_name = ''
    end
    mail(from: get_support_email, to: @user.email, subject: "Password change for #{@school_name} #{@server_config.server_name}.") if @user.email.present?
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
