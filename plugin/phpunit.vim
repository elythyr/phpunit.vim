"
" TODO: use airline to provide some "infintetest" and autocmd BufWrite to
" launch tests, maybe change the color of the top tab ? but not everybody
" print it
" TODO: add genereation of testcase, use ultisnip ?
"

if !exists('s:phpunit_bufname')
  let s:phpunit_bufname = 'PHPUnit'
endif

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
  let g:phpunit_options = ['--stop-on-failure', '--columns=50']
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


let g:PHPUnit = {}

fun! g:PHPUnit.RunAll()
  let cmd = s:BuildBaseCommand()
  let cmd = cmd + [expand(g:phpunit_testroot)]

  call s:Run(cmd, "RunAll")
endfun

fun! g:PHPUnit.RunCurrentFile()
  let cmd = s:BuildBaseCommand()

  let l:test_file = expand('%:p')
  if !s:IsATestFile(l:test_file)
    let l:test_file = s:GetTestFile(l:test_file)
  endif

  if empty(glob(l:test_file))
    echoerr printf('The test file "%s" does not exists', l:test_file)
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
    let l:file_to_open = s:GetSrcFile(expand('%:p'))
  else
    let l:file_to_open = s:GetTestFile(expand('%:p'))
  endif

  if !filereadable(l:file_to_open)
    echoerr printf('The file "%s" is not readable', l:file_to_open)
    return
  endif

  let l:file_window = bufwinnr(l:file_to_open)

  if -1 != l:file_window
    execute l:file_window . 'wincmd w'
  else
    execute 'split ' . l:file_to_open
  endif
endfun


command! -nargs=0 PHPUnitRunAll :call g:PHPUnit.RunAll()
command! -nargs=0 PHPUnitRunCurrentFile :call g:PHPUnit.RunCurrentFile()
" TODO: use -complete=customlist,{func} => create a function to retrieve all the
" tests functions of a test file - see :h E467
command! -nargs=1 -complete=tag_listfiles PHPUnitRunFilter :call g:PHPUnit.RunTestCase(<f-args>)
command! -nargs=0 PHPUnitSwitchFile :call g:PHPUnit.SwitchFile()


fun! s:GetSrcFile(test_file)
    let l:src_file = substitute(a:test_file, g:phpunit_testroot, g:phpunit_srcroot, '')
    return substitute(l:src_file, '\M' . g:phpunit_test_file_ends_with . '$', '.php', '')
endfun

fun! s:GetTestFile(src_file)
    let l:test_file = substitute(a:src_file, g:phpunit_srcroot, g:phpunit_testroot, '')
    return fnamemodify(l:test_file, ':r') . g:phpunit_test_file_ends_with
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
  call s:DebugTitle(printf('Running PHP Unit test(s) [%s]', a:title))
  call s:Debug(' * Using the command : ' . join(a:cmd, ' '))

  call s:ExecuteInBuffer(join(a:cmd, ' '), bufnr(s:phpunit_bufname, 1))

  call s:OpenTestsResults()

  if s:IsDebugActivated()
    redraw! " Need to redraw if we print some output
  endif
endfun

fun! s:ExecuteInBuffer(cmd, bufnr)
  silent execute ':buffer ' . a:bufnr
  call s:Debug(' * Switched to buffer #' . a:bufnr)

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
  call s:Debug(' * Content deleted')

  " Execute the commande and put the result in the buffer
  silent execute 'read !' . a:cmd
  call s:Debug(printf(' * Command "%s" read into the buffer', a:cmd))

  setlocal nomodifiable

  silent buffer # " Go back to the original buffer
  call s:Debug(' * Switched back to the previous buffer #' . bufnr('%'))
endfun

fun! s:OpenTestsResults()
  if -1 != bufwinnr(s:phpunit_bufname)
    return
  endif

  if g:phpunit_tests_result_in_preview
    call s:OpenPreview(bufnr(s:phpunit_bufname))
  else
    call s:OpenWindow(bufnr(s:phpunit_bufname))
  endif
endfun

fun! s:OpenPreview(bufnr)
  silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' pedit #' . a:bufnr

  wincmd p " Go to the preview window
  setlocal nobuflisted
  call s:ResizeTestsResultsWidow()
  wincmd p " Go back to the user window
endfun

fun! s:OpenWindow(bufnr)
  silent execute ':' . join(g:phpunit_tests_result_position, ' ') . ' sb ' . a:bufnr

  call s:ResizeTestsResultsWidow()

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
  echohl Question
  call s:Debug('PHPUnit - ' . a:msg)
  echohl none
endfun

fun! s:Debug(msg)
  if s:IsDebugActivated()
    silent! redraw
    echomsg a:msg
  endif
endfun

fun! s:IsDebugActivated()
  return 1 <= &vbs
endfun
