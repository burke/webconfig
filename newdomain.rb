#!/usr/bin/env ruby
# -*- ruby -*-

# ./newdomain --domain domain.com --user burke -g -c
# -g switches google MX/CNAME records on
# -c switches capistrano support on

%W{webconfig sliceapi}.each do |file|
  require File.join(File.dirname(__FILE__),'lib',file)
end

require 'rubygems'
require 'yaml'
require 'optiflag'

class Domain
  BASE_PATH = '/opt/webconfig'
  CONFIG_PATH    = "#{BASE_PATH}/config/config.yml"
  TEMPLATES_PATH = "#{BASE_PATH}/config/templates.yml"
  
  def initialize(args)
    
    args[:type]       ||= 'static'
    args[:capistrano] ||= false

    args.each do |key,value|
      next unless key.to_s.match /\w+/ or instance_variables.include? key
      instance_variable_set "@#{key}", value
    end  
  end

  def run
    puts '-'*80
    display_info
    puts '-'*80

    ask_for_permission
    puts '-'*80

    write_config
    set_dns
    make_directories
    compile_vhosts
  end

  private 

  def ask_for_permission
    puts "add this domain? [yes/no]"
    exit 1 unless $stdin.gets =~ /y|yes/i
  end

  def display_info
    puts "Domain: #{@domain}"
    puts "type:   #{@type}"
    puts "user:   #{@user}"

    puts "with:"if [@capistrano,@google].any?
    puts " -> Capistrano enabled" if @capistrano       
    puts " -> Google MX/CNAME enabled" if @google
    puts " -> Rails ENV: #{@railsenv || 'development'}" if @type.match /rack|rails/
  end

  def write_config  
    puts "Setting vhost Information ..."
    hosts  = YAML.load(open(CONFIG_PATH))
    tmp    = {@domain => {'location'   => @user, 
                          'template'   => @type,
                          'capistrano' => @capistrano}}

    hosts.merge!(tmp)

    `cp #{CONFIG_PATH} #{CONFIG_PATH}.last`

	  File.open(CONFIG_PATH, 'w') do |f|
    	f.puts YAML.dump(hosts)
	  end
  end

  def set_dns
    puts "Setting DNS information ..."
    ZoneCreator.new(@domain,@google)
  end

  def compile_vhosts
    Webconfig.run #now we can very simply get a report on any issues
  end

  def make_directories

    unless @type.match /alias/
	    puts "making needed directories"

      if  @type.match /rails|rack/
        dir = "/srv/#{@type}/#{@domain}"
        dir += "/current" if @capistrano
      else
        if @capistrano
          dir = "/srv/http/#{@user}/#{@domain}/current/htdocs"
        else
          dir = "/srv/http/#{@user}/#{@domain}/htdocs"
        end
      end
      
      `mkdir -p #{dir}`
    end
  end
end

module DomainFlags extend OptiFlagSet
  flag "domain" do
    description 'domain you wish to add'
    alternate_forms  "d"

    #this needs to happen globally. but optiflag does not seem to allow for this
    validates_against do |flag, errors|
		  errors << "This script must be run as root." if `whoami` !~ /root/ 
    end
    
      validates_against do |flag,errors|
        hosts = YAML.load(open(Domain::CONFIG_PATH))
	      hosts.each do |key , value |
		      if( key == flag.value && value['Location'] == ARGV.flags.user)
			      errors << "Domain already configured"
			      break
		      end
        end
      end
    end
  
    optional_switch_flag "google" do
      description 'google apps flag'
      alternate_forms 'g'
    end

    optional_switch_flag "capistrano" do
      description 'capistrano flag'
      alternate_forms 'c'
    end

    optional_flag "railsenv" do
      description 'rails environment flag'
      alternate_forms 'r'
    end

    flag "user" do
      description 'the domains user'
      alternate_forms "u"
    end
  
    optional_flag "type" do
      templates = YAML.load(open(Domain::TEMPLATES_PATH)).map { |key,value| key }
      alternate_forms "t"
      value_in_set(templates)
    end

    usage_flag :h ,:help
    extended_help_flag "superhelp"

    and_process!
  end

Domain.new(ARGV.flags).run if __FILE__ == $0
