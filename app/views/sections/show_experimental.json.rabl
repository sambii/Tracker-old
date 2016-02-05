object @section
attributes :id, :line_number, :name, :selected_marking_period, :message, :teacher_names
node(:students) {
  @students.map { |student|
    [student.id, student.last_name, student.first_name]
  }
}
node(:data) {
  @section.section_outcomes.each_with_index.map { |section_outcome, i|
    [
      section_outcome.id,
      section_outcome.name,
      @nested_ratings[i][0],
      section_outcome.evidence_section_outcomes.each_with_index.map { |evidence_section_outcome, j|
        [
          evidence_section_outcome.id,
          evidence_section_outcome.name,
          evidence_section_outcome.evidence_id,
          evidence_section_outcome.evidence.description,
          @nested_ratings[i][1][j]
        ]
      }
    ]
  }
}