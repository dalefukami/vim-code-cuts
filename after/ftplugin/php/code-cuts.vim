" Operator-Pendings {{{1
" Around Function (php) {{{2
" TODO genericize the function detection for different file types?
" TODO restore the old search value
onoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>
vnoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>

" Function Name (php) {{{2
onoremap fn :<c-u>execute 'normal! ?\<function\>\s*&*\s*\zs\w*\ze\s*('."\r".'ve'<cr>
