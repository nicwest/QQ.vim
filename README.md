[![Build Status](https://travis-ci.org/nicwest/QQ.vim.svg?branch=master)](https://travis-ci.org/nicwest/QQ.vim)
[![Stories in Ready](https://badge.waffle.io/nicwest/QQ.vim.png?label=ready&title=Ready)](https://waffle.io/nicwest/QQ.vim)
QQ
==

QQ is a wrapper over curl for making remote calls inside vim.

[GIFS!](GIFS.md)

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
also make use of URL variable names in the format of `:<url variable name>:`.

`URL-VAR: :<url variable name>: <url variable value>`

URL variable, this option will replace instances of `:<url variable name>:`
present in the URL with the specified `<url variable value>`. Only the name of
the variable is stored in the history this should be useful for sensitive
information.

`URL-PARAM: :<url parameter name>: <url parameter value>`

URL parameter, this option will add GET parameters to a URL, e.g. 
`:test: foobar` will append `?test=foobar` to the end of the given URL

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

`FORM: :<field name>: <field value>`

Data field, this is data sent to the URL, for example form field's sent as part
of a post request 

`FORM-FILE: :<field name>: <file location>`

File field, this file will be uploaded to the given URL with the specified name. 

`BODY: <body>`

Body, sends everything after this as raw POST body. 

###Key binds###

**from a normal/any buffer**

* `QQ` opens a new request window
* `QH` opens the recent request history
* `QCO` opens the collection list
* `QCC` change current collection
* `QCN` add a new collection
* `QG` opens a new request window with URL under cursor as URL

**from a REQUEST buffer**

* `QQ` executes the current request as defined in the buffer
* `QP` adds the JSON pretty-printing option to the current request
* `QF` adds the follow option to current request (follows HTTP redirects)
* `QAB` adds basic authentication to the current request
* `QAO` adds oAuth2 to the current request

**from a RESPONSE buffer**

* `QQ` returns to the previous REQUEST buffer
* `q` closes the buffer

**from a HISTORY buffer**

* `<CR>` loads previous request into REQUEST buffer
* `q` closes the buffer

**from a COLLECTIONS buffer**

* `<CR>` open collection under cursor and set as current
* `q` closes the buffer

###Example request###

```
METHOD:	POST
URL:	http://example.com/:test-var:/upload
URL-VAR: :test-var: supersecretkey
URL-PARAM: :format: json
HEADER:	:Cache-Control: no-cache
OPTION:	:pretty-print: True
OPTION:	:follow: True
FORM: :email: bob@example.com
FORM: :name: Bob McBobson
FORM-FILE: :photo: ~/Photos/notporn.jpg
```

Options
-------

List of configurable options for the plugin:

* `g:QQ_curl_executable` the executable to run request's with. default `'curl'`
* `g:QQ_python_executable` the executable preferred python2 executable `'python'`
* `g:QQ_default_collection` location of the default history collection. default:
  `'~/.QQ.default.collection'`
* `g:QQ_current_collection` location of the loaded collection. default
  `g:QQ_default_collection`
  `g:QQ_collection_list` location of the collection list, default
  `~/.QQ.collections`
* `g:QQ_collection_window_location` position of the collection window,
   acceptable values are `'top'` and `'bottom'`. default `'top'`
* `g:QQ_collection_window_height` height of collection window. default `10`
* `g:QQ_buffer_prefix` buffer prefix of all QQ buffers, avoids naming clashes
   default `'[QQ]'`
* `g:QQ_map_prefix` the prefix to key maps, default `Q`
* `g:QQ_map_defaults` if you want to turn the default mappings off, default
  `0`

Tests
-----

Tests are written for [vim-themis](https://github.com/thinca/vim-themis)

To run tests, clone vim-themis, and simply run the tests:

```
git clone https://github.com/thinca/vim-themis.git 
vim-themis/bin/themis --reporter dot test
```

If you want to add anything to QQ please think about writing a test for it!

 
Notes
-----

* This is very much a work in progress, if anything breaks let us know at:
  [https://github.com/nicwest/QQ.vim/issues](https://github.com/nicwest/QQ.vim/issues)
* It's also still missing features...
* And is more than a bit hacky in places.
* QQ is probably a working title.
* Yes `Q` is a useful key bind, some more and better thought will probably go
  into more intelligent binds later.
* QQ is modeled on [Postman](http://www.getpostman.com/).
* QQ may or may not be windows compatible. (it almost certainly isn't)  
