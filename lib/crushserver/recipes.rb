require 'tinder'
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

  namespace :campfire do
    desc "Send a message to the campfire chat room"
    task :snitch do
      if ENV['CAMPFIRE_SUBDOMAIN'].blank? || ENV['CAMPFIRE_TOKEN'].blank? || ENV['CAMPFIRE_ROOM'].blank?
        puts "Campfire notifications are not configured in your environment. The CAMPFIRE_SUBDOMAIN, CAMPFIRE_TOKEN and CAMPFIRE_ROOM environment variables must be set."
      else
        campfire = Tinder::Campfire.new ENV['CAMPFIRE_SUBDOMAIN'], :ssl => true, :token => ENV['CAMPFIRE_TOKEN']
        room = campfire.find_room_by_name ENV['CAMPFIRE_ROOM']
        snitch_message = fetch(:snitch_message) { ENV['MESSAGE'] || abort('Capfire snitch message is missing. Use set :snitch_message, "Your message"') }
        room.paste(snitch_message)
      end
    end

    desc "Send a message to the campfire chat room about the deploy start"
    task :snitch_start do
      message = "#{ENV['USER'].upcase} is deploying #{application.upcase} to #{stage.to_s.upcase}.  Please stand by..."
      set :snitch_message, message
      snitch
    end

    desc "Send a message to the campfire chat room about the deploy end"
    task :snitch_end do
      revisions
      message = <<HERE
#{application.upcase} was deployed to #{stage.to_s.upcase} by #{ENV['USER'].upcase} (#{branch}/#{real_revision[0, 7]})

#{revisions_result}
HERE
      set :snitch_message, message
      snitch
    end
  end

  desc "Show currently deployed revision on server."
  task :revisions, :roles => :app do
    result = String.new
    begin
      current, previous, latest = current_revision[0,7], previous_revision[0,7], real_revision[0,7]
      result << "===== Master Revision: #{latest}\n\n"
      result << "===== [ #{application} - #{stage} ]\n"
      result << "=== Deployed Revision: #{current}\n"
      result << "=== Previous Revision: #{previous}\n"

      # If deployed and master are the same, show the difference between the last 2 deployments.
      base_label, new_label, base_rev, new_rev = latest != current ? \
           ["deployed", "master", current, latest] : \
           ["previous", "deployed", previous, current]

      # Show difference between master and deployed revisions.
      if (diff = `git log #{base_rev}..#{new_rev} --oneline`) != ""
        # Colorize refs
        diff = "    " << diff.gsub("\n", "\n    ") << "\n"
        # Indent commit messages nicely, max 80 chars per line, line has to end with space.
        diff = diff.split("\n").map{|l|l.scan(/.{1,120}/).join("\n"<<" "*14).gsub(/([^ ]*)\n {14}/m,"\n"<<" "*14<<"\\1")}.join("\n")
        result << "=== Difference between #{base_label} revision and #{new_label} revision:\n\n"
        result << diff
      end
    rescue
      result << "=== Revisions Task Failed!"
    end
    set :revisions_result, result
  end

  #############################################################
  # Hooks
  #############################################################

  before :deploy do
    campfire.snitch_start unless ENV['QUIET'].to_i > 0
  end

  after :deploy do
    campfire.snitch_end unless ENV['QUIET'].to_i > 0
  end
end