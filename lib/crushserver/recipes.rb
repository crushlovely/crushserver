Capistrano::Configuration.instance(:must_exist).load do

  namespace :sync do
    desc "Sync both database and attachments to local machine.  Requires awesome-backup plugin."
    task :all do
      sync.db
      sync.attachments
    end

    desc "Sync database to local computer. Requires awesome-backup plugin."
    task :db do
      backup.mirror
    end

    desc "Copy attachments from server."
    task :attachments, :roles => :app, :only => { :primary => true } do
      FileUtils.mkdir_p "public/system"
      # While we could use the following command...
      # download("#{shared_path}/system", "public/system", :recursive => true)
      # let's use rsync instead so we only download what we need...
      system "rsync --delete --recursive --times --rsh=ssh --compress --human-readable --progress #{user}@#{domain}:#{shared_path}/system/ public/system/"
    end
  end

  namespace(:db) do
    desc "Execute db:populate rake task in appropriate environment"
    task :populate, :roles => :app, :only => { :primary => true } do
      run "cd #{current_path}; rake RAILS_ENV=#{rails_env} db:populate"
    end

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

  namespace(:bdg) do
    namespace(:localize) do
      # This should be overridden in deploy.rb
      set :config_files, []

      desc "copy shared configurations to new release.  this task should be called after deploy:update_code like so: after 'deploy:update_code', 'bdg:localize:copy_shared_configurations'"
      task :copy_shared_configurations, :roles => [:app] do
        config_files.each do |f|
          run "ln -nsf #{shared_path}/config/#{f} #{release_path}/config/#{f}"
        end
      end
    end

    desc "Clean database sessions older than 12 hours"
    task :clean_sessions do
      sudo "cd #{current_path}; RAILS_ENV=#{rails_env} script/runner 'ActiveRecord::Base.connection.delete(\"DELETE FROM sessions WHERE updated_at < now() - 12*3600\")'"
    end

    desc "Copy apache conf file to proper location on server"
    task :copy_apache_conf_file do
      sudo "cp #{current_path}/config/apache/#{stage}.conf /etc/httpd/conf/apps/#{application}.conf"
    end
  end
end
