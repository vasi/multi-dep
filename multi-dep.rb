#!/usr/bin/env ruby

class DepSpec
  attr_reader :name, :op, :version

  def initialize(spec)
    md = /^(\S+)(?: \(([><=]+) (\S+)\))?/.match(spec)
    @name, @op, @version = *md.captures
  end
end

class DepAlt
  attr_reader :deps

  def initialize(spec)
    @deps = spec.split(/\s*\|\s*/).map {|s| DepSpec.new(s)}
  end

  def self.all(spec)
    return [] if spec.nil?
    spec.split(/\s*,\s*/).map {|s| DepAlt.new(s)}
  end
end

class Package
  def initialize(io)
    @fields = {}
    cur = nil
    while line = io.readline
      line.chomp!
      return if line.empty?
      if md = /^(\S+): (.*)/.match(line)
        cur = md[1]
        @fields[cur] = md[2]
      elsif md = /^\s+(.*)/.match(line)
        @fields[cur] += "\n" unless @fields[cur].include?("\n")
        data = md[1] == "." ? "" : md[1]
        @fields[cur] += "\n" + md[1]
      end
    end
  end

  def name
    @fields["Package"]
  end
  def version
    @fields["Version"]
  end
  def installed?
    @fields["Status"].end_with?("installed")
  end
  def requires
    @requires ||= DepAlt.all(@fields["Depends"])
  end

  def inspect
    "<Package name=#{name} version=#{version}>"
  end

  def self.parse
    packages = {}
    open('/var/lib/dpkg/status') do |f|
      until f.eof?
        pkg = Package.new(f)
        packages[pkg.name] = pkg if pkg.installed?
      end
    end
    packages
  end
end

packages = Package.parse
pp packages['apache2-bin'].requires
