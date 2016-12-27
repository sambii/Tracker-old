
# replace the body of the modal dialog box with the haml we want rendered
$("#user_" + <%= @parent.id %>).html("<%= escape_javascript(render(partial: 'parents/temporary_password', locals: {user: @parent}) ) %>");
