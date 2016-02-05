object @student
attributes :id, :first_name, :last_name, :grade_level, :xid, :street_address, :city, :state, :zip_code
node (:sections) do
  @student.enrollments.map { |a| {
    id: a.section_id,
    enrollment_id: a.id,
    name: a.section.name,
    teacher_names: a.section.teacher_names,
    ratings: @section_outcome_rating_counts[a.section_id]
    }
  }
end
node (:current_sections) do
  @student.enrollments.current.map { |a| {
    id: a.section_id,
    enrollment_id: a.id,
    name: a.section.name,
    teacher_names: a.section.teacher_names,
    ratings: @section_outcome_rating_counts[a.section_id]
    }
  }
end
node (:old_sections) do
  @student.enrollments.old.map { |a| {
    id: a.section_id,
    enrollment_id: a.id,
    name: a.section.name,
    teacher_names: a.section.teacher_names,
    ratings: @section_outcome_rating_counts[a.section_id]
    }
  }
end