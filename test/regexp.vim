let s:suite = themis#suite('regexp')
let s:assert = themis#helper('assert')

let s:R = QQ#regexp#import()

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
