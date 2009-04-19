module NginxServer
  def config_ok?
    system("nginx -t")
  end
  def reload
    puts "*** WON'T RELOAD NGINX UNTIL PASSENGER FIXES `kill -HUP` ISSUE. RESTART MANUALLY. ***"
    return false
  end
end
