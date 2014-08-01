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

" Totally duplicated from PHP. How could this be refactored to reduce....
function! codecuts#FindFunctionParameterBoundaries_javascript(line, position, is_inside)
    let l:current_character = a:line[a:position]
    let l:pre_sanitized_line = a:line
    let l:sanitized_line = substitute(l:pre_sanitized_line,'[(][^(]\{-}[)]','\=repeat("X",strlen(submatch(0)))','')
    while l:sanitized_line != l:pre_sanitized_line
        if l:sanitized_line[a:position] != l:current_character
            " If we changed our current character then we did too much
            " reset the sanitized line
            let l:sanitized_line = l:pre_sanitized_line
        else
            let l:pre_sanitized_line = l:sanitized_line
            let l:sanitized_line = substitute(l:pre_sanitized_line,'[(][^(]\{-}[)]','\=repeat("X",strlen(submatch(0)))','')
        endif
    endwhile

    let l:match = 0
    let l:start_match = a:position
    while l:match != -1
        let l:match = match(l:sanitized_line,"[(,]", l:match+1)
        if l:match != -1 && l:match < a:position
            let l:start_match = l:match
        endif
    endwhile

    let l:start = l:start_match
    if !a:is_inside
        let l:start = l:start + 1
        if a:line[l:start] == ' '
            let l:start = l:start + 1
        endif
    else
        let l:start = l:start_match + 1
        if a:line[l:start] == ' '
            let l:start = l:start + 1
        endif
    endif

    let l:match = match(l:sanitized_line,"[),]", l:start_match+1)
    let l:end = l:match
    if !a:is_inside
        if a:line[l:end] == ')'
            let l:end = l:end - 1
            " Gotta remove the previous comma if it's the last arg
            let l:start = l:start_match
        elseif a:line[l:end+1] == ' '
            let l:end = l:end + 1
        endif
    else
        let l:end = l:end-1
    endif

    let l:result = {'start': l:start, 'end': l:end}
    return l:result
endfunction
