function! phpunit#init#bootstrap()
  if get(s:, 'bootstraped', 0)
    return
  endif

  call s:CheckedOptions('php_bin',                          '')
  call s:CheckedOptions('php_ext_pattern',                  '\.p%(hp[3457]?|html)')
  call s:CheckedOptions('phpunit_bin',                      'phpunit')
  call s:CheckedOptions('phpunit_test_file_suffix',         'Test')
  call s:CheckedOptions('phpunit_tests_dir',                'tests')
  call s:CheckedOptions('phpunit_src_dir',                  'src')
  call s:CheckedOptions('phpunit_tests_result_in_preview',  0)
  call s:CheckedOptions('phpunit_tests_result_position',    function('s:DefaultTestsResultPosition'))
  call s:CheckedOptions('phpunit_window_size',              function('s:DefaultPhpunitWindowsSize'))
  call s:CheckedOptions('phpunit_swith_file_position',      ['vertical', 'rightbelow'])
  call s:CheckedOptions('phpunit_swith_file_to_new_window', 1)
  call s:CheckedOptions('phpunit_swith_file_cmd',           function('s:DefaultSwitchFileCmd'))
  call s:CheckedOptions('phpunit_disable_stop_on_failure',  0)
  call s:CheckedOptions('phpunit_options',                  ['--stop-on-failure'])

  call s:ProvidesAdditionalOptionsToPhpunit()

  let s:bootstraped = 1
endfunction

function! phpunit#init#mappings()
  if get(s:, 'mapped', 0)
    return
  endif

  nnoremap <unique> <Plug>PhpunitRunall :PHPUnitRunAll<CR>
  nnoremap <unique> <Plug>PhpunitRuncurrentfile :PHPUnitRunCurrentFile<CR>
  nnoremap <unique> <Plug>PhpunitSwitchfile :PHPUnitSwitchFile<CR>

  nmap <Leader>ta <Plug>PhpunitRunall
  nmap <Leader>tf <Plug>PhpunitRuncurrentfile
  nmap <Leader>ts <Plug>PhpunitSwitchfile

  let s:mapped = 1
endfunction

function! s:CheckedOptions(name, default)
  if !exists('g:{a:name}')
    let g:{a:name} = v:t_func == type(a:default) ? a:default() : a:default
  endif
endfunction

function! s:DefaultTestsResultPosition()
  return g:phpunit_tests_result_in_preview ? ['botright'] : ['vertical', 'rightbelow']
endfunction

function! s:DefaultSwitchFileCmd()
  return g:phpunit_swith_file_to_new_window
    \ ? join(g:phpunit_swith_file_position, ' ') . ' split'
    \ : 'edit'
endfunction

function! s:DefaultPhpunitWindowsSize()
  return phpunit#are_tests_opened_verticaly() ? 50 : 12
endfunction

function! s:ProvidesAdditionalOptionsToPhpunit()
  let l:stop_on_failure_exists = -1 != index(g:phpunit_options, '--stop-on-failure')

  if !l:stop_on_failure_exists && !get(g:, 'phpunit_disable_stop_on_failure', 0)
    call add(g:phpunit_options, '--stop-on-failure')
  endif

  call add(g:phpunit_options, printf('--include-path=%s', fnamemodify(phpunit#sfile(), ':p:h:h')))
  call add(g:phpunit_options, '--printer=SimpleJsonCounterPrinter')

  if phpunit#are_tests_opened_verticaly()
    call add (g:phpunit_options, '--columns=' . g:phpunit_window_size)
  endif
endfunction
