require 'thor'
require 'smart_machine'

require 'smart_machine/commands/utilities'

require 'smart_machine/commands/app'
require 'smart_machine/commands/buildpacker'
require 'smart_machine/commands/credentials'
require 'smart_machine/commands/docker'
require 'smart_machine/commands/engine'
require 'smart_machine/commands/grid'
require 'smart_machine/commands/machine'
require 'smart_machine/commands/syncer'

module SmartMachine
  module Commands
    class CLI < Thor
      include Utilities

      def self.exit_on_failure?
        true
      end

      desc "new [NAME]", "Creates a new machine using the given name"
      option :dev, type: :boolean, default: false
      def new(name)
        raise "Can't create a machine inside a machine. Please come out of the machine directory to create another machine." if in_machine_dir?

        machine = SmartMachine::Machine.new
        machine.create(name: name, dev: options[:dev])
      end

      desc "--version", "Shows the current SmartMachine version"
      map ["--version", "-v"] => :version
      def version
        puts "SmartMachine #{SmartMachine.version}"
      end

      desc "app", "Run app commands"
      subcommand "app", App

      desc "buildpacker", "Run buildpacker commands"
      subcommand "buildpacker", Buildpacker

      desc "credentials:edit", "Allows editing the credentials"
      subcommand "credentials:edit", Credentials

      desc "docker", "Run docker commands"
      subcommand "docker", Docker

      desc "engine", "Run engine commands"
      subcommand "engine", Engine

      desc "grid", "Run grid commands"
      subcommand "grid", Grid

      desc "machine", "Run machine commands"
      subcommand "machine", Machine

      desc "syncer", "Run syncer commands"
      subcommand "syncer", Syncer
    end
  end
end

SmartMachine::Commands::CLI.start(ARGV)
