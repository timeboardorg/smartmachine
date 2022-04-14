module SmartMachine
  module Commands
    module GridCommands
      class Prereceiver < SubThor
        include Utilities

        desc "install", "Install prereceiver grid"
        def install
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing Prereceiver"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid prereceiver installer"
              puts "-----> Prereceiver Installation Complete"
            end
          end
        end

        desc "uninstall", "Uninstall prereceiver grid"
        def uninstall
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing Prereceiver"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid prereceiver uninstaller"
              puts "-----> Prereceiver Installation Complete"
            end
          end
        end

        desc "up", "Take UP the prereceiver grid"
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid prereceiver uper"
            end
          end
        end

        desc "down", "Take DOWN the prereceiver grid"
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid prereceiver downer"
            end
          end
        end

        desc "installer", "Prereceiver grid installer", hide: true
        def installer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.prereceiver.first
            prereceiver = SmartMachine::Grids::Prereceiver.new(name: name.to_s)
            prereceiver.installer
          end
        end

        desc "uninstaller", "Prereceiver grid uninstaller", hide: true
        def uninstaller
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.prereceiver.first
            prereceiver = SmartMachine::Grids::Prereceiver.new(name: name.to_s)
            prereceiver.uninstaller
          end
        end

        desc "uper", "Prereceiver grid uper", hide: true
        def uper
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.prereceiver.first
            prereceiver = SmartMachine::Grids::Prereceiver.new(name: name.to_s)
            prereceiver.uper
          end
        end

        desc "downer", "Prereceiver grid downer", hide: true
        def downer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.prereceiver.first
            prereceiver = SmartMachine::Grids::Prereceiver.new(name: name.to_s)
            prereceiver.downer
          end
        end

        desc "prereceive", "Prereceiver grid prereceive", hide: true
        def prereceive(appname, username, oldrev, newrev, refname)
          name, config = SmartMachine.config.grids.prereceiver.first
          prereceiver = SmartMachine::Grids::Prereceiver.new(name: name.to_s)
          prereceiver.prereceive(appname: appname, username: username, oldrev: oldrev, newrev: newrev, refname: refname)
        end
      end
    end
  end
end
