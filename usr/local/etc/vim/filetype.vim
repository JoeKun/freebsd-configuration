" /usr/local/etc/vim/filetype.vim
" Additional global rules for file type resolution for vim.

autocmd BufRead,BufNewFile */etc/apache2*/*.conf,*/etc/apache2*/conf.*/*,*/etc/apache2*/mods-*/*,*/etc/apache2*/sites-*/* setfiletype apache
autocmd BufRead,BufNewFile */etc/namedb/* setfiletype named
autocmd BufRead,BufNewFile */etc/nginx/* setfiletype nginx
