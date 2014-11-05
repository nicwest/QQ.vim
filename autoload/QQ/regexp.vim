" Importer : {{{1
function! QQ#regexp#import() abort
  return copy(s:R)
endfunction

let s:R = {}
" Syntax : {{{1
let s:R.request_line_ptrn = '^\([A-Z-]\+\):\s\+\(:[^:/]\+:\)\?\s*\(.*\)$'
let s:R.strip_name = '^:\(.\{-}\):$'
let s:R.strip = '^\s*\(.\{-}\)\s*$'
let s:R.falsey = '^\s*\(0\|false\|no\)\+\s*$'

" Response: {{{1

let s:R.response_header = "\\r\\n\\r\\n\\(\\([A-Z]\\+\\/[0-9\\.]\\+\\s\\+[0-9]\\+\\s\\+[A-Z]\\+\\)\\@!\\)"

" Misc : {{{1
" vim:fdm=marker
