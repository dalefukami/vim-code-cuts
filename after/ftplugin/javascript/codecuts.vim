" Functions {{{1
" Operator-Pendings {{{2
" Around Function Body {{{3
" TODO restore the old search value
" TODO: Make around function take the newline above function if it's empty
function! codecuts#SelectAroundFunctionBody_javascript()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_javascript()\r".'0V/{'."\r".'%'
endfunction

" Inside Function Body {{{3
function! codecuts#SelectInsideFunctionBody_javascript()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_javascript()\r0".'/{'."\rj0Vk0".'/{'."\r%k"
endfunction

" Operators {{{2

" Utility Functions {{{1

function! codecuts#GoToStartOfCurrentFunction_javascript()
    execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\zs\w*\ze\s*('."\<cr>"
endfunction
