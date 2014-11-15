let s:suite = themis#suite('utils')
let s:assert = themis#helper('assert')
call themis#helper('command')

"Strings: {{{1
function! s:suite.strip_name()
  call s:assert.equals(QQ#utils#strip_name(':test:'), 'test')
endfunction

function! s:suite.strip_name_no_change()
  call s:assert.equals(QQ#utils#strip_name('test'), 'test')
endfunction

function! s:suite.strip()
  call s:assert.equals(QQ#utils#strip(' test '), 'test')
endfunction

function! s:suite.strip_no_change()
  call s:assert.equals(QQ#utils#strip('test'), 'test')
endfunction

function! s:suite.matchstr_multiple()
  let l:test_str = '-a "test" -a "foo" -b "not this" -a "bar"'
  let l:test_regexp = '-a "\zs[^"]\+\ze"'
  let l:output = QQ#utils#matchstr_multiple(l:test_str, l:test_regexp)
  call s:assert.is_list(l:output)
  call s:assert.length_of(l:output, 3)
  call s:assert.equals(l:output, ['test', 'foo', 'bar'])
endfunction

function! s:suite.matchstr_multiple_no_matches()
  let l:test_str = '-c "test" -c "foo" -b "not this" -c "bar"'
  let l:test_regexp = '-a "\zs[^"]\+\ze"'
  let l:output = QQ#utils#matchstr_multiple(l:test_str, l:test_regexp)
  call s:assert.is_list(l:output)
  call s:assert.length_of(l:output, 0)
endfunction

function! s:suite.base64encode()
  call s:assert.equals(QQ#utils#base64encode('test'), 'dGVzdA==')
endfunction

function! s:suite.base64encode_multiline()
  call s:assert.equals(QQ#utils#base64encode("test\ntest"), 'dGVzdAp0ZXN0')
endfunction

" Booleans: {{{1

function! s:suite.falsey_with_value_zero()
  call s:assert.true(QQ#utils#falsey(0))
endfunction

function! s:suite.falsey_with_value_false_lower_case()
  call s:assert.true(QQ#utils#falsey('false'))
endfunction

function! s:suite.falsey_with_value_false_mixed_case()
  call s:assert.true(QQ#utils#falsey('False'))
endfunction

function! s:suite.falsey_with_value_no_lower_case()
  call s:assert.true(QQ#utils#falsey('no'))
endfunction

function! s:suite.falsey_with_value_no_mixed_case()
  call s:assert.true(QQ#utils#falsey('No'))
endfunction

function! s:suite.not_falsey()
  call s:assert.false(QQ#utils#falsey('TEST'))
endfunction

function! s:suite.truthy()
  call s:assert.true(QQ#utils#truthy('test'))
endfunction

function! s:suite.not_truthy()
  call s:assert.false(QQ#utils#truthy('false'))
endfunction

" Windows: {{{1

function! s:suite.focus_window_with_name()
  file first
  new second
  call s:assert.equals(expand('%'), 'second') 
  call QQ#utils#focus_window_with_name('first')
  call s:assert.equals(expand('%'), 'first') 
endfunction

" Errors: {{{1

function! s:suite.raise_error()
  Throws /TEST ERROR: something broke/ 
        \ :call QQ#utils#error('TEST', 'something broke')
endfunction

function! s:suite.display_warning()
  call QQ#utils#warning('TEST', 'something is vaguely broken')
endfunction

" Misc: {{{1
" vim: expandtab ts=2 sts=2 sw=2
" vim:fdm=marker
