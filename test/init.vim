let s:suite = themis#suite('init')
let s:assert = themis#helper('assert')

function! s:suite.QQ_loaded()
  call s:assert.exists('g:QQ_loaded')
  call s:assert.equals(g:QQ_loaded, 1)
endfunction

function! s:suite.QQ_curl_executable()
  call s:assert.exists('g:QQ_curl_executable')
  call s:assert.equals(g:QQ_curl_executable, 'curl')
endfunction

function! s:suite.QQ_default_collection()
  call s:assert.exists('g:QQ_default_collection')
  call s:assert.equals(g:QQ_default_collection, '~/.QQ.default.collection')
endfunction

function! s:suite.QQ_collection_list()
  call s:assert.exists('g:QQ_collection_list')
  call s:assert.equals(g:QQ_collection_list, '~/.QQ.collections')
endfunction

function! s:suite.QQ_current_collection()
  call s:assert.exists('g:QQ_current_collection')
  call s:assert.equals(g:QQ_current_collection, g:QQ_default_collection)
endfunction

function! s:suite.QQ_collection_window_location()
  call s:assert.exists('g:QQ_collection_window_location')
  call s:assert.equals(g:QQ_collection_window_location, 'top')
endfunction

function! s:suite.QQ_collection_window_height()
  call s:assert.exists('g:QQ_collection_window_height')
  call s:assert.equals(g:QQ_collection_window_height, 10)
endfunction

function! s:suite.QQ_buffer_prefix()
  call s:assert.exists('g:QQ_buffer_prefix')
  call s:assert.equals(g:QQ_buffer_prefix, '[QQ]')
endfunction
