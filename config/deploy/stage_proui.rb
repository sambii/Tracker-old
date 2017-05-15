set :stage, :stage_proui
server 'staging.parloproject.org', roles: %w{web app db}
set :rvm_ruby_version, '1.9.3-p550'
set :deploy_to, '/web/parlo-tracker/proui'
set :rails_env, 'staging'
# set :bundle_dir, "/usr/local/rvm/gems/ruby-1.9.3-p550"
set :bundle_dir, "~/.rvm/bin/gems/ruby-1.9.3-p550"
