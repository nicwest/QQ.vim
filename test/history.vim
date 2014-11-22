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

function CallWithInput(func, input)
  exe 'normal :call '.join([a:func.'()'] + a:input, '').''
endfunction

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
  call s:assert.equals(l:buffer_text, ['--NO HISTORY--'])
endfunction

function! s:suite.open_buffer_created_populates_with_response()
  call s:assert.false(bufexists(s:B.history))
  call QQ#history#open()
  let l:buffer_text = getbufline(bufnr(s:B.history), 0, '$')
  call s:assert.equals(l:buffer_text, ['--NO HISTORY--'])
endfunction
