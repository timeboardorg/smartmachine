require 'smart_machine/logger'
require "active_support/inflector"

module SmartMachine
  class Base
    include SmartMachine::Logger

    def initialize
    end

    def platform_on_machine?(os:, distro_name: nil)
      case os
      when "linux"
        command = "(uname | grep -q 'Linux')"
        command += " && (cat /etc/os-release | grep -q 'NAME=\"Debian GNU/Linux\"')" if distro_name == "debian"
      when "mac"
        command = "(uname | grep -q 'Darwin')"
      end

      machine = SmartMachine::Machine.new
      command ? machine.run_on_machine(commands: command) : false
    end

    def machine_has_engine_installed?
      machine = SmartMachine::Machine.new
      machine.run_on_machine(commands: ["which smartengine | grep -q '/smartengine'"])
    end
  end
end
