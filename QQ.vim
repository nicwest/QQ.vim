"if !exists('g:loaded_QQ') || &cp
"    finish
"endif

""other wise mark that it is loaded
"let g:loaded_QQ = 1

"so we are going to use this just in case someone wants to specify a different
"curl executable
if !exists('g:QQ_curl_executable')
  let g:QQ_curl_executable = 'curl'
endif

"this matches "{option}: [:{key}:] {value}"
let s:request_line_ptrn = "^\\([A-Z-]\\+\\):\\s\\+\\(:[^:/]\\+:\\)\\?\\s*\\(.*\\)$"

"turns ":{key}:" into "{key}"
function! StripName(input_string)
  return substitute(a:input_string, '^:\(.\{-}\):$', '\1', '')
endfunction

"if string is 0, false, or no it is falsey (normally this would include nil
"values or empty stings, but for the moment I think these will be synonymous
"with setting true in the context of "OPTION: :{key}: {value}", might change
"this later)
function! s:falsey(input_string)
  if a:input_string =~ "^\\s*\\(0\\|false\\|no\\)\\+\\s*$"
    return 1
  else
    return 0
  endif
endfunction

"if it's not falsey then it's truthy
function! s:truthy(input_string)
    return 1 - s:falsey(a:input_string)
endfunction

function! s:QQ_request_syntax() abort
  let b:current_syntax = "QQ"
  syn match QQArg "^[a-zA-Z-]\+:"
  syn match QQUrlParam ":[^/:]\+:" contained
  syn match QQUrl "\S\+:\/\/\S\+" contains=QQUrlParam
  syn match QQArgParam "^[a-zA-Z-]\+:\s\+:[^/:]\+:" contains=QQArg,QQUrlParam
  syn keyword QQMethods GET POST PUT DELETE
  syn keyword QQResponseInformational 100 101
  syn keyword QQResponseSuccess 200 201 202 203 204 205 206
  syn keyword QQResponseRedirection 300 301 302 303 304 305 306 307
  syn keyword QQResponseClientError 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417
  syn keyword QQResponseServerError 500 501 502 503 504 505 506
  syn region QQHeaderFold start="^[A-Z]\+\/[0-9\.]\+\s\+[0-9]\+\s\+[A-Z]\+.*" end="\n\n" fold keepend contains=QQArg,QQResponseSuccess,QQResponseInformational,QQResponseRedirection,QQResponseClientError,QQResponseServerError
  hi def link QQArg Constant
  hi def link QQUrlParam String
  hi def link QQMethods Keyword
  hi QQResponseInformational ctermbg=NONE ctermfg=7
  hi QQResponseSuccess ctermbg=NONE ctermfg=10
  hi QQResponseRedirection ctermbg=NONE ctermfg=14
  hi QQResponseClientError ctermbg=NONE ctermfg=13
  hi QQResponseServerError ctermbg=NONE ctermfg=4
  syn sync fromstart
  set foldmethod=syntax
endfunction

augroup QQ
  autocmd!
  autocmd BufWinLeave * let s:QQ_open = 0
  autocmd Syntax QQ call s:QQ_request_syntax()
augroup END

"open a new window
function! s:open_window(...) abort
  if exists('s:reloading_QQ')
    return
  endif
  let s:reloading_QQ = 1
  vert new REQUEST
  set ft=QQ
  setlocal buftype=nofile
  setlocal noswapfile
  let s:request_buffer = bufnr("%") 
  let s:request_window = winnr()
  call s:prefill_buffer()
  nnoremap <buffer> QQ :call QQ#send_request()<CR>
  unlet s:reloading_QQ
endfunction

function! QQ#open_window(...) abort
  call s:open_window(a:000)
endfunction

"converts buffer to request array and executes it
function! QQ#send_request(...) abort
  call s:convert_buffer(bufnr(""))
  call s:exec_curl(bufnr(""))
endfunction

"turn buffer into list of curl varibles
function! s:convert_buffer(bufno_of_request) abort
  let request = {}
  for line in getbufline(a:bufno_of_request, 0, line("$"))
    if line =~# s:request_line_ptrn
      let group = matchlist(line, s:request_line_ptrn) 
      let line_attr = group[1]
      let line_name = StripName(group[2])
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
  let s:last_request = request
  let b:request = request
endfunction

"prefill buffer
function! s:prefill_buffer(...) abort
  if !exists("s:last_request")  
    let s:last_request = {
          \ "URL": ["http://localhost:8000"], 
          \ "METHOD": ["GET"], 
          \ "URL-PARAM": [["testparam", "users"]], 
          \ "HEADER": [["Cache-Control", "no-cache"]], 
          \ "BODY": [""],
          \ "OPTION": [["pretty-print", "True"]]
          \ }
  endif
  let prefill = []
  for item in items(s:last_request)
    for attr in item[1]
      if type(attr) == type([])
        call add(prefill, item[0].":\t:".attr[0].": ".attr[1])
      else
        call add(prefill, item[0].":\t".attr)
      endif
      unlet attr
    endfor
  endfor
  normal! gg"_dG
  call append(0, prefill)
  normal! gg
endfunction

"execute curl
function! s:exec_curl(request_buffer) abort
  let request=getbufvar(a:request_buffer, 'request')
  badd RESPONSE
  buffer RESPONSE
  set ft=json
  setlocal buftype=nofile
  setlocal noswapfile
  let curl_str=g:QQ_curl_executable . " -si "
  let url=request["URL"][0]
  for option in get(request, "OPTION", [])
    if and(option[0] == "follow", s:truthy(option[1]))
      let curl_str.=" -L"
    endif
  endfor
  for header in get(request, "HEADER", [])
    let curl_str.=" -H \"".header[0].": ".header[1]."\""
  endfor
  for param in get(request, "URL-PARAM", [])
    let url=substitute(url, ":".param[0].":", param[1], "g")
  endfor
  let curl_str.= " ".url
  let b:response = system(curl_str)
  call s:save_query(curl_str)
  call s:show_response(bufnr(""))
endfunction

"save query
function! s:save_query (query) abort
  let filename=resolve(expand("~/.QQ.vim.history"))
  if filereadable(filename)
    "TODO: needs to be cross platform, does windows have cat?
    let contents=system('cat '.filename)
  else
    "TODO: needs to be cross platform, does windows have touch?
    call system('touch '.filename)
    let contents=""
  endif
  let queries=split(contents, "\\n")
  let in_previous_queries = index(queries, a:query)
  if in_previous_queries > -1
    call remove(queries, in_previous_queries)
  endif
  let queries = [a:query] + queries
  call writefile(queries, filename)
endfunction

"shows response in current buffer
function! s:show_response(response_buffer, ...) abort
  set ft=QQ
  call s:QQ_request_syntax()
  normal! gg"_dG
  let response=getbufvar(a:response_buffer, 'response')
  let body=response
  if response == ""
    call append(0, "--NO RESPONSE--")
  else
    call append(0, split(body, "\r\n"))
  endif
  normal! gg
endfunction

function! s:close_window(...) abort
endfunction

nnoremap QQ :call QQ#open_window()<CR>
