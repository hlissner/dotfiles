" Appearance {{{
    NeoBundle 'reedes/vim-colors-pencil'

    " Pretty indent indicators
    " NeoBundle 'Yggdroot/indentLine'
      "  let g:indentLine_color_gui = '#4a514f'
" }}}

" File search {{{
    " More powerful file searching
    if executable('ag')
        NeoBundle 'rking/ag.vim'
    elseif executable('ack')
        NeoBundle 'mileszs/ack.vim'
    endif

    " Project-wide search and replace
    " NeoBundle 'skwp/greplace.vim'

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

    " 'a Git wrapper so awesome, it should be illegal'
    " NeoBundle 'tpope/vim-fugitive'

    " Async compiler plugins
    " NeoBundle 'tpope/vim-dispatch'
" }

" Programming {{{
        " Syntax checkers for a multitude of languages
        " NeoBundle 'scrooloose/syntastic'
        "     let g:syntastic_auto_loc_list=0
        "     " let g:syntastic_quiet_messages={'level': 'warnings'}
        "     let g:syntastic_phpcs_disable=1
        "     let g:syntastic_echo_current_error=1
        "     let g:syntastic_enable_balloons = 0
        "
        "     let g:syntastic_error_symbol = '►'
        "     let g:syntastic_warning_symbol = '►'
        "
        "     let g:syntastic_loc_list_height = 5
        "     let g:syntastic_mode_map = {'mode': 'active', 'active_filetypes': [], 'passive_filetypes': ['html']}

    " Running code inline for testing purposes
    " NeoBundle 'notalex/vim-run-live'
" }}}

" Syntax {{{
    " HTML
    " NeoBundle 'othree/html5.vim'

    " CSS/SCSS/LESS
    NeoBundle 'cakebaker/scss-syntax.vim'

    " PHP
    NeoBundleLazy 'StanAngeloff/php.vim',       {'autoload': {'filetypes': ['php', 'blade']}}
    NeoBundleLazy '2072/PHP-Indenting-for-VIm', {'autoload': {'filetypes': ['php']}}
    " NeoBundleLazy 'stephpy/vim-phpdoc',         {'autoload': {'filetypes': ['php']}}

    " Python
    NeoBundleLazy 'indentpython.vim--nianyang', {'autoload': {'filetypes': ['python']}}
    NeoBundleLazy 'python_match.vim',           {'autoload': {'filetypes': ['python']}}

    " Javascript/Node
    NeoBundleLazy 'pangloss/vim-javascript',      {'autoload': {'filetypes': ['javascript']}}
    " NeoBundleLazy 'moll/vim-node',                {'autoload': {'filetypes': ['javascript']}}
    NeoBundleLazy 'marijnh/tern_for_vim',         {'autoload': {'filetypes': ['javascript']}, 'build': {'mac' : 'npm install'}}

    " C/C++
    "NeoBundle 'octol/vim-cpp-enhanced-highlight'

    " Other
    NeoBundle 'tpope/vim-markdown'
" }}}

" NeoBundleCheck
filetype indent plugin on

" vim:set ft=vim:
