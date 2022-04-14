# The main SmartMachine Grids Solr driver
module SmartMachine
	class Grids
		class Solr < SmartMachine::Base
			def initialize
			end

			def up(*args)
				args.flatten!
				exposed = args.empty? ? '' : args.shift

				if SmartMachine::Docker.running?
					# Creating networks
					unless system("docker network inspect solr-network", [:out, :err] => File::NULL)
						print "-----> Creating network solr-network ... "
						if system("docker network create solr-network", out: File::NULL)
							puts "done"
						end
					end

					# Creating & Starting containers
					print "-----> Creating container solr ... "
					if system("docker create \
						--name='solr' \
						--user `id -u`:`id -g` \
						#{"--publish='8983:8983'" if exposed == '--exposed'} \
						--volume='#{SmartMachine.config.user_home_path}/.smartmachine/grids/solr/solr:/var/solr' \
						--restart='always' \
						--network='solr-network' \
						solr:8.2.0", out: File::NULL)

						puts "done"
						print "-----> Starting container solr ... "
						if system("docker start solr", out: File::NULL)
							puts "done"
						end
					end
				end
			end
	
			def down
				if SmartMachine::Docker.running?
					# Stopping & Removing containers - in reverse order
					print "-----> Stopping container solr ... "
					if system("docker stop 'solr'", out: File::NULL)
						puts "done"
						print "-----> Removing container solr ... "
						if system("docker rm 'solr'", out: File::NULL)
							puts "done"
						end
					end

					# Removing networks
					print "-----> Removing network solr-network ... "
					if system("docker network rm solr-network", out: File::NULL)
						puts "done"
					end
				end
			end

			# TODO: self.create_core method must be checked line by line to see if its working properly for solr8 and above
			def self.create_core(*args)
				args.flatten!
				corename = args.empty? ? '' : args.shift

				if SmartMachine::Docker.running?
					puts "-----> Creating core #{corename} ... "
					if system("docker exec -it --user=solr solr solr create_core -c #{corename}")
						system("docker exec -it --user=solr solr solr config -c #{corename} -p 8983 -action set-user-property -property update.autoCreateFields -value false")
						puts "done"

						print "-----> Copying core files ... "
						system("sudo cp -r #{SmartMachine.config.root_path}/lib/smart_machine/grids/solr/sunspot/conf/* #{SmartMachine.config.user_home_path}/.smartmachine/grids/solr/data/#{corename}/conf/")
						if system("sudo chown -R 8983:8983 #{SmartMachine.config.user_home_path}/.smartmachine/grids/solr/data/#{corename}/conf", out: File::NULL)
							puts "done"
						end
					else
						puts "error"
					end
				end
			end

			# TODO: self.destroy_core method must be checked line by line to see if its working properly for solr8 and above
			def self.destroy_core(*args)
				args.flatten!
				corename = args.empty? ? '' : args.shift

				if SmartMachine::Docker.running?
					puts "-----> Removing core #{corename} ... "
					if system("docker exec -it --user=solr solr solr delete -c #{corename}")
						puts "done"
					else
						puts "error"
					end
				end
			end
		end
	end
end