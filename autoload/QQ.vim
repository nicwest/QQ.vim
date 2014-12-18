" Imports: {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Go: {{{1
function! QQ#go () abort
  let l:uri = matchstr(getline('.'), s:R.uri)
  let l:query = {'METHOD': ['GET'], 'URL': [l:uri]}
  call QQ#request#open(l:query)
endfunction

" Misc: {{{1
" vim:fdm=marker

