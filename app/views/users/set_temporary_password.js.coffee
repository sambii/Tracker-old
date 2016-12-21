
# replace the body of the modal dialog box with the haml we want rendered
$("#user_" + <%= @user.id %> + "_password").html("<%= escape_javascript(render(partial: 'users/temporary_password', locals: {user: @user}) ) %>");
