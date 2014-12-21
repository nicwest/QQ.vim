let s:R = QQ#regexp#import()

" String Functions: {{{1
" ===============
function! QQ#utils#strip_name(input_string) abort
  "turns ":{key}:" into "{key}"
  return substitute(a:input_string, s:R.strip_name, '\1', '')
endfunction

function! QQ#utils#strip(input_string) abort
  "removes white space at the beginning and end of string
  return substitute(a:input_string, s:R.strip, '\1', '')
endfunction

function! QQ#utils#matchstr_multiple(str, expr) abort
  "extract repeated expression from str
  let itemcount = 1
  let items = []
  while match(a:str, a:expr, 0, itemcount) >= 0
    call add(items, matchstr(a:str, a:expr, 0, itemcount))
    let itemcount += 1
  endwhile
  return items
endfunction

function! QQ#utils#base64encode(str) abort
  "TODO: refactor this madness
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let chars .= "abcdefghijklmnopqrstuvwxyz"
  let chars .= "0123456789"
  let chars .= "+/"

  let char_list = split(chars, '\ze')

  let out = ""
  let input_list = split(a:str, '\ze')
  let bin_stack = []
  while len(input_list)
    let block = input_list[:2]
    let input_list = input_list[3:]
    let block_out = ""
    let padding = ""
    while len(block) < 3
      call add(block, '')
      let padding = padding."="
    endwhile
    while len(block)
      let bin_char = []
      let nr = char2nr(block[0])
      while len(bin_char) < 8
        let result = nr/2.0
        let nr = floor(result)
        call insert(bin_char, result != nr, 0)
      endwhile
      let block = block[1:]
      let bin_stack = bin_stack + bin_char
      while len(bin_stack) > 5
        let char_bin = bin_stack[:5]
        let char_index = 0
        while len(char_bin) > 0
          let char_index = (char_index * 2) + char_bin[0] 
          let char_bin = char_bin[1:]
        endwhile
        let block_out .= char_list[char_index]
        let bin_stack = bin_stack[6:]
      endwhile
    endwhile
    if len(padding)
      let out .= join(split(block_out, '\ze')[:3-len(padding)], '').padding
    else
      let out .= block_out
    endif
  endwhile
  return out
endfunction

" Boolean Functions: {{{1
function! QQ#utils#falsey(input_string) abort
  "if string is 0, false, or no it is falsey (normally this would include nil
  "values or empty stings, but for the moment I think these will be synonymous
  "with setting true in the context of "OPTION: :{key}: {value}", might change
  "this later)
  if a:input_string =~? s:R.falsey
    return 1
  else
    return 0
  endif
endfunction

function! QQ#utils#truthy(input_string) abort
  "if it's not falsey then it's truthy
  return 1 - QQ#utils#falsey(a:input_string)
endfunction

" Window Functions: {{{1
function! QQ#utils#focus_window_with_name(window) abort
  "focuses open window with loaded buffer name active
  exe 'norm'.bufwinnr(a:window).'w'
endfunction

" Buffer Functions: {{{1
function! QQ#utils#create_buffer(name, ...) abort
  let dimension = exists('a:1') ? a:1 : ''
  let direction = exists('a:2') ? a:2 : ''
  sil! exe 'keepa bo ' . dimension . direction.'new' a:name
endfunction

" Error Functions: {{{1
function! QQ#utils#error(type, message) abort
  throw a:type." ERROR: ".a:message
endfunction

function! QQ#utils#close_window() abort
  norm! ZQ
endfunction

function! QQ#utils#warning(type, message) abort
  echohl WarningMsg | echomsg a:type." WARNING: ".a:message | echohl None
endfunction
" Misc : {{{1
" vim: expandtab ts=2 sts=2 sw=2
" vim:fdm=marker
