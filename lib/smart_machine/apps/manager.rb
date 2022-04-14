module SmartMachine
  module Apps
    class Manager < SmartMachine::Base
      attr_accessor :appname, :appversion

      def initialize(appname:, appversion: nil)
        @appname = appname
        @appversion = appversion

        @home_dir = File.expand_path('~')
        @container_path = "#{@home_dir}/machine/apps/containers/#{@appname}"

        # Checking if given appname exists
        repository_path = "#{@home_dir}/machine/apps/repositories/#{@appname}.git"
        raise "App with name '#{@appname}' does not exist. Please provide a valid appname." unless Dir.exist?(repository_path)
      end

      def deploy
        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end

        Dir.chdir("#{@container_path}/releases") do
          # Setting app version to latest if not set.
          unless @appversion
            versions = Dir.glob('*').select { |f| File.directory? f }.sort
            @appversion = versions.last
          end

          buildpacker = SmartMachine::Buildpackers::Rails.new(appname: @appname, appversion: @appversion)
          if buildpacker.package
            if release
              sleep 7
              clean
              logger.info "Launched Application ... Success."
              exit 10
            else
              raise "Error: Could not release the application."
            end
          else
            raise "Error: Could not package the application."
          end
        end

        logger.formatter = nil
      end

      def ps_scaler(formation:)
        Dir.chdir("#{@container_path}/releases") do
          # Setting app version to latest if not set.
          unless @appversion
            versions = Dir.glob('*').select { |f| File.directory? f }.sort
            @appversion = versions.last
          end

          formation.each do |proc_name, final_count|
            config = processes.dig(proc_name.to_sym)
            raise "no config found for the #{proc_name} process." unless config.present?

            current_count = `docker ps -aq --filter name="#{@appname}-#{@appversion}-#{proc_name}-" | wc -l`

            final_count = final_count.to_i
            current_count = current_count.to_i

            if final_count > current_count
              ((current_count + 1)..final_count).each do |index|
                containerize_process!(name: "#{@appname}-#{@appversion}-#{proc_name}-#{index}", config: config)
              end
            elsif final_count < current_count
              ((final_count + 1)..current_count).each do |index|
                container = SmartMachine::Apps::Container.new(name: "#{@appname}-#{@appversion}-#{proc_name}-#{index}", appname: @appname, appversion: @appversion)
                container.stop!
              end
            else
              # No Operation. Don't do anything.
            end
          end
        end
      end

      def env_vars
        @env_vars ||= load_env_vars
      end

      private

      def release
        logger.info "Releasing Application ..."

        if processes.present?
          processes.each do |name, config|
            containerize_process!(name: "#{@appname}-#{@appversion}-#{name}-1", config: config)
          end
        else
          logger.fatal "No smartmachine.yml file found. Proceeding with default settings."
          return false

          # Use the below code when you want to provide a default when smartmachine.yml is not present.
          # containerize_process!(name: "#{@appname}-#{@appversion}-web-1", config: { command: "bundle exec puma --config config/puma.rb", networks: "nginx-network" })
        end
      end

      def containerize_process!(name:, config:)
        container = SmartMachine::Apps::Container.new(name: name, appname: @appname, appversion: @appversion)
        if container.create!(using_command: config.dig(:command))
          networks = config.dig(:networks)&.split(" ")
          networks.each do |network|
            container.connect_to_network!(network_name: network)
          end

          unless container.start!
            container.stop!
          end
        else
          container.stop!
        end
      end

      def clean
        return unless env_vars.present?

        logger.info "Cleaning up ..."

        # Clean up very old versions
        Dir.chdir("#{@container_path}/releases") do
          versions = Dir.glob('*').select { |f| File.directory? f }.sort
          destroy_count = versions.count - env_vars['KEEP_RELEASES'].to_i
          if destroy_count > 0
            logger.debug "Deleting older application releases ..."
            destroy_count.times do
              version = versions.shift
              FileUtils.rm_r(File.join(Dir.pwd, version))

              # Remove corresponding docker containers & images, if they exist.
              system("docker ps -aq --filter ancestor=smartmachine/apps/#{@appname}:#{version} | xargs --no-run-if-empty docker stop | xargs --no-run-if-empty docker rm", out: File::NULL)
              system("docker image ls -aq --filter reference=smartmachine/apps/#{@appname}:#{version} | xargs --no-run-if-empty docker image rm", out: File::NULL)
            end
          end

          versions = Dir.glob('*').select { |f| File.directory? f }.sort
          versions_count = versions.count
          if versions_count > 0
            versions_count.times do
              version = versions.shift
              unless version == @appversion
                system("docker ps -aq --filter ancestor=smartmachine/apps/#{@appname}:#{version} | xargs --no-run-if-empty docker stop", out: File::NULL)
              end
            end
          end
        end
      end

      def load_env_vars
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

      def processes
        @processes ||= deserialize(IO.binread("#{@appversion}/smartmachine.yml")).deep_symbolize_keys
      end

      def deserialize(config)
        YAML.load(ERB.new(config).result).presence || {}
      end
    end
  end
end
