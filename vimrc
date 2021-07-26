""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __   _____ __  __ ___  ___                     " 
"  ------ \ \ / /_ _|  \/  | _ \/ __| ---------          "
" -------- \ V / | || |\/| |   / (__  --------------     "
"  -------- \_/ |___|_|  |_|_|_\\___| -----------------  " 
"                                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"## Other Files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim automatically loads everything in ~/.vim/plugin/ mayb use that? 🤔
" I think I have overwritten that to be `~/.vim/pluggins/
source ~/.vim/work.vim
source ~/.vim/swapfile_backup_settings.vim
source ~/.vim/plugin_settings.vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## What is this
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <c-p> :GFiles <CR>

set wildmenu wildmode=longest:full
set wildignorecase
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem          
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz                      
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/* 
set wildignore+=*/node_modules/*
set wildignore+=*.swp,*~,._*

set complete=.,w,b,u,t

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## ACTIVE SKILLS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ! bundle exec rspec %
" .r to run spec from in spec file
nnoremap ,r :!bundle exec rspec %<CR>

" copy path of file
command CopyPath let @*=expand("%")

let mapleader = " "
map <Leader>n :NERDTreeToggle<CR>

" NERDTreeFind shortcut
" ,; opens Nerdtree to current file
"
nmap ,; :NERDTreeFind<CR>

let NERDTreeShowHidden=1

map <Leader>f :FZF<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"###  Insert the current time

command! InsertTime :normal a<c-r>=strftime('%F %H:%M:%S.0 %z')<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### Remove smart quotes, etc.

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"###  MULTIPURPOSE TAB KEY
" Indent if we're at the beginning of a line. Else, do completion.
"
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col
        return "\<tab>"
    endif

    let char = getline('.')[col - 1]
    if char =~ '\k'
        " There's an identifier before the cursor, so complete the identifier.
        return "\<c-n>"
    else
        return "\<tab>"
    endif
endfunction
inoremap <expr> <tab> InsertTabWrapper()
inoremap <s-tab> <c-n>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## PASSIVE SKILLS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" enter adds blank line below cursor, does not enter insert mode
map <Enter> o<ESC>
" shift-enter adds blank line above cursor, does not enter insert
map <S-Enter> O<esc>

" hh 
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

" make vim shell in same env as bash
set shell=bash\ -l

" make delete act normal
set backspace=2

" use system clipboard
set clipboard=unnamed

" make P paste the last explicitly copied thing
" don't think this is working
nnoremap P "0p

" stop u from downcasing shit willy nilly
xnoremap U <nop>
nnoremap gu <nop>
nnoremap gU <nop>

" use shift-tab to insert unexpanded tab (hopefully works)
inoremap <S-Tab> <C-V><Tab>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### Remove trailing whitespace before save
" --------------------------------------------------
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### Jump to last known position in a file after opening it
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### Markdown
" Don't syntax highlight markdown because it's often wrong
" autocmd! FileType mkd setlocal syn=off    

" *.md is markdown
autocmd! BufNewFile,BufRead *.md setlocal ft=
        
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### Compute syntax highlighting from beginning of file. 
" (By default, vim only looks 200 lines back, 
" which can make it highlight code incorrectly in some long files.)
autocmd BufEnter * :syntax sync fromstart

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"### SYNTAX STUFF

" line length and indent (for python) (from hitchhiker's, adjusted to google style guide)
syntax on           " turn on syntax highlighting
set shiftwidth=2    " operation >> indents 2 columns; << unindents 2 columns
set tabstop=2       " a hard TAB displays as 2 columns
set expandtab       " insert spaces when hitting TABs
set softtabstop=2   " insert/delete 2 spaces when hitting a TAB/BACKSPACE
set shiftround      " round indent to multiple of 'shiftwidth'
set autoindent      " align the new line indent with the previous line
set number
set encoding=utf-8  " does what it says on the tin


"### COLORS 
set background=light
set t_Co=256
"set highlight clear SpellBad
" set highlight SpellBad ctermfg=009 ctermbg=011 guifg=#ff0000 guibg=#ffff00

"""""""""""""""""" THE END """""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
