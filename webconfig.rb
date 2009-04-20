#!/usr/bin/env ruby
# -*- ruby -*-

# Copyright 2009 Burke Libbey / Chromium 53. Released under MIT License.

$LOAD_PATH << File.join(File.dirname(__FILE__),'lib')

begin
  require 'rubygems'
rescue LoadError
end
require 'yaml'

# No syntax checking whatsoever on the yaml files. You're on your own.

module Webconfig

  WEBCONFIG_PATH = File.dirname(__FILE__)
  CONFIG_PATH    = File.join(WEBCONFIG_PATH,'config')
  DEFAULTS       = YAML.load_file("#{CONFIG_PATH}/defaults.yml")
  TEMPLATES      = YAML.load_file("#{CONFIG_PATH}/templates.yml")
  DOMAINS        = YAML.load_file("#{CONFIG_PATH}/config.yml")
 
  class ConfigError < StandardError; end
  class ReloadError < StandardError; end
  
  # Get a list of the different servers templates.yml specifies configs for.
  # example: ["nginx", "apache"]
  SERVERS = TEMPLATES.values.map(&:keys).flatten.uniq.map{|s|s.gsub('content_for_','')}

  def self.run
    puts "Building configuration..."

    config = Webconfig.config_by_server

    # Write out a file in ./gen for each server configured. 
    config.each do |server, config|
      File.open("#{Webconfig::WEBCONFIG_PATH}/gen/#{server}.gen.conf",'w') do |f|
        f.puts config
      end
    end

    puts "Testing new configuration..."
  
    unless Webconfig.test_configs
      raise ConfigError, "SERVERS REPORTED CONFIG ERRORS. NOT RELOADING."
    end

    puts "Config OK. Reloading Servers..."
  
    unless Webconfig.load_configs
      raise ReloadError, "SERVERS REPORTED ERRORS WHILE RELOADING. INVESTIGATE IMMEDIATELY."
    end

    puts "All OK."
  end

    # Return a hash of configuration files by server. Eg. {"apache" => "<VirtualHost *>........"}
  def self.config_by_server
    SERVERS.inject({}) do |hash, server|
      hash.merge({server => config_for_server(server)})
    end
  end
  
  def self.config_for_server(server)
    relevant_templates = TEMPLATES.reject{|k,v| ! v.has_key?("content_for_#{server}")}
    output = ""
    
    # Each domain of a template type that specifies configuration for this server
    relevant_domains = DOMAINS.reject do |domain, args|
      ! relevant_templates.keys.include?(args['template'])
    end
    relevant_domains.inject("") do |output, domain|
      # Add the domain name (hash key) to the args (hash value)
      domaininfo = domain[1].merge({"domain" => domain[0]})
      output << Domain.new(domaininfo).content_for_server(server)
    end

  end

  def self.test_configs
    SERVERS.inject(true) do |all_ok, server|
      ok = Server.new(server).config_ok?
      unless ok
        puts ">> Config check failed for server: #{server}."
      end
      all_ok && ok
    end
  end

  def self.load_configs
    SERVERS.inject(true) do |all_ok, server|
      ok = Server.new(server).reload
      unless ok
        puts ">> Reload seems to have failed for server: #{server}."
      end
      all_ok && ok
    end
  end
  
  class Server

    def initialize(name)
      @name = name
      srv_mod_name = "#{name.capitalize}Server"
      unless Object.const_defined?(srv_mod_name)
        begin
          require "servers/#{@name}"
        rescue LoadError
          puts ">> Don't know how to interact with server: #{@name}."
          puts "   Restart it manually or define rules in lib/servers/#{@name}.rb"
          @srv_mod = false
        end
      end
      @srv_mod = Object.const_get(srv_mod_name)
    end

    def reload
      @srv_mod ? @srv_mod::reload : true
    end

    def config_ok?
      @srv_mod ? @srv_mod::config_ok? : true
    end
    
  end
  
  class Domain

    def initialize(args)
      # This might be dangerous? I'm pretty sure we can trust whomever's
      # writing our vhost definitions :)
      args = DEFAULTS.merge args
      args.each do |k,v|
        instance_variable_set "@#{k}", v
      end

      # We need to wrap @location in slashes, but if it's root, that gives us
      #   // or ///, so we collapse multiple sequential slashes to a single /.
      @location = "/#{@location}/"
      @location.gsub!(/\/+/,'/')
    end

    def content_for_server(server)
      cfs = "content_for_#{server}"
      begin
       eval("return <<-\"SOMEUNUSUALTOKEN_END\"

#{Webconfig::TEMPLATES[@template][cfs]}

        SOMEUNUSUALTOKEN_END")
      rescue
        raise SyntaxError, "Invalid syntax in configuration files. Failed parsing #{domain}."
      end
    end
  end
end


Webconfig.run if __FILE__ == $0
