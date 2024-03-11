---
title: HAProxy http-response add-header on a redirect request
description: HAProxy doesn't add headers unless the request goes through haproxy, redirects are passed on without adding anything
date: "2021-10-30T21:26:03Z"
categories:
  - haproxy
tags:
  - haproxy
  - http-header
---


# Haproxy - unable to manipulate header on a redirect-request

When configuring the different things for Mastodon, I needed to configure .well-known/webfinger on my main domain, in such a way that CORS would pass through.

Using haproxy, this proved to be somewhat difficult - for some reason the normal `http-response add-header`-magic I was used to using, didn't work.

After some ducking', the culprit was found - which was something new to me.
Apparently, `http-request/http-response` is only processed when the request goes *through* haproxy, and it's silently ignored when haproxy simply sends the client somewhere else.

The solution is just as simple; `http-after-response` - see the sources for more info.

sources:

https://github.com/haproxy/haproxy/issues/4

https://cbonte.github.io/haproxy-dconv/2.2/configuration.html#http-after-response
