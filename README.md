QQ
==

QQ is a wrapper over curl for making remote calls inside vim.

Usage
-----

QQ works by specifying the a remote request in a REQUEST buffer. Once executed
the response is returned in a RESPONSE buffer. All executed requests are stored
in default collection file (~/.QQ.default.collection by default), and can be
accessed via the HISTORY buffer.

###Request format###
Requests are defined in the following formats:

```
<option name>: <option value> 
<option name>: :<option key>: <option value>
```

###Request options###
These are the current accepted request options

`URL: <url>`

Target URL, at present only the first URL option will be processed. URL's can
also make use of URL parameter names in the format of `:<url parameter name>:`.

`URL-PARAM: :<url parameter name>: <url parameter value>`

URL parameter, this option will replace instances of `:<url parameter name>:`
present in the URL with the specified `<url parameter value>`. Only the name of
the parameter is stored in the history this should be useful for sensitive
information.

`METHOD: <method>`
 
Request method, any method should be acceptable here but may be limited by your
executable. At present only the first method will be processed

`HEADER: :<header name>: <header value>`

Header definition, all headers should be supported, you can have as many of
these as you like

`OPTION: :<option name>: <option value>`

QQ option, these are used to alter the way that QQ handles storing requests and
displaying response's. Current option options are:

* `pretty-print` passes response through a JSON pretty printer.
* `follow` if this option is set to true the response will follow all redirects,
  otherwise will only return the first response

`DATA: :<data name>: <data value>`

Data field, this is data sent to the URL, for example form field's sent as part
of a post request 

`DATA-FILE: :<data name>: <file location>`

File field, this file will be uploaded to the given URL with the specified name. 

`BODY: <body>`

Body, at the moment this does nothing :)

###Key binds###

**from a normal buffer**

* `QQ` opens a new request window
* `QH` opens the recent request history

**from a REQUEST buffer**

* `QQ` executes the current request as defined in the buffer
* `QP` adds the JSON pretty-printing option to the current request
* `QBA` adds basic authentication to the current request
* `QH` opens the recent request history

**from a RESPONSE buffer**

* `QQ` returns to the previous REQUEST buffer
* `QH` opens the recent request history

**from a HISTORY buffer**

* `<CR>` loads previous request into REQUEST buffer

###Example request###

```
METHOD:	POST
URL:	http://example.com/:test-param:/upload
URL-PARAM: :test-param: supersecretkey
HEADER:	:Cache-Control: no-cache
OPTION:	:pretty-print: True
OPTION:	:follow: True
DATA: :email: bob@example.com
DATA: :name: Bob McBobson
DATA-FILE: :photo: ~/Photos/notporn.jpg
```

Options
-------

List of configurable options for the plugin:

* `g:QQ_curl_executable` the executable to run request's with. default `'curl'`
* `g:QQ_default_collection` location of the default history collection. default:
  `'~/.QQ.default.collection'`
* `g:QQ_current_collection` location of the loaded collection. default
  `g:QQ_default_collection`
* `g:QQ_collection_window_location` position of the collection window,
   acceptable values are `'top'` and `'bottom'`. default `'top'`
* `g:QQ_collection_window_height` height of collection window. default `10`

Notes
-----

* This is very much a work in progress, if anything breaks let us know at:
  [https://github.com/letolab/QQ.vim/issues](https://github.com/letolab/QQ.vim/issues)
* It's also still missing features...
* And is more than a bit hacky in places.
* QQ is probably a working title.
* Yes `Q` is a useful key bind, some more and better thought will probably go
  into more intelligent binds later.
* QQ is modeled on [Postman](http://www.getpostman.com/).
* QQ may or may not be windows compatible. (it almost certainly isn't)  
