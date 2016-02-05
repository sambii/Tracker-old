object @teacher
attributes :id
child :sections do
  attributes :id, :subject_id, :line_number, :full_name, :school_year_id
end