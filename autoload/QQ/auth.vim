let s:server_path = expand('<sfile>:p:h:h:h')."/authserver.py"
" Basic {{{1
function! QQ#auth#basic() abort
  let user = input("User: ")
  let password = inputsecret("Password: ")
  let auth_string = QQ#utils#base64encode(user.":".password)
  call append(line("$"), ["HEADER: :Authorization: Basic ".auth_string])
endfunction

function! QQ#auth#oauth2() abort
  let auth_url = input('Authorisation Url: ', 'https://')
  let auth_token_url = input('Authorisation Token Url: ', 'https://')
  let client_id = input('Client ID (Key): ')
  let client_secret = input('Client Secret: ')
  let state = input('State (Optional): ', 'foobar')
  let scope = input('Scope (Optional): ')
  let redirect_url = input('Redirect URL: ', 'http://localhost:8123')

  let auth_params = "?response_type=code&client_id=" . client_id .
        \ "&redirect_uri=" . redirect_url .
        \ "&state=" . state . 
        \ "&scope=" . scope
  "TODO: add optional other bits here

  call system(g:QQ_python_executable . " -m webbrowser -t '" . auth_url . auth_params ."'")
  let auth_response = system(g:QQ_python_executable . ' ' . s:server_path)
  let auth_code = matchstr(auth_response, 'code=\zs[^&]\+\ze')
  "TODO: check state
  
  let auth_token_params = "?grant_type=authorization_code" . 
        \ "&code=" . auth_code .
        \ "&client_id=" . client_id .
        \ "&client_secret=" . client_secret .
        \ "&redirect_uri=" . redirect_url

  let access_token_response = system(g:QQ_curl_executable . ' -s -X POST "' . 
        \ auth_token_url . auth_token_params . '"')
  "TODO: check for errors
  let access_token = matchstr(access_token_response, '"access_token":"\zs[^"]\+\ze"')

  call append(line("$"), ["HEADER: :Authorization: Bearer ".access_token])
endfunction
