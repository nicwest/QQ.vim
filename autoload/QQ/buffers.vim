" Importer : {{{1
function! s:SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! QQ#buffers#import() abort
  return copy(s:B)
endfunction

let s:B = {}
" names : {{{1
let s:B.request = g:QQ_buffer_prefix.'REQUEST'
let s:B.response = g:QQ_buffer_prefix.'RESPONSE'
let s:B.history = g:QQ_buffer_prefix.'HISTORY'
let s:B.collections = g:QQ_buffer_prefix.'COLLECTIONS'

" Misc : {{{1
" vim:fdm=marker
