
" Shortcut to vimrc and gvimrc
nnoremap <localleader>v :CtrlP ~/.vim<CR>

" Comma get some... sorry.
let mapleader = ','
let maplocalleader = '\'
noremap ; :

" Trigger to preserve indentation on pastes
set pastetoggle=<F12>
" Easier than escape. Pinnacle of laziness.
imap jk <ESC>
" Turn off search highlighting
noremap <silent> <leader>? :nohlsearch<CR>

" Navigation {{{
    " Normalize all the navigation keys to move by row/col despite any wrapped text
    noremap j gj
    noremap k gk
    " % matchit shortcut, but only in normal mode!
    nmap <Tab> %
    " Easier fold toggle
    nnoremap <Space> 5j 
    vnoremap <Space> 5j 
    nnoremap <Backspace> 5k
    vnoremap <Backspace> 5k

    " f: Find. Also support repeating with .
    nnoremap <Plug>OriginalSemicolon ;
    nnoremap <silent> f :<C-u>call repeat#set("\<lt>Plug>OriginalSemicolon")<CR>f
    nnoremap <silent> t :<C-u>call repeat#set("\<lt>Plug>OriginalSemicolon")<CR>t
    nnoremap <silent> F :<C-u>call repeat#set("\<lt>Plug>OriginalSemicolon")<CR>F
    nnoremap <silent> T :<C-u>call repeat#set("\<lt>Plug>OriginalSemicolon")<CR>T
" }}}

" Editing {{{
    nnoremap <C-b> <C-^>
    " Insert-mode navigation
    " Go to end of line
    inoremap <C-e> <Esc>A
    " Go to start of line
    inoremap <C-a> <Esc>I

    " Make Y act consistant with C and D
    nnoremap Y y$

    " Don't leave visual mode after indenting
    vnoremap < <gv
    vnoremap > >gv

    " Textmate-like CMD+Enter (O in insert mode)
    inoremap <S-CR> <C-O>o
    inoremap <C-S-CR> <C-O>O

    " Enabling repeat in visual mode
    vmap . :normal .<CR>
" }}}

" Buffers {{{
    " Change CWD to current file's directory
    nnoremap <leader>cd :cd %:p:h<cr>:pwd<cr>    

    " Next/prev buffer
    nnoremap ]b :<C-u>bnext<CR>
    nnoremap [b :<C-u>bprevious<CR>
" }}}

" Command {{{
    " Annoying command mistakes <https://github.com/spf13/spf13-vim>
    com! -bang -nargs=* -complete=file E e<bang> <args>
    com! -bang -nargs=* -complete=file W w<bang> <args>
    com! -bang -nargs=* -complete=file Wq wq<bang> <args>
    com! -bang -nargs=* -complete=file WQ wq<bang> <args>
    com! -bang Wa wa<bang>
    com! -bang WA wa<bang>
    com! -bang Q q<bang>
    com! -bang QA qa<bang>
    com! -bang Qa qa<bang>
    " Forget to sudo?
    com! WW w !sudo tree % >/dev/null

    " Shortcuts
    cnoremap ;/ <C-R>=expand('%:p:h').'/'<CR>
    cnoremap ;; <C-R>=expand("%:t")<CR>
    cnoremap ;. <C-R>=expand("%:p:r")<CR>
    
    " Mimic shortcuts in the terminal
    cnoremap <C-a> <Home>
    cnoremap <C-e> <End>
" }}}

" External Tools {{{
    " Send cwd to tmux
    nnoremap <localleader>x :Tmux cd <C-r>=expand("%:p:h")<CR><CR>
    nnoremap <localleader>X :Tmux cd <C-r>=expand("%:p:r")<CR><CR>
" }}}

" Plugins {{{
    " bufkill
    nnoremap zx :Bdelete<CR>

    " CtrlP
    let g:ctrlp_map = ''
    " Only open CtrlP if the cwd ISN'T $HOME
    nnoremap <silent><expr> <leader>/ getcwd() != $HOME ? ":<C-u>CtrlPCurWD<CR>" : ":<C-u>echoe 'Cannot open CtrlP in HOME'<CR>"
    nnoremap <silent> <leader>. :CtrlPCurFile<CR>
    nnoremap <silent> <leader>, :CtrlPBuffer<CR>
    nnoremap <silent> <leader>; :CtrlPFunky<CR>
    nnoremap <silent> <leader>m :CtrlPMRU<CR>
    nnoremap <silent> <leader>M :CtrlPModified<CR>
    nnoremap <silent> <leader>t :CtrlPBufTag<CR>
    nnoremap <silent> <leader>T :CtrlPBufTagAll<CR>

    " NERDTree
    map <localleader>\ :NERDTreeCWD<CR>
    map <localleader>. :NERDTreeFind<CR>

    " Tabularize
    nmap <leader>a= :Tabularize /=<CR>
    vmap <leader>a= :Tabularize /=<CR>
    nmap <leader>a> :Tabularize /=><CR>
    vmap <leader>a> :Tabularize /=><CR>
    nmap <leader>a: :Tabularize /:<CR>
    vmap <leader>a: :Tabularize /:<CR>
    nmap <leader>a:: :Tabularize /:\zs<CR>
    vmap <leader>a:: :Tabularize /:\zs<CR>
    nmap <leader>a, :Tabularize /,<CR>
    vmap <leader>a, :Tabularize /,<CR>
    nmap <leader>a<Bar> :Tabularize /<Bar><CR>
    vmap <leader>a<Bar> :Tabularize /<Bar><CR>

    " UltiSnips
    let g:UltiSnipsExpandTrigger = "<Tab>"
    let g:UltiSnipsJumpForwardTrigger = "<Tab>"
    let g:UltiSnipsJumpBackwardTrigger = "<S-Tab>"
    " Ignore the default snippets so I (and others) can define their own
    let g:UltiSnipsSnippetDirectories = ["snips"]
    
    " Emmet
    imap <expr> <C-CR> emmet#expandAbbrIntelligent("\<tab>")

    " YCM
    map g] :YcmCompleter GoToDefinitionElseDeclaration<CR>
    let g:ycm_key_list_select_completion = ['<C-j>', '<Down>']
    let g:ycm_key_list_previous_completion = ['<C-k>', '<Up>']

    " vim-surround
    " I turned the keymappings around to restore the 'feedback'
    " I get from operator mode after common vim commands, like d
    " and c.
    let g:surround_no_mappings = 1
    nmap sd  <Plug>Dsurround
    nmap sc  <Plug>Csurround
    nmap s   <Plug>Ysurround
    nmap S   <Plug>YSurround
    nmap ss  <Plug>Yssurround
    nmap Ss  <Plug>YSsurround
    nmap SS  <Plug>YSsurround
    xmap S   <Plug>VSurround
    xmap Sg  <Plug>VgSurround

    " vim-switch
    nnoremap <CR> :Switch<CR>
" }}}

" vim:set ft=vim:
