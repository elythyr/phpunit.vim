" TODO: add genereation of testcase ?

if exists('g:loaded_phpunit')
  finish
endif
let g:loaded_phpunit = 1

command! -nargs=* -complete=tag_listfiles PHPUnitRunAll :call phpunit#run_dir(phpunit#files#tests_path(), <f-args>) | :call phpunit#windows#open(phpunit#files#tests_path())
command! -nargs=* -complete=tag_listfiles PHPUnitRunCurrentFile :call phpunit#run_file(expand('%'), <f-args>) | :call phpunit#windows#open(expand('%'))
" TODO: use -complete=customlist,{func} => create a function to retrieve all the
" tests functions of a test file - see :h E467
" The first argument must be the test to filter
" The other ones are options to provide to phpunit
command! -nargs=+ -complete=tag_listfiles PHPUnitRunFilter :call phpunit#run_testcase(<f-args>) | :call phpunit#windows#open(expand('%'))
command! -nargs=0 PHPUnitSwitchFile :call phpunit#files#switch()
command! -nargs=0 PHPUnitClose :call phpunit#windows#close()

call phpunit#init#bootstrap()
call phpunit#init#mappings()
