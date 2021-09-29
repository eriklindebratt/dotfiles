""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
"""

" Save current buffer
nmap <Leader>w :w<CR>

" Quit current buffer
nmap <Leader>q :q<CR>

" Save and quit current buffer
nmap <Leader>x :x<CR>

" Edit file (or re-read current file)
nmap <Leader>e :edit<space>

" Open new empty tab
nmap <Leader>tn :tabnew<CR>

" Open file in a new tab
nmap <Leader>te :tabedit<space>

" Remove search highlighting
nmap <Leader>/ :noh<CR>

" Re-select previous selection
nmap <Leader>v gv

" Open Terminal in horizontal split
nmap <Leader>ter :split<CR>:terminal<CR>i

" Re-open last closed tab
nmap <C-S-t> :tabnew#<CR>

" Abbreviations, for sanity
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Qa qa
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Qa! qa!

" Show/hide hidden characters
nmap <Leader>l :set list!<CR>
