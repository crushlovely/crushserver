Capistrano::Configuration.instance(:must_exist).load do

  namespace(:db) do
    desc "Execute db:populate rake task in appropriate environment"
    task :populate do
      run "cd #{current_path}; rake RAILS_ENV=#{rails_env} db:populate"
    end

    desc "Execute db:seed rake task in appropriate environment"
    task :seed do
      run "cd #{current_path}; rake RAILS_ENV=#{rails_env} db:seed"
    end
  end

  namespace(:bdg) do
    namespace(:localize) do
      # This should be overridden in deploy.rb
      set :config_files, []

      desc "copy shared configurations to current"
      task :copy_shared_configurations do
        config_files.each do |f|
          run "ln -nsf #{shared_path}/config/#{f} #{current_path}/config/#{f}"
        end
      end
    end
  

    desc "create database.yml"
    task :create_database_yml do
      # Gather some info
      set :db_pass, Capistrano::CLI.password_prompt("Database Password: ")

      # Set defaults
      set :db_user, "deploy"
      set :db_host, "localhost"
      set :db_adapter, "mysql"
      database_configuration =<<-EOF
#{rails_env}:
  adapter: #{db_adapter}
  host: #{db_host}
  username: #{db_user}
  password: #{db_pass}
  database: #{application}_#{rails_env}
EOF

      run "mkdir -p #{shared_path}/config"
      put database_configuration, "#{shared_path}/config/database.yml"
    end

    desc "Clean database sessions older than 12 hours"
    task :clean_sessions do
      sudo "cd #{current_path}; RAILS_ENV=#{rails_env} script/runner 'ActiveRecord::Base.connection.delete(\"DELETE FROM sessions WHERE updated_at < now() - 12*3600\")'"
    end

    desc "Copy apache conf file to proper location on server"
    task :copy_apache_conf_file do
      sudo "cp #{current_path}/config/apache/#{stage}.conf /etc/httpd/conf/apps/#{application}.conf"
    end

    desc "Stream log from rails"
    task :log, :roles => :app do
      stream "tail -f #{current_path}/log/#{rails_env}.log"
    end

    desc "Stream access log"
    task :access_log, :roles => :app do
      sudo_stream "tail -f /etc/httpd/logs/#{domain}-access_log"
    end

    desc "Stream error log"
    task :error_log, :roles => :app do
      sudo_stream "tail -f /etc/httpd/logs/#{domain}-error_log"
    end

    desc "Stream rewrite log"
    task :rewrite_log, :roles => :app do
      sudo_stream "tail -f /etc/httpd/logs/#{domain}-rewrite_log"
    end

    desc "Show output of top"
    task :server_top do
      sudo_stream "top -b -n1"
      #sudo "top -b -n1"
    end

    desc "Remove log, tmp, and database.yml files from repository."
    task :prep_svn  do
      remove_log_from_svn
      remove_tmp_from_svn
      remove_database_yml_from_svn
    end

    desc "Remove log from svn."
    task :remove_log_from_svn do
      puts "removing log directory contents from svn"
      system "svn remove log/*"
      puts "ignoring log directory"
      system "svn propset svn:ignore '*.log' log/"
      system "svn update log/"
      puts "committing changes"
      system "svn commit -m 'Removed and ignored log files'"
    end

    desc "Remove tmp from svn."
    task :remove_tmp_from_svn do
      puts "removing tmp directory from svn"
      system "svn remove tmp/*"
      puts "ignoring tmp directory"
      system "svn propset svn:ignore '*' tmp/"
      system "svn update tmp/"
      puts "committing changes"
      system "svn commit -m 'Removed contents of and ignored tmp'"
    end

    desc "Remove database.yml from svn."
    task :remove_database_yml_from_svn do
      puts "removing database.yml from svn"
      system "svn remove config/database.yml"
      puts "ignoring database.yml"
      system "svn propset svn:ignore 'database.yml' config/"
      system "svn update config/"
      puts "committing changes"
      system "svn commit -m 'Removed and ignored database.yml'"
    end

    desc "Create a local database.yml file (for use after it's been ignored by svn)"
    task :create_local_database_yml do
      database_yml_path = 'config/database.yml'
      question = "This task will over-write #{database_yml_path} if it exists.  Are you sure you wish to continue? (y/n) "
      if Capistrano::CLI.ui.ask(question) == 'y'
        puts
        puts "First we need some configuration info..."
        puts
        set :db_user, Capistrano::CLI.ui.ask("Database User: ")
        set :db_password, Capistrano::CLI.password_prompt("Database Password: ")
        set :db_host, "localhost"
        set :db_adapter, "mysql"
        database_configuration =<<-EOF
local: &local
  adapter: mysql
  host: localhost
  username: #{db_user}
  password: #{db_password}

development:
  database: #{application}_development
  <<: *local

test:
  database: #{application}_test
  <<: *local
EOF
        system "touch #{database_yml_path} && > #{database_yml_path}"
        system "echo \"#{database_configuration}\" >> #{database_yml_path}"
        puts
        puts "Success! #{database_yml_path} has been created!"
      else
        puts "Goodbye."
      end
    end
  end
end

# So we're... 99% sure that these no longer apply.
class Capistrano::Configuration

  ##
  # Run a command as root and stream it back

  def sudo_stream(command)
    sudo(command) do |channel, stream, out|
      puts out if stream == :out
      if stream == :err
        puts "[err : #{channel[:host]}] #{out}"
        break
      end
    end
  end

  # Run a task and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression.
  #
  # Can be used where +run+ would otherwise be used.
  #
  #  run_with_input 'ssh-keygen ...'
  def run_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:run, shell_command, input_query)
  end

  # Run a task as root and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression
  def sudo_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:sudo, shell_command, input_query)
  end

  private

  # Do the actual capturing of the input and streaming of the output.
  def handle_command_with_input(local_run_method, shell_command, input_query)
    send(local_run_method, shell_command) do |channel, stream, data|
      logger.info data, channel[:host]
      if data =~ input_query
        pass = Capistrano::CLI.password_prompt "#{data}:"
        channel.send_data "#{pass}\n"
      end
    end
  end

end
