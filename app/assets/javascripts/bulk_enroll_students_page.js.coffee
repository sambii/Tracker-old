#
# * Custom JS Code for Bulk Enroll Students Page
$ ->
  if $('#page-content.bulk_enroll_students').length == 0
    return
  else
    # we are on the Bulk Enroll Students page, do the following

    #----------------------------------------------------------------------
    # Setup - Variables
    #----------------------------------------------------------------------

    err_element = $('#breadcrumb-flash-msgs')

    #----------------------------------------------------------------------
    # Setup - Calculated Variables
    #----------------------------------------------------------------------


    ###################################
    # ADD EVENT HANDLERS


    # auto submit form on change if OK
    changeSubjectSelect = (that, ev) ->
      console.log 'changeSubjectSelect'
      getSectionsForSubject(that, ev)


    # get the sections for the new subject after changing subject
    getSectionsForSubject = (that, ev) ->
      console.log 'getSectionsForSubject'
      subject_id = $(that).val()
      console.log "subject_id: #{subject_id}"
      school_year_id = $(that).attr('data-school-year-id')
      console.log "school_year_id: #{school_year_id}"
      xhr = $.ajax
        url:  "/sections"
        type: 'get'
        data:
          subject_id: subject_id,
          school_year_id: school_year_id
        dataType: 'json'
        success: (resp, status, xhr) ->
          console.log "done: status: #{status}"
          $('#subject-section-select').select2('val', '')
          $('#subject-section-select')
            .find('option')
            .remove()
            .end()
            .append("<option value=''>Select Section:</option>")
          for sect, i in resp
            $('#subject-section-select').append("<option value='#{sect.id}'>#{sect.name}</option>")
        error: (xhr, status, err) ->
          console.log "fail: status: #{status}"


    # auto submit form on change if OK
    changeSectionSelect = (that, ev) ->
      console.log 'changeSectionSelect'
      num_changes = parseInt($('#num_changes').val(), 10)
      console.log "num_changes: #{num_changes}"
      if num_changes == 0
        $(that).parents('form').submit()
      else
        if okCancelOnClick(that, ev)
          ev.preventDefault()
          $(that).parents('form').submit()
        else
          cur_section_id = $('#cur_section_id').val()
          console.log "cur_section_id: #{cur_section_id}"
          $('#subject-section-select').val(cur_section_id)


    # auto submit form on change
    okCancelOnClick = (that, ev) ->
      console.log 'okCancelOnClick'
      isok = confirm('Click OK to NOT UPDATE this section')
      if isok != true
        console.log "should be cancelled"
        return false
      else
        return true

    # increment the num-changes value on the page
    increment_num_changes = () ->
      num_changes = parseInt($('#num_changes').val(), 10)+1
      $('#num_changes').val((num_changes).toString())
      console.log "updated num_changes: #{num_changes}"


    # clear the students to be assigned
    clearStudentAssignments = (that, ev) ->
      console.log 'clearStudentAssignments'
      $('.unassign-student-btn').prop('checked', false)
      $('#students-to-assign tr').remove()
      $('#current-assignments tr.selected').removeClass('selected')
      $('#current-assignments .assignment-kept').remove()


    # add student into students to be assigned section or clear unassign checkbox
    assignStudent = (that, event) ->
      console.log 'called assignStudent'
      # get student information from node
      student_tr_node = $(that).parents('tr')
      student_xid = student_tr_node.find('.user-xid').text()
      student_fname = student_tr_node.find('.user-first-name').text()
      student_lname = student_tr_node.find('.user-last-name').text()
      student_id = student_tr_node.data('st-id')
      student_grade = student_tr_node.find('.user-grade-level').text()
      # see if student is in the current assignments table
      console.log "[data-st-id=#{student_id}]"
      matched_current = $("#current-assignments tr[data-st-id=#{student_id}]")
      console.log "matched_current: #{matched_current.length}"
      if matched_current.length > 0
        # uncheck the student in current assignments list
        matched_current.find('input').prop('checked', false)
      else
        # clone a blank student to assign node
        attach_elem = $('#clone-students-to-assign tr').clone()
        # put the student information into the assign node
        attach_elem.data('st-id', student_id)
        attach_elem.find('.user-xid').append(student_xid)
        attach_elem.find('.user-first-name').append(student_fname)
        attach_elem.find('.user-last-name').append(student_lname)
        attach_elem.data('st-id', student_id)
        input_student_id = attach_elem.find('.unassign-student-id')
        input_student_id.attr('name', "enrollments_attributes[student_id][#{student_id}][action]")
        input_student_id.attr('value', "create")
        input_student_grade = attach_elem.find('.unassign-student-grade')
        input_student_grade.attr('name', "enrollments_attributes[student_id][#{student_id}][grade]")
        input_student_grade.attr('value', "#{student_grade}")
        # attach new student to assign node to list on page
        attach_elem.appendTo('#students-to-assign')
        # bind the unassign event to the newly created unassign icon
        attach_elem.find('.unassign-student-btn').on 'click', (event, state) ->
          unassignStudent(this, event)
      # hide the assign icon for the student
      increment_num_changes()
      student_tr_node.find('.assign-student-btn').hide()



    # remove student from the students to be assigned section
    unassignStudent = (that, event) ->
      console.log 'called unassignStudent'
      console.log "tagName: #{$(that).prop('tagName')}"
      student_a_tr_node = $(that).parents('tr')
      student_id = student_a_tr_node.data('st-id')
      console.log "st-id: #{student_a_tr_node.data('st-id')}"
      # hide or uncheck the removed student
      if $(that).prop('tagName') == 'A'
        # remove the student from the students to be assigned listing
        student_a_tr_node.remove()
        # show the assign symbol in the listing of all students
        $("#all-students [data-st-id = '#{student_id}'] .assign-student-btn").show()
      else if $(that).prop('tagName') == 'INPUT'
        console.log "checked: #{$(that).prop('checked')}"
        # toggle the assignment status when clicking the checkbox
        # note value has already toggled from the click before this event was called
        if $(that).prop('checked')
          # show the assign symbol in the listing of all students
          console.log "show [data-st-id = '#{student_id}']"
          $("#all-students [data-st-id = '#{student_id}'] .assign-student-btn").show()
        else
          # show the assign symbol in the listing of all students
          console.log "hide [data-st-id = '#{student_id}']"
          $("#all-students [data-st-id = '#{student_id}'] .assign-student-btn").hide()
      else
        console.log 'Invalid node for remove student event.'
      increment_num_changes()



    ###################################
    # ADD EVENT BINDINGS

    # confirm before change then submit
    $('#subject-select').on 'change', (event, state) ->
      changeSubjectSelect(this, event)

    # confirm before change then submit
    $('#subject-section-select').on 'change', (event, state) ->
      changeSectionSelect(this, event)

    # clear the students to be assigned
    $('#clear-student-assignments').on 'click', (event, state) ->
      clearStudentAssignments(this, event)

    $('.assign-student-btn').on 'click', (event, state) ->
      assignStudent(this, event)

    $('.unassign-student-btn').on 'click', (event, state) ->
      unassignStudent(this, event)

  return



