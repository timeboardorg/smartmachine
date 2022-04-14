module SmartMachine
  module Commands
    class Docker < Thor
      include Utilities

      desc "install", "Install docker"
      def install
        inside_machine_dir do
          docker = SmartMachine::Docker.new
          docker.install
        end
      end

      desc "uninstall", "Uninstall docker"
      def uninstall
        inside_machine_dir do
          docker = SmartMachine::Docker.new
          docker.uninstall
        end
      end
    end
  end
end
