module SmartMachine
  class SCP < SmartMachine::Base
    def initialize
      @address  = SmartMachine.credentials.machine[:address]
      @port     = SmartMachine.credentials.machine[:port]
      @username = SmartMachine.credentials.machine[:username]
      @password = SmartMachine.credentials.machine[:password]
    end

    def upload!(local_path:, remote_path:)
      system("scp -q -P #{@port} #{local_path} #{@username}@#{@address}:#{remote_path}")
      $?
    end
  end
end
