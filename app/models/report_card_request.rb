# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ReportCardRequest
	include ActiveModel::Validations
	include ActiveModel::Conversion
	include ActiveModel::MassAssignmentSecurity
	extend  ActiveModel::Naming

attr_accessor :grade_level
attr_accessible

validates_inclusion_of :grade_level,
					   :in => 1..12,
					   :message => 'Grade level must be between 1 and 12'

	#allow the model attributes to be set
	def initialize( attributes = {} )
		attributes.each do |name,value|
			send("#{name}=", value)
		end
	end

    # not stored in the db
	def persisted?
		false
	end
end
