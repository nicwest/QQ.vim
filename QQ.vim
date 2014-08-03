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

let s:request_line_ptrn = "^\\([A-Z-]\\+\\):\\s\\+\\(:[^:/]\\+:\\)\\?\\s*\\(.*\\)$"

function! StripName(input_string)
  return substitute(a:input_string, '^:\(.\{-}\):$', '\1', '')
endfunction


function! Truthy(input_string)
  if a:input_string
    if "\(2\|yes\|true\)" =~ input_string
      return 1
    else
      return 0
    endif
  endif
endfunction

function! s:QQ_request_syntax() abort
  let b:current_syntax = "QQ"
  syn match QQArg "^[a-zA-Z-]\+:"
  syn match QQUrlParam ":[^/:]\+:" contained
  syn match QQUrl "\S\+:\/\/\S\+" contains=QQUrlParam
  syn match QQArgParam "^[a-zA-Z-]\+:\s\+:[^/:]\+:" contains=QQArg,QQUrlParam
  syn keyword QQMethods GET POST PUT DELETE
  hi def link QQArg Constant
  hi def link QQUrlParam String
  hi def link QQMethods Keyword
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
  call append(0, prefill)
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
    if and(option[0] == "follow", Truthy(option[1]))
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
  "this need exposed functions to work
  nnoremap <buffer> QH :call QQ#toggle_headers(bufnr(""))<CR>
  call s:save_query(curl_str)
  call s:show_response_body(bufnr(""))
  "echo curl_str
endfunction

"save query
function! s:save_query (query) abort
  let filename=resolve(expand("~/.QQ.vim.history"))
  if filereadable(filename)
    "fuck windows for the moment
    "also this should probably be a var
    "if fact all of this should be vars
    let contents=system('cat '.filename)
  else
    call system('touch '.filename)
    let contents=""
  endif
  let queries=split(contents, "\\r\\n")
  let in_previous_queries = index(queries, a:query)
  if in_previous_queries < 0
    call add(queries, a:query)
    call writefile(readfile(filename)+queries, filename)
  endif
endfunction

"process the response
function! s:split_response(response_buffer, ...) abort
  let response=getbufvar(a:response_buffer, 'response')
  let split_response=split(response, "\\r\\n\\r\\n")
  if len(split_response) > 1
    return [split_response[0], join(split_response[1:], "\r\n\r\n")]
  elseif len(split_response)
    return [split_response[0], ""]
  else
    return ["", ""]
  endif
endfunction

function! s:show_response_body(response_buffer, ...) abort
  call setbufvar(a:response_buffer, "headers_toggled", 0)
  normal! gg"_dG
  set ft=json
  let split_response = s:split_response(a:response_buffer)
  let header= split_response[0]
  let body= split_response[1]
  if header == ""
    call append(0, "--NO RESPONSE--")
  elseif body ==""
    call append(0, "--VIEW HEADERS (QH)--")
  else
    call append(0, split(body, "\r\n"))
  endif
  normal! gg
endfunction

function! s:show_response_headers(response_buffer, ...) abort
  call setbufvar(a:response_buffer, "headers_toggled", 1)
  normal! gg"_dG
  set ft=QQ
  call s:QQ_request_syntax()
  let split_response = s:split_response(a:response_buffer)
  let header= split_response[0]
  let body= split_response[1]
  if header == ""
    call append(0, "--NO RESPONSE--")
  else
    call append(0, split(header, "\r\n"))
  endif
  normal! gg
endfunction

function! QQ#toggle_headers (response_buffer, ...) abort
  if getbufvar(a:response_buffer, "headers_toggled")
    call s:show_response_body(a:response_buffer)
  else
    call s:show_response_headers(a:response_buffer)
  endif
endfunction

function! s:close_window(...) abort
endfunction

nnoremap QQ :call QQ#open_window()<CR>
