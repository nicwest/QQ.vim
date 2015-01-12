" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Open: {{{1
function! QQ#collection#open (...) abort
  "finds the COLLECTION buffer where ever it may be
  let l:position = g:QQ_collection_window_location == 'top' ? 'to' : 'bo' 
  let l:height = g:QQ_collection_window_height
  if !bufexists(s:B.collections) && !bufexists(s:B.history)
    "neither history or collections buffer exists
    sil! exe 'keepa' l:position l:height.'new' s:B.collections
  elseif !bufexists(s:B.collections) && bufwinnr(s:B.history) != -1
    "collections buffer doesn't exist, history buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.history)
    sil! exe 'badd' s:B.collections
    sil! exe 'buf' bufnr(s:B.collections) 
    sil! exe 'res' l:height
  elseif !bufexists(s:B.collections) && bufexists(s:B.history)
    "collections buffer doesn't exist, history buffer exists but is not in window
    sil! exe 'keepa' l:position l:height.'sb' bufnr(s:B.history)
    sil! exe 'res' l:height
    sil! exe 'badd' s:B.collections
    sil! exe 'buf' bufnr(s:B.collections) 
  elseif bufwinnr(s:B.collections) == -1 && bufwinnr(s:B.history) != -1
    "collections buffer exists, history buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.history)
    sil! exe 'buf' bufnr(s:B.collections) 
  elseif bufwinnr(s:B.collections) == -1
    "collections buffer exists but is not in window
    sil! exe 'keepa' l:position 'sb' bufnr(s:B.collections)
    sil! exe 'res' l:height
  else 
    call QQ#utils#focus_window_with_name(s:B.collections)
  endif
  call QQ#collection#setup()
  call QQ#collection#map_keys()
  let b:collections = QQ#collection#collections(g:QQ_collection_list)
  call QQ#collection#populate()
endfunction

" Setup: {{{1
function! QQ#collection#setup() abort
  set ft=QQ
  setl noswf nonu nobl nospell nocuc wfw
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=hide
  if v:version > 702
    setl nornu noudf cc=0
  end
  let b:current_syntax = "QQ"
  syn sync fromstart
  set foldmethod=syntax
endfunction

" Populate: {{{1
function! QQ#collection#populate() abort
  setl ma
  norm gg"_dG
  call append(0, b:collections)
  norm G"_ddgg
  setl noma
endfunction

" Save: {{{1

function! s:filepath() abort
  return resolve(expand(g:QQ_collection_list))
endfunction

function! QQ#collection#paths(collections) abort
  return map(copy(a:collections), 'matchstr(v:val, s:R.collection_path)')
endfunction

function! QQ#collection#names(collections) abort
  return map(copy(a:collections), 'matchstr(v:val, s:R.collection_name)')
endfunction

function! QQ#collection#remove (collections, filepath) abort
  let in_collections = index(QQ#collection#paths(a:collections), a:filepath)
  let l:collections = copy(a:collections)
  if in_collections > -1
    call remove(l:collections, in_collections)
  endif
  return l:collections
endfunction

function! QQ#collection#add (collections, filepath, name) abort
  call QQ#collection#viable(a:filepath)
  let l:collections = QQ#collection#remove(a:collections, a:filepath)
  if !len(a:name)
    let l:collections = l:collections + [a:filepath]
  else
    let l:collections = l:collections + ['['.a:name.'] '.a:filepath]
  endif
  return l:collections
endfunction

function! QQ#collection#collections (filepath) abort
  if filereadable(expand(a:filepath))
    return readfile(expand(a:filepath))
  else
    call writefile([], expand(a:filepath))
    return []
  endif
endfunction

function! QQ#collection#viable (filepath) abort
  let path = fnamemodify(a:filepath, ":p")
  if isdirectory(path)
    throw "collection path is directory:".a:filepath
  endif
  let directory = fnamemodify(a:filepath, ":p:h")
  if !isdirectory(directory)
    throw "target directory doesn't exist:".directory
  endif
endfunction

function! QQ#collection#save(filepath, collections) abort
  call writefile(a:collections, a:filepath)
endfunction

" Set: {{{1
function! QQ#collection#set (filepath) abort
  let g:QQ_current_collection = a:filepath
  call QQ#history#open(a:filepath)
  echo g:QQ_buffer_prefix "current collection:" a:filepath
endfunction

" Completion: {{{1

function! QQ#collection#completion (...) abort
  let l:collection_list = QQ#collection#names(QQ#collection#collections(g:QQ_collection_list))
  return join(l:collection_list, "\n")
endfunction

" Execute: {{{1

function! QQ#collection#to_history() abort
  let l:collection=matchstr(get(b:collections, line('.')-1, 0), s:R.collection_path)
  let g:QQ_current_collection = l:collection
  call QQ#history#open(l:collection)
endfunction

function! QQ#collection#new() abort
  let l:filepath = input("New collection: ", ".QQ.collection", "file")
  let l:name = input("Collection name: ")
  let l:collections = QQ#collection#collections(s:filepath()) 
  let l:collections = QQ#collection#add(l:collections, l:filepath, l:name)
  call QQ#collection#save(s:filepath(), l:collections)
  call QQ#collection#set(l:filepath)
endfunction

function! QQ#collection#change() abort
  let l:collection = input("Change collection: ", "", "custom,QQ#collection#completion")
  let l:filepath = QQ#collection#get_path_from_name(l:collection)
  if len(l:filepath) > 0
    call QQ#collection#set(l:filepath)
  else
    throw "collection with the name '".l:collection."' could not be found"
  endif
endfunction

" Utils: {{{1

function! QQ#collection#get_path_from_name(name) abort
  let l:collection_list = QQ#collection#collections(g:QQ_collection_list)
  call filter(l:collection_list, "v:val =~ '\\['.a:name.'\\].*$'")
  if len(l:collection_list) > 0
    return matchstr(l:collection_list[0], s:R.collection_path)
  else
    return ''
  endif
endfunction

" Mapping: {{{1

function! QQ#collection#map_keys () abort
  nnoremap <buffer> <CR> :call QQ#collection#to_history()<CR>
  nnoremap <buffer> q :call QQ#utils#close_window()<CR>
endfunction

" Misc: {{{1
" vim:fdm=marker
