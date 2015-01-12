let s:suite = themis#suite('regexp')
let s:assert = themis#helper('assert')

let s:R = QQ#regexp#import()
let s:test_response = "HTTP/1.0 302 FOUND\r\n" .
      \ "Date: Thu, 18 Dec 2014 22:00:24 GMT\r\n" .
      \ "Content-Type: text/html; charset=utf-8\r\n\r\n" .
      \ "HTTP/1.0 200 OK\r\n" .
      \ "Date: Thu, 18 Dec 2014 22:00:24 GMT\r\n" .
      \ "Content-Type: text/html; charset=utf-8\r\n\r\n" .
      \ "<body>TEST</body>"
let s:test_curl_request = 'curl -si -w -L -X GET '.
      \ '-H "Cache-Control:no-cache" --data "test=test&foo=foo" ' .
      \ '"http://localhost:8000?testparam=test"'
let s:test_curl_request_quotes = 'curl -si -w -L -X GET '.
      \ '-H "Cache-Control:no-cache" --data "test=test&foo=foo" ' .
      \ '''http://localhost:8000?testparam=test'''
let s:test_curl_request_form = 'curl -si -w -L -X GET '.
      \ '-H "Cache-Control:no-cache" --form "test=test&foo=foo" ' .
      \ '"http://localhost:8000?testparam=test"'

function! s:suite.request_line_ptrn()
  call s:assert.match('TEST:  test', s:R.request_line_ptrn)
  let l:data = matchlist('TEST:    test', s:R.request_line_ptrn)
  call s:assert.equals(l:data[1], 'TEST')
  call s:assert.equals(l:data[2], '')
  call s:assert.equals(l:data[3], 'test')
endfunction

function! s:suite.request_line_ptrn_with_name()
  call s:assert.match('TEST: :foobar: test', s:R.request_line_ptrn)
  let l:data = matchlist('TEST:  :foobar:  test', s:R.request_line_ptrn)
  call s:assert.equals(l:data[1], 'TEST')
  call s:assert.equals(l:data[2], ':foobar:')
  call s:assert.equals(l:data[3], 'test')
endfunction

function! s:suite.strip_name()
  call s:assert.match(':test:', s:R.strip_name)
  call s:assert.equals(matchlist(':test:', s:R.strip_name)[1], 'test')
endfunction

function! s:suite.strip()
  call s:assert.match('  test  ', s:R.strip)
  call s:assert.equals(matchlist('  test  ', s:R.strip)[1], 'test')
  call s:assert.equals(matchlist('test  ', s:R.strip)[1], 'test')
  call s:assert.equals(matchlist('  test', s:R.strip)[1], 'test')
  call s:assert.equals(matchlist("\ttest\t", s:R.strip)[1], 'test')
endfunction

function! s:suite.falsey()
  call s:assert.match('  0  ', s:R.falsey)
  call s:assert.match('  000  ', s:R.falsey)
  call s:assert.match('  false  ', s:R.falsey)
  call s:assert.match('  no  ', s:R.falsey)
  call s:assert.equals(matchlist('  0  ', s:R.falsey)[1], '0')
  call s:assert.equals(matchlist('0  ', s:R.falsey)[1], '0')
  call s:assert.equals(matchlist('  0', s:R.falsey)[1], '0')
  call s:assert.equals(matchlist("\t0\t", s:R.falsey)[1], '0')
endfunction

function! s:suite.uri()
  call s:assert.match('http://test.com', s:R.uri)
  call s:assert.match('git+ssh://github.com/foobar.git', s:R.uri)
  call s:assert.match('git+ssh://github.com/foobar.git test bags', s:R.uri)
  call s:assert.equals(matchstr('http://test.com', s:R.uri), 'http://test.com')
  call s:assert.equals(matchstr('git+ssh://github.com/foobar.git', s:R.uri), 'git+ssh://github.com/foobar.git')
  call s:assert.equals(matchstr('git+ssh://github.com/foobar.git test bags', s:R.uri), 'git+ssh://github.com/foobar.git')
  call s:assert.equals(matchstr(' pewpew git+ssh://github.com/foobar.git test bags ', s:R.uri), 'git+ssh://github.com/foobar.git')
endfunction

function! s:suite.response_header()
  call s:assert.match(s:test_response, s:R.response_header)
  call s:assert.equals(split(s:test_response, s:R.response_header)[1], '<body>TEST</body>')
endfunction

function! s:suite.content_type()
  call s:assert.match('Content-Type: text/plain', s:R.content_type)
  call s:assert.match('Content-Type: application/plain+xml', s:R.content_type)
  call s:assert.match('Content-Type: text/plain; charset=UTF-8', s:R.content_type)
  call s:assert.equals(matchstr('Content-Type: text/plain', s:R.content_type), 'text/plain')
  call s:assert.equals(matchstr('Content-Type: text/plain; charset=UTF-8', s:R.content_type), 'text/plain')
  call s:assert.equals(matchstr('Content-Type: application/plain+xml', s:R.content_type), 'application/plain+xml')
endfunction

function! s:suite.collection_name()
  call s:assert.match('[test] ~/pewpew.txt', s:R.collection_name)
  call s:assert.equals(matchstr('[test] ~/pewpew.txt', s:R.collection_name), 'test')
endfunction

function! s:suite.collection_path()
  call s:assert.match('[test] ~/pewpew.txt', s:R.collection_path)
  call s:assert.match('~/pewpew.txt', s:R.collection_path)
  call s:assert.equals(matchstr('[test] ~/pewpew.txt', s:R.collection_path), '~/pewpew.txt')
  call s:assert.equals(matchstr('~/pewpew.txt', s:R.collection_path), '~/pewpew.txt')
endfunction

function! s:suite.curl_method()
  call s:assert.equals(matchstr(s:test_curl_request, s:R.curl_method), 'GET')
endfunction

function! s:suite.curl_url()
  call s:assert.equals(matchstr(s:test_curl_request, s:R.curl_url), 'http://localhost:8000?testparam=test')
  call s:assert.equals(matchstr(s:test_curl_request_quotes, s:R.curl_url), 'http://localhost:8000?testparam=test')
endfunction

function! s:suite.curl_url_param_name()
  let l:url_param = 'foo=test'
  call s:assert.equals(matchstr(l:url_param, s:R.curl_url_param_name), 'foo')
endfunction

function! s:suite.curl_url_param_value()
  let l:url_param = 'foo=test'
  call s:assert.equals(matchstr(l:url_param, s:R.curl_url_param_value), 'test')
endfunction

function! s:suite.curl_header()
  call s:assert.equals(matchstr(s:test_curl_request, s:R.curl_header), 'Cache-Control:no-cache')
endfunction

function! s:suite.curl_form()
  call s:assert.equals(matchstr('something somthing -F ''test=foo'' something something', s:R.curl_form), 'test=foo')
endfunction

function! s:suite.curl_data()
  call s:assert.equals(matchstr('something somthing -d ''test=foo'' something something', s:R.curl_data), 'test=foo')
endfunction

function! s:suite.curl_data_fields()
  let l:data = 'test=test&foo=foo'
  call s:assert.equals(matchstr(l:data, s:R.curl_data_fields, 0), 'test=test')
  call s:assert.equals(matchstr(l:data, s:R.curl_data_fields, 9), 'foo=foo')
endfunction
