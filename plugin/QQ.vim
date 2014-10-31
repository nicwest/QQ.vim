if exists('g:QQ_loaded')
  finish
endif

"other wise mark that it is loaded
let g:QQ_loaded = 1

if !exists('g:QQ_curl_executable')
  "so we are going to use this just in case someone wants to specify a different
  "curl executable
  let g:QQ_curl_executable = 'curl'
endif

if !exists('g:QQ_default_collection')
  "default collection location
  let g:QQ_default_collection = '~/.QQ.default.collection'
endif

if !exists('g:QQ_collection_list')
  "collection list location
  let g:QQ_collection_list = '~/.QQ.collections'
endif

if !exists('g:QQ_current_collection')
  "current collection
  let g:QQ_current_collection = g:QQ_default_collection
endif

if !exists('g:QQ_collection_window_location')
  "collection window location
  let g:QQ_collection_window_location = 'top'
endif

if !exists('g:QQ_collection_window_height')
  "collection window height
  let g:QQ_collection_window_height = 10
endif

if !exists('g:QQ_buffer_prefix')
  "buffer prefix
  let g:QQ_buffer_prefix = '[QQ]'
endif
