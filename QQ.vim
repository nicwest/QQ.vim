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

if !exists('g:QQ_current_collection')
  "current collection
  let g:QQ_current_collection = g:QQ_default_collection
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

"this matches "{option}: [:{key}:] {value}"
let s:request_line_ptrn = "^\\([A-Z-]\\+\\):\\s\\+\\(:[^:/]\\+:\\)\\?\\s*\\(.*\\)$"

function! StripName(input_string)
  "turns ":{key}:" into "{key}"
  return substitute(a:input_string, '^:\(.\{-}\):$', '\1', '')
endfunction

function! s:strip(input_string) abort
  "removes white space at the beginning and end of string
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:falsey(input_string)
  "if string is 0, false, or no it is falsey (normally this would include nil
  "values or empty stings, but for the moment I think these will be synonymous
  "with setting true in the context of "OPTION: :{key}: {value}", might change
  "this later)
  if a:input_string =~ "^\\s*\\(0\\|false\\|no\\)\\+\\s*$"
    return 1
  else
    return 0
  endif
endfunction

function! s:truthy(input_string)
  "if it's not falsey then it's truthy
  return 1 - s:falsey(a:input_string)
endfunction

function! s:matchstrmultiple(str, expr) abort
  "extract repeated expression from str
  let itemcount = 1
  let items = []
  while match(a:str, a:expr, 0, itemcount) >= 0
    call add(items, matchstr(a:str, a:expr, 0, itemcount))
    let itemcount += 1
  endwhile
  return items
endfunction

function! s:base64encode(str) abort
  "base64 encoder stolen from vimstuff
  "TODO: implement this in vimscript like a boss
  return system("echo -n '".shellescape(a:str)."' | base64")[:-2]
endfunction

function! s:focus_window_with_name(window) abort
  "focuses open window with loaded buffer name active
  exe 'norm'.bufwinnr(a:window).'w'
endfunction

function! s:QQ_request_syntax() abort
  "does all the syntaxing...
  "TODO: Refactor this into buffer specfic things
  runtime! syntax/javascript.vim
  unlet b:current_syntax
  let b:current_syntax = "QQ"
  syn match QQArg "^[a-zA-Z-]\+:"
  syn match QQUrlParam ":[a-zA-Z\-_]\+:" contained
  syn match QQUrl "\S\+:\/\/\S\+" contains=QQUrlParam
  syn match QQArgParam "^[a-zA-Z-]\+:\s\+:[^/:]\+:" contains=QQArg,QQUrlParam
  syn keyword QQMethods GET POST PUT DELETE OPTIONS HEAD TRACE CONNECT PATCH
  syn keyword QQResponseInformational 100 101
  syn keyword QQResponseSuccess 200 201 202 203 204 205 206
  syn keyword QQResponseRedirection 300 301 302 303 304 305 306 307
  syn keyword QQResponseClientError 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417
  syn keyword QQResponseServerError 500 501 502 503 504 505 506
  syn region QQHeaderFold start="^[A-Z]\+\/[0-9\.]\+\s\+[0-9]\+\s\+[A-Z]\+.*" end="\n\n" fold keepend contains=QQArg,QQResponseSuccess,QQResponseInformational,QQResponseRedirection,QQResponseClientError,QQResponseServerError
  syn region QQResponseTimeFold start="^RESPONSE\sTIME: [0-9\.]\+$" end="\n\n" fold keepend contains=QQArg
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
  "this does nothing useful
  autocmd!
  autocmd BufWinLeave * let s:QQ_open = 0
  autocmd Syntax QQ call s:QQ_request_syntax()
augroup END

function! s:open_window(...) abort
  "open a new window
  call s:focus_request_buffer()
endfunction

function! s:setup_request_buffer() abort
  "opens request buffer
  "TODO: this needs to be refactored to something a bit more sane
  if exists('s:reloading_QQ')
    return
  endif
  let s:reloading_QQ = 1
  abc <buffer>
  set ft=QQ
  setl noswf nonu nobl nospell nocuc wfw
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
  if v:version > 702
    setl nornu noudf cc=0
  end
  let s:request_buffer = bufnr("%") 
  let s:request_window = winnr()
  nnoremap <buffer> QQ :call QQ#send_request()<CR>
  unlet s:reloading_QQ
endfunction

function! QQ#open_window(...) abort
  "opens request window
  "TODO: make sane
  call s:open_window(a:000)
  call s:prefill_buffer()
endfunction

function! QQ#send_request(...) abort
  "converts buffer to request array and executes it
  call s:convert_buffer(bufnr(""))
  call s:exec_curl(bufnr(""))
endfunction

function! QQ#open_history() abort
  "opens quick fix style buffer list with current collection or default
  if exists("b:current_collection")
    call s:open_history(b:current_collection, bufnr(""))
  else
    call s:open_history(g:QQ_current_collection, bufnr(""))
  endif
endfunction

function! s:open_history(collection, buffer) abort
  "reads current collection to quickfix
  if !bufexists(g:QQ_buffer_prefix.'HISTORY')
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ g:QQ_collection_window_height.'new' g:QQ_buffer_prefix.'HISTORY'
  elseif bufwinnr(g:QQ_buffer_prefix.'HISTORY') == -1
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ 'sb' g:QQ_buffer_prefix.'HISTORY'
    sil! exe 'res 10'
  else
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
  endif
  abc <buffer>
  let b:queries=split(system('cat '.expand(a:collection)), "\\n")
  setl ma
  setl noswf nonu nobl nowrap nolist nospell nocuc wfh
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
  if v:version > 702
    setl nornu noudf cc=0
  end
  call s:load_history_buffer()
endfunction

function! s:load_history_buffer() abort
  "loads history buffer from b:queries
  setl ma
  norm gg"_dG
  let displaylist=copy(b:queries)
  call s:QQ_request_syntax()
  call map(displaylist, 'matchstr(v:val, ''-X\s\zs.\{-}\s\ze'') .' . "	".
        \' matchstr(v:val, ''\s\zs[a-zA-Z]\+:\/\/.\{-}\ze$'')')
  call append(0, displaylist)
  nnoremap <buffer> <CR> :call QQ#history_to_request()<CR>
  norm Gddgg
  setl noma
endfunction

function! QQ#history_to_request()
  "load current query line under cursor to REQUEST buffer
  let query=get(b:queries, line(".")-1, 0)
  call s:focus_request_buffer()
  call s:prefill_buffer(s:convert_query(query))
endfunction

function! QQ#basic_auth() abort
  "adds basic auth header via prompt
  let user = input("User: ")
  let password = inputsecret("Password: ")
  let auth_string = s:base64encode(user.":".password)
  call append(line("$"), ["HEADER: :Authorization: Basic ".auth_string])
endfunction

function! QQ#add_option(option_name) abort
  "adds option with 'option_name' to REQUEST buffer
  call append(line("$"), ["OPTION: :" . a:option_name . ": true"])
endfunction

function! s:focus_request_buffer()
  "finds the REQUEST buffer where ever it may be
  if and(!bufexists(g:QQ_buffer_prefix.'REQUEST'), !bufexists(g:QQ_buffer_prefix.'RESPONSE'))
    "neither request or response buffer exists
    sil! exe 'keepa bo 80vnew' g:QQ_buffer_prefix.'REQUEST'
  elseif and(!bufexists(g:QQ_buffer_prefix.'REQUEST'), bufwinnr(g:QQ_buffer_prefix.'RESPONSE') != -1)
    "request buffer doesn't exist, response buffer exists and is in window
    call s:focus_window_with_name(g:QQ_buffer_prefix.'RESPONSE')
    sil! exe 'badd' g:QQ_buffer_prefix.'REQUEST'
    sil! exe 'buf' bufnr('') 
  elseif and(!bufexists(g:QQ_buffer_prefix.'REQUEST'), bufexists(g:QQ_buffer_prefix.'RESPONSE'))
    "request buffer doesn't exist, response buffer exists but is not in window
    sil! exe 'keepa bo vert sb' g:QQ_buffer_prefix.'RESPONSE'
    sil! exe 'vert res 80'
    sil! exe 'badd' g:QQ_buffer_prefix.'REQUEST'
    sil! exe 'buf' bufnr('') 
  elseif and(bufwinnr(g:QQ_buffer_prefix.'REQUEST') == -1, bufwinnr(g:QQ_buffer_prefix.'RESPONSE') != -1)
    "request buffer exists, response buffer exists and is in window
    call s:focus_window_with_name(g:QQ_buffer_prefix.'RESPONSE')
    sil! exe 'buf' bufnr(g:QQ_buffer_prefix.'REQUEST') 
  elseif bufwinnr(g:QQ_buffer_prefix.'REQUEST') == -1
    "request buffer exists but is not in window
    sil! exe 'keepa bo vert sb' g:QQ_buffer_prefix.'REQUEST'
    sil! exe 'vert res 80'
  else 
    "request buffer exists and is in window
    call s:focus_window_with_name(g:QQ_buffer_prefix.'REQUEST')
  endif
  nnoremap <buffer> QBA :call QQ#basic_auth()<CR>
  nnoremap <buffer> QP :call QQ#add_option('pretty-print')<CR>
  call s:setup_request_buffer()
endfunction

function! s:convert_buffer(bufno_of_request) abort
  "turn buffer into list of curl varibles
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

function! s:convert_query(query) abort
  "turn curl query into list of curl varibles
  let request={
        \ "URL": [],
        \ "METHOD": [],
        \ "URL-PARAM": [],
        \ "HEADER": [],
        \ "DATA": [],
        \ "DATA-FILE": [],
        \ "BODY": [],
        \ "OPTION": [],
        \}
  call add(request['URL'], matchstr(a:query, '\s\zs[a-zA-Z]\+:\/\/.*\ze$'))
  call add(request['METHOD'], matchstr(a:query, '-X\s\zs.\{-}\ze\s'))
  let request['HEADER'] = map(s:matchstrmultiple(a:query, '-H\s\([''"]\)\zs.\{-}\ze\1'), 'split(v:val, ":")')
  let data_or_form = matchstr(a:query, '--\(data\|form\)\s\([''"]\)\zs.\{-}\ze\2')
  let data_or_form_fields = map(s:matchstrmultiple(data_or_form, '\(^\|&\)\zs[^&]\+\ze\($\)\?'), 'split(v:val, "=")')
  echo data_or_form_fields
  let request['DATA'] = filter([] + data_or_form_fields, 'v:val[1][0] != "@"') 
  let request['DATA-FILE'] = map(filter([] + data_or_form_fields, 'v:val[1][0] == "@"'), '[v:val[0], v:val[1][1:]]')
  return request
endfunction

function! s:prefill_buffer(...) abort
  "prefill buffer
  if !exists("s:last_request")  
    let s:last_request = {
          \ "URL": ["http://localhost:8000"], 
          \ "METHOD": ["GET"], 
          \ "URL-PARAM": [["testparam", "users"]], 
          \ "HEADER": [["Cache-Control", "no-cache"]], 
          \ "DATA": [],
          \ "DATA-FILE": [],
          \ "BODY": [""],
          \ "OPTION": [["pretty-print", "True"]]
          \ }
  endif
  let request = a:0 ? a:1 : s:last_request 
  let prefill = []
  for item in items(request)
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
  normal! Gddgg
endfunction

function! s:exec_curl(request_buffer) abort
  "execute curl
  let request=getbufvar(a:request_buffer, 'request')
  exe 'badd' g:QQ_buffer_prefix.'RESPONSE'
  exe 'buffer "'.g:QQ_buffer_prefix.'RESPONSE"'
  setlocal buftype=nofile
  setlocal noswapfile
  let curl_str=g:QQ_curl_executable . " -si -w '\\r\\n".
        \ "\%{time_namelookup}\\r\\n".
        \ "\%{time_connect}\\r\\n".
        \ "\%{time_appconnect}\\r\\n".
        \ "\%{time_pretransfer}\\r\\n".
        \ "\%{time_redirect}\\r\\n".
        \ "\%{time_starttransfer}\\r\\n".
        \ "\%{time_total}'"
  let url=request["URL"][0]
  let options=[]
  for option in get(request, "OPTION", [])
    if and(option[0] == "follow", s:truthy(option[1]))
      call add(options, "follow")
      let curl_str.=" -L"
    elseif and(option[0] == "pretty-print", s:truthy(option[1]))
      call add(options, "pretty-print")
    endif
  endfor
  let curl_str.=" -X ".get(request, "METHOD", ["GET"])[0]
  if len(get(request, "DATA", [])) || len(get(request, "DATA-FILE", []))
    if len(get(request, "DATA-FILE", []))
      let curl_str .= ' --form "'
    else
      let curl_str .= ' --data "'
    endif 
    let first = 1
    for data in get(request, "DATA", [])
      if first
        let first = 0
      else
        let curl_str .= '&'
      endif
      let curl_str .= s:strip(data[0]).'='.s:strip(data[1])
    endfor
    for data_file in get(request, "DATA-FILE", [])
      if first
        let first = 0
      else
        let curl_str .= '&'
      endif
      let curl_str .= s:strip(data_file[0]).'=@'.s:strip(data_file[1])
    endfor
    let curl_str .= '"'
  endif
  for header in get(request, "HEADER", [])
    let curl_str.=" -H \"".s:strip(header[0]).":".s:strip(header[1])."\""
  endfor
  let sub_url = substitute(url, '\([{}]\)', '\\\1', "g")
  for param in get(request, "URL-PARAM", [])
    let sub_url=substitute(sub_url, ":".s:strip(param[0]).":", s:strip(param[1]), "g")
  endfor
  let b:response = system(curl_str." ".shellescape(sub_url))
  call s:save_query(curl_str." ".url)
  call s:show_response(bufnr(""), options)
endfunction

function! s:save_query (query) abort
  "save query
  let filename=resolve(expand(g:QQ_current_collection))
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
  if bufwinnr(g:QQ_buffer_prefix.'HISTORY') != -1
    call setbufvar(bufnr(g:QQ_buffer_prefix.'HISTORY'), 'queries', queries)
    let request_buffer=bufnr('')
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
    call s:load_history_buffer()
    call s:focus_window_with_name(request_buffer)
  endif
  call writefile(queries, filename)
endfunction

function! s:split_response(response_buffer, ...) abort
  "process the response
  let response=getbufvar(a:response_buffer, 'response')
  let lines = split(response, "\\r\\n")
  let times = lines[-7:]
  let timeblock = "RESPONSE TIME: " . times[6] . "\r\n" .
        \ "Name-Lookup: " . times[0] . "\r\n" .
        \ "Connect: " . times[1] . "\r\n" . 
        \ "App-Connect: " . times[2] . "\r\n" . 
        \ "Pre-Transfer: " . times[3] . "\r\n" . 
        \ "Redirects: " . times[4] . "\r\n" .
        \ "Start-Transfer: " . times[5]
  let response = join(lines[:-8], "\r\n")
  let split_response = split(response, "\\r\\n\\r\\n\\(\\([A-Z]\\+\\/[0-9\\.]".
        \ "\\+\\s\\+[0-9]\\+\\s\\+[A-Z]\\+\\)\\@!\\)")
  if len(split_response) > 1
    return [split_response[0], split_response[1], timeblock]
  elseif len(split_response)
    return [split_response[0], "", timeblock]
  else
    return ["", "", timeblock]
  endif
endfunction

function! s:show_response(response_buffer, options, ...) abort
  "shows response in current buffer
  set ft=QQ
  call s:QQ_request_syntax()
  normal! gg"_dG
  let response=getbufvar(a:response_buffer, 'response')
  let split_response = s:split_response(a:response_buffer)
  if split_response[0] == ""
    call append(0, "--NO RESPONSE--")
  else
    if index(a:options, "pretty-print") > -1
      let decoded_body = system("echo " . shellescape(split_response[1]) .
            \  " | python -m json.tool")
      let body =  split(decoded_body, '\n')
    else
      let body = split(substitute(split_response[1], "\\r\\n", '\n', "g"), '\n')
    endif
    let response = split_response[0] . "\r\n\r\n" . split_response[2] . 
            \ "\r\n\r\n" 
    call append(0, split(response, "\r\n") + body)
  endif
  normal! Gddgg
endfunction

function! s:close_window(...) abort
  "hello I'm a useless function
endfunction

"wrong place wrong time....
"TODO: not this
nnoremap QQ :call QQ#open_window()<CR>
nnoremap QH :call QQ#open_history()<CR>
