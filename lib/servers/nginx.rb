module NginxServer
  def self.config_ok?
    system("/opt/nginx/current/sbin/nginx -t >/dev/null 2>/dev/null")
  end
  def self.reload
    system("kill -HUP `ps ax | grep 'nginx: master' | grep -v grep | head -n1 | awk '{print $1}'`")
  end
end
