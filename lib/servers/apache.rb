module ApacheServer
  def config_ok?
    system("apachectl -t")
  end
  def reload
    system("apachectl graceful")
  end
end
