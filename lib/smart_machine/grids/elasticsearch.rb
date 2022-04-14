module SmartMachine
  class Grids
    class Elasticsearch < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.elasticsearch.dig(name.to_sym)
        raise "elasticsearch config for #{name} not found." unless config

        @port = config.dig(:port)

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

        FileUtils.mkdir_p("#{@home_dir}/machine/grids/elasticsearch/#{@name}/data")
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/elasticsearch/#{@name}/logs")

        # Creating & Starting containers
        print "-----> Creating container #{@name} ... "
        command = [
          "docker create",
          "--name='#{@name}'",
          "--label='smartmachine.elasticsearch.name=#{@name}'",
          "--env discovery.type=single-node",
          "--env cluster.name=#{@name}-cluster",
          "--env 'ES_JAVA_OPTS=-Xms512m -Xmx512m -Des.enforce.bootstrap.checks=true'",
          "--env bootstrap.memory_lock=true",
          "--ulimit memlock=-1:-1",
          "--ulimit nofile=65535:65535",
          "--user `id -u`:`id -g`",
          "--publish='#{@port}:#{@port}'",
          "--volume='#{@home_dir}/smartmachine/grids/elasticsearch/#{@name}/data:/usr/share/elasticsearch/data'",
          "--volume='#{@home_dir}/smartmachine/grids/elasticsearch/#{@name}/logs:/usr/share/elasticsearch/logs'",
          "--restart='always'",
          "--network='#{@name}-network'",
          "elasticsearch:7.4.1"
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

      def downer
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
