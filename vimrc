""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __   _____ __  __ ___  ___                     "
"  ------ \ \ / /_ _|  \/  | _ \/ __| ---------          "
" -------- \ V / | || |\/| |   / (__  --------------     "
"  -------- \_/ |___|_|  |_|_|_\\___| -----------------  "
"                                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"## Other Files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim automatically loads everything in ~/.vim/plugin/ mayb use that? ü§î
" I think I have overwritten that to be `~/.vim/pluggins/
source ~/.vim/work.vim
source ~/.vim/swapfile_backup_settings.vim
" :PlugInstall and :PlugUpdate from 
source ~/.vim/plugin_settings.vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## Wild stuff is command completion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set wildmenu wildmode=longest:full
set wildignorecase
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem          
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz                      
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/* 
set wildignore+=*/node_modules/*
set wildignore+=*.swp,*~,._*

set complete=.,w,b,u,t

" if search all lowercase, ignores case. otherwise, matches case
set smartcase

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## ACTIVE SKILLS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ! bundle exec rspec %
" ,r to run spec from in spec file
nnoremap ,r :!bundle exec rspec %<CR>

" copy absolute path of file
command Cp let @*=expand("%:p")
" copy relative path of file
command Cr let @*=expand("%")
" copy name of file
command Cn let @*=expand("%:t")

" leader is space
let mapleader = " "
map <Leader>n :NERDTreeToggle<CR>

" NERDTreeFind shortcut
" opens Nerdtree to current file (ergodox)
" kinesis
" nmap' :NERDTreeFind<CR>
" ergodox
nmap ,. :NERDTreeFind<CR>

let NERDTreeShowHidden=1

map <Leader>f :FZF<CR>
map <Leader>t :Tags<CR>


" insert the current date
command! Date :normal a<C-R>=strftime('%Y-%m-%d')<CR>
" Insert the current time
command! Time :normal a<c-r>=strftime('%F %H:%M:%S.0 %z')<cr>

" Remove smart quotes, etc.
function! RemoveFancyCharacters()
    let typo = {}
    let typo["‚Äú"] = '"'
    let typo["‚Äù"] = '"'
    let typo["‚Äò"] = "'"
    let typo["‚Äô"] = "'"
    let typo["‚Äì"] = '--'
    let typo["‚Äî"] = '---'
    let typo["‚Ä¶"] = '...'
    :exe ":%s/".join(keys(typo), '\|').'/\=typo[submatch(0)]/ge'
endfunction
command! RemoveFancyCharacters :call RemoveFancyCharacters()

"" MULTIPURPOSE TAB KEY
"" Indent if we're at the beginning of a line. Else, do completion.
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

" Better split navigation
" https://thoughtbot.com/blog/vim-splits-move-faster-and-more-naturally#easier-split-navigations
" ctrl-direction instead of ctrl-w ctrl-direction
" haven't got this to work
" nnoremap <C-J> <C-W><C-J>
" nnoremap <C-K> <C-W><C-K>
" nnoremap <C-L> <C-W><C-L>
" nnoremap <C-H> <C-W><C-H>

" Open new splits to right and bottom
set splitbelow
set splitright

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"## PASSIVE SKILLS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
scriptencoding utf-8
set encoding=utf-8

" show trailing whitespace
set list listchars=tab:\ \ ,trail:∞

" show indent characters (yaml stuff)
set list listchars=tab:ª-,trail:∑,extends:ª,precedes:´

" enter adds blank line below cursor, does not enter insert mode
map <Enter> o<ESC>
" shift-enter adds blank line above cursor, does not enter insert
map <S-Enter> O<esc>

" hh
imap hh <ESC>

" deal with annoyance of accidental macros
" leader-q records and quits macro now
nnoremap <leader>q q
" just q does nothing
nnoremap q <Nop>
" I don't need Ex mode
nnoremap Q <Nop>

" shut up W
:command W w

" why suffer?
nnoremap ; :

" make vim shell in same env as bash
set shell=bash\ -l

" make delete act normal
set backspace=2

" make delete work as delete in normal mode
nnoremap <BS> X

" use system clipboard
set clipboard=unnamed

" make P paste the last explicitly copied thing
" don't think this is working
" nnoremap P "0p

" stop u from downcasing shit willy nilly
" maybe I am strong enough to avoid this now?
xnoremap U <nop>
nnoremap gu <nop>
nnoremap gU <nop>

" use shift-tab to insert unexpanded tab (hopefully works)(seems like it does)
inoremap <S-Tab> <C-V><Tab>

autocmd FileType markdown setlocal spell
autocmd FileType gitcommit setlocal spell

set tags+=/usr/include/**/tags

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
\ "yml",
\ "sql",
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

" highlight code in backticks ``` in markdown files, not working?
let g:vim_markdown_fenced_languages = ['html', 'python', 'bash=sh', 'py=python', 'sql=sql']

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
set autoindent      " align the new line indent with the previous line
set number

" can run :retab to turn tabs into spaces with the above settings
"### COLORS set background=dark
set t_Co=256

" diff highlighting (such as in git)
" cterm - sets the style
" ctermfg - set the text color
" ctermbg - set the highlighting
" DiffAdd - line was added
" DiffDelete - line was removed
" DiffChange - part of the line was changed (highlights the whole line)
" DiffText - the exact part of the line that changed
" colors https://vim.fandom.com/wiki/Xterm256_color_names_for_console_Vim?file=Xterm-color-table.png
highlight DiffAdd    cterm=none ctermfg=36 ctermbg=none gui=none guifg=bg guibg=Red
highlight DiffDelete cterm=bold ctermfg=132 ctermbg=none gui=none guifg=bg guibg=Red
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffText   cterm=bold ctermfg=10 ctermbg=88 gui=none guifg=bg guibg=Red
highlight clear SpellBad
highlight SpellBad ctermfg=009 ctermbg=011 guifg=#ff0000 guibg=#ffff00

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"# Saved MACROS macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" must escape a ' with another '

" remove trailing whitespace from line
let @w='g_ld$'

" made for copying loadfile docs to dbt
let @d='0ct''description: hh'
let @n='0f:lyt,O- name: hhp'
let @b='i---version: 2models:- name: hh"%paÄkbÄkbÄkbÄkbhhocolumns:hh:w'

" for adding ref('') around tables in dbt
let @r = 'bi{{ ref(^Äkb"Äkb''hhea'') }}hhjjj'


"""""""""""""""""" THE END """""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
