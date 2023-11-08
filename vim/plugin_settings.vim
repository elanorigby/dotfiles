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
" https://github.com/junegunn/fzf/blob/master/README-VIM.md"
" also needs `brew install fzf` and 'brew install universal-ctags'
" https://github.com/universal-ctags/ctags/tree/master
" 'ctrl-t': 'tab split',
"'ctrl-x': 'split',
"'ctrl-v': 'vsplit'
" Plug '/usr/local/opt/fzf'  " for intel mac
Plug '/opt/homebrew/opt/fzf' " for apple silicone
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

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
noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
noremap <silent> <c-n> :<C-U>TmuxNavigateRight<cr>
noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>

" percent takes you to matching end etc.
Plug 'tmhedberg/matchit'

" Terraform syntax
Plug 'hashivim/vim-terraform'

" MARKDOWN

Plug 'tpope/vim-markdown'
let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'py=python', 'sql=sql']

" Nicer markdown files / writing experience
" ttps://github.com/reedes/vim-pencil
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

"# New plugins, value un-assesed
"
"shows the context of the currently visible buffer contents
"https://github.com/wellle/context.vim
Plug 'wellle/context.vim'

" DATABASES databases
" 
" UI for interacting with dbs
" https://github.com/kristijanhusak/vim-dadbod-ui
" open vim and run :DBUI
" press A from drawer to add a new db connection
"  example: postgres://pancakes@localhost:5432/pagila
" press d from drawer to remove selected connection
" highlight only the query to run vith visual mode (ctrl or shift v) and then
"  press <leader> S (uppercase) to run only that query
" <Leader>W - Permanently save query for later use
Plug 'kristijanhusak/vim-packager' " do I need this
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'

" colorize csvs
" https://github.com/mechatroner/rainbow_csv/
Plug 'mechatroner/rainbow_csv'



" Comment out a line based on file type
" to trigger :AutoInlineComment in both modes, press Ctrl + /
" to trigger :AutoBlockComment in both modes, press Ctrl + Shift + A
"Plug 'KarimElghamry/vim-auto-comment'


call plug#end()
