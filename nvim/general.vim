" general
let mapleader = ','
set encoding=utf-8
set showcmd
set cursorline
set colorcolumn=80
set relativenumber  " generally, use relative line numbers
set number  " for current row, use absolute line number
set timeoutlen=300
set updatetime=300
set ignorecase
set title
set titlestring=Vim\ –\ %F
set nowrap

" prefer spaces over tabs, four spaces per indentation
set tabstop=2
set shiftwidth=2
set et

" color theme config
if exists('g:plug_home') && isdirectory(g:plug_home . '/vim-colors-solarized')
  colorscheme solarized
  set background=dark
else
  echom 'WARNING: Can''t set "solarized" as colorscheme since that plugin doesn''t appear to be installed'
endif

" hidden characters config
" - define hidden characters
set listchars=tab:▸\ ,eol:¬
" - hide hidden characters by default
set nolist

" set more natural splits
set splitbelow
set splitright

" set proper formatting to JSON file comments
autocmd FileType json syntax match Comment +\/\/.\+$+

" improve syntax highlighting for some file types
" - see https://thoughtbot.com/blog/modern-typescript-and-react-development-in-vim#highlighting-for-large-files
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

" when Vim gains focus or when a buffer is entered:
" 1. reload all buffers (or ask to reload)
" 2. center scroll position to current line
function s:onFocus()
  :checktime

  if &buftype != "terminal" && &buftype != "nofile"
    :normal! zz
  endif
endfunction
autocmd FocusGained,BufEnter * call s:onFocus()
