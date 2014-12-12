function! QQ#mimetypes#getmimetype (response) abort
  return matchstr(a:response, 'Content-Type:\s\zs[^ /]\+/[^ ;]\+\ze\(\s\|;\)')
endfunction

function! QQ#mimetypes#guess_syntax (mimetype) abort
  let l:syntax_file = get(s:mimetypes, tolower(a:mimetype), 0)
  if l:syntax_file
    exe 'runtime!' l:syntax_file
  endif
endfunction

let s:mimetypes = {
      \ 'application/atom+xml': 'syntax/xml.vim',
      \ 'application/dart': 'syntax/dart.vim',
      \ 'application/ecmascript': 'syntax/javascript.vim',
      \ 'application/EDI-X12': 'syntax/edif.vim',
      \ 'application/EDIFACT': 'syntax/edif.vim',
      \ 'application/json': 'syntax/javascript.vim',
      \ 'application/javascript': 'syntax/javascript.vim',
      \ 'application/pdf': 'syntax/pdf.vim',
      \ 'application/postscript': 'syntax/postscript.vim',
      \ 'application/rdf+xml': 'syntax/xml.vim',
      \ 'application/rss+xml': 'syntax/xml.vim',
      \ 'application/soap+xml': 'syntax/xml.vim',
      \ 'application/xhtml+xml': 'syntax/html.vim',
      \ 'application/xml': 'syntax/xml.vim',
      \ 'application/xml-dtd': 'syntax/xml.vim',
      \ 'application/xop+xml': 'syntax/xml.vim',
      \ 'message/imdn+xml': 'syntax/xml.vim',
      \ 'text/css': 'syntax/css.vim',
      \ 'text/html': 'syntax/html.vim',
      \ 'text/javascript': 'syntax/javascript.vim',
      \ 'text/rtf': 'syntax/rtf.vim',
      \ 'text/xml': 'syntax/xml.vim',
      \ 'application/x-javascript': 'syntax/javascript.vim',
      \ 'application/x-latex': 'syntax/latex.vim',
      \ 'text/x-jquery-tmpl': 'syntax/javascript.vim',
      \ 'text/x-markdown': 'syntax/markdown.vim',
      \ }
