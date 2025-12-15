""" PILBO PLUGGINS """

" Reload the file or restart Vim, then you can,
" :PlugInstall to install the plugins
" :PlugUpdate to install or update the plugins
" :PlugDiff to review the changes from the last update
" :PlugClean to remove plugins no longer in the list

" Vim Plug 
call plug#begin('~/.vim/pluggins') "

"" Essential

" toggle with space-n
Plug 'scrooloose/nerdtree'

Plug 'bling/vim-airline'

" Smooth scrolling
" https://awesomeopensource.com/project/psliwka/vim-smoothie
Plug 'psliwka/vim-smoothie'

" surround (with {} as example surrounder)
" ysiw} - surround word {ysiw( for spaces)
" yss} - surround line
" cs({ - replace surroundings (old surround, new surround)
" ds{ - delete surroundings
" visual select then S{
" https://github.com/tpope/vim-surround
Plug 'tpope/vim-surround'

" gcc - comment/uncomment a line
" gc - comment/uncomment selection
" :g/term_to_comment/Commentary
Plug 'tpope/vim-commentary'

" git - :Gstatus :Gdiff :Glog :Ggrep etc
Plug 'tpope/vim-fugitive'

" abolition, substitution, coercion
" case insensetive search/replace - %Subvert/find/replace/g
" snake_case (crs), UPPER_CASE (cru), dash-case (cr-), dot.case (cr.) 
" MixedCase (crm), camelCase (crc), space case (cr<space>), and Title Case (crt) 
" https://github.com/tpope/vim-abolish
" :help abolish
Plug 'tpope/vim-abolish'

" fuzzy search in vim
" https://github.com/junegunn/fzf/blob/master/README-VIM.md"
" also needs `brew install fzf` and 'brew install universal-ctags'
" https://github.com/universal-ctags/ctags/tree/master
" 'ctrl-t': 'tab split',
" 'ctrl-x': 'split',
" 'ctrl-v': 'vsplit'
" Plug '/usr/local/opt/fzf'  " for intel mac
Plug '/opt/homebrew/opt/fzf' " for apple silicone
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
let $FZF_DEFAULT_COMMAND="rg --files --hidden -g '!\.git/'"

"" EXTRAS

" ----- Easy notes search ----- 
" c-x: Use search string as filename and open in vertical split.
" c-v: Open in vertical split
" c-s: Open in horizontal split
" c-t: Open in new tab
" c-y: Yank the selected filenames
" <Enter>: Open highlighted search result in current buffer
" https://github.com/alok/notational-fzf-vim
Plug 'alok/notational-fzf-vim'
let g:nv_use_short_pathnames = 0 " needed so that nv_search_paths can find everything for some reason
let g:nv_search_paths = ['~/projects/notes/', '~/.dotfiles/vimrc', '~/.dotfiles/vim/plugin_settings.vim']
nmap <silent> <c-s> :NV<CR>

" ----- Smooth nav attempt -----
"    <ctrl-p> => Left
"    <ctrl-j> => Down
"    <ctrl-k> => Up
"    <ctrl-n> => Right
"    <ctrl-\> => Previous split
" good nav for tmux and vim
" https://github.com/christoomey/vim-tmux-navigator
Plug 'christoomey/vim-tmux-navigator'

" Write all buffers before navigating from Vim to tmux pane
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_no_mappings = 1
noremap <silent> <c-p> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
noremap <silent> <c-n> :<C-U>TmuxNavigateRight<cr>
noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>

" percent takes you to matching end etc.
Plug 'tmhedberg/matchit'

" Terraform syntax
Plug 'hashivim/vim-terraform'

" colorize csvs
" https://github.com/mechatroner/rainbow_csv/
Plug 'mechatroner/rainbow_csv'

"shows the context of the currently visible buffer contents
"https://github.com/wellle/context.vim
Plug 'wellle/context.vim'


"############## New plugins, value un-assesed

" Github copilot plugin
" https://github.com/github/copilot.vim
" Plug 'github/copilot.vim'

" Vim claude ai plugin
" https://github.com/pasky/claude.vim
Plug 'pasky/claude.vim'

call plug#end()
