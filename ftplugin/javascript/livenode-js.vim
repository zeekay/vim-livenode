" It is insufficient to use function! to define our operator function as it
" may already be referenced by operatorfunc and vim doesn't allow redefining
" the function in that case.
if !exists('*livenodeJsOperator')
    function! livenodeJsOperator(type, ...)
        if a:0
            " Invoked from Visual mode, use '< and '> marks.
            silent exe "silent normal! `<" . a:type . "`>y"
        elseif a:type ==# 'char'
            silent exe "normal! `[v`]y"
        elseif a:type ==# 'line'
            silent exe "normal! '[V']y"
        elseif a:type ==# 'block'
            silent exe "normal! `[\<C-V>`]y"
        else
            return
        endif
        py livenode.eval(vim.eval('@@'))
    endfunction
endif

command! -nargs=* -complete=customlist,s:livenodeJsCmdComplete livenodeJsEval py livenode.eval(<f-args>)

" Mappings
nnoremap <buffer> <leader>e  :set operatorfunc=livenodeJsOperator<cr>g@
vnoremap <buffer> <leader>e  :py vimbop.js.eval_range()<cr>
