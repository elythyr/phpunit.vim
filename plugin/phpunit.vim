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


nnoremap <Leader>ta :PHPUnitRunAll<CR>
nnoremap <Leader>tf :PHPUnitRunCurrentFile<CR>
nnoremap <Leader>ts :PHPUnitSwitchFile<CR>


let g:PHPUnit = {}

fun! g:PHPUnit.RunAll()
  let cmd = s:BuildBaseCommand()
  let cmd = cmd + [expand(g:phpunit_testroot)]

  silent call s:Run(cmd, "RunAll")
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
  silent call s:Run(cmd, fnamemodify(l:test_file, ':t'))
endfun

fun! g:PHPUnit.RunTestCase(filter)
  let cmd = s:BuildBaseCommand()
  let cmd = cmd + ["--filter", a:filter , bufname("%")]
  silent call s:Run(cmd, bufname("%") . ":" . a:filter)
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
  redraw
  echohl Title
  echomsg "* Running PHP Unit test(s) [" . a:title . "] *"
  echohl None
  redraw
  echomsg "* Done PHP Unit test(s) [" . a:title . "] *"
  echohl None

  if g:phpunit_tests_result_in_preview
    silent call s:PreviewTestsResults(join(a:cmd, ' '))
  else
    silent call s:OpenTestsResultsInWindow(join(a:cmd, ' '))
  endif
endfun

fun! s:PreviewTestsResults(cmd)
  pclose! " Need it to work when the preview window is already opened

  call s:ExecuteInBuffer(a:cmd, bufnr(s:phpunit_bufname, 1))

  call s:OpenPreview(bufnr(s:phpunit_bufname))
endfun

fun! s:OpenTestsResultsInWindow(cmd)
  call s:ExecuteInBuffer(a:cmd, bufnr(s:phpunit_bufname, 1))

  call s:OpenWindow(bufnr(s:phpunit_bufname))
endfun

fun! s:ExecuteInBuffer(cmd, bufnr)
  execute ':buffer ' . a:bufnr

  " nocursorline is needed for some colorscheme with CursorLine which change ctermbg
  setlocal nobuflisted
    \ nocursorline
    \ nonumber
    \ nowrap
    \ filetype=phpunit
    \ modifiable
    \ buftype=nofile
    \ bufhidden=hide
    \ noswapfile

  silent %delete " Delete the content of the buffer

  " Execute the commande and put the result in the buffer
  execute 'read !' . a:cmd

  setlocal nomodifiable

  buffer # " Go back to the original buffer
endfun

fun! s:OpenPreview(bufnr)
  execute ':' . join(g:phpunit_tests_result_position, ' ') . ' pedit #' . a:bufnr

  wincmd p " Go to the preview window
  setlocal nobuflisted
  call s:ResizeTestsResultsWidow()
  wincmd p " Go back to the user window
endfun

fun! s:OpenWindow(bufnr)
  let l:phpunit_win = bufwinnr(a:bufnr)
  " is buffer visible?
  if -1 != l:phpunit_win
    return
  endif

  execute ':' . join(g:phpunit_tests_result_position, ' ') . ' sb ' . a:bufnr

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
