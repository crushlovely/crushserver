require 'yaml'
require 'hipchat'

Capistrano::Configuration.instance(:must_exist).load do
  set :crushserver_config_file, File.join(ENV['HOME'], '.crushserver.yml')
  set :crushserver_config_exists?, File.exist?(crushserver_config_file)
  set :crushserver_config, (crushserver_config_exists? ? YAML.load_file(crushserver_config_file) : nil)

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

  set :hipchat_config_exists?, (crushserver_config && crushserver_config['hipchat'] && crushserver_config['hipchat']['token'] && crushserver_config['hipchat']['room_name'])
  set :notify_via_hipchat, true

  if hipchat_config_exists? && notify_via_hipchat
    namespace :hipchat do
      set :hipchat_token, crushserver_config['hipchat']['token']
      set :hipchat_room_name, crushserver_config['hipchat']['room_name']
      set :hipchat_announce, crushserver_config['hipchat']['announce']
      set :hipchat_client, HipChat::Client.new(hipchat_token)

      def deployed_revision
        @deployed_revision ||= real_revision[0,7]
      end

      # Convert our Git URL to an HTTP one. This isn't very elegant, but will do for now.
      def revision_url
        if @revision_url
          @revision_url
        else
          base_url = repository.gsub('git@', 'http://').gsub(':', '/').gsub('.git', '')
          @revision_url = [base_url, 'commit', deployed_revision].join('/')
          logger.important "Revision URL is: #{@revision_url}"
          @revision_url
        end
      end

      def link_to_commit
        %{<a href="#{revision_url}">#{branch}/#{deployed_revision}</a>}
      end

      def deployer
        ENV['HIPCHAT_USER'] ||
          fetch(:hipchat_human,
                if (u = %x{git config user.name}.strip) != ""
                  u
                elsif (u = ENV['USER']) != ""
                  u
                else
                  "Someone"
                end)
      end

      def deploy_user
        fetch(:hipchat_deploy_user, "CrushBot")
      end

      task :deploy_started_message do
        "#{deployer} is deploying #{application} to #{stage}. (#{link_to_commit})"
      end

      task :deploy_canceled_message do
        "#{deployer} cancelled deployment of #{application} to #{stage}. (#{link_to_commit})"
      end

      task :deploy_finished_message do
        "#{deployer} finished deploying #{application} to #{stage}. (#{link_to_commit})"
      end

      task :notify_deploy_started do
        on_rollback do
          hipchat_client[hipchat_room_name].
            send(deploy_user, deploy_canceled_message, hipchat_announce)
        end

        hipchat_client[hipchat_room_name].
          send(deploy_user, deploy_started_message, hipchat_announce)
      end

      task :notify_deploy_finished do
        hipchat_client[hipchat_room_name].
          send(deploy_user, deploy_finished_message, hipchat_announce)
      end
    end

    before "deploy", "hipchat:notify_deploy_started"
    after  "deploy", "hipchat:notify_deploy_finished"
  end
end
