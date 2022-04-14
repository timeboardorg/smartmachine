require 'yaml'
require "base64"
require 'bcrypt'

module SmartMachine
  class Grids
    class Nginx < SmartMachine::Base
      def initialize
        @home_dir = File.expand_path('~')
      end

      def uper
        # Creating volumes
        puts "-----> Creating volume nginx-confd ... "
        if system("docker volume create nginx-confd", out: File::NULL)
          puts "done"
        end

        puts "-----> Creating volume nginx-vhost ... "
        if system("docker volume create nginx-vhost", out: File::NULL)
          puts "done"
        end

        puts "-----> Creating volume nginx-shtml ... "
        if system("docker volume create nginx-shtml", out: File::NULL)
          puts "done"
        end

        # Creating networks
        unless system("docker network inspect nginx-network", [:out, :err] => File::NULL)
          puts "-----> Creating network nginx-network ... "
          if system("docker network create nginx-network", out: File::NULL)
            puts "done"
          end
        end

        # Creating & Starting containers
        puts "-----> Creating container nginx ... "
        command = [
          "docker create",
          "--name='nginx'",
          "--publish='80:80' --publish='443:443'",
          "--volume='nginx-confd:/etc/nginx/conf.d/'",
          "--volume='nginx-vhost:/etc/nginx/vhost.d/'",
          "--volume='nginx-shtml:/usr/share/nginx/html'",
          "--volume='#{@home_dir}/smartmachine/grids/nginx/certificates:/etc/nginx/certs'",
          "--volume='#{@home_dir}/smartmachine/grids/nginx/fastcgi.conf:/etc/nginx/fastcgi.conf:ro'",
          "--volume='#{@home_dir}/smartmachine/grids/nginx/htpasswd:/etc/nginx/htpasswd:ro'",
          "--restart='always'",
          "--network='nginx-network'",
          "nginx:alpine"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          puts "done"
          puts "-----> Starting container nginx ... "
          if system("docker start nginx", out: File::NULL)
            puts "done"
          else
            raise "Error: Could not start the created nginx container."
          end
        else
          raise "Error: Could not create nginx container."
        end

        puts "-----> Creating container nginx-gen ... "
        command = [
          "docker create",
          "--name='nginx-gen'",
          "--volumes-from nginx",
          "--volume='#{@home_dir}/smartmachine/grids/nginx/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro'",
          "--volume='/var/run/docker.sock:/tmp/docker.sock:ro'",
          "--restart='always'",
          "--network='nginx-network'",
          "jwilder/docker-gen",
          "-notify-sighup nginx -watch /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          puts "done"
          puts "-----> Starting container nginx-gen ... "
          if system("docker start nginx-gen", out: File::NULL)
            puts "done"
          else
            raise "Error: Could not start the created nginx-gen container."
          end
        else
          raise "Error: Could not create nginx-gen container."
        end

        puts "-----> Creating container nginx-letsencrypt ... "
        command = [
          "docker create",
          "--name='nginx-letsencrypt'",
          "--env NGINX_PROXY_CONTAINER=nginx",
          "--env NGINX_DOCKER_GEN_CONTAINER=nginx-gen",
          "--env DEFAULT_EMAIL=#{SmartMachine.config.sysadmin_email}",
          "--volumes-from nginx",
          "--volume='/var/run/docker.sock:/var/run/docker.sock:ro'",
          "--restart='always'",
          "--network='nginx-network'",
          "jrcs/letsencrypt-nginx-proxy-companion"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          puts "done"
          puts "-----> Starting container nginx-letsencrypt ... "
          if system("docker start nginx-letsencrypt", out: File::NULL)
            puts "done"
          else
            raise "Error: Could not start the created nginx-letsencrypt container."
          end
        else
          raise "Error: Could not create nginx-letsencrypt container."
        end
      end

      # Stopping & Removing containers - in reverse order
      def downer
        puts "-----> Stopping container nginx-letsencrypt ... "
        if system("docker stop 'nginx-letsencrypt'", out: File::NULL)
          puts "done"
          puts "-----> Removing container nginx-letsencrypt ... "
          if system("docker rm 'nginx-letsencrypt'", out: File::NULL)
            puts "done"
          end
        end

        puts "-----> Stopping container nginx-gen ... "
        if system("docker stop 'nginx-gen'", out: File::NULL)
          puts "done"
          puts "-----> Removing container nginx-gen ... "
          if system("docker rm 'nginx-gen'", out: File::NULL)
            puts "done"
          end
        end

        puts "-----> Stopping container nginx ... "
        if system("docker stop 'nginx'", out: File::NULL)
          puts "done"
          puts "-----> Removing container nginx ... "
          if system("docker rm 'nginx'", out: File::NULL)
            puts "done"
          end
        end

        # Removing networks
        puts "-----> Removing network nginx-network ... "
        if system("docker network rm nginx-network", out: File::NULL)
          puts "done"
        end
      end

      def create_htpasswd_files
        htpasswd_dir = "#{Dir.pwd}/grids/nginx/htpasswd"

        # Remove existing htpasswd_dir and recreate it.
        FileUtils.rm_r htpasswd_dir if Dir.exist?(htpasswd_dir)
        FileUtils.mkdir htpasswd_dir
        FileUtils.touch "#{htpasswd_dir}/.keep"

        # Add hostfiles to htpasswd_dir
        get_users_from_file.each do |domain_name, users|
          next unless users

          file_data = ""
          users.each do |user, password|
            file_data += "#{user}:#{BCrypt::Password.create(password)}\n"
          end
          File.open("#{Dir.pwd}/grids/nginx/htpasswd/#{domain_name}", "w") { |file| file.write(file_data) }
        end
      end

      private

      def get_users_from_file
        YAML.load_file("#{Dir.pwd}/config/users.yml") || Hash.new
      end
    end
  end
end
