"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 gvimrc                                  "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Say neigh to UI cruft!
set go-=T
set go-=l
set go-=L
set go-=r
set go-=R
" No GUI tabs!
set go-=e
" Don't show dialogues, use text prompts
set go+=c

" Sets File>Open to start in current file's path
set browsedir=buffer

" Share a clipboard with OS and vim terminal sessions
if has('unnamedplus')
    set clipboard=unnamedplus
else
    set clipboard=unnamed
endif

" For macvim
if has('gui_macvim')

    " j doesn't seem to work from terminal
    set formatoptions+=j

    " set guifont=Ubuntu\ Mono:h14
    " set guifont=Monaco:h12
    set guifont=Inconsolata:h16

    " Replace some CMD shortcuts
    macmenu &File.Open\.\.\. key=<nop>
    macmenu &Tools.Make key=<nop>

    " Switching buffers
    nmap <D-]> ]b
    nmap <D-[> [b

    " Textmate-like CMD+Enter
    inoremap <D-CR> <C-O>o
    inoremap <S-D-CR> <C-O>O

    " Fast scrolling
    map <D-j> 5j
    map <D-k> 5k
    imap <D-j> <C-o>5j
    imap <D-k> <C-o>5k

    " Commenting using CMD+/"
    nmap <D-/> gcc
    vmap <D-/> gc

    " Tab navigation
    nmap <D-1> 1gt
    nmap <D-2> 2gt
    nmap <D-3> 3gt
    nmap <D-4> 4gt
    nmap <D-5> 5gt
    nmap <D-6> 6gt
    nmap <D-7> 7gt
    nmap <D-8> 8gt
    nmap <D-9> 9gt

    map <D-r> <leader>r
    " Replace :make
    map <D-b> :Dispatch<CR>

    " Shortcuts to outside apps {{{
        " Open in finder
        nnoremap <localleader>f :silent !open "%:p:h"<CR>
        nnoremap <localleader>F :silent !open .<CR>

        " Open in terminal
        nnoremap <localleader>t :silent !open -a iTerm "%:p:h"<CR>
        nnoremap <localleader>T :silent !open -a iTerm .<CR>

        " Send to transmit
        nnoremap <localleader>u :silent !open -a Transmit "%"<CR>

        " Send to launchbar (project and file, respectively)
        nnoremap <silent> <localleader>[ :call LaunchBarSelect(expand("%:p:h"))<CR>
        nnoremap <silent> <localleader>] :call LaunchBarSelect(expand("%:p"))<CR>

        func LaunchBarSelect(arg)
            silent! let l:arg = substitute(a:arg, '[^A-Za-z0-9_.~-/]','\="%".printf("%02X",char2nr(submatch(0)))','g')
            if l:arg ==# ""
                let l:arg = expand("%:p:h")
            endif
            exec 'silent !open "x-launchbar:select?file=' . l:arg . '"'
        endfunc
    " }}}

else

    " For unix only
    inoremap <C-v> <C-r>*
    cnoremap <C-v> <C-r>*

    set go-=m
    set novisualbell

    " For gvim
    set guifont=Monospace\ 10
    
    " Commenting using Ctrl+/
    map <C-/> gcc

    " Textmate-like CMD+Enter
    inoremap <C-CR> <C-O>o
    inoremap <S-C-CR> <C-O>O

endif
