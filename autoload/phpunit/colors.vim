let s:auto_colors_option_pattern     = '\v^--colors%(\=auto)?$'
let s:activate_colors_option_pattern = '\v^--colors%(\=%(auto|always))?$'
let s:force_colors_options           = '--colors=always'
let s:no_colors_option               = '--colors=never'
let s:phpunit_filetype               = 'phpunit'

function! phpunit#colors#can_use_ansi() " {{{
  "return 0
  return 2 == exists(':AnsiEsc')
endfunction " }}}

function! phpunit#colors#escape_ansi() " {{{
    AnsiEsc
endfunction " }}}

function! phpunit#colors#highlight() " {{{
  if phpunit#colors#can_use_ansi()
    call phpunit#messages#debug('Colorize with ANSI colors')
    call phpunit#colors#escape_ansi()
  else
    call phpunit#messages#debug('Colorize using filetype')
    execute ':setlocal filetype=' . s:phpunit_filetype
  endif
endfunction " }}}

function! phpunit#colors#activated(cmd) " {{{
  for l:option in a:cmd
    if l:option =~# s:activate_colors_option_pattern
      return 1
    endif
  endfor

  return 0
endfunction " }}}

function! phpunit#colors#handle_option(cmd) " {{{
  call map(a:cmd, function('s:ConvertAutoColorsOption'))
endfunction " }}}

" We must force the colors if we want to use ANSI colors
function! s:ConvertAutoColorsOption(index, option) " {{{
  if phpunit#colors#can_use_ansi() && a:option =~# s:auto_colors_option_pattern
    call phpunit#messages#debug('Forces the coloration')
    return s:force_colors_options
  endif

  return a:option
endfunction " }}}

" vim: ts=2 sw=2 et fdm=marker
