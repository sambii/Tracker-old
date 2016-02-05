set :application, 'parlo_tracker'
set :repo_url, 'git@github.com:21pstem/tracker.git'

#ask :branch , proc { `git rev-parse --abbrev-ref HEAD`.chomp }
ask :branch, proc { `git tag`.split("\n").last }
set :scm, :git

#set username for all servers
set :ssh_options, { user: 'deploy' }

set :format, :pretty
set :log_level, :debug
set :pty, true

set :linked_files, %w{config/database.yml config/newrelic.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets public/system}

# set :default_env, { rvm_bin_path: '~/.rvm/bin' }
# set :default_env, { rvm_bin_path: '/usr/local/rvm/bin:$PATH' }
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :bundle_dir, "/usr/local/rvm/gems/ruby-1.9.3-p550" # moved to individual deploy file

set :keep_releases, 10
set :keep_db_backups, 10

#rvm
set :rvm_type, :user

namespace :deploy do
  # 21pstem custom hooks into the deploy lifecycle
  before :starting, 'check_write_permissions'
  before :updating, 'db:backup'
  before :publishing, 'delayed_job:stop'
  after  :published, 'delayed_job:start'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  #after :restart, :clear_cache do
    #on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    #end
  #end

  after :finishing, 'deploy:cleanup'

end
