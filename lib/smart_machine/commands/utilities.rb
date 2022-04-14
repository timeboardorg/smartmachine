module SmartMachine
  module Commands
    module Utilities

      private

      def in_machine_dir?
        File.file?("./config/master.key")
      end

      def inside_machine_dir
        if in_machine_dir?
          yield
        else
          puts "Are you in the correct directory to run this command?"
        end
      end

      def inside_engine_machine_dir
        if ENV["INSIDE_ENGINE"] == "yes" && File.file?('./bin/smartengine')
          yield
        else
          raise "Not inside the engine machine dir to run this command"
        end
      end

      def with_docker_running
        machine = SmartMachine::Machine.new
        if machine.run_on_machine(commands: "docker info &>/dev/null")
          yield
        else
          puts "Error: Docker daemon is not running. Have you installed docker? Please ensure docker daemon is running and try again."
        end
      end
    end
  end
end
