"
" TODO: use airline to provide some "infintest" and autocmd BufWrite to
" launch tests, maybe change the color of the top tab ? but not everybody
" print it
" TODO: add genereation of testcase, use ultisnip ?
"

let s:bufname_format = 'PHPUnit-%s'
let s:auto_colors_option_pattern = '\v^--colors%(\=auto)?$' " Represents --colors and --colors=auto
let s:activate_colors_option_pattern = '\v^--colors%(\=%(auto|always))?$' " Represents --colors and --colors=auto and --colors=always
" We must force the colors, otherwise phpunit detects that we can not handle
" ANSI colors and disable them
let s:force_colors_options = '--colors=always'
let s:no_colors_option = '--colors=never'
let s:phpunit_filetype = 'phpunit'


command! -nargs=? -complete=tag_listfiles PHPUnitRunAll :call g:PHPUnit.RunAll(<f-args>)
command! -nargs=? -complete=tag_listfiles PHPUnitRunCurrentFile :call g:PHPUnit.RunCurrentFile(<f-args>)
" TODO: use -complete=customlist,{func} => create a function to retrieve all the
" tests functions of a test file - see :h E467
" The first argument must be the test to filter
" The other ones are options to provide to phpunit
command! -nargs=+ -complete=tag_listfiles PHPUnitRunFilter :call g:PHPUnit.RunTestCase(<f-args>)
command! -nargs=0 PHPUnitSwitchFile :call g:PHPUnit.SwitchFile()

call phpunit#init#bootstrap()
call phpunit#init#mappings()


let g:PHPUnit = {}

fun! g:PHPUnit.RunAll(...)
  let l:cmd = call('s:BuildBaseCommand', [expand(g:phpunit_testroot)] + a:000)

  call s:Run(l:cmd, "RunAll")
endfun

fun! g:PHPUnit.RunCurrentFile(...)
  let l:cmd = call('s:BuildBaseCommand', a:000)

  let l:test_file = s:GetCurrentTestFile()

  if empty(glob(l:test_file))
    call s:Error(printf('The test file "%s" does not exists', l:test_file))
    return
  endif

  call add(l:cmd, l:test_file)
  call s:Run(l:cmd, fnamemodify(l:test_file, ':t:r'))
endfun

fun! g:PHPUnit.RunTestCase(filter, ...)
  let l:cmd = call('s:BuildBaseCommand', ["--filter", a:filter] + a:000 + [bufname('%')])

  call s:Run(l:cmd, bufname("%") . ":" . a:filter)
endfun

fun! g:PHPUnit.SwitchFile()
  let l:file_to_open = ''

  if s:IsATestFile(expand('%'))
    let l:file_to_open = s:GetCurrentSrcFile()
  else
    let l:file_to_open = s:GetCurrentTestFile()
  endif

  if empty(glob(l:file_to_open)) && !s:CreateFile(l:file_to_open)
    return
  endif

  call s:OpenFile(l:file_to_open)
endfun


fun! s:CreateFile(file, ...)
  if 'y' != input('The file does not exists, create it ? (y/n) ')
    return
  endif

  let l:file_path = fnamemodify(a:file, ':h')

  if !isdirectory(l:file_path)
    call mkdir(l:file_path, 'p')
    call s:Debug('Creates the directory : ' . l:file_path)
  endif

  return 1
endfun

fun! s:OpenFile(file)
  let l:file_window = bufwinnr(a:file)

  if -1 != l:file_window
    execute l:file_window . 'wincmd w'
  else
    execute g:phpunit_swith_file_cmd a:file
  endif
endfun

fun! s:GetSrcFileFor(file)
  if !s:IsATestFile(a:file)
    return fnamemodify(a:file, ':p')
  endif

  let l:src_file = substitute(fnamemodify(a:file, ':p'), g:phpunit_testroot, g:phpunit_srcroot, '')
  return substitute(l:src_file, '\M' . g:phpunit_test_file_ends_with . '$', '.php', '')
endfun

fun! s:GetTestFileFor(file)
  if s:IsATestFile(a:file)
    return fnamemodify(a:file, ':p')
  endif

  let l:test_file = substitute(fnamemodify(a:file, ':p'), g:phpunit_srcroot, g:phpunit_testroot, '')
  return fnamemodify(l:test_file, ':r') . g:phpunit_test_file_ends_with
endfun

fun! s:GetCurrentSrcFile()
  return s:GetSrcFileFor(expand('%:p'))
endfun

fun! s:GetCurrentTestFile()
  return s:GetTestFileFor(expand('%:p'))
endfun

fun! s:IsATestFile(filename)
  return a:filename =~ '\M' . g:phpunit_test_file_ends_with . '$'
endfun!

fun! s:BuildBaseCommand(...)
  let l:cmd = []

  if !empty(g:php_bin)
    call add(l:cmd, g:php_bin)
  endif

  call add(l:cmd, g:phpunit_bin)
  call extend(l:cmd, g:phpunit_options)
  call s:AddOptionsTo(l:cmd, a:000)

  return l:cmd
endfun

fun! s:AddOptionsTo(cmd, ...)
  if a:0 && type(a:1) == v:t_list
      call extend(a:cmd, a:1)
  elseif a:0
    call add(a:cmd, a:1)
  endif

  return a:cmd
endfun

fun! s:Run(cmd, title)
  let l:results_bufnr = bufnr(printf(s:bufname_format, a:title), 1)

  call s:DebugTitle(printf('Running PHP Unit test(s) [%s]', a:title))

  call s:ExecuteInBuffer(a:cmd, l:results_bufnr)

  call s:OpenTestsResults(l:results_bufnr)
endfun

fun! s:ExecuteInBuffer(cmd, bufnr)
  silent execute ':buffer ' . a:bufnr
  call s:Debug('Switched to buffer #' . a:bufnr)

  " nocursorline is needed for some colorscheme with CursorLine which change ctermbg
  " I don't know why but if the type of the buffer is nofile then whe have an
  " issue with the preview window, this is how I found it:
  "   1 - Open a file
  "   2 - <Leader>tf
  "   3 - <Leader>ts
  "   4 - CTRL-W-z => close the preview window
  "   5 - <Leader>tf
  " Then the preview window is empty
  " Type :ls! and we can see that a fourth buffer has been created, with the
  " same name : PHPUnit
  setlocal modifiable
    \ nocursorline
    \ nonumber
    \ nowrap
    \ nobuflisted
    \ bufhidden=hide
    \ noswapfile
    \ buftype=nowrite

  silent %delete " Delete the content of the buffer
  call s:Debug('Content deleted')

  call s:HandleColorsOption(a:cmd)
  call s:SetColorsActivated(a:cmd)

  " Execute the commande and put the result in the buffer
  silent execute 'read !' . join(a:cmd, ' ')
  call s:Debug(printf('Command "%s" read into the buffer', join(a:cmd, ' ')))

  silent $d " Cut the last line, with the JSON results
  let w:phpunit_results = json_decode(@") " Decode the JSON results

  call s:ColorizeResults()
  setlocal nomodifiable

  silent buffer # " Go back to the original buffer
  call s:Debug('Switched back to the previous buffer #' . bufnr('%'))
endfun

fun! s:OpenTestsResults(bufnr)
  if g:phpunit_tests_result_in_preview
    call s:OpenPreview(a:bufnr)
  else
    call s:OpenWindow(a:bufnr)
  endif
endfun

fun! s:OpenPreview(bufnr)
  pclose " a trick to force the cursor to be placed on the last line of the buffer
  silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' pedit + #' . a:bufnr

  wincmd P " Go to the preview window
  setlocal nobuflisted
  call s:ResizeTestsResultsWidow()
  wincmd p " Go back to the user window
endfun

fun! s:OpenWindow(bufnr)
  if exists('t:phpunit_winid') && win_id2win(t:phpunit_winid)
    silent execute win_id2win(t:phpunit_winid) .'wincmd w'
  else
    silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' split'
    let t:phpunit_winid = win_getid()

    call s:ResizeTestsResultsWidow()
  endif

  setlocal nobuflisted

  if a:bufnr != winbufnr(t:phpunit_winid)
    silent execute ':edit + #' . a:bufnr
    call s:Debug('execute :edit + #' . a:bufnr)
  " If the buffer as more line than the window can show
  elseif len(getbufline(bufnr('%'), 1, '$')) > winheight('%')
    $ " Go to the last line
    redraw " Need to redraw the window
  endif

  wincmd p
endfun

fun! s:ResizeTestsResultsWidow()
  let l:cmd = ':'
  if phpunit#are_tests_opened_verticaly()
    let l:cmd .= 'vertical '
  endif

  execute l:cmd . 'resize ' . g:phpunit_window_size
endfun

fun! s:HandleColorsOption(cmd)
  call map(a:cmd, function('s:ConvertAutoColorsOption'))
endfun

fun! s:ConvertAutoColorsOption(index, option)
  if s:CanUseAnsiColors() && a:option =~# s:auto_colors_option_pattern
    call s:Debug('Forces the coloration')
    return s:force_colors_options
  endif

  return a:option
endfun

fun! s:SetColorsActivated(cmd)
  let s:colors_are_activated = s:AreColorsActivated(a:cmd) ? 1 : 0
endfun

fun! s:AreColorsActivated(cmd)
  for l:option in a:cmd
    if l:option =~# s:activate_colors_option_pattern
      return 1
    endif
  endfor

  return 0
endfun

fun! s:ColorizeResults()
  if !s:colors_are_activated
    return
  endif

  if s:CanUseAnsiColors()
    call s:Debug('Colorize with ANSI colors')
    call s:TranslateAnsiColosForTheBuffer()
  else
    call s:Debug('Colorize using filetype')
    execute ':setlocal filetype=' . s:phpunit_filetype
  endif
endfun

fun! s:CanUseAnsiColors()
  return 2 == exists(':AnsiEsc')
endfun

func! s:TranslateAnsiColosForTheBuffer()
  AnsiEsc
endfun

fun! s:DebugTitle(msg)
  call s:EchoMsg('Question', 'PHPUnit - ' . a:msg)
endfun

fun! s:Debug(msg)
  call s:EchoMsg('none', ' * ' . a:msg)
endfun

fun! s:Error(msg)
  call s:EchoMsg('ErrorMsg', ' * ' . a:msg)
endfun

fun! s:EchoMsg(group_name, msg)
  if s:IsDebugActivated()
    execute 'echohl ' . a:group_name
    silent! redraw
    echomsg a:msg
    echohl none
  endif
endfun

fun! s:IsDebugActivated()
  return 1 <= &vbs
endfun
