module SmartMachine
  module Buildpackers
    class Buildpacker < SmartMachine::Base
      def initialize(packname:)
        @packname = packname
      end

      def installer
        if @packname == "rails"
          unless system("docker image inspect #{rails_image_name}", [:out, :err] => File::NULL)
            print "-----> Creating image #{rails_image_name} ... "
            command = [
              "docker image build -t #{rails_image_name}",
              "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
              "--build-arg USER_UID=`id -u`",
              "--build-arg USER_NAME=`id -un`",
              "#{SmartMachine.config.gem_dir}/lib/smart_machine/buildpackers/rails"
            ]
            if system(command.join(" "), out: File::NULL)
              puts "done"
            end
          end
        else
          raise "Error: Pack with name #{name} not supported."
        end
      end

      def uninstaller
        if @packname == "rails"
          if system("docker image inspect #{rails_image_name}", [:out, :err] => File::NULL)
            print "-----> Removing image #{rails_image_name} ... "
            if system("docker image rm #{rails_image_name}", out: File::NULL)
              puts "done"
            end
          end
        else
          raise "Error: Pack with name #{name} not supported."
        end
      end

      def packer
        if @packname == "rails" && File.exist?("bin/rails")
          rails = SmartMachine::Buildpackers::Rails.new(appname: nil, appversion: nil)
          rails.packer
        else
          raise "Error: Pack with name #{@packname} not supported."
        end
      end

      private

      def rails_image_name
        "smartmachine/buildpackers/rails:#{SmartMachine.version}"
      end

      # These swapfile methods can be used (after required modification), when you need to make swapfile for more memory.
      # def self.create_swapfile
      # 	# Creating swapfile for bundler to work properly
      # 	unless system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
      # 		print "-----> Creating swap swapfile ... "
      # 		system("sudo install -o root -g root -m 0600 /dev/null /swapfile", out: File::NULL)
      # 		system("sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k", [:out, :err] => File::NULL)
      # 		system("sudo mkswap /swapfile", out: File::NULL)
      # 		system("sudo sh -c 'echo \"/swapfile       none    swap    sw      0       0\" >> /etc/fstab'", out: File::NULL)
      # 		system("echo 10 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
      # 		system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
      # 		system("echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf", out: File::NULL)
      # 		puts "done"
      #
      # 		print "-----> Starting swap swapfile ... "
      # 		if system("sudo swapon /swapfile", out: File::NULL)
      # 			puts "done"
      # 		end
      # 	end
      # end
      #
      # def self.destroy_swapfile
      # 	if system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
      # 		print "-----> Stopping swap swapfile ... "
      # 		if system("sudo swapoff /swapfile", out: File::NULL)
      # 			system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
      # 			system("echo 60 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
      # 			puts "done"
      #
      # 			print "-----> Removing swap swapfile ... "
      # 			system("sudo sed -i '/^\\/swapfile/d' /etc/fstab", out: File::NULL)
      # 			if system("sudo rm /swapfile", out: File::NULL)
      # 				puts "done"
      # 			end
      # 		end
      # 	end
      # end
    end
  end
end
