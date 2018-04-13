let s:sfile = expand('<sfile>')

function! phpunit#sfile()
  return s:sfile
endfunction

function! phpunit#are_tests_opened_verticaly()
  return -1 != index(g:phpunit_tests_results_position, 'vertical')
endfunction

function! phpunit#run_dir(dir, ...)
  let l:dir = resolve(fnamemodify(a:dir, ':p'))
  if !isdirectory(l:dir)
    phpunit#messages#error(printf('The file "%s" is not a directory', l:dir))
  endif

  call call('phpunit#run', [l:dir] + a:000)
endfunction

function! phpunit#run_file(file, ...)
  let l:test_file = phpunit#files#test(a:file)

  if empty(glob(l:test_file))
    call phpunit#messages#debug(printf('The test file "%s" does not exist, abort', l:test_file))
    return
  elseif !filereadable(l:test_file)
    call phpunit#messages#error(printf('The test file "%s" is not readable', l:test_file))
    return
  endif

  call call('phpunit#run', [l:test_file] + a:000)
endfunction

function! phpunit#run_testcase(testcase, ...)
  call call('phpunit#run_file', [expand('%'), '--filter=' . a:testcase] + a:000)
endfunction

function! phpunit#run(file, ...)
  call phpunit#messages#title('Running PHP Unit test(s) for ' . a:file)

  let l:cmd = call('s:BuildCmd', a:000 + [a:file])
  " Forces the colors for ANSI colors
  call phpunit#colors#handle_option(l:cmd)

  if -1 == phpunit#buffers#nr(a:file)
    call phpunit#buffers#create(a:file)

    " Must only do it when we create a new buffer
    if phpunit#colors#activated(l:cmd)
      call phpunit#colors#highlight()
    endif
  else " if already exists we must open it
    call phpunit#buffers#switch(a:file)
  endif

  setlocal modifiable

  silent %delete
  call phpunit#messages#debug('Content deleted')

  try
    silent put = system(join(l:cmd, ' '))
    call phpunit#messages#debug(printf('Results of "%s" put into the buffer', join(l:cmd, ' ')))

    let w:phpunit_results = json_decode(getline('$')) " Decode the JSON results
    silent $delete _ " Cut the last line, with the JSON results
  catch
    let w:phpunit_results = {}
  finally
    setlocal nomodifiable

    silent buffer # " Go back to the original buffer
    call phpunit#messages#debug(printf('Switched back to the previous buffer %s (#%d)', bufname('%'), bufnr('%')))
  endtry
endfunction

function! s:BuildCmd(...)
  let l:cmd = []

  if !empty(g:php_bin)
    call add(l:cmd, g:php_bin)
  endif

  call add(l:cmd, g:phpunit_bin)
  call extend(l:cmd, g:phpunit_options)
  call extend(l:cmd, a:000)

  return l:cmd
endfunction
