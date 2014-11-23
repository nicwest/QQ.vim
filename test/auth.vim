let s:suite = themis#suite('auth')
let s:assert = themis#helper('assert')
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

let s:B = QQ#buffers#import()
" Basic {{{1
function! s:suite.basic()
  exe "new ".s:B.request
  call CallWithInput('QQ#auth#basic', ['testuser', 'testpassword'])
  let l:buffer_text = getbufline(bufnr(s:B.request), 0, '$')
  call s:assert.equals(l:buffer_text, ['', 'HEADER: :Authorization: Basic dGVzdHVzZXI6dGVzdHBhc3N3b3Jk'])
endfunction

" oAuth2 {{{1

function! s:suite.oauth2()
  " TODO: test this, have to mock system...
endfunction
" Misc: {{{1
" vim:fdm=marker
