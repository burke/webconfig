# Webconfig

## Description

Webconfig is a tool to generate Virtual Host configuration files for web servers. I use it to manage Apache and Nginx, but I'm sure you could find additional uses for it.

## Installation

Basically, just unpack this wherever you want. I like to keep it in `/opt/webconfig`.

## How to use

The two files you need to worry about are `templates.yml` and `config.yml`. `templates.yml` specifies all the different configuration templates you'll be plugging data into. It should make a whole lot of sense once you look at the file. Every template will have one or more "content_for_FOO" keys. When you run Webconfig, it concatenates all the content_for_FOO template content, with domain info interpolated, into `gen/FOO.gen.conf`. 

The domain info is pulled from `config.yml`. I've provided `config.sample.yml`, which is a configuration I was using on my server at one point. Domains are listed with a number of parameters, each of which is translated into an instance variable before parsing the requested template for the domain.

Note that there's very little or no syntax checking on any of these config files. Be careful.

## How to make your servers use the new configuration

For apache, find your httpd.conf. There's very likely a line that says something along the lines of "Include vhosts/*.conf". You can replace that with "Include /opt/webconfig/gen/apache.gen.conf".

For nginx, find your nginx.conf, and add a line somewhere in the `http{ }` block: "include /opt/webconfig/gen/nginx.gen.conf".

For other servers, you're on your own. Most configuration file syntaxes have some sort of include directive.
