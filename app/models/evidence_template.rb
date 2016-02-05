# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceTemplate < ActiveRecord::Base
  attr_accessible :description, :name, :subject_id
end
