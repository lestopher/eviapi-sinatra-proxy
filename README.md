Evisions Proxy Server
=====================
You can use this small proxy server to mirror another server somewhere else.

It's useful to use the public folder as a softlink and serve up the AWV project (or your own).

How To Use
==========
Make sure you get the dependencies:

    bundle install


You can only install eviapi if you have access to that [repo](https://github.com/lestopher/eviapi.git).
It will prompt you to authenticate if you don't have an ssh key.

Make sure the following folders exist (as real folders, not softlinks): **ssl**

Public can be a softlink, or be a real folder with softlinks in it. In ssl, drop in your cer and key files.

To run the proxy:

    bundle exec ruby proxy.rb -e 'http://your-endpoint-here/' -p 6443

Options for using a redis cache:
--use-redis => bool(true/false)
--redis (-r) => string(hostname) // Make sure you don't include any schemes like http or such
--redis-port (-d) => integer(6379)
