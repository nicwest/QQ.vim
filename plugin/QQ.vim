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
  let g:QQ_current_collection = copy(g:QQ_default_collection)
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

if !exists('g:QQ_map_prefix')
  "prefix to map command with
  let g:QQ_map_prefix = 'Q'
endif

if !exists('g:QQ_map_defaults')
  "map default keys
  let g:QQ_map_defaults = 1
endif

if !exists('g:QQ_defaults_mapped')
  "default keys have been mapped
  let g:QQ_defaults_mapped = 0
endif

nnoremap <silent> <Plug>QQRequest :call QQ#request#open()<CR>
nnoremap <silent> <Plug>QQHistory :call QQ#history#open()<CR>
nnoremap <silent> <Plug>QQCollections :call QQ#collection#open()<CR>
nnoremap <silent> <Plug>QQCollectionNew :call QQ#collection#new()<CR>
nnoremap <silent> <Plug>QQCollectionChange :call QQ#collection#change()<CR>
nnoremap <silent> <Plug>QQGo :call QQ#go()<CR>

let s:key_mappings = [
      \ {'suffix': 'Q', 'plug': 'QQRequest'},
      \ {'suffix': 'H', 'plug': 'QQHistory'},
      \ {'suffix': 'CO', 'plug': 'QQCollections'},
      \ {'suffix': 'CN', 'plug': 'QQCollectionNew'},
      \ {'suffix': 'CC', 'plug': 'QQCollectionChange'},
      \ {'suffix': 'CG', 'plug': 'QQGo'},
      \ ]

if g:QQ_map_defaults && !g:QQ_defaults_mapped
  for key_mapping in s:key_mappings
    let plug_name = '<Plug>' . key_mapping.plug
    if !hasmapto(plug_name)
      exe 'nmap' g:QQ_map_prefix . key_mapping.suffix plug_name
    endif
  endfor
  let g:QQ_defaults_mapped = 1
endif
