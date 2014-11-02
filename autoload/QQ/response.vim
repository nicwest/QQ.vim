" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Defaults: {{{1
let s:last_response = ''
let s:base_curl_query = g:QQ_curl_executable . " -si -w '\\r\\n".
      \ "\%{time_namelookup}\\r\\n".
      \ "\%{time_connect}\\r\\n".
      \ "\%{time_appconnect}\\r\\n".
      \ "\%{time_pretransfer}\\r\\n".
      \ "\%{time_redirect}\\r\\n".
      \ "\%{time_starttransfer}\\r\\n".
      \ "\%{time_total}'"

" Open: {{{1
function! QQ#response#open(...) abort
  "finds the RESPONSE buffer where ever it may be
  let l:buffer_created = 0
  if and(!bufexists(s:B.response), !bufexists(s:B.request))
    "neither request or response buffer exists
    sil! exe 'keepa bo 80vnew' s:B.response
    let l:buffer_created = 1
  elseif and(!bufexists(s:B.response), bufwinnr(s:B.request) != -1)
    "response buffer doesn't exist, request buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.request)
    sil! exe 'badd' s:B.response
    sil! exe 'buf' bufnr(s:B.response) 
    sil! exe 'vert res 80'
    let l:buffer_created = 1
  elseif and(!bufexists(s:B.response), bufexists(s:B.request))
    "response buffer doesn't exist, request buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.request
    sil! exe 'vert res 80'
    sil! exe 'badd' s:B.response
    sil! exe 'buf' bufnr('') 
    let l:buffer_created = 1
  elseif and(bufwinnr(s:B.response) == -1, bufwinnr(s:B.request) != -1)
    "response buffer exists, request buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.request)
    sil! exe 'buf' bufnr(s:B.response) 
  elseif bufwinnr(s:B.response) == -1
    "response buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.response
    sil! exe 'vert res 80'
  else 
    call QQ#utils#focus_window_with_name(s:B.response)
  endif
  call QQ#response#map_keys()
  call QQ#response#setup()
  if l:buffer_created
    let response = a:0 ? a:1 : s:last_response 
    call QQ#response#populate(response)
  endif
endfunction

" Setup: {{{1

function! QQ#response#setup() abort
  set ft=QQ
  setl noswf nonu nobl nospell nocuc wfw
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=hide
  if v:version > 702
    setl nornu noudf cc=0
  end
endfunction

" Populate: {{{1

function! QQ#response#populate(...) abort

endfunction

" Mapping: {{{1
function! QQ#response#map_keys() abort

endfunction

" Misc: {{{1
" vim:fdm=marker

