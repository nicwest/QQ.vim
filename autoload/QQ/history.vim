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
