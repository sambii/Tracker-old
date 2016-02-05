set :stage, :production_usa
server 'parloproject.org', roles: %w{web app db}
set :rvm_ruby_version, '1.9.3-p550'
set :deploy_to, '/web/parlo-tracker/usa'
set :rails_env, 'production'