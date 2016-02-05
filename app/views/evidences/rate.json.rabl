object @evidence
attributes :id, :name
node (:students) {
  @enrollments.alphabetical.map { |a|
    {
      id: a.student_id,
      first_name: a.student.first_name,
      last_name: a.student.last_name,
      ratings: @evidence_ratings[a.student_id],
      subsection: a.subsection
    }
  }
}
child (:evidence_section_outcomes) {
  attributes :id, :section_outcome_name, :section_outcome_id
}