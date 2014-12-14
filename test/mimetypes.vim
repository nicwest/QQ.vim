let s:suite = themis#suite('mimetypes')
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

" Get: {{{1

function! s:suite.mimetype_from_content_type_header()
  let l:mimetype = QQ#mimetypes#getmimetype('Content-Type: application/json')
  call s:assert.equals(l:mimetype, 'application/json')
endfunction

function! s:suite.mimetype_from_multiline()
  let l:mimetype = QQ#mimetypes#getmimetype("pewpew:\nContent-Type: application/json\nlollol")
  call s:assert.equals(l:mimetype, 'application/json')
endfunction

function! s:suite.mimetype_from_content_type_with_charset()
  let l:mimetype = QQ#mimetypes#getmimetype("Content-Type: application/json; charset=utf-8")
  call s:assert.equals(l:mimetype, 'application/json')
endfunction

" Set Syntax: {{{1

function! s:suite.sets_correct_file_type_with_json()
  new 'test_buffer'
  let l:mimetype = QQ#mimetypes#set_file_type('application/json')
  call s:assert.equals(&l:filetype, 'QQ.javascript')
endfunction

function! s:suite.sets_correct_file_type_with_rss()
  new 'test_buffer'
  let l:mimetype = QQ#mimetypes#set_file_type('application/atom+xml')
  call s:assert.equals(&l:filetype, 'QQ.xml')
endfunction

function! s:suite.sets_correct_file_type_with_html()
  new 'test_buffer'
  let l:mimetype = QQ#mimetypes#set_file_type('text/html')
  call s:assert.equals(&l:filetype, 'QQ.html')
endfunction

function! s:suite.sets_correct_file_type_with_css()
  new 'test_buffer'
  let l:mimetype = QQ#mimetypes#set_file_type('text/css')
  call s:assert.equals(&l:filetype, 'QQ.css')
endfunction

function! s:suite.sets_correct_file_type_with_markdown()
  new 'test_buffer'
  let l:mimetype = QQ#mimetypes#set_file_type('text/x-markdown')
  call s:assert.equals(&l:filetype, 'QQ.markdown')
endfunction

function! s:suite.sets_no_additional_file_type()
  new 'test_buffer'
  set ft=QQ
  let l:mimetype = QQ#mimetypes#set_file_type('not/real')
  call s:assert.equals(&l:filetype, 'QQ')
endfunction

  
" Misc: {{{1
" vim:fdm=marker
