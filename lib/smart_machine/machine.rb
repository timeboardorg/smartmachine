require "net/ssh"

module SmartMachine
  class Machine < SmartMachine::Base
    def initialize
    end

    # Create a new smartmachine
    #
    # Example:
    #   >> Machine.create("qw21334q")
    #   => "New machine qw21334q has been created."
    #
    # Arguments:
    #   name: (String)
    #   dev: (Boolean)
    def create(name:, dev:)
      raise "Please specify a machine name" if name.blank?

      pathname = File.expand_path "./#{name}"

      if Dir.exist?(pathname)
        puts "A machine with this name already exists. Please use a different name."
        return
      end

      FileUtils.mkdir pathname
      FileUtils.cp_r "#{SmartMachine.config.gem_dir}/lib/smart_machine/templates/dotsmartmachine/.", pathname
      FileUtils.chdir pathname do
        credentials = SmartMachine::Credentials.new
        credentials.create

        File.write("Gemfile", File.open("Gemfile",&:read).gsub("replace_ruby_version", "#{SmartMachine.ruby_version}"))
        File.write(".ruby-version", SmartMachine.ruby_version)
        if dev
          File.write("Gemfile", File.open("Gemfile",&:read).gsub("\"~> replace_smartmachine_version\"", "path: \"../\""))
        else
          File.write("Gemfile", File.open("Gemfile",&:read).gsub("replace_smartmachine_version", "#{SmartMachine.version}"))
        end
        system("mv gitignore-template .gitignore")

        # Here BUNDLE_GEMFILE is needed as it may be already set due to usage of bundle exec (which may not be correct in this case)
        bundle_gemfile = "#{pathname}/Gemfile"
        system("BUNDLE_GEMFILE='#{bundle_gemfile}' bundle install && BUNDLE_GEMFILE='#{bundle_gemfile}' bundle binstubs smartmachine")

        system("git init && git add . && git commit -m 'initial commit by SmartMachine #{SmartMachine.version}'")
      end

      puts "New machine #{name} has been created."
    end

    def initial_setup
      getting_started
      securing_your_server
    end

    def run_on_machine(commands:)
      commands = Array(commands).flatten
      ssh = SmartMachine::SSH.new
      status = ssh.run commands

      status[:exit_code] == 0
    end

    private

    def getting_started
      # apt install locales-all

      # puts 'You may be prompted to make a menu selection when the Grub package is updated on Ubuntu. If prompted, select keep the local version currently installed.'
      # apt update && apt upgrade

      # hostnamectl set-hostname SmartMachine.credentials.machine[:name]

      # The value you assign as your system’s FQDN should have an “A” record in DNS pointing to your Linode’s IPv4 address. For IPv6, you should also set up a DNS “AAAA” record pointing to your Linode’s IPv6 address.
      # Add DNS records for IPv4 and IPv6 for ip addresses and their fully qualified domain names FQDN
      # /etc/hosts
      # 203.0.113.10 SmartMachine.credentials.machine[:name].example.com SmartMachine.credentials.machine[:name]
      # 2600:3c01::a123:b456:c789:d012 SmartMachine.credentials.machine[:name].example.com SmartMachine.credentials.machine[:name]

      # dpkg-reconfigure tzdata
      # date
    end

    def securing_your_server
      # apt install unattended-upgrades
      # dpkg-reconfigure --priority=low unattended-upgrades

      # nano /etc/apt/apt.conf.d/20auto-upgrades
      # APT::Periodic::Update-Package-Lists "1";
      # APT::Periodic::Download-Upgradeable-Packages "1";
      # APT::Periodic::AutocleanInterval "7";
      # APT::Periodic::Unattended-Upgrade "1";

      # apt install apticron
      # /usr/lib/apticron/apticron.conf
      # EMAIL="root@example.com"

      # adduser example_user
      # adduser example_user sudo

      # mkdir -p ~/.ssh && sudo chmod -R 700 ~/.ssh/
      # scp ~/.ssh/id_rsa.pub example_user@203.0.113.10:~/.ssh/authorized_keys
      # sudo chmod -R 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

      # sudo nano /etc/ssh/sshd_config
      # PermitRootLogin no
      # PasswordAuthentication no
      # echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
      # sudo systemctl restart sshd

      # sudo apt update && sudo apt upgrade -y

      # sudo apt install ufw
      # sudo ufw default allow outgoing
      # sudo ufw default deny incoming
      # sudo ufw allow SmartMachine.credentials.machine[:port]/tcp
      # sudo ufw enable
      # sudo ufw logging on

      # sudo apt install fail2ban
      # sudo apt install sendmail
      # sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
      # sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      # Change destmail, sendername, sender
      # Change action = %(action_mwl)s
      # sudo fail2ban-client reload
      # sudo fail2ban-client status
    end
  end
end
