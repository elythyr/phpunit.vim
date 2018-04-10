let s:bufname_format = 'PHPUnit - %s'
let s:buffers        = {}

function! phpunit#buffers#name(file)
  if !s:Exists(a:file)
    call s:Add(a:file)
  endif

  return s:buffers[a:file]['name']
endfunction

function! phpunit#buffers#nr(file)
  if !s:Exists(a:file)
    call s:Add(a:file)
  endif

  return s:buffers[a:file]['nr']
endfunction

function! phpunit#buffers#create(file)
  if s:Exists(a:file) && -1 != s:buffers[a:file].nr
    throw printf('Trying to create an already existing buffer for the file "%s"', a:file)
  endif

  call s:Create(a:file)
  call phpunit#messages#debug(printf('New buffer created %s (#%d)', phpunit#buffers#name(a:file), phpunit#buffers#nr(a:file)))

  call phpunit#buffers#switch(a:file)

  setlocal modifiable
    \ nocursorline
    \ nonumber
    \ nowrap
    \ nobuflisted
    \ bufhidden=hide
    \ noswapfile
    \ buftype=nowrite
endfunction

function! phpunit#buffers#switch(file)
  execute ':buffer' phpunit#buffers#nr(a:file)
  call phpunit#messages#debug(printf('Switched to buffer %s (#%d)', phpunit#buffers#name(a:file), phpunit#buffers#nr(a:file)))
endfunction

function! s:FormatName(file)
  return printf(s:bufname_format, isdirectory(a:file) ? a:file : s:GetClassName(a:file))
endfunction

function! s:Exists(file)
  return exists('s:buffers[a:file]')
endfunction

function! s:Add(file)
  call s:Register(a:file, v:false)
endfunction

function! s:Create(file)
  call s:Register(a:file, v:true)
endfunction

function! s:Register(file, create)
  let l:name = s:FormatName(a:file)

  let s:buffers[a:file] = {
    \'name': l:name,
    \'nr': bufnr(l:name, a:create),
  \}
endfunction

function! s:GetClassName(file)
  let l:pattern = printf(
        \ '\v%%(%s)?%s$',
        \ g:phpunit_test_file_suffix,
        \ g:php_ext_pattern
        \ )

  return substitute(fnamemodify(a:file, ':t'), l:pattern, '', '')
endfunction
