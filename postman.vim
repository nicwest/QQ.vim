""checks if this the plugin is already loaded
"if !exists('g:loaded_postman') || &cp
"    finish
"endif

""other wise mark that it is loaded
"let g:loaded_postman = 1

""so we are going to use this just in case someone wants to specify a different
""curl executable
"if !exists('g:postman_curl_executable')
"  let g:postman_curl_executable = 'curl'
"endif

let s:request_line_ptrn = "^\\([A-Z-]\\+\\):\\s\\+\\(:[^:/]\\+:\\)\\?\\s*\\(.*\\)$"

function! StripName(input_string)
  return substitute(a:input_string, '^:\(.\{-}\):$', '\1', '')
endfunction

function! s:postman_request_syntax() abort
  let b:current_syntax = "postman"
  syn match postmanArg "^[A-Z-]\+:"
  syn match postmanUrlParam ":[^/:]\+:" contained
  syn match postmanUrl "\S\+:\/\/\S\+" contains=postmanUrlParam
  syn match postmanArgParam "^[A-Z-]\+:\s\+:[^/:]\+:" contains=postmanArg,postmanUrlParam
  syn keyword postmanMethods GET POST PUT DELETE
  hi def link postmanArg Constant
  hi def link postmanUrlParam String
  hi def link postmanMethods Keyword
endfunction

augroup postman
  autocmd!
  autocmd BufWinLeave * let s:postman_open = 0
  autocmd Syntax postman call s:postman_request_syntax()
augroup END

"open a new window
function! s:open_window(...) abort
  if exists('s:reloading_postman')
    return
  endif
  let s:reloading_postman = 1
  vert new REQUEST
  set ft=postman
  setlocal buftype=nofile
  setlocal noswapfile
  let s:request_buffer = bufnr("%") 
  let s:request_window = winnr()
  call s:prefill_buffer()
  nnoremap <buffer> <bar><bar> :call postman#send_request()<CR>
  unlet s:reloading_postman
endfunction

function! postman#open_window(...) abort
  call s:open_window(a:000)
endfunction

function! postman#send_request(...) abort
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
  echo s:last_request
endfunction

"prefill buffer
function! s:prefill_buffer(...) abort
  if !exists("s:last_request")  
    let s:last_request = {
          \ "URL": ["http://api.example.com/:testparam:/"], 
          \ "METHOD": ["GET"], 
          \ "URL-PARAM": [["testparam", "users"]], 
          \ "HEADER": [["Cache-Control", "no-cache"]], 
          \ "BODY": [""]
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
function! s:exec_curl(request) abort
endfunction

"process the response
function! s:show_response_body(response) abort
endfunction

function! s:show_response_headers(response) abort
endfunction

function! s:close_window(...) abort
endfunction

nnoremap <bar><bar> :call postman#open_window()<CR>
