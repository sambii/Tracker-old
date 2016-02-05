# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
# misc.rb
# dummy model with no database connection for Misc pages (and authorization)
class Misc
  def persisted?
    false
  end
end
