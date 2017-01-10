# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module ApplicationHelper
  require 'prawn'

  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def allow_markup string
    # New Paragraphs
    output = ""
    output << string
    output.gsub!(/\r\n\r\n/, "\n<br /><br />\n")
    output.gsub!(/\n\n/, "\n<br /><br />\n")
    output.gsub!(/(^\*\s(.+?))+/, "<li>\\2</li>")
    output.gsub!(/\*\*(.+?)\*\*/, "<b>\\1</b>")
    output.gsub!(/\*(.+?)\*/, "<i>\\1</i>")
    output.gsub!(/--(.+?)--/,"<del>\\1</del>")
    output.gsub!(/\^(.+?)\s/,"<sup>\\1</sup> ")
    output.gsub!(/\[(.+?)\]\([http:\/\/]*(.+)\)/, "<a href=http://\\2>\\1</a>")
    output
  end

  def display_eastern time
    time = time.in_time_zone(LOCAL_TIME_ZONE)
    time.strftime("%B %d, %Y at %I:%M %p %Z")
  end

  def display_errors object
    if object.errors.any?
      list_items = object.errors.full_messages.map { |a| content_tag("li", a) }
      p list_items
      content_tag("div", class: "errors") do
        "The following errors prevented this record from being saved:".html_safe +
        content_tag("ul", list_items.join("").html_safe)
      end
    end
  end

  def display_short_eastern time
    time = time.in_time_zone(LOCAL_TIME_ZONE)
    time.strftime("%Y-%m-%d at %I:%M %p")
  end

  def long_section_outcome_rating rating
    case rating
      when "H", "H*"
        "High Performance"
      when "P", "P*"
        "Proficient"
      when "N", "N*"
        "Not Yet Proficient"
      else
        "Unrated"
    end
  end

  def sor_color_class rating
    case rating
    when "H", "H*"
      "blue"
    when "P", "P*"
      "green"
    when "N", "N*"
      "red"
    else
      "unrated"
    end
  end

  def sor_color_class_text rating
    case rating
    when "H", "H*"
      "text-blue-lg"
    when "P", "P*"
      "text-green-lg"
    when "N", "N*"
      "text-red-lg"
    else
      "text-unrated-lg"
    end
  end

  def evidence_icon_html rating
    case rating
    when 'B'
      "<i class='fa fa-asterisk text-blue2'></i>"
    when 'G'
      "<i class='fa fa-circle text-green2'></i>"
    when 'Y'
      "<i class='fa fa-adjust text-yellow2'></i>"
    when 'R'
      "<i class='fa fa-circle-o text-red2'></i>"
    when 'M'
      "<i class='fa fa-ban text-missing2'></i>"
    when 'U'
      "<i class='fa fa-circle text-unrated2'></i>"
    else
      "<i class='fa text-empty2'></i>"
    end
  end


  def set_temporary_password user, two_lines=true
    out_str = ''
    if user.temporary_password.present?
      out_str += "<span class='temp-pwd height-30'>#{user.temporary_password}</span>"
      if two_lines
        out_str += "<br>"
      else
        out_str += "&nbsp;"
      end
    end
    out_str += "<span class='reset-pwd height-30'>#{link_to 'Reset Password', set_temporary_password_user_path(user), remote: true, class: 'btn btn-xs btn-primary pointer-cursor'}</span>"
    return out_str.html_safe
  end

  def to_excel_column integer
    alphabet = [""] + "A".upto("Z").map { |a| a }
    return_value = alphabet[integer / 26] + alphabet[integer % 26]
    return_value
  end

  def yes_no boolean
    return "Yes" if boolean == true
    "No"
  end

  def help_gen_breadcrumbs
    breadcrumbs(style: :bootstrap, pretext: 'You are here: ', class: 'breadcrumb breadcrumb-top', display_single_fragment: true, link_current: false)
  end

  def user_dashboard_path(user)
    if user.system_administrator?
      return system_administrator_path(user.id)
    elsif user.researcher?
      return researcher_path(user.id)
    elsif user.school_administrator?
      return school_administrator_path(user.id)
    elsif user.teacher?
      return teacher_path(user.id)
    elsif user.counselor?
      return counselor_path(user.id)
    elsif user.student?
      return student_path(user.id)
    elsif user.parent?
      return parent_path(user.id)
    else
      Rails.logger.error("ERROR: unknown user role for user.id = #{user.id}")
      return user_path(user.id)
    end
  end

  def append_with_comma(base_string, appending_string)
    result = (base_string.present? ? "#{base_string}, #{appending_string}" : "#{appending_string}")
  end

end
