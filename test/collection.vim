let s:suite = themis#suite('collection')
let s:assert = themis#helper('assert')
call themis#helper('command')
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

function! AddLine(str)
  put! = a:str
endfunction

function! AddLines(lines)
  for line in reverse(copy(a:lines))
    put! = line
  endfor
endfunction

function! CallWithInput(func, input)
  exe 'normal :call '.join([a:func.'()'] + a:input, '').''
endfunction

let s:test_collections = [
      \ '[test] /path/to/test/collection',
      \ '[foo] /path/to/foo/pewpew',
      \ '[bar] /one/man/walks/into/a',
      \ ]

let s:test_names = ['test', 'foo', 'bar']

let s:test_paths = [
      \ '/path/to/test/collection',
      \ '/path/to/foo/pewpew',
      \ '/one/man/walks/into/a',
      \ ]

" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Open: {{{1
function! s:suite.open_creates_new_buffer()
  call s:assert.false(bufexists(s:B.collections))
  call QQ#collection#open()
  call s:assert.true(bufexists(s:B.collections))
endfunction

function! s:suite.open_creates_new_window_of_correct_size()
  call QQ#collection#open()
  " checks window width is the specified 10 rows or is full width minus
  " one row for the separator and one rows for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_10_or_fullheight = or(
        \  winheight(0) == 10,
        \  winheight(0) == &lines - 4)
  call s:assert.true(window_is_10_or_fullheight)
endfunction

function! s:suite.open_doesnt_recreate_buffer()
  exe 'badd' s:B.collections
  call s:assert.true(bufexists(s:B.collections))
  call s:assert.length_of(s:buflist(), 1)
  call QQ#collection#open()
  call s:assert.true(bufexists(s:B.collections))
  call s:assert.length_of(s:buflist(), 1)
endfunction

function! s:suite.open_replaces_open_request_buffer()
  exe 'badd' s:B.history
  exe 'sb' bufnr(s:B.history)
  call s:assert.not_equals(bufwinnr(s:B.history), -1)
  call QQ#collection#open()
  call s:assert.true(bufexists(s:B.history))
  call s:assert.true(bufexists(s:B.collections))
  call s:assert.length_of(s:buflist(), 2)
  call s:assert.equals(bufwinnr(s:B.history), -1)
  call s:assert.not_equals(bufwinnr(s:B.collections), -1)
endfunction

function! s:suite.open_replaces_window_of_correct_size()
  exe 'badd' s:B.history
  exe 'vert sb' bufnr(s:B.history)
  call QQ#collection#open()
  " checks window width is the specified 80 columns or is full width minus
  " one column for the separator and one column for the previous buffer.
  " Bit hacky hense the explanation
  let window_is_10_or_fullheight = or(
        \  winheight(0) == 10,
        \  winheight(0) == &lines - 4)
  call s:assert.true(window_is_10_or_fullheight)
endfunction

function! s:suite.open_buffer_created_populates_with_default()
  call s:assert.false(bufexists(s:B.collections))
  call QQ#collection#open()
  let l:buffer_text = getbufline(bufnr(s:B.collections), 0, '$')
  call s:assert.not_equals(l:buffer_text, ['--NO COLLECTIONS--'])
endfunction

function! s:suite.open_buffer_created_populates_with_response()
  call s:assert.false(bufexists(s:B.collections))
  call QQ#collection#open()
  let l:buffer_text = getbufline(bufnr(s:B.collections), 0, '$')
  call s:assert.not_equals(l:buffer_text, ['--NO COLLECTIONS--'])
endfunction

" Setup: {{{1
function! s:suite.setup_settings()
  exe 'new' s:B.collections
  call QQ#collection#setup()
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
  call s:assert.equals(b:current_syntax, 'QQ')
  call s:assert.equals(&l:foldmethod, 'syntax')
endfunction

" Populate: {{{1

function! s:suite.populate_sets_not_modifiable()
  exe 'new' s:B.collections
  let b:collections = []
  call QQ#collection#populate()
  call s:assert.equals(&l:modifiable, 0)
endfunction

function! s:suite.populates_with_correct_queries()
  exe 'new' s:B.collections
  let b:collections = s:test_collections
  call QQ#collection#populate()
  call s:assert.equals(getbufline(s:B.collections, 1, '$'), s:test_collections)

endfunction

" Save: {{{1

function! s:suite.paths_reduces_list_to_paths_only()
  let l:collections = QQ#collection#paths(s:test_collections)
  call s:assert.equals(l:collections, s:test_paths)
endfunction

function! s:suite.names_reduces_list_to_name_only()
  let l:collections = QQ#collection#names(s:test_collections)
  call s:assert.equals(l:collections, s:test_names)
endfunction

function! s:suite.remove_collection()
  let l:collections = QQ#collection#remove(s:test_collections, '/path/to/test/collection')
  let l:expected = s:test_collections[1:]
  call s:assert.equals(l:collections, l:expected)
endfunction

function! s:suite.add_collection_new()
  let l:filepath = tempname()
  let l:collections = QQ#collection#add(s:test_collections, l:filepath, 'pew')
  let l:expected = s:test_collections + ['[pew] '.l:filepath]
  call s:assert.equals(l:collections, l:expected)
endfunction

function! s:suite.add_collection_existing()
  let l:filepath = tempname()
  let l:test_collections = ['[sausage] '.l:filepath] + s:test_collections
  let l:collections = QQ#collection#add(s:test_collections, l:filepath, 'pew')
  let l:expected = s:test_collections + ['[pew] '.l:filepath] 
  call s:assert.equals(l:collections, l:expected)
endfunction

function! s:suite.collections_adds_empty_file()
  let l:old_list = copy(g:QQ_collection_list)
  let g:QQ_collection_list = tempname()
  let l:collections = QQ#collection#collections(g:QQ_collection_list)
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:collections, [])
endfunction

function! s:suite.collections_reads_file()
  let l:old_list = copy(g:QQ_collection_list)
  let g:QQ_collection_list = tempname()
  call writefile(s:test_collections, g:QQ_collection_list)
  let l:collections = QQ#collection#collections(g:QQ_collection_list)
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:collections, s:test_collections)
endfunction

" Set: {{{1

function! s:suite.set_current_collection()
  let l:old_collection = copy(g:QQ_current_collection)
  let l:filepath = tempname()
  call QQ#collection#set(l:filepath)
  let l:new_collection = g:QQ_current_collection
  let g:QQ_current_collection = l:old_collection
  call s:assert.equals(l:new_collection, l:filepath)
endfunction

function! s:suite.set_opens_history()
  let l:old_collection = copy(g:QQ_current_collection)
  call s:assert.false(bufexists(s:B.history))
  call QQ#collection#set(tempname())
  let g:QQ_current_collection = l:old_collection
  call s:assert.true(bufexists(s:B.history))
endfunction

" Completion: {{{1

function! s:suite.completion_returns_new_lined_string()
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath = tempname()
  let g:QQ_collection_list = l:filepath
  call writefile(s:test_collections, l:filepath)
  let l:completion = QQ#collection#completion('A', 'L', 'P')
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:completion, join(s:test_names, "\n"))
endfunction

" Execute: {{{1

function! s:suite.to_history_opens_history_buffer()
  let l:old_collection = copy(g:QQ_current_collection)
  call s:assert.false(bufexists(s:B.history))
  exe 'new' s:B.collections
  let l:filepath = tempname()
  let b:collections = ['[pew]'.l:filepath]
  call QQ#collection#to_history()
  let g:QQ_current_collection = l:old_collection
  call s:assert.true(bufexists(s:B.history))
endfunction

function! s:suite.to_history_opens_correct_collection()
  let l:old_collection = copy(g:QQ_current_collection)
  call s:assert.false(bufexists(s:B.history))
  exe 'new' s:B.collections
  call AddLines(s:test_names)
  let l:filepath = tempname()
  let b:collections = s:test_collections + ['[pew]'.l:filepath]
  norm jjj
  call QQ#collection#to_history()
  let l:new_collection = g:QQ_current_collection
  let g:QQ_current_collection = l:old_collection
  call s:assert.equals(l:new_collection, l:filepath)
endfunction

function! s:suite.new_saves_collection()
  let l:old_collection = copy(g:QQ_current_collection)
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath_collection = tempname()
  let l:filepath_list = tempname()
  let g:QQ_collection_list = l:filepath_list
  call CallWithInput('QQ#collection#new', [''.l:filepath_collection, 'pew'])
  let g:QQ_current_collection = l:old_collection
  let g:QQ_collection_list = l:old_list
  let l:collections = readfile(l:filepath_list)
  call s:assert.equals(l:collections, ['[pew] '.l:filepath_collection])
endfunction

function! s:suite.new_sets_new_collection_to_current_collection()
  let l:old_collection = copy(g:QQ_current_collection)
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath_collection = tempname()
  let l:filepath_list = tempname()
  let g:QQ_collection_list = l:filepath_list
  call CallWithInput('QQ#collection#new', [''.l:filepath_collection, 'pew'])
  let l:new_collection = g:QQ_current_collection
  let g:QQ_current_collection = l:old_collection
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:new_collection, l:filepath_collection)
endfunction

function! s:suite.change_changes_collection_when_name_exists()
  let l:old_collection = copy(g:QQ_current_collection)
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath_collection = tempname()
  let l:filepath_list = tempname()
  let g:QQ_collection_list = l:filepath_list
  call writefile(s:test_collections + ['[pew]'.l:filepath_collection], l:filepath_list)
  call CallWithInput('QQ#collection#change', ['pew'])
  let l:new_collection = g:QQ_current_collection
  let g:QQ_current_collection = l:old_collection
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:new_collection, l:filepath_collection)
endfunction

function! s:suite.change_changes_collection_when_name_exists()
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath_list = tempname()
  let g:QQ_collection_list = l:filepath_list
  call writefile(s:test_collections, l:filepath_list)
  Throws /collection with the name 'pew' could not be found/
        \ :call CallWithInput('QQ#collection#change', ['pew'])
  let g:QQ_collection_list = l:old_list
endfunction

" Utils: {{{1

function! s:suite.get_path_from_name_name_exists()
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath = tempname()
  let g:QQ_collection_list = l:filepath
  call writefile(s:test_collections, l:filepath)
  let l:path = QQ#collection#get_path_from_name('test')
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:path, '/path/to/test/collection')
endfunction

function! s:suite.get_path_from_name_no_name()
  let l:old_list = copy(g:QQ_collection_list)
  let l:filepath = tempname()
  let g:QQ_collection_list = l:filepath
  call writefile(s:test_collections, l:filepath)
  let l:path = QQ#collection#get_path_from_name('pew')
  let g:QQ_collection_list = l:old_list
  call s:assert.equals(l:path, '')
endfunction


" Mapping: {{{1
"
function! s:suite.maps_correct_keys()
  call QQ#collection#map_keys()
  call s:assert.equals(maparg('<CR>', 'n'), ':call QQ#collection#to_history()<CR>')
  call s:assert.equals(maparg('q', 'n'), ':call QQ#utils#close_window()<CR>')
endfunction






" Misc: {{{1
" vim:fdm=marker
