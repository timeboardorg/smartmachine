module SmartMachine
  module Commands
    module GridCommands
      class Mysql < SubThor
        include Utilities

        desc "up", "Take UP the mysql grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid mysql uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the mysql grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid mysql downer#{name_option}"
            end
          end
        end

        # def flushlogs
        # end

        # def backup
        # end

        desc "uper", "Mysql grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              mysql = SmartMachine::Grids::Mysql.new(name: options[:name])
              mysql.uper
            else
              SmartMachine.config.grids.mysql.each do |name, config|
                mysql = SmartMachine::Grids::Mysql.new(name: name.to_s)
                mysql.uper
              end
            end
          end
        end

        desc "downer", "Mysql grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              mysql = SmartMachine::Grids::Mysql.new(name: options[:name])
              mysql.downer
            else
              SmartMachine.config.grids.mysql.each do |name, config|
                mysql = SmartMachine::Grids::Mysql.new(name: name.to_s)
                mysql.downer
              end
            end
          end
        end
      end
    end
  end
end
