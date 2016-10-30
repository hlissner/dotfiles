set nocompatible

" Preferences {{{
    syntax on
    filetype indent plugin on

    set laststatus=2             " Show statusbar
    set nolist                   " Don't show whitespace chars (indentLine does it nicer)
    set nospell                  " No spell check, please
    set number                   " Line numbers
    set visualbell               " No sounds!
    set showmatch                " Show matching delimiters
    set browsedir=buffer         " Sets File>Open to start in current file's path
    set showmode                 " Show mode in cmdline
    set autoread                 " Auto-update a file that's been edited externally
    set backspace=indent,eol,start
    set mouse=a
    set lazyredraw               " Don't update screen while running macros
    set hidden                   " Hide abandoned buffers
    set nostartofline
    set scrolloff=5
    set shortmess+=filmnrxoOtTs

    set ruler                " Show line/col no in statusline
    set showcmd              " Show command issued

    set textwidth=88
    set fillchars=vert:¦

    set tags=./.tags;/,~/.tags,~/tags

    set completeopt=longest,menu,preview
    set wildmenu                    " Show menu instead of auto-complete
    set wildmode=list:longest,full  " command <Tab> completion: list
                                    " matches -> longest common -> then
                                    " all.
    set wildignore+=*.cache,cache/**,*~,*.swp,*.log,.sass-cache
    set wildignore+=*.class,*.o,*.pyc,*.obj,*DS_Store*

    " Shell {{{
        " 256bit terminals
        set t_Co=256
        set title
    " }}}
    " Search {{{
        set incsearch            " find as you type
        set hlsearch             " Highlight search terms
        set ignorecase           " case insensitive search
        set smartcase            " case sensitive when uc present
        set gdefault             " global flag for substitute by default
    " }}}
    " Formatting {{{
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
        set backspace=indent,eol,start      " normal backspace behavior
        " see :h fo-table
        set formatoptions=qrn1lr
    " }}}
    " Keymaps {{{
        let mapleader = ","
    " }}}
    " Navigation {{{
        " netrw
        let g:netrw_banner = 0
        let g:netrw_keepdir = 0
        let g:netrw_liststyle = 3
        let g:netrw_sort_options = 'i'
    " }}}
" }}}
