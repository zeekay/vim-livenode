if !exists("g:livenode_loaded")
    let g:livenode_loaded = 1
else
    finish
endif

let s:default_opts = {
    \ 'livenode_host': '"localhost"',
    \ 'livenode_port': 8010,
    \ 'livenode_auto_connect': 1,
    \ 'livenode_preview_window': 1,
    \ 'livenode_preview_location': '"botright 10"',
\ }

for kv in items(s:default_opts)
    let k = 'g:'.kv[0]
    let v = kv[1]
    if !exists(k)
        exe 'let '.k.'='.v
    endif
endfor

python <<EOF
import sys
import vim
# add vimbop to syspath
sys.path.append(vim.eval("expand('<sfile>:p:h')")  + '/lib/')

try:
    import vimbop
    import vimbop.js
    import vimbop.coffee
except ImportError:
    vim.command('let g:livenode_not_installed = 1')
EOF

if exists('g:livenode_not_installed')
    finish
endif

func! livenode#Init()
    command! -nargs=0 livenodeConnect      py vimbop.connect(host=vim.eval('g:livenode_host'), port=int(vim.eval('g:livenode_port')))
    command! -nargs=0 livenodeList         py vimbop.list_websocket_clients()
    command! -nargs=1 livenodeSwitch       py vimbop.set_active_client(<f-args>); vimbop.list_websocket_clients()
    command! -bang -nargs=* livenodeReload py vimbop.reload("<bang>", <f-args>)
    command! -nargs=0 livenodeBroadcast    py vimbop.toggle_broadcast()

    nnoremap <leader>bl :livenodeList<cr>
    nnoremap <leader>br :livenodeReload<cr>
    nnoremap <leader>bR :livenodeReload!<cr>
    nnoremap <leader>bs :livenodeSwitch<space>
    nnoremap <leader>bc :livenodeConnect<cr>
    livenodeConnect
endf

func! livenode#Enable()
    let g:livenode_enabled = 1
    call livenode#Init()
    exe 'set ft='.&ft
endf

func! livenode#EnableCompletion()
    if eval('g:livenode_enable_js') && eval('g:livenode_complete_js')
        au FileType javascript setlocal omnifunc=livenodeJsComplete
        if &filetype == "javascript"
            setlocal omnifunc=livenodeJsComplete
        endif
    endif

    if eval('g:livenode_enable_coffee') && eval('g:livenode_complete_coffee')
        au FileType coffee setlocal omnifunc=livenodeCoffeeComplete
        if &filetype == "coffee"
            setlocal omnifunc=livenodeCoffeeComplete
        endif
    endif

    if eval('g:livenode_enable_neocomplcache_patterns') && exists('g:neocomplcache_omni_patterns')
        " let g:neocomplcache_omni_patterns.coffee = '[^. *\t]\w*\|[^. *\t]\.\%(\h\w*\)\?|[^. *\t]\w*::\%(\w*\)\?'
        let g:neocomplcache_omni_patterns.coffee = '\S*\|\S*::\S*?'
        let g:neocomplcache_omni_patterns.javascript = '[^. *\t]\w*\|[^. *\t]\.\%(\h\w*\)\?'
    endif
endf

func! livenode#DisableCompletion()
    au FileType javascript,coffee setlocal omnifunc=javascriptcomplete#CompleteJS
    setlocal omnifunc=javascriptcomplete#CompleteJS
endf

if eval('g:livenode_enabled')
    call livenode#Init()
else
    command! -nargs=0 livenodeEnable call livenode#Enable()
    nnoremap <leader>be :livenodeEnable<cr>
endif
