set nocompatible

" Initialize NeoBundle
set rtp+=~/.vim/bundle/neobundle.vim/
call neobundle#rc(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/neobundle.vim'

" Preferences {{{
    syntax on

    " Editor looks {{{
        " Disable matchit, I find it distracting
        let loaded_matchparen = 1

        if &t_Co == 8 && $TERM !~# '^linux'
            set t_Co=16
        else
            set t_Co=256
        endif
        set background=dark
        colorscheme Tomorrow-Night-Eighties

        set number                   " Line numbers
        set showcmd                  " Show command issued
        set fillchars=vert:¦
        set list
        set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
        set textwidth=88

        set synmaxcol=1500
    " }}}

    " Behavior {{{
        set autoread                 " Auto-update a file that's been edited externally
        set nospell                  " No spell check, please
        set visualbell               " No sounds!
        set backspace=indent,eol,start
        set lazyredraw               " Don't update screen while running macros
        set hidden                   " Hide abandoned buffers
        set shortmess+=filmnrxoOtTs
        set nrformats-=octal
        set fileformats+=mac

        set mouse=a
        if exists('$TMUX')  " Support resizing in tmux
            set ttymouse=xterm2
        endif
    " }}}

    " StatusBar {{{
        if has('statusline')
            set laststatus=2
            set ruler                                      " Show line/col no in statusline
            set statusline=%t                              " tail of the filename
            set statusline+=%w%h%m%r                       " Options
            if exists('g:loaded_syntastic_plugin')
                set statusline+=\ %{SyntasticStatuslineFlag()}
            endif
            set statusline+=%=                             " left/right separator
            set statusline+=%y                             " filetype
            if exists('g:loaded_fugitive')
                set statusline+=\ %{fugitive#statusline()}     " Git Hotness
            endif
            set statusline+=\ •\ 
            set statusline+=%c                             " cursor column
            set statusline+=\ %l/%L                        " cursor line/total lines
            set statusline+=\ \:%P                         " percent through file
        endif
    " }}}

    " Movement & search {{{
        set nostartofline
        set sidescrolloff=5

        set incsearch            " find as you type
        set hlsearch             " Highlight search terms
        set ignorecase           " case insensitive search
        set smartcase            " case sensitive when uc present
        set gdefault             " global flag for substitute by default

        if executable('ag')
            let g:ackprg = 'ag --nogroup --nocolor --column'
            set grepprg=ag\ --nogroup\ --nocolor
        elseif executable('ack-grep')
            let g:ackprg = "ack-grep -H --nocolor --nogroup --column"
        endif
    " }}}

    " Text formatting {{{
        set autoindent
        set shiftround
        set expandtab
        set shiftwidth=4
        set tabstop=4
        set softtabstop=4
        " Wrapping
        set nowrap
        " Backspace and cursor keys to wrap
        set whichwrap=b,s,h,l,<,>,[,]
        " see :h fo-table
        set formatoptions=qrn1lr
    " }}}

    " Folding {{{
        set foldlevel=1
        " Cleaner, readable fold headers
        set foldtext=MyFoldText()
        fu! MyFoldText()
            let line = getline(v:foldstart)
            " Lines that have been folded
            let nl = v:foldend - v:foldstart + 1

            let indent = repeat(' ', indent(v:foldstart))
            let endcol = &colorcolumn ? &colorcolumn : &textwidth
            let startcol = &columns < endcol ? &columns-4 : endcol

            return indent . substitute(line,"^ *","",1)
        endf
    " }}}

    " Swap files, history & persistence {{{
        " No backup (that's what git is for!) and swapfiles are annoying
        set nobackup
        set nowritebackup
        set noswapfile
        if has('persistent_undo')
            set undodir=~/.vim/tmp/undo
            set undofile
            set undolevels=500
            set undoreload=500
        endif
        set history=5000

        " Preserve buffer state (cursor location, folds, etc.)
        set viewdir=~/.vim/tmp/views
        set viewoptions=cursor,folds,unix,slash
        augroup persistence
            au!
            au BufWinLeave * if expand("%") != "" | silent! mkview | endif
            au BufWinEnter * if expand("%") != "" | silent! loadview | endif
        augroup END
    " }}}

    " Omnicomplete + wild settings {{{
        set tags=./.tags;/,~/.tags,~/tags

        set complete-=i
        set completeopt=menu
        set wildmenu                    " Show menu instead of auto-complete
        set wildmode=list:longest,full  " command <Tab> completion: list
                                        " matches -> longest common -> then
                                        " all.
        set wildignore+=*.swp,*.log,.sass-cache,.codekit-cache,config.codekit
        set wildignore+=*.class,*.o,*.pyc,*.obj,*DS_Store*
    " }}}

    " Automatically close the popup menu / preview window
    au InsertLeave * if pumvisible() == 0|silent! pclose|endif

    " Set *.scss to ft=scss instead of css.scss
    au BufRead,BufNewFile *.scss set filetype=scss
" }}}

"""""""""""""""""""""""""""""""""""""""""
"  Packages/Bundles and their settings  "
"""""""""""""""""""""""""""""""""""""""""
" {{{
    " File search {{{
        " More powerful file searching
        if executable('ag')
            NeoBundle 'rking/ag.vim'
        elseif executable('ack')
            NeoBundle 'mileszs/ack.vim'
        endif

        " Project-wide search and replace
        " NeoBundle 'skwp/greplace.vim'
        
        NeoBundle 'christoomey/vim-tmux-navigator'

        " Netrw improvements
        NeoBundle 'scrooloose/nerdtree'
            let NERDTreeMinimalUI = 1
            let NERDTreeChDirMode = 2
            " let NERDTreeBookmarksFile = "$HOME/.vim/tmp/NERDtreeBookmarks"
            let NERDTreeIgnore = ['\~$', '\.swo$', '\.swp$', '\.git$', '\.hg', '\.svn', '\.bzr', '\.settings', '\.project', '\.DS_Store']
            let NERDTreeShowHidden = 1

        " Command-T, Peepopen or Goto-anything, but for vim, written in VimL
        NeoBundle 'kien/ctrlp.vim'
        " Ctrlp extension for jumping to functions
        NeoBundle 'tacahiroy/ctrlp-funky'
        " Ctrlp extension for listing git modified files
        NeoBundle 'jasoncodes/ctrlp-modified.vim'
            let g:ctrlp_extensions = ['tag', 'buffertag', 'funky']
            " let g:ctrlp_max_height = 10
            let g:ctrlp_cache_dir = "~/.vim/tmp/ctrlp"
            let g:ctrlp_custom_ignore = {
                \ 'dir':  '\.(git|hg|svn|settings)$|tmp$',
                \ 'file': '\.(exe|so|dll|sass-cache|classpaths|project|cache|jpg|png|gif|swf)$'
            \ }
            let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
            let g:ctrlp_match_window = 'bottom,order:btt,min:10,max:10,results:10'
    " }}}

    " Editing {{{
        " Extended visual mode commands, substitutes and searches
        NeoBundle 'vis'

        " Auto-closes delimiters like (),{},[],etc.
        NeoBundle 'Raimondi/delimitMate'
            let g:delimitMate_expand_cr = 1
            let g:delimitMate_expand_space = 1

        " HTML & CSS emmet goodness; Zen coding's successor
        NeoBundle 'mattn/emmet-vim'

        " Clean way to close buffers without altering window layout
        " NeoBundle 'mattdbridges/bufkill.vim'
        NeoBundle 'moll/vim-bbye'

        " For aligning text
        NeoBundle 'godlygeek/tabular'

        " Comment out code with native comment syntax
        NeoBundle 'tomtom/tcomment_vim'
            let g:tcomment_types = {'blade': '{-- %s --}', 'twig': '{# %s #}'}

        " Offers some plugins better compatibility with repeat ('.') 
        NeoBundle 'tpope/vim-repeat'

        " Easy changing and insertion of surrounding delimiters (e.g. quotes,
        " parenthesis, etc.)
        NeoBundle 'tpope/vim-surround'

        " Snippets system
        if has("python")
            NeoBundle 'SirVer/ultisnips'

            " My snippets
            NeoBundle 'hlissner/vim-ultisnips-snippets'
        endif

        " One-key switching between true/false, yes/no, etc
        NeoBundle 'AndrewRadev/switch.vim'
    " }}}

    " Remote resources {{{
        " Visual git diffs in the gutter
        NeoBundle 'airblade/vim-gitgutter'
            let g:gitgutter_realtime = 0
            let g:gitgutter_eager = 0
    " }}}

    " Programming {{{
        " Running code inline for testing purposes
        NeoBundle 'notalex/vim-run-live'
    " }}}

    " Syntax {{{
        " CSS/SCSS/LESS
        NeoBundle 'cakebaker/scss-syntax.vim'

        " PHP
        NeoBundleLazy 'StanAngeloff/php.vim',       {'autoload': {'filetypes': ['php', 'blade']}}
        NeoBundleLazy '2072/PHP-Indenting-for-VIm', {'autoload': {'filetypes': ['php']}}
        " NeoBundleLazy 'stephpy/vim-phpdoc',         {'autoload': {'filetypes': ['php']}}

        " Python
        NeoBundleLazy 'klen/python-mode',           {'autoload': {'filetypes': ['python']}}

        " Javascript/Node
        NeoBundleLazy 'pangloss/vim-javascript',      {'autoload': {'filetypes': ['javascript']}}

        " Other
        NeoBundle 'tpope/vim-markdown'
    " }}}

    " NeoBundleCheck
    filetype indent plugin on
" }}}

"""""""""""""""""
"  Keymappings  "
"""""""""""""""""
" {{{
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
        nnoremap <M-j> 5j
        vnoremap <M-j> 5j
        nnoremap <M-k> 5k
        vnoremap <M-k> 5k

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
        nnoremap zz :Bdelete<CR>

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
        nmap <leader>= :Tabularize /

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

        " vim-switch
        nnoremap ! :Switch<CR>
    " }}}
" }}}

" vim:set fdl=0 fdm=marker:
