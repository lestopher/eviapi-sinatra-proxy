Evisions Proxy Server
=====================
You can use this small proxy server to mirror another server somewhere else.

It's useful to use the public folder as a softlink and serve up the AWV project (or your own).

How To Use
==========
Make sure that you have the following gems installed: Sinatra, Thin, Eviapi

    gem install sinatra
    gem install thin

You can only install eviapi if you have access to that [repo](https://github.com/lestopher/eviapi.git)

Make sure the following folders exist (as real folders, not softlinks): **public, ssl**

In public, you can create softlinks to your codebase. In ssl, drop in your cer and key files.

To run the proxy:

    ruby proxy.rb 'http://your-endpoint-here/' 

There are a few options that you can pass in: the endpoint and a port that tells the proxy what port you want it bound to (in case you want to have multiple proxies running) 
