
# replace the body of the modal dialog box with the haml we want rendered
$("#user_" + <%= @student.id %>).html("<%= escape_javascript(render(partial: 'students/temporary_password', locals: {user: @student}) ) %>");
