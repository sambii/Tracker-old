set :stage, :production_mc2
server 'parloproject.org', roles: %w{web app db}
set :rvm_ruby_version, '1.9.3-p550'
set :deploy_to, '/web/parlo-tracker/mc2'
set :rails_env, 'production'