require 'tinder'

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

namespace :campfire do
  desc "Send a message to the campfire chat room"
  task :snitch do
    if ENV['CAMPFIRE_SUBDOMAIN'].blank? || ENV['CAMPFIRE_TOKEN'].blank? || ENV['CAMPFIRE_ROOM'].blank?
      puts "Campfire notifications are not configured in your environment. The CAMPFIRE_SUBDOMAIN, CAMPFIRE_TOKEN and CAMPFIRE_ROOM environment variables must be set."
    else
      campfire = Tinder::Campfire.new ENV['CAMPFIRE_SUBDOMAIN'], :ssl => true, :token => ENV['CAMPFIRE_TOKEN']
      room = campfire.find_room_by_name ENV['CAMPFIRE_ROOM']
      snitch_message = fetch(:snitch_message) { ENV['MESSAGE'] || abort('Capfire snitch message is missing. Use set :snitch_message, "Your message"') }
      room.speak(snitch_message)
    end
  end

  # desc "Send a message to the campfire chat room about the deploy start"
  # task :snitch_begin do
  #   set :snitch_message, "BEGIN DEPLOY [#{stage.to_s.upcase}]: #{ENV['USER']}, #{branch}/#{real_revision[0, 7]} to #{deploy_to}"
  #   snitch
  # end

  desc "Send a message to the campfire chat room about the deploy end"
  task :snitch_end do
    # set :snitch_message, "END DEPLOY [#{stage.to_s.upcase}]: #{ENV['USER']}, #{branch}/#{real_revision[0, 7]} to #{deploy_to}"
    set :snitch_message, "#{application.upcase} was deployed to #{stage.to_s.upcase} by #{ENV['USER'].upcase} (#{branch}/#{real_revision[0, 7]})"
    snitch
  end

  # desc "Send a message to the campfire chat roob about the rollback"
  # task :snitch_rollback do
  #   set :snitch_message, "ROLLBACK [#{stage.to_s.upcase}]: #{ENV['USER']}, #{latest_revision[0, 7]} to #{previous_revision[0, 7]} on #{deploy_to}"
  #   snitch
  # end
end

#############################################################
# Hooks
#############################################################

# before :deploy do
#   campfire.snitch_begin unless ENV['QUIET'].to_i > 0
# end

after :deploy do
  campfire.snitch_end unless ENV['QUIET'].to_i > 0
end

# before 'deploy:rollback', 'campfire:snitch_rollback'
