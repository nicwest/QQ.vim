" Importer : {{{1
function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! QQ#regexp#import() abort
  return copy(s:R)
endfunction

let s:R = {}
" Syntax : {{{1
let s:R.request_line_ptrn = '^\([A-Z-]\+\):\s\+\(:[^:/]\+:\)\?\s*\(.*\)$'
let s:R.strip_name = '^:\(.\{-}\):$'
let s:R.strip = '^\s*\(.\{-}\)\s*$'
let s:R.falsey = '^\s*\(0\|false\|no\)\+\s*$'

" Misc : {{{1
" vim:fdm=marker
