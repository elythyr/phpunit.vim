"
" TODO: use airline to provide some "infintetest" and autocmd BufWrite to
" launch tests
"

highlight PHPUnitFail guibg=Red ctermbg=Red guifg=White ctermfg=White
highlight PHPUnitOK guibg=Green ctermbg=Green guifg=Black ctermfg=Black
highlight PHPUnitAssertFail guifg=LightRed ctermfg=LightRed

if !exists('s:phpunit_bufname')
  let s:phpunit_bufname = 'PHPUnit'
endif

if !exists('g:phpunit_show_in_preview')
  let g:phpunit_show_in_preview = 1 " TODO: pass to 0 for production, keeping old functionality
endif

if !exists('g:phpunit_vertical')
  let g:phpunit_vertical = 0
endif

if !exists('g:phpunit_position')
  let g:phpunit_position = 'botright'
endif

" root of unit tests
if !exists('g:phpunit_testroot')
  let g:phpunit_testroot = 'tests'
endif
if !exists('g:phpunit_srcroot')
  let g:phpunit_srcroot = 'src'
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


let g:PHPUnit = {}

fun! g:PHPUnit.buildBaseCommand()
  let cmd = []
  if g:php_bin != ""
    call add(cmd, g:php_bin)
  endif
  call add(cmd, g:phpunit_bin)
  call add(cmd, join(g:phpunit_options, " "))
  return cmd
endfun

fun! g:PHPUnit.Run(cmd, title)
  redraw
  echohl Title
  echomsg "* Running PHP Unit test(s) [" . a:title . "] *"
  echohl None
  redraw
  echomsg "* Done PHP Unit test(s) [" . a:title . "] *"
  echohl None

  if g:phpunit_show_in_preview
    silent call g:PHPUnit.PreviewTestResult(join(a:cmd, " "))
  else
    let output = system(join(a:cmd, " "))
    silent call g:PHPUnit.OpenBuffer(output)
  endif
endfun

fun! g:PHPUnit.PreviewTestResult(cmd)
  pclose! " Need it to work when the preview window is already opened

  call s:ExecuteInBuffer(a:cmd, bufnr(s:phpunit_bufname, 1))

  call s:OpenPreview(bufnr(s:phpunit_bufname))
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
  execute "read !" . a:cmd

  setlocal nomodifiable

  buffer # " Go back to the original buffer
endfun

fun! s:OpenPreview(file)
  let vertical = ''
  if g:phpunit_vertical
    let vertical .= 'vertical'
  endif

  execute ":" . vertical . " " . g:phpunit_position . " pedit #" . a:file

endfun

fun! g:PHPUnit.OpenBuffer(content)
  " is there phpunit_buffer?
  if exists('g:phpunit_buffer') && bufexists(g:phpunit_buffer)
    let phpunit_win = bufwinnr(g:phpunit_buffer)
    " is buffer visible?
    if phpunit_win > 0
      " switch to visible phpunit buffer
      execute phpunit_win . "wincmd w"
    else
      " split current buffer, with phpunit_buffer
      execute "rightbelow vertical sb ".g:phpunit_buffer
    endif
    " well, phpunit_buffer is opened, clear content
    setlocal modifiable
    silent %d
  else
    " there is no phpunit_buffer create new one
    rightbelow 50vnew
    let g:phpunit_buffer=bufnr('%')
  endif

  file PHPUnit
  " exec 'file Diff-' . file
  setlocal nobuflisted cursorline nonumber nowrap buftype=nofile filetype=phpunit modifiable bufhidden=hide
  setlocal noswapfile
  silent put=a:content
  "efm=%E%\\d%\\+)\ %m,%CFailed%m,%Z%f:%l,%-G
  " FIXME: It is better use match(), or :syntax

  call matchadd("PHPUnitFail","^FAILURES.*$")
  call matchadd("PHPUnitOK","^OK .*$")

  call matchadd("PHPUnitFail","^not ok .*$")
  call matchadd("PHPUnitOK","^ok .*$")

  call matchadd("PHPUnitAssertFail","^Failed asserting.*$")
  setlocal nomodifiable

  wincmd p
endfun




fun! g:PHPUnit.RunAll()
  let cmd = g:PHPUnit.buildBaseCommand()
  let cmd = cmd + [expand(g:phpunit_testroot)]

  silent call g:PHPUnit.Run(cmd, "RunAll")
endfun

fun! g:PHPUnit.RunCurrentFile()
  let cmd = g:PHPUnit.buildBaseCommand()
  let cmd = cmd +  [expand("%:p")]
  silent call g:PHPUnit.Run(cmd, bufname("%"))
endfun
fun! g:PHPUnit.RunTestCase(filter)
  let cmd = g:PHPUnit.buildBaseCommand()
  let cmd = cmd + ["--filter", a:filter , bufname("%")]
  silent call g:PHPUnit.Run(cmd, bufname("%") . ":" . a:filter)
endfun

fun! g:PHPUnit.SwitchFile()
  let file = expand('%')
  let cmd = ''
  let isTest = expand('%:t') =~ "Test\.php$"

  if isTest
    " replace phpunit_testroot with libroot
    let file = substitute(file, '^' . g:phpunit_testroot . '/', g:phpunit_srcroot . '/', '')

    " remove 'Test.' from filename
    let file = substitute(file,'Test\.php$','.php','')
    let cmd = 'to '
  else
    let file = expand('%:r')
    let file = substitute(file,'^'.g:phpunit_srcroot, g:phpunit_testroot, '')
    let file = file . 'Test.php'
    let cmd = 'bo '
  endif
  " exec 'tabe ' . f

  " is there window with complent file open?
  let win = bufwinnr(file)
  if win > 0
    execute win . "wincmd w"
  else
    execute cmd . "vsplit " . file
    let dir = expand('%:h')
    if ! isdirectory(dir)
      cal mkdir(dir,'p')
    endif
  endif
endf

command! -nargs=0 PHPUnitRunAll :call g:PHPUnit.RunAll()
command! -nargs=0 PHPUnitRunCurrentFile :call g:PHPUnit.RunCurrentFile()
command! -nargs=1 PHPUnitRunFilter :call g:PHPUnit.RunTestCase(<f-args>)
command! -nargs=0 PHPUnitSwitchFile :call g:PHPUnit.SwitchFile()

nnoremap <Leader>ta :PHPUnitRunAll<CR>
nnoremap <Leader>tf :PHPUnitRunCurrentFile<CR>
nnoremap <Leader>ts :PHPUnitSwitchFile<CR>
