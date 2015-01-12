let s:suite = themis#suite('history')
let s:assert = themis#helper('assert')

" Test Setup: {{{1
let s:themis_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
function! s:buflist ()
  return map(filter(filter(range(1, bufnr('$')), 'index(s:themis_buffers, v:val) < 0'), 'bufexists(v:val)'), 'bufname(v:val)')
endfunction

function! s:suite.after_each()
  for buffer_name in s:buflist()
    if bufnr(buffer_name) > -1
      exe 'bw!' bufnr(buffer_name)
    endif
  endfor
endfunction

function! AddLine(str)
  put! = a:str
endfunction

function! AddLines(lines)
  for line in reverse(copy(a:lines))
    put! = line
  endfor
endfunction

function! CallWithInput(func, input)
  exe 'normal :call '.join([a:func.'()'] + a:input, '').''
endfunction

let s:curl_str_with_time = 'curl -si -w ''\r\n%{time_namelookup}\r\n%{time_connect}\r\n%{time_appconnect}\r\n%{time_pretransfer}\r\n%{time_redirect}\r\n%{time_starttransfer}\r\n%{time_total}'''

" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Open: {{{1
function! s:suite.open_creates_new_buffer()
  call s:assert.false(bufexists(s:B.history))
  call QQ#history#open()
  call s:assert.true(bufexists(s:B.history))
endfunction

function! s:suite.open_creates_new_window_of_correct_size()
  call QQ#history#open()
  " checks window width is the specified 10 rows or is full width minus
  " one row for the separator and one rows for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_10_or_fullheight = or(
        \  winheight(0) == 10,
        \  winheight(0) == &lines - 4)
  call s:assert.true(window_is_10_or_fullheight)
endfunction

function! s:suite.open_doesnt_recreate_buffer()
  exe 'badd' s:B.history
  call s:assert.true(bufexists(s:B.history))
  call s:assert.length_of(s:buflist(), 1)
  call QQ#history#open()
  call s:assert.true(bufexists(s:B.history))
  call s:assert.length_of(s:buflist(), 1)
endfunction

function! s:suite.open_replaces_open_request_buffer()
  exe 'badd' s:B.collections
  exe 'sb' bufnr(s:B.collections)
  call s:assert.not_equals(bufwinnr(s:B.collections), -1)
  call QQ#history#open()
  call s:assert.true(bufexists(s:B.collections))
  call s:assert.true(bufexists(s:B.history))
  call s:assert.length_of(s:buflist(), 2)
  call s:assert.equals(bufwinnr(s:B.collections), -1)
  call s:assert.not_equals(bufwinnr(s:B.history), -1)
endfunction

function! s:suite.open_replaces_window_of_correct_size()
  exe 'badd' s:B.collections
  exe 'vert sb' bufnr(s:B.collections)
  call QQ#history#open()
  " checks window width is the specified 80 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_10_or_fullheight = or(
        \  winheight(0) == 10,
        \  winheight(0) == &lines - 4)
  call s:assert.true(window_is_10_or_fullheight)
endfunction

function! s:suite.open_buffer_created_populates_with_default()
  call s:assert.false(bufexists(s:B.history))
  call QQ#history#open()
  let l:buffer_text = getbufline(bufnr(s:B.history), 0, '$')
  call s:assert.not_equals(l:buffer_text, ['--NO HISTORY--'])
endfunction

function! s:suite.open_buffer_created_populates_with_response()
  call s:assert.false(bufexists(s:B.history))
  call QQ#history#open()
  let l:buffer_text = getbufline(bufnr(s:B.history), 0, '$')
  call s:assert.not_equals(l:buffer_text, ['--NO HISTORY--'])
endfunction

" Setup: {{{1

function! s:suite.setup_settings()
  exe 'new' s:B.history
  call QQ#history#setup()
  call s:assert.equals(&filetype, 'QQ')
  call s:assert.equals(&l:swapfile, 0)
  call s:assert.equals(&l:number, 0)
  call s:assert.equals(&l:spell, 0)
  call s:assert.equals(&l:cursorcolumn, 0)
  call s:assert.equals(&l:winfixwidth, 1)
  call s:assert.equals(&l:foldcolumn, 0)
  call s:assert.equals(&l:foldlevel, 99)
  call s:assert.equals(&l:textwidth, 0)
  call s:assert.equals(&l:buftype, 0)
  call s:assert.equals(&l:bufhidden, 'hide')
  if v:version > 702
    call s:assert.equals(&l:relativenumber, 0)
    call s:assert.equals(&l:undofile, 0)
    call s:assert.equals(&l:colorcolumn, 0)
  endif
  call s:assert.equals(b:current_syntax, 'QQ')
  call s:assert.equals(&l:foldmethod, 'syntax')
endfunction

" Populate: {{{1

function! s:suite.populate_sets_not_modifiable()
  exe 'new' s:B.history
  let b:queries = []
  call QQ#history#populate()
  call s:assert.equals(&l:modifiable, 0)
endfunction

function! s:suite.populates_with_correct_queries()
  exe 'new' s:B.history
  let b:queries = [
        \ s:curl_str_with_time.' -X TESTQUERY "http://test.com"',
        \ s:curl_str_with_time.' -X FOOQUERY "http://foo.com"',
        \]
  call QQ#history#populate()
  call s:assert.equals(getbufline(s:B.history, 1, '$'), [
        \ "TESTQUERY\thttp://test.com",
        \ "FOOQUERY\thttp://foo.com"])

endfunction


" Save: {{{1
function! s:suite.queries_writes_file()
  let l:filepath = tempname()
  let l:result =  QQ#history#queries(l:filepath)
  call s:assert.true(filereadable(l:filepath))
  call s:assert.equals(l:result, [])
endfunction

function! s:suite.queries_reads_file()
  let l:filepath = tempname()
  call writefile(['test', 'thing', 'pew'], l:filepath)
  let l:result =  QQ#history#queries(l:filepath)
  call s:assert.equals(l:result, ['test', 'thing', 'pew'])
endfunction

function! s:suite.remove_query_removes_query_when_present()
  let l:queries = ['foo', 'bar', 'test', 'pewpew']
  let l:result = QQ#history#remove_query(l:queries, 'test')
  call s:assert.equals(l:result, ['foo', 'bar', 'pewpew'])
endfunction

function! s:suite.remove_query_does_nothing_with_query_not_present()
  let l:queries = ['foo', 'bar', 'pewpew']
  let l:result = QQ#history#remove_query(l:queries, 'test')
  call s:assert.equals(l:result, ['foo', 'bar', 'pewpew'])
endfunction

function! s:suite.add_query_prepends_query()
  let l:queries = ['foo', 'bar', 'pewpew']
  let l:result = QQ#history#add_query(l:queries, 'test')
  call s:assert.equals(l:result, ['test', 'foo', 'bar', 'pewpew'])
endfunction

function! s:suite.add_query_removes_query_and_prepends_query()
  let l:queries = ['foo', 'bar', 'test', 'pewpew']
  let l:result = QQ#history#add_query(l:queries, 'test')
  call s:assert.equals(l:result, ['test', 'foo', 'bar', 'pewpew'])
endfunction

function! s:suite.save_saves_query()
  let g:QQ_current_collection = tempname()
  call QQ#history#save({'METHOD': ['TESTQUERY'], 'URL': ['http://test.com']})
  let l:result = readfile(expand(g:QQ_current_collection))
  let g:QQ_current_collection = g:QQ_default_collection
  call s:assert.equals(l:result, [s:curl_str_with_time.' -X TESTQUERY ''http://test.com'''])
endfunction

function! s:suite.save_query_updates_history_buffer_when_in_window()
  exe 'new' s:B.request
  only!
  exe 'new' s:B.history
  call QQ#history#save({'METHOD': ['TESTQUERY'], 'URL': ['http://test.com']})
  call s:assert.equals(getbufline(s:B.history, 1), ["TESTQUERY\thttp://test.com"])
endfunction

" Mapping: {{{1
function! s:suite.maps_correct_keys()
  exe 'new' s:B.history
  call QQ#history#map_keys()
  call s:assert.equals(maparg('<CR>', 'n'), ':call QQ#history#to_request()<CR>')
  call s:assert.equals(maparg('q', 'n'), ':call QQ#utils#close_window()<CR>')
endfunction

" Misc: {{{1
" vim:fdm=marker
