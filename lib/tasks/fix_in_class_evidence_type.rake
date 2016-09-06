# fix_in_class_evidence_type.rake
# one time fix to safely remove the In-Class evidence type.
# all evidences using In-Class evidence type will be replace with the In Class evidence type.
# then the In-Class evidence type will be removed

namespace :fix_in_class_evidence_type do
  desc "one time fix to safely remove the In-Class evidence type."

  task fix: :environment do

    # get the 'In-Class Evidence Type'
    et_dashes = EvidenceType.where(name: 'In-Class')
    if et_dashes.count > 1
      fatal "SYSTEM ERROR - duplicate 'In-Class' evidence types."
    elsif et_dashes.count == 0
      puts "No In-Class Evidence Type exists.  Nothing to do."
    else
      et_dash = et_dashes.first

      # get the 'In Class' evidence type record
      et_spaces = EvidenceType.where(name: 'In Class')
      if et_spaces.count > 1
        fatal "SYSTEM ERROR - duplicate 'In Class' evidence types."
      elsif et_spaces.count == 0
        # create 'In Class' evidence type
        et_space = EvidenceType.new
        et_space.name = ''
        et_space.save
        fatal("Fatal Creating missing 'In Class' Evidence Type") if et_space.errors.count > 0
      else
        et_space = et_spaces.first
      end

      # replace all evidences using the 'In-Class' Evidence Type with 'In Class' Evidence Type
      evids = Evidence.where(evidence_type_id: et_dash.id)
      evids.each do |e|
        e.evidence_type_id = et_space.id
        e.save
      end

      # remove the 'In-Class' Evidence Type
      if et_dash.delete
        puts "Successfully removed 'In Class' evidence Type"
      else
        puts "ERROR deleting 'In-Class' Evidence type: #{et_dash.errors.full_messages}"
      end

    end # et_dashes count == 1

    puts "Done"

  end # fix

end # fix_in_task_evidence_type
