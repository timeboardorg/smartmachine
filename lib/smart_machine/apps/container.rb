module SmartMachine
  module Apps
    class Container < SmartMachine::Base
      def initialize(name:, appname:, appversion:)
        @name = name
        @appname = appname
        @appversion = appversion
        @appimage = "smartmachine/apps/#{@appname}:#{@appversion}"

        @home_dir = File.expand_path('~')
      end

      def create!(using_command:, using_buildpacker: false)
        unless using_buildpacker
          unless system("docker image inspect #{@appimage}", [:out, :err] => File::NULL)
            raise "Error: App Image with name #{@appimage} not found. Could not create #{@name} container."
          end
        end

        logger.debug "-----> Creating container #{@name} ... "
        command = [
          "docker create",
          "--name='#{@name}'",
          "--env-file='#{@home_dir}/machine/apps/containers/#{@appname}/env'",
          "--user `id -u`:`id -g`",
          "--workdir /app",
          "--expose='3000'",
          "--volume='#{@home_dir}/smartmachine/config/environment.rb:#{@home_dir}/machine/config/environment.rb'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/releases/#{@appversion}:/app'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/app/vendor/bundle:/app/vendor/bundle'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/app/public/assets:/app/public/assets'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/app/public/packs:/app/public/packs'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/app/node_modules:/app/node_modules'",
          "--volume='#{@home_dir}/smartmachine/apps/containers/#{@appname}/app/storage:/app/storage'",
          "--restart='always'",
          "--init",
          # "--network='nginx-network'",
          "#{using_buildpacker ? "smartmachine/buildpackers/rails:#{SmartMachine.version}" : @appimage}"
        ]
        command.push(using_command) if using_command.present?

        if system(command.compact.join(" "), out: File::NULL)
          logger.debug "done"
          return true
        else
          raise "Error: Could not create #{@name} container"
        end

        return false
      end

      def start!
        logger.debug "-----> Starting container #{@name} ... "
        if system("docker start #{@name}", out: File::NULL)
          logger.debug "done"
          return true
        else
          raise "Error: Could not start #{@name} container"
        end

        return false
      end

      def stop!
        container_id = `docker ps -a -q --filter='name=^#{@name}$'`.chomp
        unless container_id.empty?
          logger.debug "Stopping & Removing container #{@name} ..."
          if system("docker stop #{@name} && docker rm #{@name}", out: File::NULL)
            logger.debug "Stopped & Removed container #{@name} ..."
            return true
          else
            raise "Error: Container '#{@name}' could not be stopped and removed."
          end
        else
          raise "Error: Container '#{@name}' does not exist to stop."
        end

        return false
      end

      def connect_to_network!(network_name:)
        unless `docker network ls -q --filter name=^#{network_name}$`.chomp.empty?
          if system("docker network connect #{network_name} #{@name}", out: File::NULL)
            logger.debug "Connected to network #{network_name}."
            return true
          else
            raise "Error: Could not connect to #{network_name} network."
          end
        else
          raise "Error: The network with name #{network_name} was not found."
        end

        return false
      end

      def commit_app_image!
        if create!(using_command: "smartmachine buildpacker packer rails", using_buildpacker: true)
          logger.debug "-----> Starting attached container #{@name} ... "
          if system("docker start --attach #{@name}")
            logger.debug "-----> Committing container #{@name} to image... "
            if system("docker commit #{@name} #{@appimage}", out: File::NULL)
              stop!
              return true
            else
              stop!
              raise "Error: Could not commit #{@name} container to image."
            end
          else
            stop!
            raise "Error: Could not start attached #{@name} container"
          end
        else
          raise "Error: Could not create #{@name} container"
        end

        return false
      end
    end
  end
end
