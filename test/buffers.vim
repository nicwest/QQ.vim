let s:suite = themis#suite('buffers')
let s:assert = themis#helper('assert')

let s:B = QQ#buffers#import()

" Import: {{{1
function! s:suite.import()
  call s:assert.is_dict(s:B)
  call s:assert.length_of(s:B, 4)
  call s:assert.is_string(s:B.request)
  call s:assert.is_string(s:B.response)
  call s:assert.is_string(s:B.history)
  call s:assert.is_string(s:B.collections)
endfunction

function! s:suite.request_buffer_name()
  call s:assert.equals(s:B.request, '[QQ]REQUEST')
endfunction

function! s:suite.response_buffer_name()
  call s:assert.equals(s:B.response, '[QQ]RESPONSE')
endfunction

function! s:suite.history_buffer_name()
  call s:assert.equals(s:B.history, '[QQ]HISTORY')
endfunction

function! s:suite.collections_buffer_name()
  call s:assert.equals(s:B.collections, '[QQ]COLLECTIONS')
endfunction
