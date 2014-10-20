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
