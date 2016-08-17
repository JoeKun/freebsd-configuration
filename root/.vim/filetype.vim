" ~/.vim/filetype.vim
" User rules for file type resolution for vim.

autocmd BufRead,BufNewFile */etc/nginx/* if &ft == '' | setfiletype nginx | endif

