require 'open3'

module SmartMachine
  module Buildpackers
    class Rails < SmartMachine::Base
      def initialize(appname:, appversion:)
        @home_dir = File.expand_path('~')
        @appname = appname
        @appversion = appversion
        @container_path = "#{@home_dir}/machine/apps/containers/#{@appname}"
      end

      def package
        return unless File.exist? "#{@container_path}/releases/#{@appversion}/bin/rails"

        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end

        logger.info "Ruby on Rails application detected."
        logger.info "Packaging Application ..."

        # Setup rails env
        env_path = "#{@container_path}/env"
        system("grep -q '^## Rails' #{env_path} || echo '## Rails' >> #{env_path}")
        system("grep -q '^MALLOC_ARENA_MAX=' #{env_path} || echo '# MALLOC_ARENA_MAX=2' >> #{env_path}")
        system("grep -q '^RAILS_ENV=' #{env_path} || echo 'RAILS_ENV=production' >> #{env_path}")
        system("grep -q '^RACK_ENV=' #{env_path} || echo 'RACK_ENV=production' >> #{env_path}")
        system("grep -q '^RAILS_LOG_TO_STDOUT=' #{env_path} || echo 'RAILS_LOG_TO_STDOUT=enabled' >> #{env_path}")
        system("grep -q '^RAILS_SERVE_STATIC_FILES=' #{env_path} || echo 'RAILS_SERVE_STATIC_FILES=enabled' >> #{env_path}")
        system("grep -q '^LANG=' #{env_path} || echo 'LANG=en_US.UTF-8' >> #{env_path}")
        system("grep -q '^RAILS_MASTER_KEY=' #{env_path} || echo 'RAILS_MASTER_KEY=yourmasterkey' >> #{env_path}")
        logger.warn "Please set your RAILS_MASTER_KEY env var for this rails app." if system("grep -q '^RAILS_MASTER_KEY=yourmasterkey' #{env_path}")

        # Setup app folders needed for volumes. If this is not created then docker will create it while running the container,
        # but the folder will have root user assigned instead of the current user.
        FileUtils.mkdir_p("#{@container_path}/app/vendor/bundle")
        FileUtils.mkdir_p("#{@container_path}/app/public/assets")
        FileUtils.mkdir_p("#{@container_path}/app/public/packs")
        FileUtils.mkdir_p("#{@container_path}/app/node_modules")
        FileUtils.mkdir_p("#{@container_path}/app/storage")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/vendor/bundle")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/public/assets")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/public/packs")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/node_modules")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/storage")

        # Creating a valid docker app image.
        container = SmartMachine::Apps::Container.new(name: "#{@appname}-#{@appversion}-packed", appname: @appname, appversion: @appversion)
        if container.commit_app_image!
          logger.formatter = nil
          return true
        end

        logger.formatter = nil
        return false
      end

      def packer
        set_logger_formatter_arrow

        if File.exist? "tmp/smartmachine/packed"
          begin
            pid = File.read('tmp/smartmachine/packed').to_i
            Process.kill('QUIT', pid)
          rescue Errno::ESRCH # No such process
          end
          exec "bundle", "exec", "puma", "--config", "config/puma.rb"
        else
          if initial_setup? && bundle_install? && precompile_assets? && db_migrate? && test_web_server?
            logger.formatter = nil

            exit 0
          else
            logger.error "Could not continue ... Launch Failed."
            logger.formatter = nil

            exit 1
          end
        end
      end

      private

      # Perform initial_setup
      def initial_setup?
        logger.info "Performing initial setup ..."

        exit_status = nil

        # Fix for mysql2 gem to support sha256_password, until it is fixed in main mysql2 gem.
        # https://github.com/brianmario/mysql2/issues/1023
        exit_status = system("mkdir -p ./lib/mariadb && ln -s /usr/lib/mariadb/plugin ./lib/mariadb/plugin")

        if exit_status
          return true
        else
          logger.error "Could not complete initial setup."
          return false
        end
      end

      # Perform bundle install
      def bundle_install?
        logger.info "Performing bundle install ..."

        set_logger_formatter_tabs

        unless system("bundle config set deployment 'true' && bundle config set clean 'true'")
          logger.error "Could not complete bundle config setting."
          return false
        end

        exit_status = nil
        Open3.popen2e("bundle", "install") do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not complete bundle install."
          return false
        end
      end

      # Perform pre-compiling of assets
      def precompile_assets?
        logger.info "Installing Javascript dependencies & pre-compiling assets ..."

        set_logger_formatter_tabs
        exit_status = nil
        Open3.popen2e("bundle", "exec", "rails", "assets:precompile") do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not install Javascript dependencies or pre-compile assets."
          return false
        end
      end

      # Perform db_migrate
      def db_migrate?
        return true # remove this line when you want to start using db_migrate?

        logger.info "Performing database migrations ..."

        set_logger_formatter_tabs
        exit_status = nil
        Open3.popen2e("bundle", "exec", "rails", "db:migrate") do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not complete database migrations."
          return false
        end
      end

      # Perform testing of web server
      def test_web_server?
        logger.info "Setting up Web Server ..."

        # tmp folders
        FileUtils.mkdir_p("tmp/pids")
        FileUtils.mkdir_p("tmp/smartmachine")
        FileUtils.rm_f("tmp/smartmachine/packed")

        # Spawn Process
        pid = Process.spawn("bundle", "exec", "puma", "--config", "config/puma.rb", out: File::NULL)
        Process.detach(pid)

        # Sleep
        sleep 5

        # Check PID running
        status = nil
        begin
          Process.kill(0, pid)
          system("echo '#{pid}' > tmp/smartmachine/packed")
          status = true
        rescue Errno::ESRCH # No such process
          logger.info "Web Server could not start"
          status = false
        end

        # Return status
        return status
      end

      def set_logger_formatter_arrow
        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end
      end

      def set_logger_formatter_tabs
        logger.formatter = proc do |severity, datetime, progname, message|
          "\t\t\t\t       #{message}"
        end
      end
    end
  end
end
