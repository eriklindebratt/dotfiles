let vimplug_exists=expand(g:NEOVIM_CONFIG_DIR . '/autoload/plug.vim')

if !filereadable(vimplug_exists)
  if !executable('curl')
    echoerr 'You have to install curl or first install vim-plug yourself!'
    execute 'q!'
  endif
  echo 'Installing Vim-Plug...'
  echo ''
  silent exec '!\curl -fLo ' . vimplug_exists . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  let g:not_finish_vimplug = 'yes'
endif

call plug#begin(g:NEOVIM_CONFIG_DIR . '/plugged')

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" syntax highlighting and indentation
Plug 'sheerun/vim-polyglot'

" appearance and themes
Plug 'altercation/vim-colors-solarized'
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'

" autocompletion, linting
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" markdown viewer
Plug 'chemzqm/macdown.vim'

" utilities
Plug 'airblade/vim-rooter'
Plug 'moll/vim-bbye'
Plug 'jiangmiao/auto-pairs'
Plug 'alvan/vim-closetag'
Plug 'ervandew/supertab'
Plug 'tpope/vim-surround'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'luochen1990/rainbow'
"Plug 'ludovicchabant/vim-gutentags'
Plug 'psliwka/vim-smoothie'
Plug 'ryanoasis/vim-devicons'
Plug 'grvcoelho/vim-javascript-snippets'
Plug 'iamcco/coc-tailwindcss',  {'do': 'npm install && npm run build'}
call plug#end()
