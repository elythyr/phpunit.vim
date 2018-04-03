"
" TODO: use airline to provide some "infintest" and autocmd BufWrite to
" launch tests, maybe change the color of the top tab ? but not everybody
" print it
" TODO: add genereation of testcase, use ultisnip ?
"

let s:phpunit_bufname_format = 'PHPUnit-%s'

if !exists('g:phpunit_tests_result_in_preview')
  let g:phpunit_tests_result_in_preview = 0
endif

if !exists('g:phpunit_tests_result_position')
  if g:phpunit_tests_result_in_preview
    let g:phpunit_tests_result_position = ['botright']
  else
    let g:phpunit_tests_result_position = ['vertical', 'rightbelow']
  endif
endif

if !exists('g:phpunit_swith_file_position')
  let g:phpunit_swith_file_position = ['vertical', 'rightbelow']
endif

if get(g:, 'phpunit_swith_file_to_new_window', 1)
  let g:phpunit_swith_file_cmd = join(g:phpunit_swith_file_position, ' ') . ' split'
else
  let g:phpunit_swith_file_cmd = 'edit'
endif

" Forced to declare it here because it needs to be available when the script
" is loaded
fun! s:OpenTestsResultsVerticaly()
  return -1 != index(g:phpunit_tests_result_position, 'vertical')
endfun

if !exists('g:phpunit_window_size')
  if s:OpenTestsResultsVerticaly()
    let g:phpunit_window_size = 50 " Width
  else
    let g:phpunit_window_size = 12 " Height
  endif
endif

" root of unit tests
if !exists('g:phpunit_testroot')
  let g:phpunit_testroot = fnamemodify(finddir('tests', '.;'), ':p:h')
endif

if !exists('g:phpunit_srcroot')
  let g:phpunit_srcroot = fnamemodify(finddir('src', '.;'), ':p')
elseif '.' == g:phpunit_srcroot
  let g:phpunit_srcroot = fnamemodify(g:phpunit_testroot, ':h')
else
  let g:phpunit_srcroot = finddir(g:phpunit_srcroot, '.;')
endif

if !exists('g:phpunit_test_file_ends_with')
  let g:phpunit_test_file_ends_with = 'Test.php'
endif

if !exists('g:php_bin')
  let g:php_bin = ''
endif

if !exists('g:phpunit_bin')
  let g:phpunit_bin = 'phpunit'
endif

if !exists('g:phpunit_options')
  let g:phpunit_options = ['--stop-on-failure']

  if s:OpenTestsResultsVerticaly()
    let g:phpunit_options = ['--columns=' . g:phpunit_window_size]
  endif
endif

if !exists('g:phpunit_launch_test_on_save')
  let g:phpunit_launch_test_on_save = 0
endif

" you can set there subset of tests if you do not want to run
" full set
if !exists('g:phpunit_tests')
  let g:phpunit_tests = g:phpunit_testroot
endif


nnoremap <unique> <Plug>PhpunitRunall :PHPUnitRunAll<CR>
nnoremap <unique> <Plug>PhpunitRuncurrentfile :PHPUnitRunCurrentFile<CR>
nnoremap <unique> <Plug>PhpunitSwitchfile :PHPUnitSwitchFile<CR>

nmap <Leader>ta <Plug>PhpunitRunall
nmap <Leader>tf <Plug>PhpunitRuncurrentfile
nmap <Leader>ts <Plug>PhpunitSwitchfile

augroup phpunit
  autocmd!
  if g:phpunit_launch_test_on_save
    autocmd BufWritePost *.php :PHPUnitRunCurrentFile
  endif
augroup END

command! -nargs=0 PHPUnitRunAll :call g:PHPUnit.RunAll()
command! -nargs=0 PHPUnitRunCurrentFile :call g:PHPUnit.RunCurrentFile()
" TODO: use -complete=customlist,{func} => create a function to retrieve all the
" tests functions of a test file - see :h E467
command! -nargs=1 -complete=tag_listfiles PHPUnitRunFilter :call g:PHPUnit.RunTestCase(<f-args>)
command! -nargs=0 PHPUnitSwitchFile :call g:PHPUnit.SwitchFile()


let g:PHPUnit = {}

fun! g:PHPUnit.RunAll()
  let cmd = s:BuildBaseCommand()
  let cmd = cmd + [expand(g:phpunit_testroot)]

  call s:Run(cmd, "RunAll")
endfun

fun! g:PHPUnit.RunCurrentFile()
  let cmd = s:BuildBaseCommand()

  let l:test_file = s:GetCurrentTestFile()

  if empty(glob(l:test_file))
    call s:Error(printf('The test file "%s" does not exists', l:test_file))
    return
  endif

  let cmd = cmd + [l:test_file]
  call s:Run(cmd, fnamemodify(l:test_file, ':t:r'))
endfun

fun! g:PHPUnit.RunTestCase(filter)
  let cmd = s:BuildBaseCommand()
  let cmd = cmd + ["--filter", a:filter , bufname("%")]
  call s:Run(cmd, bufname("%") . ":" . a:filter)
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

fun! s:BuildBaseCommand()
  let cmd = []
  if g:php_bin != ""
    call add(cmd, g:php_bin)
  endif
  call add(cmd, g:phpunit_bin)
  call add(cmd, join(g:phpunit_options, " "))
  return cmd
endfun

fun! s:Run(cmd, title)
  let l:results_bufnr = bufnr(printf(s:phpunit_bufname_format, a:title), 1)

  call s:DebugTitle(printf('Running PHP Unit test(s) [%s]', a:title))
  call s:Debug('Using the command : ' . join(a:cmd, ' '))

  call s:ExecuteInBuffer(join(a:cmd, ' '), l:results_bufnr)

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
    \ filetype=phpunit
    \ nobuflisted
    \ bufhidden=hide
    \ noswapfile
    \ buftype=nowrite

  silent %delete " Delete the content of the buffer
  call s:Debug('Content deleted')

  " Execute the commande and put the result in the buffer
  silent execute 'read !' . a:cmd
  call s:Debug(printf('Command "%s" read into the buffer', a:cmd))

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
  if s:OpenTestsResultsVerticaly()
    let l:cmd .= 'vertical '
  endif

  execute l:cmd . 'resize ' . g:phpunit_window_size
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
