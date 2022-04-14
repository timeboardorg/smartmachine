module SmartMachine
  module Commands
    module GridCommands
      class Redis < SubThor
        include Utilities

        desc "up", "Take UP the redis grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid redis uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the redis grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid redis downer#{name_option}"
            end
          end
        end

        desc "uper", "Redis grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              redis = SmartMachine::Grids::Redis.new(name: options[:name])
              redis.uper
            else
              SmartMachine.config.grids.redis.each do |name, config|
                redis = SmartMachine::Grids::Redis.new(name: name.to_s)
                redis.uper
              end
            end
          end
        end

        desc "downer", "Redis grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              redis = SmartMachine::Grids::Redis.new(name: options[:name])
              redis.downer
            else
              SmartMachine.config.grids.redis.each do |name, config|
                redis = SmartMachine::Grids::Redis.new(name: name.to_s)
                redis.downer
              end
            end
          end
        end
      end
    end
  end
end
