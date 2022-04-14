module SmartMachine
  module Commands
    class Credentials < Thor
      include Utilities

      default_task :edit

      desc "edit", "Allows editing the credentials"
      def edit
        inside_machine_dir do
          credentials = SmartMachine::Credentials.new
          credentials.edit
        end
      end
    end
  end
end
