module SmartMachine
  module Commands
    class App < Thor
      include Utilities

      desc "create [APPNAME] [APPDOMAIN] [USERNAME]", "Create an App"
      def create(appname, appdomain, username)
        inside_machine_dir do
          with_docker_running do
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine app creater #{appname} #{appdomain} #{username}"
          end
        end
      end

      desc "destroy [APPNAME]", "Destroy an App"
      def destroy(appname)
        inside_machine_dir do
          with_docker_running do
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine app destroyer #{appname}"
          end
        end
      end

      desc "ps:scale [APPNAME]", "Scale the app processes"
      map "ps:scale" => "ps_scale"
      option :formation, type: :hash, required: true
      option :version, type: :numeric, default: nil
      def ps_scale(appname)
        inside_machine_dir do
          with_docker_running do
            machine = SmartMachine::Machine.new
            command = [
              "smartengine app ps:scaler #{appname}"
            ]
            formation = options[:formation].map { |proctype, count| "#{proctype}:#{count}" }.join(' ')
            command.push("--formation=#{formation}") if options[:formation]
            command.push("--version=#{options[:version]}") if options[:version]
            machine.run_on_machine commands: command.join(" ")
          end
        end
      end

      desc "up [APPNAME]", "Take UP the app"
      option :version, type: :numeric, default: 0
      def up(appname)
        inside_machine_dir do
          with_docker_running do
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine app uper #{appname} --version=#{options[:version]}"
          end
        end
      end

      desc "down [APPNAME]", "Take DOWN the app"
      def down(appname)
        inside_machine_dir do
          with_docker_running do
            machine = SmartMachine::Machine.new
            machine.run_on_machine commands: "smartengine app downer #{appname}"
          end
        end
      end

      desc "creater", "App creator", hide: true
      def creater(appname, appdomain, username)
        inside_engine_machine_dir do
          app = SmartMachine::Apps::App.new(appname: appname, username: username)
          prereceiver_name, prereceiver_config = SmartMachine.config.grids.prereceiver.first
          app.creater(appdomain: appdomain, prereceiver_name: prereceiver_name)
        end
      end

      desc "destroyer", "App destroyer", hide: true
      def destroyer(appname)
        inside_engine_machine_dir do
          app = SmartMachine::Apps::App.new(appname: appname)
          app.destroyer
        end
      end

      desc "ps:scaler [APPNAME]", "Scale the app processes", hide: true
      map "ps:scaler" => "ps_scaler"
      option :formation, type: :hash, required: true
      option :version, type: :numeric, default: nil
      def ps_scaler(appname)
        inside_engine_machine_dir do
          manager = SmartMachine::Apps::Manager.new(appname: appname, appversion: options[:version])
          manager.ps_scaler(formation: options[:formation])
        end
      end

      desc "uper [APPNAME]", "App uper", hide: true
      option :version, type: :numeric, default: 0
      def uper(appname)
        inside_engine_machine_dir do
          app = SmartMachine::Apps::App.new(appname: appname)
          app.uper(version: options[:version])
        end
      end

      desc "downer [APPNAME]", "App downer", hide: true
      def downer(appname)
        inside_engine_machine_dir do
          app = SmartMachine::Apps::App.new(appname: appname)
          app.downer
        end
      end
    end
  end
end
