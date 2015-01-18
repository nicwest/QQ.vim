let s:R = QQ#regexp#import()

" URL: {{{1
function! QQ#query#get_url(query) abort
  let l:urls = get(a:query, 'URL', [])
  if len(l:urls) < 1
    call QQ#utils#error('REQUEST', 'Request has no URL specified')
  endif
  if len(l:urls) > 1
    call QQ#utils#error('REQUEST', 'Request has multiple URLs specified')
  endif
  let l:url = l:urls[0]
  return l:url
endfunction

" Options: {{{1
function! QQ#query#get_options(query) abort
  let l:args = ''
  let l:options = []
  for [name, value] in get(a:query, "OPTION", [])
    if name == 'follow' && QQ#utils#truthy(value)
      call add(l:options, 'follow')
      let l:args .= ' -L'
    elseif name == 'pretty-print' && QQ#utils#truthy(value)
      call add(l:options, 'pretty-print')
    endif
  endfor
  return [l:args, l:options]
endfunction

" Method: {{{1
function! QQ#query#get_method(query) abort
  let l:methods = get(a:query, 'METHOD', [])
  if len(l:methods) < 1
    call QQ#utils#error('REQUEST', 'Request has no method specified')
  endif
  if len(l:methods) > 1
    call QQ#utils#error('REQUEST', 'Request has multiple methods specified')
  endif
  let l:method = ' -X '.l:methods[0]
  return l:method
endfunction

" Data: {{{1
function! QQ#query#get_data(query) abort
  let l:data = get(a:query, 'FORM', [])
  let l:files = get(a:query, 'FORM-FILE', [])
  let l:body = get(a:query, 'BODY', [])
  let l:args = ''
  if len(l:data)
    for [name, value] in l:data
      let l:args .= ' -F ' . shellescape(
            \ QQ#utils#strip(name) . '=' . QQ#utils#strip(value)) 
    endfor
  endif
  if len(l:files)
    for [name, path] in l:files
      if !filereadable(expand(QQ#utils#strip(path)))
        call QQ#utils#warning('REQUEST',
              \ 'File not readable: ' . QQ#utils#strip(path))
        continue
      endif
      let l:args .= ' -F ' . shellescape( 
            \ QQ#utils#strip(name) . '=@' . expand(QQ#utils#strip(path)))
    endfor
  endif
  if len(l:body)
    let l:args = ' -d ' . substitute(shellescape(join(l:body, "\n")),
          \ '\\\n' , "\n", 'g')
  endif
  return l:args
endfunction

" Headers: {{{1

function! QQ#query#get_headers(query) abort
  let l:args = ''
  for [name, value] in get(a:query, "HEADER", [])
    let l:args .= ' -H "'.QQ#utils#strip(name).':'.QQ#utils#strip(value).'"'
  endfor
  return l:args
endfunction

" Params: {{{1

function! QQ#query#get_params(query) abort
  let l:params = ''
  let l:first = 1
  for [name, value] in get(a:query, 'URL-PARAM', [])
    if l:first
      let l:params .=  '?'
      let l:first = 0
    else
      let l:params .=  '&'
    endif
    let l:params .= name.'='.value
  endfor
  return l:params
endfunction

" Vars: {{{1

function! QQ#query#sub_url_vars(query, url) abort
  let l:url = copy(a:url)
  for [name, value] in get(a:query, 'URL-VAR', [])
    let l:url = substitute(l:url, ':'.QQ#utils#strip(name).':', QQ#utils#strip(value), 'g')
  endfor
  return l:url
endfunction

" String: {{{1

function! QQ#query#get_base_query_str() abort
  let l:base_query_str = g:QQ_curl_executable 
  let l:base_query_str .= " -si -w '\\r\\n"
  let l:base_query_str .= "\%{time_namelookup}\\r\\n"
  let l:base_query_str .= "\%{time_connect}\\r\\n"
  let l:base_query_str .= "\%{time_appconnect}\\r\\n"
  let l:base_query_str .= "\%{time_pretransfer}\\r\\n"
  let l:base_query_str .= "\%{time_redirect}\\r\\n"
  let l:base_query_str .= "\%{time_starttransfer}\\r\\n"
  let l:base_query_str .= "\%{time_total}'"
  return l:base_query_str
endfunction


function! QQ#query#get_query_args(query) abort
  let l:query_args = ''
  let l:url = QQ#query#get_url(a:query)
  let l:options = QQ#query#get_options(a:query)
  let l:method = QQ#query#get_method(a:query)
  let l:headers = QQ#query#get_headers(a:query)
  let l:data = QQ#query#get_data(a:query)
  let l:params = QQ#query#get_params(a:query)

  let l:query_args .= l:options[0]
  let l:query_args .= l:method
  let l:query_args .= l:headers
  let l:query_args .= l:data

  let l:url_with_params = l:url . l:params
  let l:url_with_vars = QQ#query#sub_url_vars(a:query, l:url_with_params)
  
  let l:query_args_with_vars = l:query_args . ' ' .
        \ substitute(escape(shellescape(l:url_with_vars, 1), '{}$'),
        \ " ", "%20", "g")
  let l:query_args .=  ' ' . shellescape(l:url_with_params)

  return [l:query_args, l:query_args_with_vars]
endfunction

function! QQ#query#get_query_str(query) abort
  let l:query_str = QQ#query#get_base_query_str()
  let [l:query_args, l:query_args_vars] = QQ#query#get_query_args(a:query)
  return [l:query_str.l:query_args, l:query_str.l:query_args_vars]
endfunction

" Execute: {{{1

function! QQ#query#execute(query) abort
  let l:query_str_with_vars = QQ#query#get_query_str(a:query)[1]
  let l:response = system(l:query_str_with_vars)
  return l:response
endfunction

" Convert: {{{1

function! QQ#query#convert(query_str) abort
  "TODO: refactor this
  let l:query={
        \ "URL": [],
        \ "METHOD": [],
        \ "URL-VAR": [],
        \ "URL-PARAM": [],
        \ "HEADER": [],
        \ "FORM": [],
        \ "FORM-FILE": [],
        \ "BODY": [],
        \ "OPTION": [],
        \}
  let l:url = matchstr(a:query_str, s:R.curl_url)
  let l:param_split = split(url, '?')
  if len(l:param_split) > 1
    let l:url = param_split[0]
    let l:params = split(join(param_split[1:]), '&')
    call map(params, '[matchstr(v:val, s:R.curl_url_param_name), matchstr(v:val, s:R.curl_url_param_value)]')
    let l:query['URL-PARAM'] = l:params
  endif
  call add(l:query.URL, url)
  call add(l:query.METHOD, matchstr(a:query_str, s:R.curl_method))
  let l:query.HEADER = map(QQ#utils#matchstr_multiple(a:query_str, s:R.curl_header), 'split(v:val, ":")')
  let l:form = QQ#utils#matchstr_multiple(a:query_str, s:R.curl_form)
  let l:form_fields = map(QQ#utils#matchstr_multiple(l:form, s:R['curl_data_fields']), 'split(v:val, "=")')
  let l:query.FORM = filter([] + l:form_fields, 'v:val[1][0] != "@"') 
  let l:query['FORM-FILE'] = map(filter([] + l:form_fields, 'v:val[1][0] == "@"'), '[v:val[0], v:val[1][1:]]')
  let l:data = matchstr(a:query_str, s:R.curl_data)
  if len(l:data)
    let l:query.BODY = split(l:data, "\n")
  endif
  return l:query
endfunction


" Misc : {{{1
" vim: expandtab ts=2 sts=2 sw=2
" vim:fdm=marker
