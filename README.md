# SmartMachine

Git push should deploy.

SmartMachine is a full-stack deployment framework for rails optimized for admin programmer happiness and peaceful administration. It encourages natural simplicity by favoring convention over configuration.

Before you begin, you should install ruby on your system.

Deploy your Rails apps to your own server with - git push production main

### How does it help?

After you run the below commands, you get.
1. Setup of basic best practices of setting up and securing a VPS server.
2. Setup and installation of Docker.
3. Setup and installation of docker based Mysql, Solr, Nginx, App Prereceiver.
4. Deployment of your Rails apps to your own server with - git push production main

### Prerequisites

If using SmartMachine on a server, perform the below steps before proceeding.

Ensure that you have debian LTS installed on the server.
Running the below command should say some latest version of debian LTS.

    $ cat /etc/issue

Then complete, getting started with linode.

    https://www.linode.com/docs/getting-started/

And then secure your server.

    https://www.linode.com/docs/security/securing-your-server/

## Installation

Install SmartMachine at the command prompt:

    $ gem install smartmachine

Then create a new machine and move into it:

    $ smartmachine new yourmachinename
    $ cd yourmachinename

here "yourmachinename" is the machine name you can choose

Add your credentials using:

    $ smartmachine credentials:edit

Add your environment details using: - Coming Soon

    $ smartmachine environment:edit

Add your users using:

    $ smartmachine grid nginx users:edit

Install docker, and add UFW rules for Docker if specified at the end of installation.

    $ smartmachine docker install

Install the engine and buildpacker:

    $ smartmachine engine install
    $ smartmachine buildpacker install rails

## Usage

### Choose Your Grids

Choose only the grids you need. You can start or stop a grid at anytime using <b>up</b> or <b>down</b> commands respectively.

#### 1. Nginx Grid
Lets you run a nginx web server fully equipped with https encryption using letsencrypt.
    
    $ smartmachine grid nginx up
    $ smartmachine grid nginx down

#### 2. Prereceiver Grid
Lets you push rails apps to your server without any additional configuration or downtime using <b>git push production main</b>.

    $ smartmachine grid prereceiver install
    $ smartmachine grid prereceiver up
    $ smartmachine grid prereceiver down
    $ smartmachine grid prereceiver uninstall

#### 3. Mysql Grid
Lets you run a mysql server instance with as many databases as you need.

    $ smartmachine grid mysql up
    $ smartmachine grid mysql down

#### 4. Minio Grid
Lets you run minio server instance with file storage persistance.

    $ smartmachine grid minio up
    $ smartmachine grid minio down

#### 5. Elasticsearch Grid
Lets you run elasticsearch server instance with data persistance.

    $ smartmachine grid elasticsearch up
    $ smartmachine grid elasticsearch down

#### 4. Redis Grid
Lets you run redis server instance for cache storage and job queueing.

    $ smartmachine grid redis up
    $ smartmachine grid redis down

#### 6. Scheduler Grid - Coming Soon
Lets you setup scheduling services like database backups, etc.

    $ smartmachine grid scheduler install
    $ smartmachine grid scheduler up
    $ smartmachine grid scheduler down
    $ smartmachine grid scheduler uninstall

### Setup Your Apps

Create your apps and manage them.

#### 1. New App on the server
Lets you create a new bare app on the server.

    $ smartmachine app create <APPNAME> <APPDOMAIN> <USERNAME>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/timeboardcode/smartbytes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/timeboardorg/smartmachine/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [AGPL License](https://www.gnu.org/licenses/agpl-3.0.html).

## Code of Conduct

Everyone interacting in the SmartMachine project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/timeboardorg/smartmachine/blob/main/CODE_OF_CONDUCT.md).
