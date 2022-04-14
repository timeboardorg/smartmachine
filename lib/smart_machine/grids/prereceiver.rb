module SmartMachine
  class Grids
    class Prereceiver < SmartMachine::Base

      def initialize(name:)
        config = SmartMachine.config.grids.prereceiver.dig(name.to_sym)
        raise "prereceiver config for #{name} not found." unless config

        @git_domain = config.dig(:git_domain)
        @letsencrypt_test = config.dig(:letsencrypt_test)
        @letsencrypt_email = SmartMachine.config.sysadmin_email
        @image_name = "smartmachine/prereceiver:#{SmartMachine.version}"

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        unless system("docker image inspect #{@image_name}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image_name} ... "
          command = [
            "docker image build -t #{@image_name}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "#{SmartMachine.config.gem_dir}/lib/smart_machine/grids/prereceiver"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"
          else
            raise "Error: Could not install Prereceiver."
          end
        else
          raise "Error: Prereceiver already installed. Please uninstall using 'smartmachine grids prereceiver uninstall' and try installing again."
        end
      end

      def uninstaller
        unless system("docker inspect -f '{{.State.Running}}' '#{@name}'", [:out, :err] => File::NULL)
          if system("docker image inspect #{@image_name}", [:out, :err] => File::NULL)
            puts "-----> Removing image #{@image_name} ... "
            if system("docker image rm #{@image_name}", out: File::NULL)
              puts "done"
            end
          else
            raise "Error: Prereceiver already uninstalled. Please install using 'smartmachine grids prereceiver install' and try uninstalling again."
          end
        else
          raise "Error: Prereceiver is currently running. Please stop the prereceiver using 'smartmachine grids prereceiver down' and try uninstalling again."
        end
      end

      def uper
        if system("docker image inspect #{@image_name}", [:out, :err] => File::NULL)
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/prereceiver/#{@name}")
          system("cp #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/prereceiver/pre-receive #{@home_dir}/machine/grids/prereceiver/#{@name}/pre-receive")
          system("chmod +x #{@home_dir}/machine/grids/prereceiver/#{@name}/pre-receive")

          puts "-----> Creating container #{@name} with image #{@image_name} ... "
          command = [
            "docker create",
            "--name='#{@name}'",
            "--env VIRTUAL_PROTO=fastcgi",
            "--env VIRTUAL_HOST=#{@git_domain}",
            "--env LETSENCRYPT_HOST=#{@git_domain}",
            "--env LETSENCRYPT_EMAIL=#{@letsencrypt_email}",
            "--env LETSENCRYPT_TEST=#{@letsencrypt_test}",
            "--env GIT_PROJECT_ROOT=#{@home_dir}/machine/apps/repositories",
            "--env GIT_HTTP_EXPORT_ALL=''",
            "--user `id -u`",
            "--workdir #{@home_dir}/machine",
            "--expose='9000'",
            "--volume='#{@home_dir}/smartmachine/config:#{@home_dir}/machine/config'",
            "--volume='#{@home_dir}/smartmachine/apps:#{@home_dir}/machine/apps'",
            "--volume='#{@home_dir}/smartmachine/grids/prereceiver/#{@name}:#{@home_dir}/machine/grids/prereceiver/#{@name}'",
            "--volume='/var/run/docker.sock:/var/run/docker.sock:ro'",
            "--restart='always'",
            "--network='nginx-network'",
            "#{@image_name}"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"

            puts "-----> Starting container #{@name} with image #{@image_name} ... "
            if system("docker start #{@name}", out: File::NULL)
              puts "done"
            else
              raise "Error: Could not start the created image to take UP the prereceiver."
            end
          else
            raise "Error: Could not create image to take UP the prereceiver."
          end
        end
      end

      # Stopping & Removing containers - in reverse order
      def downer
        if system("docker inspect -f '{{.State.Running}}' '#{@name}'", [:out, :err] => File::NULL)
          puts "-----> Stopping container #{@name} with image #{@image_name} ... "
          if system("docker stop '#{@name}'", out: File::NULL)
            puts "done"

            puts "-----> Removing container #{@name} with image #{@image_name} ... "
            if system("docker rm '#{@name}'", out: File::NULL)

              system("rm -r #{@home_dir}/machine/grids/prereceiver/#{@name}")

              puts "done"
            end
          end
        else
          puts "-----> Container '#{@name}' is currently not running."
        end
      end

      def prereceive(appname:, username:, oldrev:, newrev:, refname:)
        manager = SmartMachine::Apps::Manager.new(appname: appname)

        # Loading SmartMachine Environment File
        if File.exist?("#{@home_dir}/machine/config/environment.rb")
          require "#{@home_dir}/machine/config/environment"
        end

        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end

        # Load vars and environment
        container_path = "#{@home_dir}/machine/apps/containers/#{appname}"

        # Verify the user and ensure the user is correct and has access to this repository
        unless manager.env_vars.present? && manager.env_vars['USERNAME'] == username
          logger.error "Unauthorized."
          return
        end

        # Only run this script for the main branch. You can remove this
        # if block if you wish to run it for others as well.
        if refname == "refs/heads/main"
          logger.info "Loading Application ..."

          # Note: There should be no space between + and " in version.
          # Note: date will be UTC date until timezone has been changed.
          version = `date +"%Y%m%d%H%M%S"`.chomp!
          container_path_with_version = "#{container_path}/releases/#{version}"

          unless Dir.exist? container_path_with_version
            FileUtils.mkdir_p(container_path_with_version)
            if system("git archive #{newrev} | tar -x -C #{container_path_with_version}")
              # Deploy app with the latest release
              manager.deploy
            else
              logger.fatal "Could not extract new app version ... Failed."
              return
            end
          else
            logger.fatal "This version name already exists ... Failed."
            return
          end
        else
          # Allow the push to complete for all other branches normally.
          exit 10
        end

        logger.formatter = nil
      end
    end
  end
end
