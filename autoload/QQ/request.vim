" Imports {{{1
let s:B = QQ#buffers#import()
let s:R = QQ#regexp#import()

" Defaults: {{{1
let s:last_query = {
      \ "URL": ["http://localhost:8000"], 
      \ "METHOD": ["GET"], 
      \ "URL-VAR": [["testvar", "users"]], 
      \ "URL-PARAM": [["testparam", "test"]],
      \ "HEADER": [["Cache-Control", "no-cache"]], 
      \ "FORM": [],
      \ "FORM-FILE": [],
      \ "BODY": [],
      \ "OPTION": [["pretty-print", "True"]]
      \ }

let s:query_arg_order = [
      \ 'METHOD', 'URL', 'URL-PARAM', 'URL-VAR', 'HEADER', 'OPTION', 'FORM',
      \ 'FORM-FILE', 'BODY']

" Open: {{{1
function! QQ#request#open(...) abort
  "finds the REQUEST buffer where ever it may be
  if !bufexists(s:B.request) && !bufexists(s:B.response)
    "neither request or response buffer exists
    sil! exe 'keepa bo 50vnew' s:B.request
  elseif !bufexists(s:B.request) && bufwinnr(s:B.response) != -1
    "request buffer doesn't exist, response buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.response)
    sil! exe 'badd' s:B.request
    sil! exe 'buf' bufnr(s:B.request) 
    sil! exe 'vert res 50'
  elseif !bufexists(s:B.request) && bufexists(s:B.response)
    "request buffer doesn't exist, response buffer exists but is not in window
    sil! exe 'keepa bo vert sb' s:B.response
    sil! exe 'vert res 50'
    sil! exe 'badd' s:B.request
    sil! exe 'buf' bufnr(s:B.request) 
  elseif bufwinnr(s:B.request) == -1 && bufwinnr(s:B.response) != -1
    "request buffer exists, response buffer exists and is in window
    call QQ#utils#focus_window_with_name(s:B.response)
    sil! exe 'buf' bufnr(s:B.request) 
    sil! exe 'vert res 50'
  elseif bufwinnr(s:B.request) == -1
    "request buffer exists but is not in window
    sil! exe 'keepa bo vert sb' bufnr(s:B.request)
    sil! exe 'vert res 50'
  else 
    call QQ#utils#focus_window_with_name(s:B.request)
  endif
  call QQ#request#map_keys()
  call QQ#request#setup()
  let l:query = a:0 ? a:1 : s:last_query 
  call QQ#request#populate(l:query)
endfunction

" Setup: {{{1
function! QQ#request#setup() abort
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

" Convert: {{{1
function! QQ#request#convert() abort
  let request = {}
  let l:is_body = 0
  for line in getbufline(bufnr(s:B.request), 0, line('$'))
    if line =~# s:R.body_line_ptrn 
      let l:rest = matchlist(line, s:R.body_line_ptrn)[1]
      let request.BODY = []
      if len(l:rest) > 0
        call add(request.BODY, l:rest)
      endif
      let l:is_body = 1
    elseif l:is_body
      call add(request.BODY, line)
    elseif line =~# s:R.request_line_ptrn
      let group = matchlist(line, s:R.request_line_ptrn)
      let line_attr = group[1]
      let line_name = QQ#utils#strip_name(group[2])
      let line_value = group[3]
      if !has_key(request, line_attr)
        let request[line_attr] = []
      endif
      if len(line_name) > 0
        call add(request[line_attr], [line_name, line_value])
      else
        call add(request[line_attr], line_value)
      endif
    endif
  endfor
  return request
endfunction

" Populate: {{{1

function! QQ#request#populate(...)  abort
  let query = a:0 ? a:1 : s:last_query 
  let lines = []
  let items = map(copy(s:query_arg_order), '[v:val, get(query, v:val, [])]')
  for item in items 
    if item[0] == 'BODY'
      continue
    endif
    for attr in item[1]
      if type(attr) == type([])
        call add(lines, item[0].":\t:".attr[0].": ".attr[1])
      else
        call add(lines, item[0].":\t".attr)
      endif
      unlet attr
    endfor
  endfor
  if has_key(query, 'BODY') && len(query.BODY) > 0
    call add(lines, 'BODY:')
    call extend(lines, query.BODY)
  endif
  normal! gg"_dG
  call append(0, lines)
  normal! G"_ddgg
endfunction



" Send: {{{1

function! QQ#request#send() abort
  let l:query = QQ#request#convert()
  let l:options = QQ#query#get_options(l:query)[1]
  let l:response = QQ#query#execute(l:query)
  let s:last_query = l:query
  call QQ#history#save(l:query)
  call QQ#response#open(l:response, l:options)
endfunction

" Helpers: {{{1

function! QQ#request#add_option(option_name) abort
  call append(line("$"), ["OPTION: :" . a:option_name . ": true"])
endfunction

function! QQ#request#set_last_query(query) abort
  let s:last_query = a:query
endfunction

" Mapping: {{{1
function! QQ#request#map_keys () abort
  nmap <buffer> QQ :call QQ#request#send()<CR>
  nmap <buffer> QAB :call QQ#auth#basic()<CR>
  nmap <buffer> QAO :call QQ#auth#oauth2()<CR>
  nmap <buffer> QP :call QQ#request#add_option('pretty-print')<CR>
  nmap <buffer> QF :call QQ#request#add_option('follow')<CR>
endfunction
" Misc: {{{1
" vim:fdm=marker
