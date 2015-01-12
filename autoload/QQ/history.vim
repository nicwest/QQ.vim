" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Defaults: {{{1
let s:last_response = ''

" Open: {{{1
function! QQ#history#open(...) abort
  "finds the HISTORY buffer where ever it may be
  let l:position = g:QQ_collection_window_location == 'top' ? 'to' : 'bo' 
  let l:height = g:QQ_collection_window_height
  if !bufexists(s:B.history) && !bufexists(s:B.collections)
    "neither collections or history buffer exists
    sil! exe 'keepa' l:position l:height.'new' s:B.history
  elseif !bufexists(s:B.history) && bufwinnr(s:B.collections) != -1
    "history buffer doesn't exist, collections buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.collections)
    sil! exe 'badd' s:B.history
    sil! exe 'buf' bufnr(s:B.history) 
    sil! exe 'res' l:height
  elseif !bufexists(s:B.history) && bufexists(s:B.collections)
    "history buffer doesn't exist, collections buffer exists but is not in window
    sil! exe 'keepa' l:position l:height.'sb' bufnr(s:B.collections)
    sil! exe 'res' l:height
    sil! exe 'badd' s:B.history
    sil! exe 'buf' bufnr(s:B.history) 
  elseif bufwinnr(s:B.history) == -1 && bufwinnr(s:B.collections) != -1
    "history buffer exists, collections buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.collections)
    sil! exe 'buf' bufnr(s:B.history) 
  elseif bufwinnr(s:B.history) == -1
    "history buffer exists but is not in window
    sil! exe 'keepa' l:position 'sb' bufnr(s:B.history)
    sil! exe 'res' l:height
  else 
    call QQ#utils#focus_window_with_name(s:B.history)
  endif
  call QQ#history#map_keys()
  call QQ#history#setup()
  let l:collection = a:0 ? a:1 : g:QQ_current_collection 
  let b:queries = QQ#history#queries(l:collection)
  call QQ#history#populate()
endfunction

" Setup: {{{1
function! QQ#history#setup() abort
  set ft=QQ
  setl noswf nonu nobl nospell nocuc wfw
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=hide
  if v:version > 702
    setl nornu noudf cc=0
  end
  let b:current_syntax = "QQ"
  syn sync fromstart
  set foldmethod=syntax
endfunction

" Populate: {{{1
function! QQ#history#populate() abort
  setl ma
  norm gg"_dG
  let displaylist=copy(b:queries)
  call map(displaylist, 'matchstr(v:val, s:R.curl_method) . "\t" . ' . 
        \ 'matchstr(v:val, s:R.curl_url)')
  call append(0, displaylist)
  norm G"_ddgg
  setl noma
endfunction

" Save: {{{1

function! s:filepath() abort
  return resolve(expand(g:QQ_current_collection))
endfunction

function! QQ#history#remove_query(queries, query) abort
  let in_previous_queries = index(a:queries, a:query)
  if in_previous_queries > -1
    call remove(a:queries, in_previous_queries)
  endif
  return a:queries
endfunction

function! QQ#history#add_query(queries, query) abort
  let queries = QQ#history#remove_query(a:queries, a:query)
  let queries = [a:query] + queries
  return queries
endfunction

function! QQ#history#queries(filepath) abort
  if filereadable(expand(a:filepath))
    return readfile(expand(a:filepath))
  else
    call writefile([], expand(a:filepath))
    return []
  endif
endfunction

function! QQ#history#save(query) abort
  "save query
  let filepath=s:filepath()
  let query_str = QQ#query#get_query_str(a:query)[0]
  let queries = QQ#history#queries(filepath)
  let queries = QQ#history#add_query(queries, query_str)
  if bufwinnr(s:B.history) != -1
    call setbufvar(bufnr(s:B.history), 'queries', queries)
    let previous_buffer=bufname('')
    call QQ#utils#focus_window_with_name(s:B.history)
    call QQ#history#populate()
    call QQ#utils#focus_window_with_name(previous_buffer)
  endif
  call writefile(queries, filepath)
endfunction

" Execute: {{{1

function! QQ#history#to_request() abort
  let l:query_str=get(b:queries, line(".")-1, 0)
  let l:query = QQ#query#convert(l:query_str)
  call QQ#request#open(l:query)
endfunction

" Mapping: {{{1
function! QQ#history#map_keys () abort
  nnoremap <buffer> <CR> :call QQ#history#to_request()<CR>
  nnoremap <buffer> q :call QQ#utils#close_window()<CR>
endfunction

" Misc: {{{1
" vim:fdm=marker
