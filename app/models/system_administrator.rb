# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SystemAdministrator < User
  default_scope where(system_administrator: true)

end
