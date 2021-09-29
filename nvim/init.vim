let g:NEOVIM_CONFIG_DIR=fnamemodify($MYVIMRC, ':p:h')

exec 'source' g:NEOVIM_CONFIG_DIR . '/plugin-list.vim'
exec 'source' g:NEOVIM_CONFIG_DIR . '/general.vim'
exec 'source' g:NEOVIM_CONFIG_DIR . '/plugin-config.vim'
exec 'source' g:NEOVIM_CONFIG_DIR . '/key-mappings.vim'
exec 'source' g:NEOVIM_CONFIG_DIR . '/key-mappings.plugins.vim'
