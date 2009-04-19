module ApacheServer
  def self.config_ok?
    system("apachectl -t >/dev/null 2>/dev/null")
  end
  def self.reload
    system("apachectl graceful >/dev/null 2>/dev/null")
  end
end
