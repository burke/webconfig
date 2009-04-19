module ApacheServer
  def self.config_ok?
    system("apachectl -t")
  end
  def self.reload
    system("apachectl graceful")
  end
end
