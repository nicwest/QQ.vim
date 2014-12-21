" Imports: {{{1
let s:R = QQ#regexp#import()

" Get: {{{1
function! QQ#mimetypes#getmimetype (response) abort
  return matchstr(a:response, s:R.content_type)
endfunction

function! QQ#mimetypes#getformattingtype(mimetype) abort
  return get(s:mimetypes, tolower(a:mimetype), '')
endfunction

" Set Syntax: {{{1
function! QQ#mimetypes#set_file_type (mimetype) abort
  let l:syntax_file = QQ#mimetypes#getformattingtype(a:mimetype)
  if len(l:syntax_file)
    exe 'set ft=QQ.'.l:syntax_file
  endif
endfunction

" Mimetypes: {{{1
let s:mimetypes = {
      \ 'application/atom+xml': 'xml',
      \ 'application/dart': 'dart',
      \ 'application/ecmascript': 'javascript',
      \ 'application/EDI-X12': 'edif',
      \ 'application/EDIFACT': 'edif',
      \ 'application/json': 'javascript',
      \ 'application/javascript': 'javascript',
      \ 'application/pdf': 'pdf',
      \ 'application/postscript': 'postscript',
      \ 'application/rdf+xml': 'xml',
      \ 'application/rss+xml': 'xml',
      \ 'application/soap+xml': 'xml',
      \ 'application/xhtml+xml': 'html',
      \ 'application/xml': 'xml',
      \ 'application/xml-dtd': 'xml',
      \ 'application/xop+xml': 'xml',
      \ 'message/imdn+xml': 'xml',
      \ 'text/css': 'css',
      \ 'text/html': 'html',
      \ 'text/javascript': 'javascript',
      \ 'text/rtf': 'rtf',
      \ 'text/xml': 'xml',
      \ 'application/x-javascript': 'javascript',
      \ 'application/x-latex': 'latex',
      \ 'text/x-jquery-tmpl': 'javascript',
      \ 'text/x-markdown': 'markdown',
      \ }

" Misc: {{{1
" vim:fdm=marker
