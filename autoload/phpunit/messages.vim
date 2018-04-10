fun! phpunit#messages#title(msg)
  call phpunit#messages#echomsg('Question', 'PHPUnit - ' . a:msg)
endfun

fun! phpunit#messages#debug(msg)
  call phpunit#messages#echomsg('none', ' * ' . a:msg)
endfun

fun! phpunit#messages#error(msg)
  call phpunit#messages#echomsg('ErrorMsg', ' * ' . a:msg, 1)
endfun

" If a:0 > 1 then force the printing of the message
fun! phpunit#messages#echomsg(group_name, msg, ...)
  if a:0 || s:IsDebugActivated()
    silent! redraw
    execute 'echohl' a:group_name
    echomsg a:msg
    echohl none
  endif
endfun

fun! s:IsDebugActivated()
  return 1 <= &vbs
endfun
