module SmartMachine
  module Commands
    class Buildpacker < Thor
      include Utilities

      desc "install [PACKNAME]", "Install buildpacker"
      def install(packname)
        inside_machine_dir do
          with_docker_running do
            puts "-----> Installing Buildpacker"
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine buildpacker installer #{packname}"
            puts "-----> Buildpacker Installation Complete"
          end
        end
      end

      desc "uninstall [PACKNAME]", "Uninstall buildpacker"
      def uninstall(packname)
        inside_machine_dir do
          with_docker_running do
            puts "-----> Uninstalling Buildpacker"
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine buildpacker uninstaller #{packname}"
            puts "-----> Buildpacker Uninstallation Complete"
          end
        end
      end

      desc "installer [PACKNAME]", "Buildpacker installer", hide: true
      def installer(packname)
        inside_engine_machine_dir do
          buildpacker = SmartMachine::Buildpackers::Buildpacker.new(packname: packname)
          buildpacker.installer
        end
      end

      desc "uninstaller [PACKNAME]", "Buildpacker uninstaller", hide: true
      def uninstaller(packname)
        inside_engine_machine_dir do
          buildpacker = SmartMachine::Buildpackers::Buildpacker.new(packname: packname)
          buildpacker.uninstaller
        end
      end

      desc "packer", "Pack a buildpack. System command. Should not be used by user.", hide: true
      def packer(packname)
        buildpacker = SmartMachine::Buildpackers::Buildpacker.new(packname: packname)
        buildpacker.packer
      end
    end
  end
end
