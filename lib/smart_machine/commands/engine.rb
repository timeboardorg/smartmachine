module SmartMachine
  module Commands
    class Engine < Thor
      include Utilities

      desc "install", "Install engine"
      def install
        inside_machine_dir do
          with_docker_running do
            engine = SmartMachine::Engine.new
            engine.install
          end
        end
      end

      desc "uninstall", "Uninstall engine"
      def uninstall
        inside_machine_dir do
          with_docker_running do
            engine = SmartMachine::Engine.new
            engine.uninstall
          end
        end
      end
    end
  end
end
