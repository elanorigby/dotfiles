""" PILBO PLUGGINS """

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
" also needs `brew install fzf`
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

"" Extras

" c-x: Use search string as filename and open in vertical split.
" c-v: Open in vertical split
" c-s: Open in horizontal split
" c-t: Open in new tab
" c-y: Yank the selected filenames
" <Enter>: Open highlighted search result in current buffer
" https://github.com/alok/notational-fzf-vim
Plug 'alok/notational-fzf-vim'
" let g:nv_search_paths = ['~/notes', '~/.dotfiles/vimrc', '~/.dotfiles/vim/plugin_settings.vim', '~/.dotfiles/bashrc', '~/.dotfiles/tmux.conf']
let g:nv_search_paths = ['~/notes']
nmap <silent> <c-s> :NV<CR>

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
nnoremap <silent> <c-n> :TmuxNavigateRight<cr>.
nnoremap <silent> <c-p> :TmuxNavigateLeft<cr>.

" percent takes you to matching end etc.
Plug 'tmhedberg/matchit'

" make chruby work with vim
Plug 'mikepjb/vim-chruby'

" Terraform syntax
Plug 'hashivim/vim-terraform'

"# MARKDOWN
"
" Nicer markdown files / writing experience
" https://github.com/reedes/vim-pencil
set nocompatible
filetype plugin on       " may already be in your .vimrc

augroup pencil
  autocmd!
  autocmd FileType markdown,mkd,md call pencil#init({'wrap': 'soft'})
augroup END

let g:pencil#conceallevel = 3
Plug 'reedes/vim-pencil'

"https://github.com/reedes/vim-colors-pencil
Plug 'reedes/vim-colors-pencil'

call plug#end()
