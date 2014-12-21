let s:suite = themis#suite('response')
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

let s:B = QQ#buffers#import()

let s:test_headers = "HTTP/1.1 302 Moved Temporarily\r\nCache-Control: private\r\nContent-Type: application/json; charset=UTF-8\r\nContent-Length: 259\r\nDate: Tue, 04 Nov 2014 10:01:17 GMT\r\nServer: GFE/2.0\r\nAlternate-Protocol: 80:quic,p=0.01\r\nConnection: keep-alive"
let s:test_body = '{"test": "lol", "trololol": [1, 2, 3], "pie": true}'
let s:test_times = "\r\n1\r\n2\r\n3\r\n4\r\n5\r\n6\r\n7"
let s:test_response = s:test_headers . "\r\n\r\n" . s:test_body . s:test_times
let s:test_options = ['pretty-print']
let s:test_time = {'response': 7, 'name_lookup': 1, 'connect': 2, 'app_connect': 3, 'pre_transfer': 4, 'redirects': 5, 'start_transfer': 6}
let s:test_headers_output = ['HTTP/1.1 302 Moved Temporarily', 'Cache-Control: private', 'Content-Type: application/json; charset=UTF-8', 'Content-Length: 259', 'Date: Tue, 04 Nov 2014 10:01:17 GMT', 'Server: GFE/2.0', 'Alternate-Protocol: 80:quic,p=0.01', 'Connection: keep-alive', '']
let s:test_time_output = ['RESPONSE TIME: 7', 'Name-Lookup: 1', 'Connect: 2', 'App-Connect: 3', 'Pre-Transfer: 4', 'Redirects: 5', 'Start-Transfer: 6', ''] 
let s:test_body_output = ['{"test": "lol", "trololol": [1, 2, 3], "pie": true}']
let s:test_body_output_pretty = ['{', '    "pie": true,', '    "test": "lol",', '    "trololol": [', '        1,', '        2,', '        3', '    ]', '}']
let s:test_response_output = s:test_headers_output + s:test_time_output + s:test_body_output
let s:test_response_output_pretty = s:test_headers_output + s:test_time_output + s:test_body_output_pretty

" Open: {{{1
function! s:suite.open_creates_new_buffer()
  call s:assert.false(bufexists(s:B.response))
  call QQ#response#open()
  call s:assert.true(bufexists(s:B.response))
endfunction

function! s:suite.open_creates_new_window_of_correct_size()
  call QQ#response#open()
  " checks window width is the specified 80 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_80_or_fullwidth = or(
        \  winwidth(0) == 80,
        \  winwidth(0) == &columns - 2)
  call s:assert.true(window_is_80_or_fullwidth)
endfunction

function! s:suite.open_doesnt_recreate_buffer()
  exe 'badd' s:B.response
  call s:assert.true(bufexists(s:B.response))
  call s:assert.length_of(s:buflist(), 1)
  call QQ#response#open()
  call s:assert.true(bufexists(s:B.response))
  call s:assert.length_of(s:buflist(), 1)
endfunction

function! s:suite.open_replaces_open_request_buffer()
  exe 'badd' s:B.request
  exe 'sb' bufnr(s:B.request)
  call s:assert.not_equals(bufwinnr(s:B.request), -1)
  call QQ#response#open()
  call s:assert.true(bufexists(s:B.request))
  call s:assert.true(bufexists(s:B.response))
  call s:assert.length_of(s:buflist(), 2)
  call s:assert.equals(bufwinnr(s:B.request), -1)
  call s:assert.not_equals(bufwinnr(s:B.response), -1)
endfunction

function! s:suite.open_replaces_window_of_correct_size()
  exe 'badd' s:B.request
  exe 'vert sb' bufnr(s:B.request)
  call QQ#response#open()
  " checks window width is the specified 80 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_80_or_fullwidth = or(
        \  winwidth(0) == 80,
        \  winwidth(0) == &columns - 2)
  call s:assert.true(window_is_80_or_fullwidth)
endfunction

function! s:suite.open_buffer_created_populates_with_default()
  call s:assert.false(bufexists(s:B.response))
  call QQ#response#open()
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, ['--NO RESPONSE--'])
endfunction

function! s:suite.open_buffer_created_populates_with_response()
  call s:assert.false(bufexists(s:B.response))
  call QQ#response#open(s:test_response)
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_response_output)
endfunction

function! s:suite.open_buffer_created_populates_with_response_and_options()
  call s:assert.false(bufexists(s:B.response))
  call QQ#response#open(s:test_response, s:test_options)
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_response_output_pretty)
endfunction

" Setup: {{{1

function! s:suite.setup_settings()
  exe 'new' s:B.response
  call QQ#response#setup('')
  call s:assert.equals(&l:swapfile, 0)
  call s:assert.equals(&l:number, 0)
  call s:assert.equals(&l:spell, 0)
  call s:assert.equals(&l:cursorcolumn, 0)
  call s:assert.equals(&l:winfixwidth, 1)
  call s:assert.equals(&l:foldcolumn, 0)
  call s:assert.equals(&l:foldlevel, 0)
  call s:assert.equals(&l:textwidth, 0)
  call s:assert.equals(&l:buftype, 0)
  call s:assert.equals(&l:bufhidden, 'hide')
  if v:version > 702
    call s:assert.equals(&l:relativenumber, 0)
    call s:assert.equals(&l:undofile, 0)
    call s:assert.equals(&l:colorcolumn, 0)
  endif
endfunction

function! s:suite.setup_with_mimetype()
  exe 'new' s:B.response
  call QQ#response#setup('application/json')
  call s:assert.equals(&l:filetype, 'QQ.javascript')
endfunction

function! s:suite.setup_without_mimetype()
  exe 'new' s:B.response
  call QQ#response#setup('')
  call s:assert.equals(&l:filetype, 'QQ')
endfunction

" Populate: {{{1

function! s:suite.split_response()
  let [l:headers, l:body, l:time] = QQ#response#split_response(s:test_response)
  call s:assert.equals(l:time.name_lookup, 1)
  call s:assert.equals(l:time.connect, 2)
  call s:assert.equals(l:time.app_connect, 3)
  call s:assert.equals(l:time.pre_transfer, 4)
  call s:assert.equals(l:time.redirects, 5)
  call s:assert.equals(l:time.start_transfer, 6)
  call s:assert.equals(l:time.response, 7)
  call s:assert.equals(l:headers, s:test_headers)
  call s:assert.equals(l:body, s:test_body)
endfunction

function! s:suite.format_time()
  let l:timeblock = QQ#response#format_time(s:test_time)
  let l:timelines = split(l:timeblock, '\r\n')
  call s:assert.equals(l:timelines[0], 'RESPONSE TIME: 7')
  call s:assert.equals(l:timelines[1], 'Name-Lookup: 1')
  call s:assert.equals(l:timelines[2], 'Connect: 2')
  call s:assert.equals(l:timelines[3], 'App-Connect: 3')
  call s:assert.equals(l:timelines[4], 'Pre-Transfer: 4')
  call s:assert.equals(l:timelines[5], 'Redirects: 5')
  call s:assert.equals(l:timelines[6], 'Start-Transfer: 6')
endfunction

function! s:suite.populate_with_response()
  exe 'new' s:B.response 
  call QQ#response#populate(s:test_response, [], 'application/json')
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_response_output)
endfunction

function! s:suite.populate_with_no_response()
  exe 'new' s:B.response 
  call QQ#response#populate('', [], 'application/json')
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, ['--NO RESPONSE--'])
endfunction

function! s:suite.populate_with_no_response_body()
  exe 'new' s:B.response 
  call QQ#response#populate(s:test_headers . s:test_times, [], 'application/json')
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_headers_output + s:test_time_output)
endfunction

function! s:suite.populate_with_response_and_pretty_print()
  exe 'new' s:B.response 
  call QQ#response#populate(s:test_response, ['pretty-print'], 'application/json')
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_response_output_pretty)
endfunction

" Mapping: {{{1

function! s:suite.map_keys()
  call QQ#response#map_keys()
  call s:assert.equals(maparg('q', 'n'), ':call QQ#utils#close_window()<CR>')
endfunction

  

" Misc: {{{1
" vim:fdm=marker
