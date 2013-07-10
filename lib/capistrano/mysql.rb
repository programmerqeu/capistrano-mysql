unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

################################################################################
## Backup
###############################################################################

require "capistrano/mysql/version"
require 'capistrano/recipes/deploy/scm'
require 'capistrano/recipes/deploy/strategy'
require "fileutils"
require 'yaml'

# PHP binary to execute
set :deploy_env,           "staging"

namespace :mysql do

	desc "Dev Task"

	task :dev, :roles => :db, :only => { :primary => true } do
		databaseCrendentials = YAML::load(IO.read('config/database.yml'))
		puts databaseCrendentials[fetch(:deploy_env, "staging")]['database']
		#ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
	end

	desc "creating a database backup of the current environment"
	task :backup, :roles => :db, :only => { :primary => true } do
		file = "#{application_root}#{backup_dir}sql/#{stage_current}_dump.sql"
		set :file, file
		#		if stage_current == 'staging'
		#			transaction do
		#				puts "Check if backup directory exists: "
		#				run "mkdir -p #{application_root}#{backup_dir}sql/", :once => true
		#				puts "Create a backup of the existing dumps: "
		#				run "if [[ -d #{file} ]]; then cp -b #{file} #{file}.backup; fi"
		#				puts "Create  a database backup for \"#{stage_current}\" enviroment:"
		#				run "mysqldump -u #{database_username} -h #{database_host} --add-drop-table --password=#{database_password} #{database_dbname} --default-character-set='utf8'  >  #{file};"
		#				run "chmod 650  #{file};"
		#				puts "\nDie Datei ist zu finden unter \e[1;46m\"#{file}\" \e[0m.\n"
		#			end
		#		elsif stage_current == 'development'
		#			transaction do
		#				puts 'Prüfen ob Backup-Verzeichnis vorhanden ist:'
		#				run_locally "mkdir -p #{application_root}#{backup_dir}sql/"
		#				puts "Sicherung des vorhanden Dumps erstellen:"
		#				run_locally "if [[ -d #{file} ]]; then cp -b #{file} #{file}.backup; fi"
		#				puts "Datenbank-Dump für \"#{stage_current}\" erstellen:"
		#				run_locally "mysqldump -u #{database_username} -h #{database_host} --add-drop-table --password=#{database_password} #{database_dbname} --default-character-set='utf8'  >  #{file};"
		#				puts "\nDie Datei ist zu finden unter \e[1;46m\"#{file}\" \e[0m.\n"
		#			end
		#		end
	end


	desc "Pull a database backup of the current environment to local"
	task :pull, :roles => :db, :only => { :primary => true } do
	end

	desc "Pull a database backup of the one environment to onother"
	task :pullto, :roles => :db, :only => { :primary => true } do
	end

	desc "Push a local database backup to the current environment"
	task :push, :roles => :db, :only => { :primary => true } do
	end

	desc "Move a database backup of the one environment to another"
	task :move, :roles => :db, :only => { :primary => true } do

		env       = fetch(:deploy_env, "remote")
		filename  = "#{application}.#{env}_dump.latest.sql.gz"
		config    = load_database_config IO.read("#{app_config_path}/#{app_config_file}"), symfony_env_local
		sqlfile   = "#{application}_dump.sql"

		database.dump.remote

		f = File.new("backups/#{sqlfile}", "a+")
		gz = Zlib::GzipReader.new(File.open("backups/#{filename}", "r"))
		f << gz.read
		f.close

		case config['database_driver']
		when "pdo_mysql", "mysql"
			`mysql -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} < backups/#{sqlfile}`
		when "pdo_pgsql", "pgsql"
			`PGPASSWORD=\"#{config['database_password']}\" psql -U #{config['database_user']} #{config['database_name']} < backups/#{sqlfile}`
		end
		FileUtils.rm("backups/#{sqlfile}")
	end

	desc "Dumps local database, loads it to remote, and populates there"
	task :to_remote, :roles => :db, :only => { :primary => true } do
		filename  = "#{application}.local_dump.latest.sql.gz"
		file      = "backups/#{filename}"
		sqlfile   = "#{application}_dump.sql"
		config    = ""

		database.dump.local

		upload(file, "#{remote_tmp_dir}/#{filename}", :via => :scp)
		run "#{try_sudo} gunzip -c #{remote_tmp_dir}/#{filename} > #{remote_tmp_dir}/#{sqlfile}"

		data = capture("#{try_sudo} cat #{current_path}/#{app_config_path}/#{app_config_file}")
		config = load_database_config data, symfony_env_prod

		case config['database_driver']
		when "pdo_mysql", "mysql"
			data = capture("#{try_sudo} mysql -u#{config['database_user']} --host='#{config['database_host']}' --password='#{config['database_password']}' #{config['database_name']} < #{remote_tmp_dir}/#{sqlfile}")
			puts data
		when "pdo_pgsql", "pgsql"
			data = capture("#{try_sudo} PGPASSWORD=\"#{config['database_password']}\" psql -U #{config['database_user']} #{config['database_name']} < #{remote_tmp_dir}/#{sqlfile}")
			puts data
		end

		run "#{try_sudo} rm -f #{remote_tmp_dir}/#{filename}"
		run "#{try_sudo} rm -f #{remote_tmp_dir}/#{sqlfile}"

	end
end