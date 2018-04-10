fun! phpunit#files#is_test(filename)
  return a:filename =~# printf('\v%s%s$', g:phpunit_test_file_suffix, g:php_ext_pattern)
endfun!

fun! phpunit#files#src(file)
  if !phpunit#files#is_test(a:file)
    return fnamemodify(a:file, ':p')
  endif

  let l:src_file = substitute(fnamemodify(a:file, ':p'), g:phpunit_testroot, g:phpunit_srcroot, '')
  return substitute(
    \ l:src_file,
    \ printf('\v%s(%s)$', g:phpunit_test_file_suffix, g:php_ext_pattern),
    \ '\1',
    \ ''
  \ )
endfun

fun! phpunit#files#test(file)
  if phpunit#files#is_test(a:file)
    return fnamemodify(a:file, ':p')
  endif

  let l:test_file = substitute(fnamemodify(a:file, ':p'), g:phpunit_srcroot, g:phpunit_testroot, '')
  return printf(
    \ '%s.%s',
    \ fnamemodify(l:test_file, ':r') . g:phpunit_test_file_suffix,
    \ fnamemodify(l:test_file, ':e')
  \ )
endfun

fun! phpunit#files#switch()
  let l:file_to_open = expand('%')

  if phpunit#files#is_test(l:file_to_open)
    let l:file_to_open = phpunit#files#src(l:file_to_open)
  else
    let l:file_to_open = phpunit#files#test(l:file_to_open)
  endif

  if empty(glob(l:file_to_open))
    if 'y' != input('The file does not exists, create it ? (y/n) ')
      return
    endif

    call phpunit#files#create(l:file_to_open)
  endif

  call phpunit#files#open(l:file_to_open)
endfun

fun! phpunit#files#create(file)
  let l:file_path = fnamemodify(a:file, ':h')

  if !isdirectory(l:file_path)
    call mkdir(l:file_path, 'p')
    call phpunit#messages#debug('Creates the directory : ' . l:file_path)
  endif
endfun

fun! phpunit#files#open(file)
  let l:file_window = bufwinnr(a:file)

  if -1 != l:file_window
    execute l:file_window . 'wincmd w'
  else
    execute g:phpunit_swith_file_cmd a:file
  endif
endfun
