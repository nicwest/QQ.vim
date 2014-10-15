" Curl wrapper in the style of Postman app
" Last Change: 2014-10-06	
" Init: {{{1
" Loaded Vars {{{2
" ==========
"if exists('g:QQ_loaded')
"  finish
"endif

"other wise mark that it is loaded
let g:QQ_loaded = 1

" Options {{{2
" ======
if !exists('g:QQ_curl_executable')
  "so we are going to use this just in case someone wants to specify a different
  "curl executable
  let g:QQ_curl_executable = 'curl'
endif

if !exists('g:QQ_default_collection')
  "default collection location
  let g:QQ_default_collection = '~/.QQ.default.collection'
endif

if !exists('g:QQ_collection_list')
  "collection list location
  let g:QQ_collection_list = '~/.QQ.collections'
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

" ---------------------------------------------------------------------

" Utilities: {{{1
" Regex {{{2
" ====
"this matches "{option}: [:{key}:] {value}"
let s:request_line_ptrn = "^\\([A-Z-]\\+\\):\\s\\+\\(:[^:/]\\+:\\)\\?\\s*\\(.*\\)$"

" String Functions {{{2
" ===============
function! StripName(input_string)
  "turns ":{key}:" into "{key}"
  return substitute(a:input_string, '^:\(.\{-}\):$', '\1', '')
endfunction

function! s:strip(input_string) abort
  "removes white space at the beginning and end of string
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
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
  let tempname = tempname()
  call writefile([a:str], tempname, 'b')
  return system("base64 ".tempname)[:-2]
endfunction

" Boolean Functions {{{2
" ================
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

" Window Functions {{{2
function! s:focus_window_with_name(window) abort
  "focuses open window with loaded buffer name active
  exe 'norm'.bufwinnr(a:window).'w'
endfunction

" ---------------------------------------------------------------------

" Syntax: {{{1
" Horrible Monstrosities {{{2
function! s:QQ_request_syntax() abort
  "does all the syntaxing...
  "TODO: Refactor this into buffer specfic things
  runtime! syntax/javascript.vim
  unlet b:current_syntax
  let b:current_syntax = "QQ"
  syn match QQArg "^[a-zA-Z-]\+:"
  syn match QQUrlVar ":[a-zA-Z\-_]\+:" contained
  syn match QQUrl "\S\+:\/\/\S\+" contains=QQUrlVar
  syn match QQArgVar "^[a-zA-Z-]\+:\s\+:[^/:]\+:" contains=QQArg,QQUrlVar
  syn keyword QQMethods GET POST PUT DELETE OPTIONS HEAD TRACE CONNECT PATCH
  syn keyword QQResponseInformational 100 101
  syn keyword QQResponseSuccess 200 201 202 203 204 205 206
  syn keyword QQResponseRedirection 300 301 302 303 304 305 306 307
  syn keyword QQResponseClientError 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417
  syn keyword QQResponseServerError 500 501 502 503 504 505 506
  syn region QQHeaderFold start="^[A-Z]\+\/[0-9\.]\+\s\+[0-9]\+\s\+[A-Z]\+.*" end="\n\n" fold keepend contains=QQArg,QQResponseSuccess,QQResponseInformational,QQResponseRedirection,QQResponseClientError,QQResponseServerError
  syn region QQResponseTimeFold start="^RESPONSE\sTIME: [0-9\.]\+$" end="\n\n" fold keepend contains=QQArg
  hi def link QQArg Constant
  hi def link QQUrlVar String
  hi def link QQMethods Keyword
  hi QQResponseInformational ctermbg=NONE ctermfg=7
  hi QQResponseSuccess ctermbg=NONE ctermfg=10
  hi QQResponseRedirection ctermbg=NONE ctermfg=14
  hi QQResponseClientError ctermbg=NONE ctermfg=13
  hi QQResponseServerError ctermbg=NONE ctermfg=4
  syn sync fromstart
  set foldmethod=syntax
endfunction

" ---------------------------------------------------------------------

" Auto Groups: {{{1
" QQ? {{{2
augroup QQ
  "this does nothing useful
  autocmd!
  autocmd BufWinLeave * let s:QQ_open = 0
  autocmd Syntax QQ call s:QQ_request_syntax()
augroup END

" ---------------------------------------------------------------------

" Core Functions: {{{1
" Request {{{2
" =======

" Open {{{3
" ----
function! s:open_window(...) abort
  "open a new window
  "FIXME: I don't think this does anything anymore :(
  call s:focus_request_buffer()
endfunction

function! s:setup_request_buffer() abort
  "opens request buffer
  "TODO: this needs to be refactored to something a bit more sane
  "FIXME: I don't think this does anything anymore :(
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
  nnoremap <buffer> QAB :call QQ#basic_auth()<CR>
  nnoremap <buffer> QAO :call QQ#oauth2()<CR>
  nnoremap <buffer> QP :call QQ#add_option('pretty-print')<CR>
  call s:setup_request_buffer()
endfunction

" Convert {{{3
" -------
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

" Save {{{3
" ----
function! s:save_query (query) abort
  "save query
  let filename=resolve(expand(g:QQ_current_collection))
  if filereadable(filename)
    let queries=readfile(filename)
  else
    call writefile([], filename)
    let queries = []
  endif
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

" Populate {{{3
" --------
function! s:prefill_buffer(...) abort
  "prefill buffer
  if !exists("s:last_request")  
    let s:last_request = {
          \ "URL": ["http://localhost:8000"], 
          \ "METHOD": ["GET"], 
          \ "URL-VAR": [["testvar", "users"]], 
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

" Exposed {{{3
" -------
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

function! QQ#add_option(option_name) abort
  "adds option with 'option_name' to REQUEST buffer
  call append(line("$"), ["OPTION: :" . a:option_name . ": true"])
endfunction


" Response {{{2
" ========

" Convert {{{3
" -------
function! s:exec_curl(request_buffer) abort
  "execute curl
  let request=getbufvar(a:request_buffer, 'request')
  sil! exe 'badd' g:QQ_buffer_prefix.'RESPONSE'
  sil! exe 'buffer "'.g:QQ_buffer_prefix.'RESPONSE"'
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
  for var in get(request, "URL-VAR", [])
    let sub_url=substitute(sub_url, ":".s:strip(var[0]).":", s:strip(var[1]), "g")
  endfor
  let b:response = system(curl_str." ".shellescape(sub_url))
  call s:save_query(curl_str." ".url)
  call s:show_response(bufnr(""), options)
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

" Populate {{{3
" --------
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
      let temp_file = tempname()
      call writefile(split(split_response[1], "\n"), temp_file)
      let decoded_body = system("python -m json.tool ".temp_file)
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


" History {{{2
" =======
" Open {{{3
" ----
function! s:open_history(collection, buffer) abort
  "opens history of current collection
  if !bufexists(g:QQ_buffer_prefix.'HISTORY') && bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') == -1
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ g:QQ_collection_window_height.'new' g:QQ_buffer_prefix.'HISTORY'
  elseif bufwinnr(g:QQ_buffer_prefix.'HISTORY') == -1 && bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') == -1
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ 'sb' g:QQ_buffer_prefix.'HISTORY'
    sil! exe 'res 10'
  elseif !bufexists(g:QQ_buffer_prefix.'HISTORY') && bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') != -1
    sil! exe 'badd' g:QQ_buffer_prefix.'HISTORY'
    call s:focus_window_with_name(g:QQ_buffer_prefix.'COLLECTIONS')
    sil! exe 'buffer' bufnr(g:QQ_buffer_prefix.'HISTORY')
  elseif bufwinnr(g:QQ_buffer_prefix.'HISTORY') == -1 && bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') != -1
    call s:focus_window_with_name(g:QQ_buffer_prefix.'COLLECTIONS')
    sil! exe 'buffer' bufnr(g:QQ_buffer_prefix.'HISTORY')
  else
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
  endif
  abc <buffer>
  let b:queries=readfile(expand(a:collection))
  setl ma
  setl noswf nonu nobl nowrap nolist nospell nocuc wfh
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
  if v:version > 702
    setl nornu noudf cc=0
  end
  call s:load_history_buffer()
endfunction

" Populate {{{3
" --------
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

function! s:convert_query(query) abort
  "turn curl query into list of curl varibles
  let request={
        \ "URL": [],
        \ "METHOD": [],
        \ "URL-VAR": [],
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
  let request['DATA'] = filter([] + data_or_form_fields, 'v:val[1][0] != "@"') 
  let request['DATA-FILE'] = map(filter([] + data_or_form_fields, 'v:val[1][0] == "@"'), '[v:val[0], v:val[1][1:]]')
  return request
endfunction

" Exposed {{{3
" -------
function! QQ#open_history() abort
  "opens quick fix style buffer list with current collection or default
  if exists("b:current_collection")
    call s:open_history(b:current_collection, bufnr(""))
  else
    call s:open_history(g:QQ_current_collection, bufnr(""))
  endif
endfunction

function! QQ#history_to_request()
  "load current query line under cursor to REQUEST buffer
  let query=get(b:queries, line(".")-1, 0)
  call s:focus_request_buffer()
  call s:prefill_buffer(s:convert_query(query))
endfunction


" Collection {{{2
" ==========
" Open {{{3
" ----
function! s:open_collection_list(collection_list) abort
  "opens collection list
  if !filereadable(expand(a:collection_list))
    call writefile(['[QQ DEFAULT COLLECTION] '.g:QQ_default_collection], expand(a:collection_list))
  endif

  if !bufexists(g:QQ_buffer_prefix.'COLLECTIONS') && bufwinnr(g:QQ_buffer_prefix.'HISTORY') == -1
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ g:QQ_collection_window_height.'new' g:QQ_buffer_prefix.'COLLECTIONS'
  elseif bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') == -1 && bufwinnr(g:QQ_buffer_prefix.'HISTORY') == -1
    sil! exe 'keepa' ( g:QQ_collection_window_location == 'top' ? 'to' : 'bo' ) 
          \ 'sb' g:QQ_buffer_prefix.'COLLECTIONS'
    sil! exe 'res 10'
  elseif !bufexists(g:QQ_buffer_prefix.'COLLECTIONS') && bufwinnr(g:QQ_buffer_prefix.'HISTORY') != -1
    sil! exe 'badd' g:QQ_buffer_prefix.'COLLECTIONS'
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
    sil! exe 'buffer' bufnr(g:QQ_buffer_prefix.'COLLECTIONS')
  elseif bufwinnr(g:QQ_buffer_prefix.'COLLECTIONS') == -1 && bufwinnr(g:QQ_buffer_prefix.'HISTORY') != -1
    call s:focus_window_with_name(g:QQ_buffer_prefix.'HISTORY')
    sil! exe 'buffer' bufnr(g:QQ_buffer_prefix.'COLLECTIONS')
  else
    call s:focus_window_with_name(g:QQ_buffer_prefix.'COLLECTIONS')
  endif
  abc <buffer>
  let b:collections=readfile(expand(a:collection_list))
  setl ma
  setl noswf nonu nobl nowrap nolist nospell nocuc wfh
  setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
  if v:version > 702
    setl nornu noudf cc=0
  end
  call s:load_collections_buffer()
endfunction

" Add {{{3
" ---
function! s:add_collection(path, name, collection_list) abort
  "adds collection to collection list
  let path = fnamemodify(a:path, ":p")
  if isdirectory(path)
    throw "collection path is directory:" a:path
  endif
  let directory = fnamemodify(a:path, ":p:h")
  if !isdirectory(directory)
    throw "target directory doesn't exist:" directory
  endif
  let line = "[".a:name."] ".a:path
  let collection_list = readfile(expand(a:collection_list))
  let collection_files = [] + collection_list
  call map(collection_files, "fnamemodify(matchstr(v:val, '^\\(\\[.*\\]\\s*\\)\\?\\zs.\\+\\ze$'), ':p')")
  let list_index = index(collection_files, path) 
  if list_index >= 0
    let collection_list[list_index] = line
  else
    call add(collection_list, line)
  endif
  call writefile(collection_list, expand(a:collection_list))
  if !filereadable(path)
    call writefile([], path)
  endif
endfunction

" Populate {{{3
" --------
function! s:load_collections_buffer() abort
  "loads collection buffer from b:collections
  setl ma
  norm gg"_dG
  let displaylist=copy(b:collections)
  call s:QQ_request_syntax()
  call append(0, displaylist)
  nnoremap <buffer> <CR> :call QQ#collection_to_history()<CR>
  norm Gddgg
  setl noma
endfunction

" Modify {{{3
" ------
function! s:set_current_collection(collection) abort
  "set current collection
  let g:QQ_current_collection = a:collection
  let b:current_buffer = a:collection
  call s:open_history(a:collection, bufnr(""))
  echo g:QQ_buffer_prefix "current collection:" a:collection
endfunction

" Completion {{{3
" ----------

function! s:collection_completion (A, L, P) abort
  let collection_list = readfile(expand(g:QQ_collection_list))
  call map(collection_list, "matchstr(v:val, '^\\[\\zs.*\\ze\\]\\s*.\\+$')")
  echo collection_list
  return join(collection_list, "\n")
endfunction

" Utilities {{{3
" ---------
function! s:get_collection_path_from_name (name) abort
  let collection_list = readfile(expand(g:QQ_collection_list))
  call filter(collection_list, "v:val =~ '\\['.a:name.'\\].*$'")
  if len(collection_list) > 0
    return matchstr(collection_list[0], '^\(\[.*\]\s*\)\?\zs.\+\ze$')
  else
    return ''
  endif
endfunction

" Exposed {{{3
" -------
function! QQ#open_collection_list() abort
  "opens quick fix style buffer list with collections
  call s:open_collection_list(g:QQ_collection_list)
endfunction

function! QQ#add_collection() abort
  "add a collection via prompt
  let path = input("New collection (./.QQ.collection): ", ".QQ.collection", "file")
  let name = input("Collection name: ")
  call s:add_collection(path, name, g:QQ_collection_list)
  call s:set_current_collection(path)
endfunction

function! QQ#collection_completion(A, L, P) abort
  return s:collection_completion(a:A, a:L, a:P)
endfunction

function! QQ#change_collection() abort
  let collection = input("Change collection: ", "", "custom,QQ#collection_completion")
  let path = s:get_collection_path_from_name(collection)
  if len(path) > 0
    call s:set_current_collection(path)
  else
    throw "collection with the name" collection "could not be found"
  endif
endfunction

function! QQ#collection_to_history()
  "load current query line under cursor to REQUEST buffer
  let collection=matchstr(get(b:collections, line(".")-1, 0), '^\(\[.*\]\s*\)\?\zs.\+\ze$')
  call s:open_history(collection, bufnr(""))
endfunction

" Auth {{{2
" ====

" basic auth {{{3
" ----------
function! s:basic_auth() abort
  "adds basic auth header via prompt to request buffer
  "TODO: swap to request buffer
  let user = input("User: ")
  let password = inputsecret("Password: ")
  let auth_string = s:base64encode(user.":".password)
  call append(line("$"), ["HEADER: :Authorization: Basic ".auth_string])
endfunction

" oauth2 {{{3
" ------
function! s:oauth2_authorisation() abort
  let auth_url = input('Authorisation Url: ', 'https://')
  let auth_token_url = input('Authorisation Token Url: ', 'https://')
  let client_id = input('Client ID (Key): ')
  let client_secret = input('Client Secret: ')
  let state = input('State (Optional): ', 'foobar')
  let scope = input('Scope (Optional): ')
  let redirect_url = input('Redirect URL: ', 'http://localhost:8123')

  let auth_params = "?response_type=code&client_id=".client_id
  let auth_params .= "&redirect_uri=".redirect_url
  let auth_params .= "&state=".state
  "TODO: add optional other bits here

  let server_path = expand('<sfile>:p:h')."/authserver.py"
  call system("python -m webbrowser -t '".auth_url.auth_params."'")
  let auth_response = system("python ".server_path)
  let auth_code = matchstr(auth_response, 'code=\zs[^&]\+\ze')
  "TODO: check state
  
  let auth_token_params = "?grant_type=authorization_code"
  let auth_token_params .= "&code=".auth_code
  let auth_token_params .= "&client_id=".client_id
  let auth_token_params .= "&client_secret=".client_secret
  let auth_token_params .= "&redirect_uri=".redirect_url

  let access_token_response = system(g:QQ_curl_executable.' -s -X POST "'.auth_token_url.auth_token_params.'"')
  "TODO: check for errors
  let access_token = matchstr(access_token_response, '"access_token":"\zs[^"]\+\ze"')

  call append(line("$"), ["HEADER: :Authorization: Bearer ".access_token])
endfunction

" Exposed {{{3
" -------

function! QQ#basic_auth() abort
  call s:basic_auth()
endfunction

function! QQ#oauth2() abort
  call s:oauth2_authorisation()
endfunction

" ---------------------------------------------------------------------

" Key Bindings {{{1
" ==========
"wrong place wrong time....
"TODO: not this
nnoremap QQ :call QQ#open_window()<CR>
nnoremap QH :call QQ#open_history()<CR>
nnoremap QCL :call QQ#open_collection_list()<CR>
nnoremap QAC :call QQ#add_collection()<CR>
nnoremap QCC :call QQ#change_collection()<CR>
" Misc {{{1
" vim:fdm=marker
