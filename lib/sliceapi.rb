#!/usr/bin/env ruby

require 'rubygems'
require 'activeresource'

SITE = "https://#{File.read(File.join(File.dirname(__FILE__),'api_key.txt')).strip}@api.slicehost.com/"
OGLAROON="209.20.65.91"

class ZoneCreator
  
  class Zone < ActiveResource::Base
    self.site =  "https://#{File.read(File.join(File.dirname(__FILE__),'api_key.txt')).strip}@api.slicehost.com/"
  end

  class Record < ActiveResource::Base
    self.site =  "https://#{File.read(File.join(File.dirname(__FILE__),'api_key.txt')).strip}@api.slicehost.com/"
  end

  
  def initialize(domain, mail)
    @mail   = mail
    @domain = domain
    @fqdn   = "#{domain}."
    
    create_zone
    create_records
  end
  
  def create_zone
    zone = Zone.new(:origin => @domain, :ttl => 3600)
    zone.save
    @zid = zone.id
  end 
  
  def create_records
    create_A(@fqdn, OGLAROON)
    for i in 1..3 do
      create_NS(@fqdn, "ns#{i}.slicehost.net.")
    end
    create_CNAME("*.#{@fqdn}", @fqdn)
    if @mail
      create_CNAME("mail.#{@fqdn}", 'ghs.google.com.')
      create_MX(@fqdn, "ASPMX.L.GOOGLE.COM.", 10)
      create_MX(@fqdn, "ALT1.ASPMX.L.GOOGLE.COM.", 20)
      create_MX(@fqdn, "ALT2.ASPMX.L.GOOGLE.COM.", 20)
      create_MX(@fqdn, "ASPMX2.GOOGLEMAIL.COM.", 30)
      create_MX(@fqdn, "ASPMX3.GOOGLEMAIL.COM.", 30)
      create_MX(@fqdn, "ASPMX4.GOOGLEMAIL.COM.", 30)
      create_MX(@fqdn, "ASPMX5.GOOGLEMAIL.COM.", 30)
    end
  end
  
  def create_A(name, data)
    Record.new(
      :record_type => 'A', 
      :zone_id => @zid,
      :name => name,
      :data => data).save
  end
  
  def create_CNAME(name, data)
    Record.new(
      :record_type => 'CNAME', 
      :zone_id => @zid,
      :name => name,
      :data => data).save
  end
  
  def create_NS(name, data)
    Record.new(
      :record_type => 'NS', 
      :zone_id => @zid,
      :name => name,
      :data => data).save
  end 
  
  def create_MX(name, data, aux)
    Record.new(
      :record_type => 'MX', 
      :zone_id => @zid,
      :name => name,
      :data => data,
      :aux => aux).save
  end

end

