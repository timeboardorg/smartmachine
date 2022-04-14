require 'smart_machine/commands/grid_commands/sub_thor'
require 'smart_machine/commands/grid_commands/elasticsearch'
require 'smart_machine/commands/grid_commands/minio'
require 'smart_machine/commands/grid_commands/mysql'
require 'smart_machine/commands/grid_commands/nginx'
require 'smart_machine/commands/grid_commands/prereceiver'
require 'smart_machine/commands/grid_commands/redis'

module SmartMachine
  module Commands
    class Grid < Thor
      include Utilities

      desc "elasticsearch", "Run elasticsearch grid commands"
      subcommand "elasticsearch", GridCommands::Elasticsearch

      desc "minio", "Run minio grid commands"
      subcommand "minio", GridCommands::Minio

      desc "mysql", "Run mysql grid commands"
      subcommand "mysql", GridCommands::Mysql

      desc "nginx", "Run nginx grid commands"
      subcommand "nginx", GridCommands::Nginx

      desc "prereceiver", "Run prereceiver grid commands"
      subcommand "prereceiver", GridCommands::Prereceiver

      desc "redis", "Run redis grid commands"
      subcommand "redis", GridCommands::Redis
    end
  end
end
