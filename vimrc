""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __   _____ __  __ ___  ___                     " 
"  ------ \ \ / /_ _|  \/  | _ \/ __| ---------          "
" -------- \ V / | || |\/| |   / (__  --------------     "
"  -------- \_/ |___|_|  |_|_|_\\___| -----------------  " 
"                                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""" Other Files """"""""""""""""""""""""""""""""""""""
source ~/.vim/work.vim

"""""""""""""""" Nerdtree stuff  """"""""""""""""""""""""""""""""""

let mapleader = " "
map <Leader>n :NERDTreeToggle<CR>

let NERDTreeShowHidden=1


""""""""""""""""NORMAL MODE HACKS """"""""""""""""""""""""""""""""""

" enter adds blank line below cursor, does not enter insert mode
map <Enter> o<ESC>
" shift-enter adds blank line above cursor, does not enter insert
map <S-Enter> O<esc>

imap hh <ESC>

" deal with annoyance of accidental macros
" Q records macro now
nnoremap Q q
" just q does nothing
nnoremap q <Nop>

" shut up W
:command W w

" why suffer?
nnoremap ; :

" cnoremap :record @
" nnoremap @ <nop>

" copy path of file
command CopyPath let @*=expand("%")

" make vim shell in same env as bash
set shell=bash\ -l

" make delete act normal
set backspace=2

" use system clipboard
set clipboard=unnamed

" ! bundle exec rspec %
" ., to run spec from in spec file
nnoremap ,. :!bundle exec rspec %<CR>

" NERDTreeFind shortcut
nmap ,; :NERDTreeFind<CR>

nmap <c-p> :GFiles <CR>

set wildmenu wildmode=longest:full
set wildignorecase
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem          
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz                      
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/* 
set wildignore+=*/node_modules/*
set wildignore+=*.swp,*~,._*

set complete=.,w,b,u,t
set noswapfile


""""""""""""""""" PILBO PLUGGINS """"""""""""""""""""""""""""""""""""
" Vim Plug 
call plug#begin('~/.vim/pluggins') "

" go linting and stuff
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" live markdown previw!
" Plug 'skywind3000/asyncrun.vim'

" syntax highlighting for python
" Plug '~/.vim/pluggins/python.vim'

" Terraform syntax
Plug 'hashivim/vim-terraform'

" Linting
" Plug 'w0rp/ale'

Plug 'bling/vim-airline'
" Plug 'vim-airline/vim-airline-themes'

" toggle with space-n
Plug 'scrooloose/nerdtree'

" git - :Gstatus :Gdiff :Glog :Ggrep etc
Plug 'tpope/vim-fugitive'

" rails
" Plug 'tpope/vim-rails'

" surround (with {} as example surrounder)
" ysiw} - surround word {ysiw( for spaces)
" yss} - surround line
" cs({ - replace surroundings (old surround, new surround)
" ds{ - delete surroundings
" visual select then S{
" https://github.com/tpope/vim-surround
Plug 'tpope/vim-surround'

" abolition, substitution, coercion
" case insensetive search/replace - %Subvert/find/replace/g
" snake_case (crs), UPPER_CASE (cru), dash-case (cr-), dot.case (cr.) 
" MixedCase (crm), camelCase (crc), space case (cr<space>), and Title Case (crt) 
" https://github.com/tpope/vim-abolish
" :help abolish
Plug 'tpope/vim-abolish'

" percent takes you to matching end etc.
Plug 'tmhedberg/matchit'

" make chruby work with vim
Plug 'mikepjb/vim-chruby'

" fuzzy search in vim
" also needs `brew install fzf`
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
nnoremap <Leader>t :FZF<CR>

" draw ascii boxes
" space-d-i to start
" space-d-s to stop
" Plug 'vim-scripts/DrawIt'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""
" Remove trailing whitespace before save
" --------------------------------------------------
"
" Add filetypes to have vim auto-strip trailing whitespace, in some languages
" (like markdown) this is undesirable.

let stripEolFiletypes = [
\ "c",
\ "handlebars",
\ "html",
\ "html.handlebars",
\ "javascript",
\ "ruby",
\ "rust",
\ "yaml",
\]

execute "autocmd FileType " . join(stripEolFiletypes, ",") . " autocmd BufWritePre <buffer> :%s/\\s\\+$//e"

"""""""""""""""" COMMANDS """""""""""""""""""""""""""""""

" jump to last known position in a file after opening it
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

" Don't syntax highlight markdown because it's often wrong
autocmd! FileType mkd setlocal syn=off    

" *.md is markdown
autocmd! BufNewFile,BufRead *.md setlocal ft=
        
" Compute syntax highlighting from beginning of file. (By default, vim only
" looks 200 lines back, which can make it highlight code incorrectly in some
" long files.)
autocmd BufEnter * :syntax sync fromstart

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MULTIPURPOSE TAB KEY
" Indent if we're at the beginning of a line. Else, do completion.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col
        return "\<tab>"
    endif

    let char = getline('.')[col - 1]
    if char =~ '\k'
        " There's an identifier before the cursor, so complete the identifier.
        return "\<c-p>"
    else
        return "\<tab>"
    endif
endfunction
inoremap <expr> <tab> InsertTabWrapper()
inoremap <s-tab> <c-n>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RENAME CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
" map <leader>n :call RenameFile()<cr> (conflicts with nerdtree)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" InsertTime COMMAND
" Insert the current time
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! InsertTime :normal a<c-r>=strftime('%F %H:%M:%S.0 %z')<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RemoveFancyCharacters COMMAND
" Remove smart quotes, etc.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RemoveFancyCharacters()
    let typo = {}
    let typo["“"] = '"'
    let typo["”"] = '"'
    let typo["‘"] = "'"
    let typo["’"] = "'"
    let typo["–"] = '--'
    let typo["—"] = '---'
    let typo["…"] = '...'
    :exe ":%s/".join(keys(typo), '\|').'/\=typo[submatch(0)]/ge'
endfunction
command! RemoveFancyCharacters :call RemoveFancyCharacters()

""""""""""""""""" SYNTAX STUFF """"""""""""""""""""""""""""""""

" line length and indent (for python) (from hitchhiker's, adjusted to google style guide)
" google style: 80 lines, 4 space indent, 
syntax on           " turn on syntax highlighting
" set textwidth=80    " lines longer than 80 columns will be broken
set shiftwidth=2    " operation >> indents 2 columns; << unindents 2 columns
set tabstop=2       " a hard TAB displays as 2 columns
set expandtab       " insert spaces when hitting TABs
set softtabstop=2   " insert/delete 2 spaces when hitting a TAB/BACKSPACE
set shiftround      " round indent to multiple of 'shiftwidth'
set autoindent      " align the new line indent with the previous line
" set number relativenumber        " turn on line numbering 
set number
set encoding=utf-8  " does what it says on the tin


""""""""""""""""" COLORS """""""""""""""""""""""""""""""""""""""""""""
set background=light
set t_Co=256

" airline theme
" let g:airline_theme='badwolf'


"""""""""""""""""" THE END """""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
