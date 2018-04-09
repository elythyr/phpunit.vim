let s:sfile = expand('<sfile>')

function! phpunit#sfile()
  return s:sfile
endfunction

function! phpunit#are_tests_opened_verticaly()
  return -1 != index(g:phpunit_tests_result_position, 'vertical')
endfunction
