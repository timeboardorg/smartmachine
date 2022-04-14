module SmartMachine
  class Grids
    class Minio < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.minio.dig(name.to_sym)
        raise "minio config for #{name} not found." unless config

        @host = config.dig(:host)
        @access_key = config.dig(:access_key)
        @secret_key = config.dig(:secret_key)
        @browser = config.dig(:browser)
        @worm = config.dig(:worm)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        # Creating networks
        unless system("docker network inspect #{@name}-network", [:out, :err] => File::NULL)
          print "-----> Creating network #{@name}-network ... "
          if system("docker network create #{@name}-network", out: File::NULL)
            puts "done"
          end
        end

        FileUtils.mkdir_p("#{@home_dir}/machine/grids/minio/#{@name}/data")

        # Creating & Starting containers
        print "-----> Creating container #{@name} ... "
        command = [
          "docker create",
          "--name='#{@name}'",
          "--env VIRTUAL_HOST=#{@host}",
          "--env LETSENCRYPT_HOST=#{@host}",
          "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
          "--env LETSENCRYPT_TEST=false",
          "--env MINIO_ACCESS_KEY=#{@access_key}",
          "--env MINIO_SECRET_KEY=#{@secret_key}",
          "--env MINIO_BROWSER=#{@browser}",
          "--env MINIO_WORM=#{@worm}",
          "--user `id -u`:`id -g`",
          "--volume='#{@home_dir}/smartmachine/grids/minio/#{@name}/data:/data'",
          "--restart='always'",
          "--network='#{@name}-network'",
          "minio/minio:RELEASE.2020-02-27T00-23-05Z server /data"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          # The alias is necessary to support internal network requests directed to minio container using public url
          system("docker network connect --alias #{@host} #{@name}-network nginx")
          system("docker network connect nginx-network #{@name}")

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

      def downer
        # Disconnecting networks
        system("docker network disconnect nginx-network #{@name}")
        system("docker network disconnect #{@name}-network nginx")

        # Stopping & Removing containers - in reverse order
        print "-----> Stopping container #{@name} ... "
        if system("docker stop '#{@name}'", out: File::NULL)
          puts "done"
          print "-----> Removing container #{@name} ... "
          if system("docker rm '#{@name}'", out: File::NULL)
            puts "done"
          end
        end

        # Removing networks
        print "-----> Removing network #{@name}-network ... "
        if system("docker network rm #{@name}-network", out: File::NULL)
          puts "done"
        end
      end
    end
  end
end
