# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceType < ActiveRecord::Base
  attr_accessible :name
  validates :name, presence: {message: I18n.translate('errors.cant_be_blank')}
end
