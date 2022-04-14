module SmartMachine
  module Commands
    class Machine < Thor
      include Utilities

      desc "ssh", "SSH into the machine"
      def ssh
        inside_machine_dir do
          ssh = SmartMachine::SSH.new
          ssh.login
        end
      end

      desc "run [COMMAND]", "Run commands on the machine"
      map ["run"] => :runner
      def runner(*args)
        inside_machine_dir do
          machine = SmartMachine::Machine.new
          machine.run_on_machine(commands: "#{args.join(' ')}")
        end
      end
    end
  end
end
