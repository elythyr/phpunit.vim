" TODO: add genereation of testcase ?

command! -nargs=? -complete=tag_listfiles PHPUnitRunAll :call phpunit#run_dir(g:phpunit_testroot, <f-args>) | :call phpunit#windows#open(g:phpunit_testroot)
command! -nargs=? -complete=tag_listfiles PHPUnitRunCurrentFile :call phpunit#run_file(expand('%'), <f-args>) | :call phpunit#windows#open(expand('%'))
" TODO: use -complete=customlist,{func} => create a function to retrieve all the
" tests functions of a test file - see :h E467
" The first argument must be the test to filter
" The other ones are options to provide to phpunit
command! -nargs=+ -complete=tag_listfiles PHPUnitRunFilter :call phpunit#run_testcase(<f-args>) | :call phpunit#windows#open(expand('%'))
command! -nargs=0 PHPUnitSwitchFile :call phpunit#files#switch()

call phpunit#init#bootstrap()
call phpunit#init#mappings()
