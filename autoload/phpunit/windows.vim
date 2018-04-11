function! phpunit#windows#id()
  return get(t:, 'phpunit_winid')
endfunction

function! phpunit#windows#nr()
  return win_id2win(phpunit#windows#id())
endfunction

" Param: string a:1 file
function! phpunit#windows#opened(...)
  if a:0
    return -1 != bufwinid(phpunit#buffers#nr(a:1))
  else
    return 0 != win_id2win(phpunit#windows#id())
  endif
endfunction

function phpunit#windows#open(file)
  if !phpunit#windows#opened(a:file)
    if g:phpunit_tests_result_in_preview
      call phpunit#windows#preview(a:file)
    else
      call phpunit#windows#normal(a:file)
    endif

    return
  endif

  call phpunit#windows#update()
endfunction

function! phpunit#windows#preview(file)
  "pclose! " a trick to force the cursor to be placed on the last line of the buffer
  silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' pedit + #' . phpunit#buffers#nr(a:file)

  wincmd P " Go to the preview window
  call s:SetWinid(win_getid())
  call phpunit#windows#resize()
  setlocal nobuflisted
  wincmd p " Go back to the user window
endfunction

function! phpunit#windows#normal(file)
  if phpunit#windows#opened()
    silent execute phpunit#windows#nr() .'wincmd w'
  else
    silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' split'

    call s:SetWinid(win_getid())
    call phpunit#windows#resize()
  endif

  setlocal nobuflisted

  let l:bufnr = phpunit#buffers#nr(a:file)
  silent execute ':edit + #' . l:bufnr
  call phpunit#messages#debug('execute :edit + #' . l:bufnr)

  wincmd p
endfunction

" Update the window, usefull when the runned tests were alredy opened in a
" window.
" Put the cursor on the last line, if needed, to allow to see the results
function! phpunit#windows#update()
  execute phpunit#windows#nr() 'wincmd w'

  " If the buffer as more line than the window can show
  if len(getbufline('%', 1, '$')) > winheight('%')
    $
    redraw
  endif

  wincmd p
endfunction

function! phpunit#windows#resize()
  let l:cmd = ':'
  if phpunit#are_tests_opened_verticaly()
    let l:cmd .= 'vertical '
  endif

  execute l:cmd . 'resize ' . g:phpunit_window_size
endfunction

function! phpunit#windows#close()
  if !phpunit#windows#opened()
    return
  endif

  execute phpunit#windows#nr() 'wincmd c'
endfunction

function! s:SetWinid(winid)
  " TODO: see WinLeave event for handling when the window is closed
  let t:phpunit_winid = a:winid
endfunction
