function! phpunit#messages#title(msg) " {{{
  call phpunit#messages#echomsg('Question', 'PHPUnit - ' . a:msg)
endfunction " }}}

function! phpunit#messages#debug(msg) " {{{
  call phpunit#messages#echomsg('none', ' * ' . a:msg)
endfunction " }}}

function! phpunit#messages#error(msg) " {{{
  call phpunit#messages#echomsg('ErrorMsg', ' * ' . a:msg, 1)
endfunction " }}}

" If a:0 > 1 then force the printing of the message
function! phpunit#messages#echomsg(group_name, msg, ...) " {{{
  if a:0 || s:IsDebugActivated()
    silent! redraw
    execute 'echohl' a:group_name
    echomsg a:msg
    echohl none
  endif
endfunction " }}}

function! s:IsDebugActivated() " {{{
  return 1 <= &vbs
endfunction " }}}

" vim: ts=2 sw=2 et fdm=marker
