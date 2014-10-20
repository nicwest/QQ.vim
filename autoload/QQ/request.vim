function! QQ#request#import()
    let prefix = '<SNR>' . s:SID() . '_'
    let module = {}
    for func in s:functions
        let module[func] = function(prefix . func)
    endfor
    return copy(module)
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

let s:functions = [
\   'open',
\   'map_keys'
\ ]

" Imports {{{1
let s:B = QQ#buffers#import()
let s:U = QQ#utils#import()

" Open: {{{1
function! s:open()
  "finds the REQUEST buffer where ever it may be
  if and(!bufexists(s:B.request), !bufexists(s:B.response))
    "neither request or response buffer exists
    sil! exe 'keepa bo 80vnew' s:B.request
  elseif and(!bufexists(s:B.request), bufwinnr(s:B.response) != -1)
    "request buffer doesn't exist, response buffer exists and is in window
    call s:U.focus_window_with_name(s:B.response)
    sil! exe 'badd' s:B.request
    sil! exe 'buf' bufnr(s:B.request) 
  elseif and(!bufexists(s:B.request), bufexists(s:B.response))
    "request buffer doesn't exist, response buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.response
    sil! exe 'vert res 80'
    sil! exe 'badd' s:B.request
    sil! exe 'buf' bufnr('') 
  elseif and(bufwinnr(s:B.request) == -1, bufwinnr(s:B.response) != -1)
    "request buffer exists, response buffer exists and is in window
    call s:U.focus_window_with_name(s:B.response)
    sil! exe 'buf' bufnr(s:B.request) 
  elseif bufwinnr(s:B.request) == -1
    "request buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.request
    sil! exe 'vert res 80'
  else 
    "request buffer exists and is in window
    call s:U.focus_window_with_name(s:B.request)
  endif
  call s:map_keys()
  "call s:setup_request_buffer()
endfunction

" Mapping: {{{1
function! s:map_keys () abort
  nnoremap <buffer> QAB :call QQ#basic_auth()<CR>
  nnoremap <buffer> QAO :call QQ#oauth2()<CR>
  nnoremap <buffer> QP :call QQ#add_option('pretty-print')<CR>
endfunction
" Misc: {{{1
" vim:fdm=marker
