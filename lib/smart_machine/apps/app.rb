module SmartMachine
  module Apps
    class App < SmartMachine::Base
      def initialize(appname:, container_number: nil, username: nil)
        @home_dir = File.expand_path('~')
        @appname = appname
        @container_number = container_number
        @username = username

        @repository_path = "#{@home_dir}/machine/apps/repositories/#{@appname}.git"
        @container_path = "#{@home_dir}/machine/apps/containers/#{@appname}"
      end

      def creater(appdomain:, prereceiver_name:)
        raise "Please provide appname and username" if @appname.empty? || @username.empty?
        prereceiver_name = prereceiver_name.to_s

        print "-----> Creating Application ... "

        # Checking if app with given name already exists
        if Dir.exist?(@repository_path)
          puts "failed. App with name '#{@appname}' already exists."
          exit
        end

        # Creating Directories
        FileUtils.mkdir_p(@repository_path)
        FileUtils.mkdir_p(@container_path)

        # Initializing bare repo and pre-receive
        Dir.chdir(@repository_path) do
          %x[git init --bare]
          %x[ln -s ../../../../grids/prereceiver/#{prereceiver_name}/pre-receive hooks/pre-receive]
          puts "done"
        end

        # Creating Environment File
        if File.exist?("#{@home_dir}/machine/config/environment.rb")
          require "#{@home_dir}/machine/config/environment"
        end
        unless File.exist? "#{@container_path}/env"
          print "-----> Creating App Environment ... "
          page = <<~HEREDOC
                  ## System
                  USERNAME=#{@username}
                  KEEP_RELEASES=3

                  ## Docker
                  VIRTUAL_HOST=#{@appname}.#{appdomain}
                  LETSENCRYPT_HOST=#{@appname}.#{appdomain}
                  LETSENCRYPT_EMAIL=#{@username}
                  LETSENCRYPT_TEST=false
               HEREDOC
          puts "done" if system("echo '#{page}' > #{@container_path}/env")
        end
      end

      def destroyer
        raise "Please provide appname" if @appname.empty?

        # Checking if app with given name exists
        unless Dir.exist?(@repository_path)
          raise "App with name '#{@appname}' does not exist. Please provide a valid appname."
        end

        container_id = `docker ps -a -q --filter='name=^#{@appname}$' --filter='status=running'`.chomp
        if container_id.empty?
          # Destroying Directories
          print "-----> Deleting App #{@appname} ... "
          FileUtils.rm_r(@repository_path)
          FileUtils.rm_r(@container_path)
          puts "done"
        end
      end

      def uper(version:)
        raise "Please provide appname" if @appname.empty?

        # Checking if app with given name exists
        unless Dir.exist?(@repository_path)
          raise "App with name '#{@appname}' does not exist. Please provide a valid appname."
        end

        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end

        Dir.chdir("#{@container_path}/releases") do
          # Getting App Version
          if version == 0
            versions = Dir.glob('*').select { |f| File.directory? f }.sort
            version = versions.last
          end

          logger.info "Launching Application ..."

          buildpacker_rails = SmartMachine::Buildpackers::Rails.new(appname: @appname, version: version)
          buildpacker_rails.uper
        end

        logger.formatter = nil
      end

      def downer
        raise "Please provide appname" if @appname.empty?

        # Checking if app with given name exists
        unless Dir.exist?(@repository_path)
          raise "App with name '#{@appname}' does not exist. Please provide a valid appname."
        end

        container_name = @appname
        container_name += "_" + @container_number if @container_number

        container_id = `docker ps -a -q --filter='name=^#{container_name}$'`.chomp
        unless container_id.empty?
          logger.debug "Stopping & Removing container #{container_name} ..."
          if system("docker stop #{container_name} && docker rm #{container_name}", out: File::NULL)
            logger.debug "Stopped & Removed container #{container_name} ..."
          end
        else
          logger.debug "Container '#{container_name}' does not exist to stop."
        end
      end

      def cleaner
        env_vars = get_env_vars
        return unless env_vars

        logger.info "Cleaning up ..."

        # Clean up very old versions
        Dir.chdir("#{@container_path}/releases") do
          versions = Dir.glob('*').select { |f| File.directory? f }.sort
          destroy_count = versions.count - env_vars['KEEP_RELEASES'].to_i
          if destroy_count > 0
            logger.debug "Deleting older application releases ..."
            destroy_count.times do
              FileUtils.rm_r(File.join(Dir.pwd, versions.shift))
            end
          end
        end
      end

      def get_env_vars
        unless File.exist? "#{@container_path}/env"
          logger.fatal "Environment could not be loaded ... Failed."
          return false
        end

        env_vars = {}
        File.open("#{@container_path}/env").each_line do |line|
          line.chomp!
          next if line.empty? || line.start_with?('#')
          key, value = line.split "="
          env_vars[key] = value
        end

        env_vars
      end
    end
  end
end
