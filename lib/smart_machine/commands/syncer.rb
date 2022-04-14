module SmartMachine
  module Commands
    class Syncer < Thor
      include Utilities

      desc "sync", "Sync files"
      def sync
        inside_machine_dir do
          syncer = SmartMachine::Syncer.new
          syncer.sync
        end
      end

      desc "rsync", "Run rsync command. System command. Should not be used by user.", hide: true
      def rsync(*args)
        inside_engine_machine_dir do
          syncer = SmartMachine::Syncer.new
          syncer.rsync(args)
        end
      end
    end
  end
end
