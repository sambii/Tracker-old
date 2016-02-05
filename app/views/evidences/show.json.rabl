object @evidence
attributes :id, :name, :assignment_date, :evidence_type_name, :reassessment, :evidence_type_id, :description, :shortened_name, :reassessment
child (:section_outcomes) {
  attributes :id, :name
}
node (:evidence_attachments) {
  @evidence.evidence_attachments.map{ |ea|
    {
      id: ea.id,
      name: ea.name,
      url: ea.attachment.url
    }
  }
}
child (:evidence_hyperlinks) {
  attributes :id, :title, :hyperlink
}
