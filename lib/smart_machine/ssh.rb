require "net/ssh"

module SmartMachine
  class SSH < SmartMachine::Base
    def initialize
    end

    def run(*commands)
      commands.flatten!
      status = {}

      Net::SSH.start(SmartMachine.credentials.machine[:address], SmartMachine.credentials.machine[:username], { port: SmartMachine.credentials.machine[:port], password: SmartMachine.credentials.machine[:password] }) do |ssh|
        commands.each do |command|

          puts "\e[1m" + "$ " + command + "\e[0m"

          channel = ssh.open_channel do |channel|

            channel.on_open_failed do |channel, code, description|
              raise "could not open channel (#{description}, ##{code})"
            end

            ssh.listen_to(STDIN) do |stdin|
              input = stdin.readpartial(1024)
              channel.send_data(input) unless input.empty?
            end

            channel.request_pty :modes => { Net::SSH::Connection::Term::ECHO => 0 } do |channel, success|
              raise "could not obtain pty" unless success

              channel.exec command do |channel, success|
                raise "could not execute command: #{command.inspect}" unless success

                if status
                  channel.on_request("exit-status") do |ch2, data|
                    status[:exit_code] = data.read_long
                  end

                  channel.on_request("exit-signal") do |ch2, data|
                    status[:exit_signal] = data.read_long
                  end
                end

                channel.on_data do |ch2, data|
                  $stdout.print data

                  if (data[/\[sudo\]|Password/i])
                    channel.send_data "#{SmartMachine.credentials.machine[:password]}\n"
                  end
                end

                channel.on_extended_data do |ch2, type, data|
                  $stderr.print data
                end
              end
            end
          end

          channel.wait

          break if status[:exit_code] != 0
        end
      end

      status
    end

    def login
      exec "ssh -p #{SmartMachine.credentials.machine[:port]} #{SmartMachine.credentials.machine[:username]}@#{SmartMachine.credentials.machine[:address]}"
    end
  end
end
