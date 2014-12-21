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

function! s:suite.QQ_map_prefix()
  call s:assert.exists('g:QQ_map_prefix')
  call s:assert.equals(g:QQ_map_prefix, 'Q')
endfunction

function! s:suite.QQ_map_defaults()
  call s:assert.exists('g:QQ_map_defaults')
  call s:assert.equals(g:QQ_map_defaults, 1)
endfunction

function! s:suite.QQ_defaults_mapped()
  call s:assert.exists('g:QQ_defaults_mapped')
  call s:assert.equals(g:QQ_defaults_mapped, 1)
endfunction

function! s:suite.plug_maps_exist()
  call s:assert.equals(maparg('<Plug>QQRequest'), ':call QQ#request#open()<CR>')
  "call s:assert.equals(maparg('<Plug>QQSend'), ':call QQ#request#send()<CR>')
  "call s:assert.equals(maparg('<Plug>QQBasicAuth'), ':call QQ#auth#basic()<CR>')
  "call s:assert.equals(maparg('<Plug>QQOAuth2'), ':call QQ#auth#oauth2()<CR>')
  "call s:assert.equals(maparg('<Plug>QQPrettyPrint'), ':call QQ#auth#add_option(''pretty-print'')<CR>')
  "call s:assert.equals(maparg('<Plug>QQFollow'), ':call QQ#auth#add_option(''follow'')<CR>')
  call s:assert.equals(maparg('<Plug>QQHistory'), ':call QQ#history#open()<CR>')
  "call s:assert.equals(maparg('<Plug>QQHistoryRequest'), ':call QQ#history#to_request()<CR>')
  call s:assert.equals(maparg('<Plug>QQCollections'), ':call QQ#collection#open()<CR>')
  "call s:assert.equals(maparg('<Plug>QQCollectionHistory'), ':call QQ#collection#to_history()<CR>')
  call s:assert.equals(maparg('<Plug>QQCollectionNew'), ':call QQ#collection#new()<CR>')
  call s:assert.equals(maparg('<Plug>QQCollectionChange'), ':call QQ#collection#change()<CR>')
  call s:assert.equals(maparg('<Plug>QQGo'), ':call QQ#go()<CR>')
  "call s:assert.equals(maparg('<Plug>QQClose'), ':call QQ#utils#close_window()<CR>')
endfunction

function! s:suite.default_mappings()
  call s:assert.equals(maparg('QQ'), '<Plug>QQRequest')
  call s:assert.equals(maparg('QH'), '<Plug>QQHistory')
  call s:assert.equals(maparg('QCO'), '<Plug>QQCollections')
  call s:assert.equals(maparg('QCN'), '<Plug>QQCollectionNew')
  call s:assert.equals(maparg('QCC'), '<Plug>QQCollectionChange')
  call s:assert.equals(maparg('QG'), '<Plug>QQGo')
endfunction
