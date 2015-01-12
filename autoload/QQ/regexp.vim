" Importer : {{{1
function! QQ#regexp#import() abort
  return copy(s:R)
endfunction

let s:R = {}
" Syntax : {{{1
let s:R.request_line_ptrn = '^\([A-Z-]\+\):\s\+\(:[^:/]\+:\)\?\s*\(.*\)$'
let s:R.body_line_ptrn = '^BODY:\s*\(.*\)$'
let s:R.strip_name = '^:\(.\{-}\):$'
let s:R.strip = '^\s*\(.\{-}\)\s*$'
let s:R.falsey = '^\s*\([0]\+\|false\|no\)\s*$'

" Vim: {{{1
let s:R.uri = '\zs[a-z+]\+:\/\/\S\+\ze\_s\?'

" Response: {{{1

let s:R.response_header = "\\r\\n\\r\\n\\(\\([A-Z]\\+\\/[0-9\\.]\\+\\s\\+[0-9]\\+\\s\\+[A-Z]\\+\\)\\@!\\)"
let s:R.content_type = 'Content-Type:\s\zs[a-zA-Z0-9_\-\.+]\+/[a-zA-Z0-9_\-\.+]\+\ze\(\_s\|;\)\?'

" Collections: {{{1

let s:R.collection_name = '^\[\zs.\+\ze\].*$'
let s:R.collection_path = '^\(\[.\+\]\s*\)\?\zs.*\ze$'

" Curl: {{{1

let s:R.curl_method =  '-X\s\zs.\{-}\ze\s'
let s:R.curl_url = '\s\("\|''\)\zs[a-zA-Z]\+:\/\/.\{-}\ze\1$'
let s:R.curl_url_param_name = '^\zs.\+\ze='
let s:R.curl_url_param_value = '=\zs.\+\ze$'
let s:R.curl_header = '-H\s\([''"]\)\zs.\{-}\ze\1'
let s:R.curl_form = '-F\s\([''"]\)\zs.\{-}\ze\1'
let s:R.curl_data = '-d\s\([''"]\)\zs.\{-}\ze\1'
let s:R.curl_data_fields = '\(^\|&\)\zs[^&]\+\ze\($\)\?'

" Misc : {{{1
" vim:fdm=marker
