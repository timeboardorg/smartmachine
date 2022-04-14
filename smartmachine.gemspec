# frozen_string_literal: true

require_relative 'lib/smart_machine/version'

Gem::Specification.new do |s|
  s.platform    	= Gem::Platform::RUBY
  s.name        	= "smartmachine"
  s.version     	= SmartMachine.version
  s.summary     	= "Full-stack deployment framework for Rails."
  s.description 	= "SmartMachine is a full-stack deployment framework for rails optimized for admin programmer happiness and peaceful administration. It encourages natural simplicity by favoring convention over configuration."

  s.required_ruby_version     = Gem::Requirement.new(">= #{SmartMachine.ruby_version}")
  s.required_rubygems_version = ">= 1.8.11"

  s.license     	= "AGPL-3.0-or-later"

  s.author       	= "Gaurav Goel"
  s.email       	= "gaurav@timeboard.me"
  s.homepage    	= "https://github.com/timeboardorg/smartmachine"

  s.files        	= Dir["LICENSE.txt", "README.md", "bin/**/*", "bin/**/.keep", "lib/**/*", "lib/**/.keep"]
  s.require_path        = "lib"

  s.bindir              = "exe"
#  s.executables 	= %w(buildpacker prereceiver scheduler smartmachine smartrunner)
  s.executables 	= ["smartmachine"]

  s.metadata		= {
    "homepage_uri"      => s.homepage,
    "bug_tracker_uri"   => "https://github.com/timeboardorg/smartmachine/issues",
    "changelog_uri"     => "https://github.com/timeboardorg/smartmachine/releases/tag/v#{s.version}",
    # "documentation_uri" => "https://www.timeboard.org/about/software/smartmachine/api/v#{s.version}/",
    # "mailing_list_uri"  => "https://www.timeboard.org/about/software/smartmachine/discuss",
    "source_code_uri"   => "https://github.com/timeboardorg/smartmachine/tree/v#{s.version}/smartmachine"
  }

  s.add_dependency "net-ssh", "~> 6.1"
  s.add_dependency "bcrypt", "~> 3.1", ">= 3.1.13"
  s.add_dependency "activesupport", "~> 6.0"
  s.add_dependency "thor", '~> 1.0', '>= 1.0.1'
  s.add_dependency "bundler", '>= 2.1.4', "< 3.0.0"
  s.add_dependency "whenever", "~> 1.0"
end
