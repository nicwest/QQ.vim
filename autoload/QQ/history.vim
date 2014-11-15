" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Defaults: {{{1
let s:last_response = ''

" Open: {{{1
function! QQ#history#open(...) abort
  "finds the HISTORY buffer where ever it may be
  let l:buffer_created = 0
  if and(!bufexists(s:B.history), !bufexists(s:B.collections))
    "neither collections or history buffer exists
    sil! exe 'keepa bo 80vnew' s:B.history
    let l:buffer_created = 1
  elseif and(!bufexists(s:B.history), bufwinnr(s:B.collections) != -1)
    "history buffer doesn't exist, collections buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.collections)
    sil! exe 'badd' s:B.history
    sil! exe 'buf' bufnr(s:B.history) 
    sil! exe 'vert res 80'
    let l:buffer_created = 1
  elseif and(!bufexists(s:B.history), bufexists(s:B.collections))
    "history buffer doesn't exist, collections buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.collections
    sil! exe 'vert res 80'
    sil! exe 'badd' s:B.history
    sil! exe 'buf' bufnr('') 
    let l:buffer_created = 1
  elseif and(bufwinnr(s:B.history) == -1, bufwinnr(s:B.collections) != -1)
    "history buffer exists, collections buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.collections)
    sil! exe 'buf' bufnr(s:B.history) 
  elseif bufwinnr(s:B.history) == -1
    "history buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.history
    sil! exe 'vert res 80'
  else 
    call QQ#utils#focus_window_with_name(s:B.history)
  endif
  call QQ#response#map_keys()
  call QQ#response#setup()
  if l:buffer_created
    let l:response = a:0 ? a:1 : s:last_response 
    let l:options = a:0 > 1 ? a:2 : []
    call QQ#response#populate('test', [])
    "call QQ#response#populate(l:response, l:options)
  endif
endfunction

" Save {{{3
" ----
function! s:save_query (query) abort
  "save query
  let filename=resolve(expand(g:QQ_current_collection))
  if filereadable(filename)
    let queries=readfile(filename)
  else
    call writefile([], filename)
    let queries = []
  endif
  let in_previous_queries = index(queries, a:query)
  if in_previous_queries > -1
    call remove(queries, in_previous_queries)
  endif
  let queries = [a:query] + queries
  if bufwinnr(g:QQ_buffer_prefix.'HISTORY') != -1
    call setbufvar(bufnr(g:QQ_buffer_prefix.'HISTORY'), 'queries', queries)
    let request_buffer=bufnr('')
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
    call s:load_history_buffer()
    call s:focus_window_with_name(request_buffer)
  endif
  call writefile(queries, filename)
endfunction
