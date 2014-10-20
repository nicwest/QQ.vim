let s:suite = themis#suite('utilities')
let s:assert = themis#helper('assert')

let s:U = QQ#utils#import()

" Import: {{{1
function! s:suite.import()
  call s:assert.is_dict(s:U)
  call s:assert.length_of(s:U, 7)
  call s:assert.is_func(s:U.strip_name)
  call s:assert.is_func(s:U.strip)
  call s:assert.is_func(s:U.matchstr_multiple)
  call s:assert.is_func(s:U.base64encode)
  call s:assert.is_func(s:U.falsey)
  call s:assert.is_func(s:U.truthy)
  call s:assert.is_func(s:U.focus_window_with_name)
endfunction

"String functions: {{{1
function! s:suite.strip_name()
  call s:assert.equals(s:U.strip_name(':test:'), 'test')
endfunction

function! s:suite.strip_name_no_change()
  call s:assert.equals(s:U.strip_name('test'), 'test')
endfunction

function! s:suite.strip()
  call s:assert.equals(s:U.strip(' test '), 'test')
endfunction

function! s:suite.strip_no_change()
  call s:assert.equals(s:U.strip('test'), 'test')
endfunction

function! s:suite.matchstr_multiple()
  let l:test_str = '-a "test" -a "foo" -b "not this" -a "bar"'
  let l:test_regexp = '-a "\zs[^"]\+\ze"'
  let l:output = s:U.matchstr_multiple(l:test_str, l:test_regexp)
  call s:assert.is_list(l:output)
  call s:assert.length_of(l:output, 3)
  call s:assert.equals(l:output, ['test', 'foo', 'bar'])
endfunction

function! s:suite.matchstr_multiple_no_matches()
  let l:test_str = '-c "test" -c "foo" -b "not this" -c "bar"'
  let l:test_regexp = '-a "\zs[^"]\+\ze"'
  let l:output = s:U.matchstr_multiple(l:test_str, l:test_regexp)
  call s:assert.is_list(l:output)
  call s:assert.length_of(l:output, 0)
endfunction

function! s:suite.base64encode()
  call s:assert.equals(s:U.base64encode('test'), 'dGVzdA==')
endfunction

function! s:suite.base64encode_multiline()
  call s:assert.equals(s:U.base64encode("test\ntest"), 'dGVzdAp0ZXN0')
endfunction

" Boolean functions: {{{1

function! s:suite.falsey_with_value_zero()
  call s:assert.true(s:U.falsey(0))
endfunction

function! s:suite.falsey_with_value_false_lower_case()
  call s:assert.true(s:U.falsey('false'))
endfunction

function! s:suite.falsey_with_value_false_mixed_case()
  call s:assert.true(s:U.falsey('False'))
endfunction

function! s:suite.falsey_with_value_no_lower_case()
  call s:assert.true(s:U.falsey('no'))
endfunction

function! s:suite.falsey_with_value_no_mixed_case()
  call s:assert.true(s:U.falsey('No'))
endfunction

function! s:suite.not_falsey()
  call s:assert.false(s:U.falsey('TEST'))
endfunction

function! s:suite.truthy()
  call s:assert.true(s:U.truthy('test'))
endfunction

function! s:suite.not_truthy()
  call s:assert.false(s:U.truthy('false'))
endfunction

" Window functions: {{{1

function! s:suite.focus_window_with_name()
  file first
  new second
  call s:assert.equals(expand('%'), 'second') 
  call s:U.focus_window_with_name('first')
  call s:assert.equals(expand('%'), 'first') 
endfunction

" vim: expandtab ts=2 sts=2 sw=2
" vim:fdm=marker
