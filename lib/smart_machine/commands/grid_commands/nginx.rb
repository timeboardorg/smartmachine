module SmartMachine
  module Commands
    module GridCommands
      class Nginx < SubThor
        include Utilities

        desc "up", "Take UP the nginx grid"
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid nginx uper"
            end
          end
        end

        desc "down", "Take DOWN the nginx grid"
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid nginx downer"
            end
          end
        end

        desc "users:edit", "Allows editing the users"
        map "users:edit" => :users_edit
        def users_edit
          inside_machine_dir do
            system("#{ENV['EDITOR']} config/users.yml")
          end
        end

        desc "uper", "Nginx grid uper", hide: true
        def uper
          inside_engine_machine_dir do
            nginx = SmartMachine::Grids::Nginx.new
            nginx.uper
          end
        end

        desc "downer", "Nginx grid downer", hide: true
        def downer
          inside_engine_machine_dir do
            nginx = SmartMachine::Grids::Nginx.new
            nginx.downer
          end
        end
      end
    end
  end
end
