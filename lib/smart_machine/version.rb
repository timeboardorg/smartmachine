# frozen_string_literal: true

module SmartMachine
  # Returns the version of the currently loaded SmartMachine as a <tt>Gem::Version</tt>.
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  def self.version
    self.gem_version.to_s
  end

  def self.ruby_version
    RUBY_VERSION::STRING
  end

  module VERSION
    MAJOR = 0
    MINOR = 9
    TINY  = 0
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end

  module RUBY_VERSION
    MAJOR = 2
    MINOR = 7
    TINY  = 0
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end
