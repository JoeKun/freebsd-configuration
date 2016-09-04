" ~/.vim/filetype.vim
" User rules for file type resolution for vim.

autocmd BufRead,BufNewFile */etc/apache* if &ft == '' | setfiletype apache | endif
autocmd BufRead,BufNewFile */etc/namedb/* if &ft == '' | setfiletype named | endif
autocmd BufRead,BufNewFile */etc/nginx/* if &ft == '' | setfiletype nginx | endif

