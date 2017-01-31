# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ServerConfig < ActiveRecord::Base

  validates :support_email, presence: true, on: :update # use default on create
  validates :support_team, presence: true, on: :update # use default on create
  validates :school_support_team, presence: true, on: :update # use default on create
  validates :server_name, presence: true, on: :update # use default on create
  validates :web_server_name, presence: true, on: :update # use default on create

end
