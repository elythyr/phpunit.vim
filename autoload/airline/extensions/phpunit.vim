if !exists('*phpunit#run_file') || !get(g:, 'airline#extensions#phpunit#enabled', 1)
  finish
endif

let s:spc                  = g:airline_symbols.space
let s:part_name_format     = 'phpunit-%s'
let s:function_name_format = 'airline#extensions#phpunit#get_formated_%s'

" Used as an enum
let s:counters = {
  \ 'tests':      'tests',
  \ 'assertions': 'assertions',
  \ 'errors':     'errors',
  \ 'failures':   'failures',
  \ 'warnings':   'warnings',
  \ 'skipped':    'skipped',
  \ 'incomplete': 'incomplete',
  \ 'risky':      'risky',
\ }

" Used as an enum
let s:states = {
  \ 'success': 'success',
  \ 'warning': 'warning',
  \ 'error':   'error',
\ }

let s:format = {
  \ 'tests':      'T: %d',
  \ 'assertions': 'A: %d',
  \ 'errors':     'E: %d',
  \ 'failures':   'F: %d',
  \ 'warnings':   'W: %d',
  \ 'skipped':    'S: %d',
  \ 'incomplete': 'I: %d',
  \ 'risky':      'R: %d',
\}

" Patch the palette of the current theme to add the state's colors for phpunit
function! airline#extensions#phpunit#patch(palette)
  let l:attr = a:palette.normal.airline_z[4]

  " Need 232 for ctermbg, with 0 the text is not readble when attr=bold
  let a:palette.phpunit = {
    \ s:states.success: ['#000000', '#b5bd68', 232, 2, l:attr],
    \ s:states.warning: ['#000000', '#f0c674', 232, 3, l:attr],
    \ s:states.error:   ['#000000', '#cc6666', 232, 1, l:attr]
  \ }
endfunction!

function! airline#extensions#phpunit#load_theme(palette)
  if exists('a:palette.phpunit') " If a theme already provides the colors
    return
  endif

  call airline#extensions#phpunit#patch(a:palette)
endfunction

function airline#extensions#phpunit#run()
  let l:current_file = expand('%')
  call phpunit#run_file(l:current_file)

  " If the current file tests are already opened, update the window
  if phpunit#windows#opened(l:current_file)
    call phpunit#windows#update()
  endif

  AirlineRefresh " To update the statusline
endfunction

function! airline#extensions#phpunit#init(ext)
  augroup AirlinePhpunit
    autocmd!
    autocmd BufWritePost *.php call airline#extensions#phpunit#run()
  augroup END

  " Declares all parts
  for l:counter in values(s:counters)
    call airline#parts#define_function(s:PartName(l:counter), s:FunctionName(l:counter))
  endfor

  " Function to call when the satusline is updated, will decide what to show
  call a:ext.add_statusline_func('airline#extensions#phpunit#apply')

  " Function to call to configure the colors for the plugin
  call a:ext.add_theme_func('airline#extensions#phpunit#load_theme')
endfunction

function! airline#extensions#phpunit#apply(...)
  " Do nothing if there is no tests results, otherwise the section colors will
  " change in favor of "palette.phpunit.success"
  if !s:CountOf(s:counters.tests)
    return
  endif

  call s:ChangeColors()

  let l:content = s:spc . g:airline_right_sep . s:spc .
    \airline#section#create_left(s:OrderedPartsNames())
  call airline#extensions#append_to_section('z', l:content)
endfunction

" Change the colors of the section according to the state of the tests results
function! s:ChangeColors()
  let l:palette = g:airline#themes#{g:airline_theme}#palette

  let l:palette.normal.airline_z = l:palette.phpunit[s:TestsResultsState()]

  " Refresh the colors of the section
  call airline#highlighter#highlight(['normal']) "Only override the colors in normal mode
endfunction

" Return the state of the tests results
function! s:TestsResultsState()
  if s:TestsWereSuccessful() &&
    \ empty(airline#extensions#phpunit#get_formated_incomplete()) &&
    \ empty(airline#extensions#phpunit#get_formated_skipped()) &&
    \ empty(airline#extensions#phpunit#get_formated_risky())
    return s:states.success
  elseif s:TestsWereSuccessful()
    return s:states.warning
  else
    return s:states.error
  endif
endfunction

" Checks if the tests were successful
function! s:TestsWereSuccessful()
  return empty(airline#extensions#phpunit#get_formated_errors()) &&
    \ empty(airline#extensions#phpunit#get_formated_failures()) &&
    \ empty(airline#extensions#phpunit#get_formated_warnings())
endfunction

function! s:FormatedPart(type)
  if !s:CountOf(a:type)
    return ''
  endif

  return printf(
    \ get(g:, printf('airline#extensions#phpunit#%s_format', a:type), s:format[a:type]),
    \ s:CountOf(a:type)
  \ )
endfunction

function! s:PartName(type)
  return printf(s:part_name_format, a:type)
endfunction

function! s:FunctionName(type)
  return printf(s:function_name_format, a:type)
endfunction

" values() does not guaranty the order of the resulted list
function! s:OrderedPartsNames()
  return [
    \ s:PartName(s:counters.tests),
    \ s:PartName(s:counters.assertions),
    \ s:PartName(s:counters.errors),
    \ s:PartName(s:counters.failures),
    \ s:PartName(s:counters.warnings),
    \ s:PartName(s:counters.skipped),
    \ s:PartName(s:counters.incomplete),
    \ s:PartName(s:counters.risky),
  \ ]
endfunction

function! airline#extensions#phpunit#get_formated_tests()
  return s:FormatedPart(s:counters.tests)
endfunction

function! airline#extensions#phpunit#get_formated_assertions()
  return s:FormatedPart(s:counters.assertions)
endfunction

function! airline#extensions#phpunit#get_formated_errors()
  return s:FormatedPart(s:counters.errors)
endfunction

function! airline#extensions#phpunit#get_formated_failures()
  return s:FormatedPart(s:counters.failures)
endfunction

function! airline#extensions#phpunit#get_formated_warnings()
  return s:FormatedPart(s:counters.warnings)
endfunction

function! airline#extensions#phpunit#get_formated_skipped()
  return s:FormatedPart(s:counters.skipped)
endfunction

function! airline#extensions#phpunit#get_formated_incomplete()
  return s:FormatedPart(s:counters.incomplete)
endfunction

function! airline#extensions#phpunit#get_formated_risky()
  return s:FormatedPart(s:counters.risky)
endfunction

function! s:CountOf(type)
  return get(get(w:, 'phpunit_results', {}), a:type, 0)
endfunction
