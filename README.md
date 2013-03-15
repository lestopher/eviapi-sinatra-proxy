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

To run the proxy:

    ruby proxy.rb 'http://your-endpoint-here/' true

There are a few options that you can pass in: the endpoint and a flag that tells the proxy if you want to reload the local codebase files everytime (avoid caching)
