let s:suite = themis#suite('buffers')
let s:assert = themis#helper('assert')

let s:themis_buffers = map(range(1, bufnr('$')), 'bufname(v:val)')
"call s:assert.equals(map(range(0, bufnr('$')), 'bufname(v:val)'), [])
function! s:buflist ()
  return filter(map(filter(range(1, bufnr('$')), 'bufexists(v:val)'), 'bufname(v:val)'), 'index(s:themis_buffers, v:val) < 0')
endfunction


function! s:tear_down ()
  for buffer_name in s:buflist()
    if bufnr(buffer_name) > -1
      "exe 'bw!' bufnr(buffer_name)
    endif
  endfor
endfunction

let s:B = QQ#buffers#import()
let s:Request = QQ#request#import()

" Import: {{{1
function! s:suite.import()
  call s:assert.is_dict(s:Request)
  call s:assert.length_of(s:Request, 2)
  call s:assert.is_func(s:Request.open)
  call s:assert.is_func(s:Request.map_keys)
  call s:tear_down()
endfunction

" Open: {{{1

function! s:suite.open_creates_new_buffer()
  call s:assert.false(bufexists(s:B.request))
  call s:Request.open()
  call s:assert.true(bufexists(s:B.request))
  call s:tear_down()
endfunction

function! s:suite.open_creates_new_window_of_correct_size()
  call s:Request.open()
  " checks window width is the specified 80 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_80_or_fullwidth = or(
        \  winwidth(0) == 80,
        \  winwidth(0) == &columns - 2)
  call s:assert.true(window_is_80_or_fullwidth)
  call s:tear_down()
endfunction


function! s:suite.open_doesnt_recreate_buffer()
  exe 'badd' s:B.request
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 1)
  call s:Request.open()
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 1)
  call s:tear_down()
endfunction

function! s:suite.open_replaces_open_response_buffer()
  exe 'badd' s:B.response
  exe 'buf' bufnr(s:B.response)
  call s:assert.not_equals(bufwinnr(s:B.response), -1)
  call s:Request.open()
  call s:assert.true(bufexists(s:B.response))
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 2)
  call s:assert.equals(bufwinnr(s:B.response), -1)
  call s:assert.not_equals(bufwinnr(s:B.request), -1)
  call s:tear_down()
endfunction
