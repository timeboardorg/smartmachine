module SmartMachine
  module Commands
    module GridCommands
      class Minio < SubThor
        include Utilities

        desc "up", "Take UP the minio grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid minio uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the minio grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid minio downer#{name_option}"
            end
          end
        end

        desc "uper", "Minio grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              minio = SmartMachine::Grids::Minio.new(name: options[:name])
              minio.uper
            else
              SmartMachine.config.grids.minio.each do |name, config|
                minio = SmartMachine::Grids::Minio.new(name: name.to_s)
                minio.uper
              end
            end
          end
        end

        desc "downer", "Minio grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              minio = SmartMachine::Grids::Minio.new(name: options[:name])
              minio.downer
            else
              SmartMachine.config.grids.minio.each do |name, config|
                minio = SmartMachine::Grids::Minio.new(name: name.to_s)
                minio.downer
              end
            end
          end
        end
      end
    end
  end
end
