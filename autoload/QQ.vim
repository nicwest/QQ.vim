" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Go: {{{1
function! QQ#go () abort
  let l:uri = matchstr(getline('.'), s:R.uri)
  let l:query = {'METHOD': ['GET'], 'URL': [l:uri]}
  let [l:args, l:options] = QQ#query#get_options(l:query)
  let l:response = QQ#query#execute(l:query)
  call QQ#request#set_last_query(l:query)
  call QQ#history#save(l:query)
  call QQ#response#open(l:response, l:options)
endfunction

" Misc: {{{1
" vim:fdm=marker

