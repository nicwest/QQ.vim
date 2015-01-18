let s:suite = themis#suite('query')
let s:assert = themis#helper('assert')
call themis#helper('command')

" URL: {{{1
function! s:suite.get_url()
  let l:test_query = {'URL': ['http://test.com']}
  call s:assert.equals(QQ#query#get_url(l:test_query), 'http://test.com')
endfunction

function! s:suite.get_url_no_url_key()
  Throws /REQUEST ERROR: Request has no URL specified/ 
        \ :call QQ#query#get_url({})
endfunction

function! s:suite.get_url_no_url()
  Throws /REQUEST ERROR: Request has no URL specified/ 
        \ :call QQ#query#get_url({'URL': []})
endfunction

function! s:suite.get_url_multiple_urls()
  let l:test_query = {'URL': ['http://test.com', 'http://fu.bar']}
  Throws /REQUEST ERROR: Request has multiple URLs specified/ 
        \ :call QQ#query#get_url(l:test_query)
endfunction

" Options: {{{1
function! s:suite.get_options_with_follow()
  let l:test_query = {'OPTION': [['follow', 'True']]}
  let [l:args, l:options] = QQ#query#get_options(l:test_query)
  call s:assert.equals(l:args, ' -L')
  call s:assert.equals(l:options, ['follow'])
endfunction

function! s:suite.get_options_with_pretty_print()
  let l:test_query = {'OPTION': [['pretty-print', 'True']]}
  let [l:args, l:options] = QQ#query#get_options(l:test_query)
  call s:assert.equals(l:args, '')
  call s:assert.equals(l:options, ['pretty-print'])
endfunction

function! s:suite.get_options_no_options()
  let l:test_query = {'OPTIONS': []}
  let [l:args, l:options] = QQ#query#get_options(l:test_query)
  call s:assert.equals(l:args, '')
  call s:assert.equals(l:options, [])
endfunction

function! s:suite.get_options_no_options_key_set()
  let l:test_query = {}
  let [l:args, l:options] = QQ#query#get_options(l:test_query)
  call s:assert.equals(l:args, '')
  call s:assert.equals(l:options, [])
endfunction

" Method: {{{1

function! s:suite.get_method()
  let l:test_query = {'METHOD': ['GET']}
  let l:args = QQ#query#get_method(l:test_query)
  call s:assert.equals(l:args, ' -X GET')
endfunction

function! s:suite.get_method_no_method()
  let l:test_query = {'METHOD': []}
  Throws /REQUEST ERROR: Request has no method specified/ 
        \ :call QQ#query#get_method(l:test_query)
endfunction

function! s:suite.get_method_no_method_key()
  let l:test_query = {}
  Throws /REQUEST ERROR: Request has no method specified/ 
        \ :call QQ#query#get_method(l:test_query)
endfunction

function! s:suite.get_method_multiple_method()
  let l:test_query = {'METHOD': ['GET', 'POST']}
  Throws /REQUEST ERROR: Request has multiple methods specified/ 
        \ :call QQ#query#get_method(l:test_query)
endfunction

" Data: {{{1

function! s:suite.get_data_no_data()
  let l:test_query = {}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, '')
endfunction

function! s:suite.get_data_with_data()
  let l:test_query = {'FORM': [['test', 'foo']]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, ' -F ''test=foo''')
endfunction

function! s:suite.get_data_with_multiple_data()
  let l:test_query = {'FORM': [['test', 'foo'], ['bosh', 'lol']]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, ' -F ''test=foo'' -F ''bosh=lol''')
endfunction

function! s:suite.get_data_with_file()
  let l:file_existing = getcwd() . "/README.md"
  let l:test_query = {'FORM-FILE': [['test', l:file_existing]]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, ' -F ''test=@'.l:file_existing.'''')
endfunction

function! s:suite.get_data_with_mutliple_files()
  let l:readme = getcwd() . "/README.md"
  let l:gitignore = getcwd() . "/.gitignore"
  let l:test_query = {'FORM-FILE': [['readme', l:readme], ['gitignore', l:gitignore]]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, ' -F ''readme=@'.l:readme.''' -F ''gitignore=@'.l:gitignore.'''')
endfunction

function! s:suite.get_data_with_file_doesnt_exist()
  let l:file_missing = getcwd() . "/porn.jpg"
  let l:test_query = {'FORM-FILE': [['test', l:file_missing]]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, '')
endfunction

function! s:suite.get_data_with_data_and_file()
  let l:readme = getcwd() . "/README.md"
  let l:test_query = {
        \ 'FORM': [['foo', 'bar']],
        \ 'FORM-FILE': [['test', l:readme]]}
  let l:args = QQ#query#get_data(l:test_query)
  call s:assert.equals(l:args, ' -F ''foo=bar'' -F ''test=@'.l:readme.'''')
endfunction

" Headers: {{{1

function! s:suite.get_headers_no_headers()
  let l:test_query = {'HEADER': []}
  let l:args = QQ#query#get_headers(l:test_query)
  call s:assert.equals(l:args, '')
endfunction

function! s:suite.get_headers_no_header_key()
  let l:test_query = {}
  let l:args = QQ#query#get_headers(l:test_query)
  call s:assert.equals(l:args, '')
endfunction

function! s:suite.get_headers()
  let l:test_query = {'HEADER': [['test', 'foo']]}
  let l:args = QQ#query#get_headers(l:test_query)
  call s:assert.equals(l:args, ' -H "test:foo"')
endfunction

function! s:suite.get_headers_multiple_headers()
  let l:test_query = {'HEADER': [['test', 'foo'], ['lol', 'beans']]}
  let l:args = QQ#query#get_headers(l:test_query)
  call s:assert.equals(l:args, ' -H "test:foo" -H "lol:beans"')
endfunction

" Params: {{{1

function! s:suite.get_params_no_params()
  let l:test_query = {'URL-PARAM': []}
  let l:params = QQ#query#get_params(l:test_query)
  call s:assert.equals(l:params, '')
endfunction

function! s:suite.get_params_no_params_key()
  let l:test_query = {}
  let l:params = QQ#query#get_params(l:test_query)
  call s:assert.equals(l:params, '')
endfunction

function! s:suite.get_params()
  let l:test_query = {'URL-PARAM': [['test', 'foo']]}
  let l:params = QQ#query#get_params(l:test_query)
  call s:assert.equals(l:params, '?test=foo')
endfunction

function! s:suite.get_params_multiple()
  let l:test_query = {'URL-PARAM': [['test', 'foo'], ['lol', 'beans']]}
  let l:params = QQ#query#get_params(l:test_query)
  call s:assert.equals(l:params, '?test=foo&lol=beans')
endfunction

" Vars: {{{1

function! s:suite.sub_url_vars_no_vars()
  let l:test_query = {'URL-VAR': []}
  let l:url = 'http://foobar.com/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, l:url)
endfunction

function! s:suite.sub_url_vars_no_vars_key()
  let l:test_query = {}
  let l:url = 'http://foobar.com/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, l:url)
endfunction

function! s:suite.sub_url_vars_var_not_in_query_leaves_var_in_url()
  let l:test_query = {'URL-VAR': []}
  let l:url = 'http://foobar.com/:test:/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, l:url)
endfunction

function! s:suite.sub_url_vars_var_in_query_not_in_url()
  let l:test_query = {'URL-VAR': [['test', 'foo']]}
  let l:url = 'http://foobar.com/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, l:url)
endfunction

function! s:suite.sub_url_vars()
  let l:test_query = {'URL-VAR': [['test', 'foo']]}
  let l:url = 'http://foobar.com/:test:/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, 'http://foobar.com/foo/')
endfunction

function! s:suite.sub_url_vars_mutiple_vars()
  let l:test_query = {'URL-VAR': [['test', 'foo'], ['lol', 'beans']]}
  let l:url = 'http://foobar.com/:test:/:lol:/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, 'http://foobar.com/foo/beans/')
endfunction

function! s:suite.sub_url_vars_repeated()
  let l:test_query = {'URL-VAR': [['test', 'foo']]}
  let l:url = 'http://foobar.com/:test:/:test:/'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, 'http://foobar.com/foo/foo/')
endfunction

function! s:suite.sub_url_vars_in_url_parameter()
  let l:test_query = {'URL-VAR': [['test', 'foo']]}
  let l:url = 'http://foobar.com/?lol=beans&key=:test:'
  let l:subbed_url = QQ#query#sub_url_vars(l:test_query, l:url)
  call s:assert.equals(l:subbed_url, 'http://foobar.com/?lol=beans&key=foo')
endfunction

" String: {{{1

let s:test_query = {
      \ 'METHOD': ['GET'],
      \ 'URL': ['https://www.googleapis.com/urlshortener/v1/url'],
      \ 'URL-VAR': [['url', 'https://weareleto.com'], ['api-key', '123123']],
      \ 'URL-PARAM': [['shortUrl', ':url:'], ['key', ':api-key:']],
      \ 'HEADER': [['Cache-Control', 'no-cache']],
      \ 'FORM': [['test', 'foo']],
      \ 'OPTION': [['pretty-print', 'True']]
      \}

let s:test_query_args = ' -X GET -H "Cache-Control:no-cache" -F ''test=foo'' ''https://www.googleapis.com/urlshortener/v1/url?shortUrl=:url:&key=:api-key:'''
let s:test_query_args_with_vars = ' -X GET -H "Cache-Control:no-cache" -F ''test=foo'' ''https://www.googleapis.com/urlshortener/v1/url?shortUrl=https://weareleto.com&key=123123'''

function! s:suite.get_base_query_str()
  let l:base_query_str = QQ#query#get_base_query_str()
  let l:expected_base = "curl -si -w '\\r\\n"
  let l:expected_base .= "\%{time_namelookup}\\r\\n"
  let l:expected_base .= "\%{time_connect}\\r\\n"
  let l:expected_base .= "\%{time_appconnect}\\r\\n"
  let l:expected_base .= "\%{time_pretransfer}\\r\\n"
  let l:expected_base .= "\%{time_redirect}\\r\\n"
  let l:expected_base .= "\%{time_starttransfer}\\r\\n"
  let l:expected_base .= "\%{time_total}'"
  call s:assert.equals(l:base_query_str, l:expected_base)
endfunction

function! s:suite.get_query_args()
  let [l:query_args, l:query_args_with_vars] = QQ#query#get_query_args(s:test_query)
  call s:assert.equals(l:query_args, s:test_query_args)
  call s:assert.equals(l:query_args_with_vars, s:test_query_args_with_vars)
endfunction

function! s:suite.get_query_str()
  let [l:query_str, l:query_str_with_vars] = QQ#query#get_query_str(s:test_query)
  let l:base_query_str = QQ#query#get_base_query_str()
  call s:assert.equals(l:query_str, l:base_query_str.s:test_query_args)
  call s:assert.equals(l:query_str_with_vars, l:base_query_str.s:test_query_args_with_vars)
endfunction

" Execute: {{{1

function! s:suite.execute()
  let l:old_exec = g:QQ_curl_executable
  let g:QQ_curl_executable = 'python test/mock/curl.py'
  let l:response = QQ#query#execute(s:test_query)
  let g:QQ_curl_executable = l:old_exec
  let l:response_list = split(l:response[2:-4], "', '")
  call s:assert.equals(l:response_list[0], '-si')
  call s:assert.equals(l:response_list[1], '-w')
  let l:format_args = split(l:response_list[2], '\\\\r\\\\n')
  call s:assert.equals(l:format_args[0], '%{time_namelookup}')
  call s:assert.equals(l:format_args[1], '%{time_connect}')
  call s:assert.equals(l:format_args[2], '%{time_appconnect}')
  call s:assert.equals(l:format_args[3], '%{time_pretransfer}')
  call s:assert.equals(l:format_args[4], '%{time_redirect}')
  call s:assert.equals(l:format_args[5], '%{time_starttransfer}')
  call s:assert.equals(l:format_args[6], '%{time_total}')
  call s:assert.equals(l:response_list[3], '-X')
  call s:assert.equals(l:response_list[4], 'GET')
  call s:assert.equals(l:response_list[5], '-H')
  call s:assert.equals(l:response_list[6], 'Cache-Control:no-cache')
  call s:assert.equals(l:response_list[7], '-F')
  call s:assert.equals(l:response_list[8], 'test=foo')
  call s:assert.equals(l:response_list[9], 'https://www.googleapis.com/urlshortener/v1/url?shortUrl=https://weareleto.com&key=123123')
endfunction

" Convert: {{{1

function! s:suite.convert_handles_multiple_form_fields()
  let l:curl_str = 'something -F ''foo=pew'' -F ''boo=bar'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.FORM, [['foo', 'pew'], ['boo', 'bar']])
endfunction

function! s:suite.convert_handles_form_and_form_files()
  let l:curl_str = 'something -F ''foo=pew'' -F ''boo=@bar'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query['FORM-FILE'], [['boo', 'bar']])
  call s:assert.equals(l:query.FORM, [['foo', 'pew']])
endfunction

function! s:suite.convert_matches_url()
  let l:curl_str = 'something ''http://pewpew.com'''
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.URL, ['http://pewpew.com'])
endfunction

function! s:suite.convert_gets_url_params()
  let l:curl_str = 'something ''http://pewpew.com?foo=bar'''
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query['URL-PARAM'], [['foo', 'bar']])
endfunction

function! s:suite.convert_gets_multiple_url_params()
  let l:curl_str = 'something ''http://pewpew.com?foo=bar&pewpew=pow'''
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query['URL-PARAM'], [['foo', 'bar'], ['pewpew', 'pow']])
endfunction

function! s:suite.convert_gets_method()
  let l:curl_str = 'something -X GET something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.METHOD, ['GET'])
endf

function! s:suite.convert_gets_method_only_once()
  let l:curl_str = 'something -X GET -X POST something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.METHOD, ['GET'])
endf

function! s:suite.convert_gets_header()
  let l:curl_str = 'something -H ''Content-type:pew'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.HEADER, [['Content-type', 'pew']])
endf

function! s:suite.convert_gets_multiple_headers()
  let l:curl_str = 'something -H ''Content-type:pew'' -H ''foo:pew'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.HEADER, [['Content-type', 'pew'], ['foo', 'pew']])
endf

function! s:suite.convert_gets_body()
  let l:curl_str = 'something -d ''THIS IS BODY'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.BODY, ['THIS IS BODY'])
endf

function! s:suite.convert_gets_multiple_line_body()
  let l:curl_str = 'something -d ''THIS IS BODY' . "\n" . 'THIS IS ALSO BODY'' something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.BODY, ['THIS IS BODY', 'THIS IS ALSO BODY'])
endf

function! s:suite.convert_doesnt_return_empty_string_when_body_is_empty()
  let l:curl_str = 'something something'
  let l:query = QQ#query#convert(l:curl_str)
  call s:assert.equals(l:query.BODY, [])
endfunction



" Misc: {{{1
" vim: expandtab ts=2 sts=2 sw=2
" vim:fdm=marker
