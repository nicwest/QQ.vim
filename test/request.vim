let s:suite = themis#suite('request')
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
      \ "FORM": [],
      \ "FORM-FILE": [],
      \ "BODY": [],
      \ "OPTION": [["pretty-print", "True"]]
      \ }

" Open: {{{1

function! s:suite.open_creates_new_buffer()
  call s:assert.false(bufexists(s:B.request))
  call QQ#request#open()
  call s:assert.true(bufexists(s:B.request))
endfunction

function! s:suite.open_creates_new_window_of_correct_size()
  call QQ#request#open()
  " checks window width is the specified 50 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_50_or_fullwidth = or(
        \  winwidth(0) == 50,
        \  winwidth(0) == &columns - 2)
  call s:assert.true(window_is_50_or_fullwidth)
endfunction

function! s:suite.open_doesnt_recreate_buffer()
  exe 'badd' s:B.request
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 1)
  call QQ#request#open()
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 1)
endfunction

function! s:suite.open_replaces_open_response_buffer()
  exe 'badd' s:B.response
  exe 'sb' bufnr(s:B.response)
  call s:assert.not_equals(bufwinnr(s:B.response), -1)
  call QQ#request#open()
  call s:assert.true(bufexists(s:B.response))
  call s:assert.true(bufexists(s:B.request))
  call s:assert.length_of(s:buflist(), 2)
  call s:assert.equals(bufwinnr(s:B.response), -1)
  call s:assert.not_equals(bufwinnr(s:B.request), -1)
endfunction

function! s:suite.open_replaces_window_of_correct_size()
  exe 'badd' s:B.response
  exe 'vert sb' bufnr(s:B.response)
  call QQ#request#open()
  " checks window width is the specified 50 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_50_or_fullwidth = or(
        \  winwidth(0) == 50,
        \  winwidth(0) == &columns - 2)
  call s:assert.true(window_is_50_or_fullwidth)
endfunction

function! s:suite.open_buffer_created_populates_with_default()
  call s:assert.false(bufexists(s:B.request))
  call QQ#request#open()
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(l:buffer_text, s:default_request)
endfunction

function! s:suite.open_buffer_created_populates_with_query()
  call s:assert.false(bufexists(s:B.request))
  call QQ#request#open(s:test_query)
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(l:buffer_text, s:test_request)
endfunction

" Setup: {{{1
function! s:suite.setup_settings()
  exe 'new' s:B.request
  call QQ#request#setup()
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

" Convert: {{{1

function! s:suite.convert()
  exe 'new' s:B.request
  call AddLines(s:test_request)
  let query = QQ#request#convert()
  call s:assert.equals(query, s:test_query)
endfunction

function! s:suite.convert_empty()
  exe 'new' s:B.request
  let query = QQ#request#convert()
  call s:assert.equals(query, {})
endfunction

" Populate: {{{1

function! s:suite.populate_with_no_last_query()
  exe 'new' s:B.request
  call QQ#request#populate()
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(buffer_text, s:default_request)
endfunction

function! s:suite.populate_with_last_query()
  exe 'new' s:B.request
  call QQ#request#populate(s:test_query)
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(buffer_text, s:test_request)
endfunction

" Send: {{{1

function! s:suite.send()
  " TODO: work out how to test this
endfunction

" Helpers: {{{1

function! s:suite.add_option()
  exe 'new' s:B.request
  call AddLine('METHOD: GET')
  norm! G"_ddgg
  call QQ#request#add_option('test')
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(l:buffer_text, ['METHOD: GET', 'OPTION: :test: true'])
endfunction


" Mapping: {{{1
function! s:suite.maps_correct_keys()
  exe 'new' s:B.request 
  call QQ#request#map_keys()
  call s:assert.equals(maparg('QQ', 'n'), ':call QQ#request#send()<CR>')
  call s:assert.equals(maparg('QAB', 'n'), ':call QQ#auth#basic()<CR>')
  call s:assert.equals(maparg('QAO', 'n'), ':call QQ#auth#oauth2()<CR>')
  call s:assert.equals(maparg('QP', 'n'), ':call QQ#request#add_option(''pretty-print'')<CR>')
  call s:assert.equals(maparg('QF', 'n'), ':call QQ#request#add_option(''follow'')<CR>')
endfunction



" Misc: {{{1
" vim:fdm=marker
