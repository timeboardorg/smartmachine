module SmartMachine
  class Grids
    class Mysql < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.mysql.dig(name.to_sym)
        raise "mysql config for #{name} not found." unless config

        @port = config.dig(:port)
        @root_password = config.dig(:root_password)
        @username = config.dig(:username)
        @password = config.dig(:password)
        @database_name = config.dig(:database_name)

        @name = name.to_s
        @home_dir = File.expand_path('~')
        @backups_path = "#{@home_dir}/smartmachine/grids/mysql/#{@name}/backups"
      end

      def uper
        # Creating networks
        unless system("docker network inspect #{@name}-network", [:out, :err] => File::NULL)
          puts "-----> Creating network #{@name}-network ... "
          if system("docker network create #{@name}-network", out: File::NULL)
            puts "done"
          end
        end

        FileUtils.mkdir_p("#{@home_dir}/machine/grids/mysql/#{@name}/data")
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/mysql/#{@name}/backups")

        # Creating & Starting containers
        puts "-----> Creating container #{@name} ... "
        command = [
          "docker create",
          "--name='#{@name}'",
          "--env MYSQL_ROOT_PASSWORD=#{@root_password}",
          "--env MYSQL_USER=#{@username}",
          "--env MYSQL_PASSWORD=#{@password}",
          "--env MYSQL_DATABASE=#{@database_name}",
          "--user `id -u`:`id -g`",
          "--publish='#{@port}:#{@port}'",
          "--volume='#{@home_dir}/smartmachine/grids/mysql/#{@name}/data:/var/lib/mysql'",
          "--restart='always'",
          "--network='#{@name}-network'",
          "mysql:8.0.18"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          puts "done"
          puts "-----> Starting container #{@name} ... "
          if system("docker start #{@name}", out: File::NULL)
            puts "done"
          else
            raise "Error: Could not start the created #{@name} container"
          end
        else
          raise "Error: Could not create #{@name} container"
        end
      end

      # Stopping & Removing containers - in reverse order
      def downer
        puts "-----> Stopping container #{@name} ... "
        if system("docker stop '#{@name}'", out: File::NULL)
          puts "done"
          puts "-----> Removing container #{@name} ... "
          if system("docker rm '#{@name}'", out: File::NULL)
            puts "done"
          end
        end

        # Removing networks
        puts "-----> Removing network #{@name}-network ... "
        if system("docker network rm #{@name}-network", out: File::NULL)
          puts "done"
        end
      end

      # Flushing logs
      def flushlogs(*args)
        puts "-----> Flushing logs for #{@name} ... "
        if system("docker exec #{@name} sh -c \
                    'exec mysqladmin \
                    --user=root \
                    --password=#{@root_password} \
                    flush-logs'")

          puts "done"
        else
          puts "error"
        end
      end

      # Create backup using the grids backup command
      def backup(*args)
        args.flatten!
        type = args.empty? ? '--snapshot' : args.shift

        if type == "--daily"
          run_backup(type: "daily")
        elsif type == "--promote-to-weekly"
          run_backup(type: "weekly")
        elsif type == "--snapshot"
          run_backup(type: "snapshot")
        elsif type == "--transfer"
          transfer_backups_to_external_storage
        end
      end

      private

      # Transfer all current backups to external storage
      def transfer_backups_to_external_storage
      end

      def run_backup(type:)
        FileUtils.mkdir_p("#{@backups_path}/#{type}")

        unless type == "weekly"
          standard_backup(type: type)
        else
          weekly_backup_from_latest_daily
        end
      end

      def restore(type:, version:)
        printf "Are you sure you want to do this? It will destroy/overwrite all the current databases? Type 'YES' and press enter to continue: ".red
        prompt = STDIN.gets.chomp
        return unless prompt == 'YES'

        puts "-----> Restoring the backup of all databases with version #{version} (without binlogs) in #{@name} ... "
        if system("docker exec -i #{@name} sh -c \
                    'exec xz < #{@backups_path}/#{type}/#{version}.sql.xz \
                    | mysql \
                    --user=root \
                    --password=#{@root_password}")

          puts "done"
        else
          puts "error... check data & try again"
        end
      end

      # Create a standard backup
      def standard_backup(type:)
        # Note: There should be no space between + and " in version.
        # Note: date will be UTC date until timezone has been changed.
        version = `date +"%Y%m%d%H%M%S"`.chomp!
        backup_version_file = "#{version}.sql.xz"

        puts "-----> Creating #{type} backup of all databases with backup version file #{backup_version_file} in #{@name} ... "
        if system("docker exec #{@name} sh -c \
                    'exec mysqldump \
                    --user=root \
                    --password=#{@root_password} \
                    --all-databases \
                    --single-transaction \
                    --flush-logs \
                    --master-data=2 \
                    --events \
                    --routines \
                    --triggers' \
                    | xz -9 > #{@backups_path}/#{type}/#{backup_version_file}")

          puts "done"

          clean_up(type: type)
        else
          puts "error... check data & try again"
        end
      end

      # Copy weekly backup from the daily backup
      def weekly_backup_from_latest_daily
        Dir.chdir("#{@backups_path}/daily") do
          backup_versions = Dir.glob('*').sort
          backup_version = backup_versions.last

          if backup_version
            puts "-----> Creating weekly backup from daily backup version file #{backup_version} ... "
            system("cp ./#{backup_version} ../weekly/#{backup_version}")
            puts "done"

            clean_up(type: "weekly")
          else
            puts "-----> Could not find daily backup to copy to weekly ... error"
          end
        end
      end

      # Clean up very old versions
      def clean_up(type:)
        keep_releases = { snapshot: 2, daily: 7, weekly: 3 }

        Dir.chdir("#{@backups_path}/#{type}") do
          backup_versions = Dir.glob('*').sort
          destroy_count = backup_versions.count - keep_releases[type.to_sym]
          if destroy_count > 0
            puts "Deleting older #{type} backups ... "
            destroy_count.times do
              FileUtils.rm_r(File.join(Dir.pwd, backup_versions.shift))
            end
            puts "done"
          end
        end
      end
    end
  end
end
