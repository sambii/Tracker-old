set :stage, :production_egypt
server 'tracker.stemmaster.moe.edu.eg', roles: %w{web app db}
set :rvm_ruby_version, '1.9.3-p550'
set :deploy_to, '/web/parlo-tracker/stem-egypt'
set :rails_env, 'production'
set :bundle_dir, "~/.rvm/bin/gems/ruby-1.9.3-p550"
