module SmartMachine
  class Grids
    class Redis < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.redis.dig(name.to_sym)
        raise "redis config for #{name} not found." unless config

        @port = config.dig(:port)
        @password = config.dig(:password)
        @appendonly = config.dig(:appendonly)
        @maxmemory = config.dig(:maxmemory)
        @maxmemory_policy = config.dig(:maxmemory_policy)
        @modules = config.dig(:modules)&.map { |module_name| "--loadmodule /usr/lib/redis/modules/#{module_name}.so" } || []
        @modules.push("Plugin /var/opt/redislabs/modules/rg/plugin/gears_python.so")

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        # Creating networks
        unless system("docker network inspect #{@name}-network", [:out, :err] => File::NULL)
          puts "-----> Creating network #{@name}-network ... "
          if system("docker network create #{@name}-network", out: File::NULL)
            puts "done"
          end
        end

        FileUtils.mkdir_p("#{@home_dir}/machine/grids/redis/#{@name}/data")

        # Creating & Starting containers
        puts "-----> Creating container #{@name} ... "

        command = [
          "docker create",
          "--name='#{@name}'",
          "--user `id -u`:`id -g`",
          "--publish='#{@port}:#{@port}'",
          "--volume='#{@home_dir}/smartmachine/grids/redis/#{@name}/data:/data'",
          "--restart='always'",
          "--network='#{@name}-network'",
          "redislabs/redismod:latest --port #{@port} --requirepass #{@password} --appendonly #{@appendonly} --maxmemory #{@maxmemory} --maxmemory-policy #{@maxmemory_policy} #{@modules.join(' ')}"
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
    end
  end
end
