require 'yaml'

crushserver_config_file = File.join(ENV['HOME'], '.crushserver.yml')
if File.exist?(crushserver_config_file)
  @crushserver_config = YAML.load_file(crushserver_config_file)
  require 'hipchat/capistrano'
end

Capistrano::Configuration.instance(:must_exist).load do
  if @crushserver_config
    set :hipchat_token, @crushserver_config['hipchat']['token']
    set :hipchat_room_name, @crushserver_config['hipchat']['room_name']
    set :hipchat_announce, @crushserver_config['hipchat']['announce']
  end

  namespace(:db) do
    desc "Execute db:seed rake task in appropriate environment"
    task :seed, :roles => :app, :only => { :primary => true } do
      run "cd #{current_path}; rake RAILS_ENV=#{rails_env} db:seed"
    end

    desc "Execute db:seed_fu rake task in appropriate environment"
    task :seed_fu, :roles => :app, :only => { :primary => true } do
      run "cd #{current_path}; rake RAILS_ENV=#{rails_env} db:seed_fu"
    end
  end

  namespace(:asset) do
    namespace(:packager) do
      desc "Execute asset:packager:build_all rake task in appropriate environment"
      task :build_all, :roles => :app do
        run "cd #{latest_release}; rake RAILS_ENV=#{rails_env} asset:packager:build_all"
      end

      desc "Execute asset:packager:delete_all rake task in appropriate environment"
      task :delete_all, :roles => :app do
        run "cd #{latest_release}; rake RAILS_ENV=#{rails_env} asset:packager:delete_all"
      end
    end
  end
end