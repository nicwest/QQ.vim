let s:suite = themis#suite('response')
let s:assert = themis#helper('assert')
" Test Setup: {{{1
let s:themis_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')"{{{
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

let s:B = QQ#buffers#import()"}}}
let s:test_request = [
      \ "METHOD:\tGET",
      \ "URL:\thttps://www.googleapis.com/urlshortener/v1/url",
      \ "URL-PARAM:\t:shortUrl: :url:",
      \ "URL-PARAM:\t:key: :api-key:",
      \ "URL-VAR:\t:url: https://weareleto.com",
      \ "URL-VAR:\t:api-key: 123123",
      \ "HEADER:\t:Cache-Control: no-cache",
      \ "OPTION:\t:pretty-print: True",
      \]

let s:test_query = {
      \ 'METHOD': ['GET'],
      \ 'URL': ['https://www.googleapis.com/urlshortener/v1/url'],
      \ 'URL-VAR': [['url', 'https://weareleto.com'], ['api-key', '123123']],
      \ 'URL-PARAM': [['shortUrl', ':url:'], ['key', ':api-key:']],
      \ 'HEADER': [['Cache-Control', 'no-cache']],
      \ 'OPTION': [['pretty-print', 'True']]
      \}

let s:default_request =  [
      \ "METHOD:\tGET", 
      \ "URL:\thttp://localhost:8000", 
      \ "URL-PARAM:\t:testparam: test",
      \ "URL-VAR:\t:testvar: users", 
      \ "HEADER:\t:Cache-Control: no-cache", 
      \ "OPTION:\t:pretty-print: True"
      \ ]

let s:default_query =  {
      \ "URL": ["http://localhost:8000"], 
      \ "METHOD": ["GET"], 
      \ "URL-VAR": [["testvar", "users"]], 
      \ "URL-PARAM": [["testparam", "test"]],
      \ "HEADER": [["Cache-Control", "no-cache"]], 
      \ "DATA": [],
      \ "DATA-FILE": [],
      \ "BODY": [],
      \ "OPTION": [["pretty-print", "True"]]
      \ }

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
  call s:assert.equals(l:buffer_text, [''])
endfunction

function! s:suite.open_buffer_created_populates_with_query()
  call s:assert.false(bufexists(s:B.response))
  call QQ#response#open(s:test_query)
  let l:buffer_text = getbufline(bufnr(s:B.response), 0, '$')
  call s:assert.equals(l:buffer_text, [''])
endfunction

" Setup: {{{1

function! s:suite.setup_settings()
  exe 'new' s:B.response
  call QQ#response#setup()
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
endfunction



" Misc: {{{1
" vim:fdm=marker
