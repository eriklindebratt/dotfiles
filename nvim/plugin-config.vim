""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDTree
"""

let NERDTreeIgnore=['\.DS_Store', '\.netrwhist', '\.nvimlog']
let NERDTreeShowHidden=1

" Close NERDTree when leaving the tab holding its buffer
autocmd TabLeave NERD_tree* NERDTreeClose

" Refresh NERDTree when Vim gains focus
autocmd FocusGained * NERDTreeRefreshRoot


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf.vim
"
"""
let g:fzf_layout = { 'down': '40%' }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COC and its extensions
" 
" NOTE: Key bindings are in keys.vim
"""

if exists('g:plug_home') && isdirectory(g:plug_home . '/coc.nvim')
  let g:coc_global_extensions = [
    \ 'coc-tsserver',
    \ 'coc-eslint',
    \ 'coc-tslint',
    \ 'coc-json',
    \ 'coc-css',
    \ 'coc-html',
    \ 'coc-python',
    \ 'coc-prettier',
    \ 'coc-svg',
    \ 'coc-snippets',
    \ 'coc-ultisnips',
    \ 'coc-vetur',
    \ ]

  function HasLocalEslintConfigFile()
    let currentDir = fnamemodify('.', ':p:h')
    let localEslintConfigFilePaths = glob(currentDir . '/.eslintrc*', 0, 1)
    let readableLocalEslintConfigFilePaths = filter(localEslintConfigFilePaths, 'filereadable(v:val)')
    let numberOfReadableLocalEslintConfigFilePaths = len(readableLocalEslintConfigFilePaths)

    if numberOfReadableLocalEslintConfigFilePaths == 0
      return v:false
    else
      return v:true
    endif
  endfunction

  function EnableOrDisableLinterForBuffer()
    let localTslintDir = fnamemodify('.', ':p:h') . '/node_modules/tslint'
    let localEslintDir = fnamemodify('.', ':p:h') . '/node_modules/eslint'

    if isdirectory(localEslintDir)
      if HasLocalEslintConfigFile()
        call coc#config('eslint.enable', v:true)
      else
        " No local .eslintrc* file(s) found - disabling coc-eslint
        call coc#config('eslint.enable', v:false)
      endif
    else
      call coc#config('eslint.enable', v:false)

      if isdirectory(localTslintDir)
        call coc#config('tslint.enable', v:true)
      else
        call coc#config('tslint.enable', v:false)
      endif
    endif
  endfunction

  " Get rid of those "[coc.nvim] Failed to load the ESLint library ..." warnings
  autocmd BufNewFile,BufReadPre,BufEnter,BufLeave
    \ * call EnableOrDisableLinterForBuffer()

  augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " Add `:Format` command to format current buffer.
  command! -nargs=0 Format :call CocAction('format')

  " Add `:Fold` command to fold current buffer.
  command! -nargs=? Fold :call     CocAction('fold', <f-args>)

  " Add `:OR` command for organize imports of the current buffer.
  command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

  " Highlight the symbol and its references when holding the cursor.
  autocmd CursorHold * silent call CocActionAsync('highlight')

  " Set the current function symbol when holding the cursor.
  " Note: Disabling this for now due to error 'documentSymbol provider not found for current buffer, your language server don't support it.'
  "autocmd CursorHold * silent call CocActionAsync('getCurrentFunctionSymbol')
else
  echom 'WARNING: Can''t use coc.nvim as part of statusline that plugin doesn''t appear to be installed'
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" lightline.vim
"""

function! CocCurrentFunction()
  return get(b:, 'coc_current_function', '')
endfunction

let g:lightline = {
  \ 'colorscheme': 'powerline',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ],
  \     [ 'coc_status', 'readonly', 'filename', 'modified', 'coc_current_function'  ] ]
  \ },
  \ 'component_function': {
  \   'coc_status': 'coc#status',
  \   'coc_current_function': 'CocCurrentFunction'
  \ },
  \ }

set noshowmode  " lightline already shows current mode


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" auto-pairs
"""

" Reduce the types to pair, for sanity
let g:AutoPairs = {'(':')', '[':']', '{':'}', '''''''': '''''''', '"""': '"""'}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-closetag
"""

let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.jsx,*.tsx'
let g:closetag_filetypes = 'html,xhtml,phtml,jsx,tsx'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
let g:closetag_xhtml_filetypes = 'xhtml,jsx,tsx'


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" gutentags
"""

let g:gutentags_ctags_executable='/usr/local/bin/ctags'


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
