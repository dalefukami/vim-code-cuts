" General Configuration {{{1
if !exists('g:codecuts_map_motions')
    let g:codecuts_map_motions = 1
endif

if !exists('g:codecuts_map_operators')
    let g:codecuts_map_operators = 1
endif

if !exists('g:codecuts_refactor_map_prefix')
    let g:codecuts_refactor_map_prefix = '<leader>r'
endif

function! codecuts#CreateOperatorMapping(mapping, function_name)
    execute "nnoremap <buffer>"  g:codecuts_refactor_map_prefix.a:mapping  ":set operatorfunc=codecuts#".a:function_name."<CR>g@"
    execute "vnoremap <buffer>"  g:codecuts_refactor_map_prefix.a:mapping  ":<c-u>call codecuts#".a:function_name."(visualmode())<CR>"
endfunction

" Operator Mappings {{{1
if g:codecuts_map_operators
    call codecuts#CreateOperatorMapping("rwv", "ReplaceWithVariable")
endif

" Operators {{{1
" Replace With Variable {{{2
function! codecuts#ReplaceWithVariable(type, ...)
    if codecuts#IsMultiLine(a:type)
        echom "ReplaceWithVariable is only available with single line selections"
        return
    endif

    let l:new_name = input("Enter new variable name: ")
    let l:new_name = codecuts#ConvertToVariableName(l:new_name)

    " Select the text
    if a:type ==# 'char'
        silent execute "normal! `[v`]"
    else
        silent execute "normal! `<v`>"
    endif

    " Get the text
    execute 'normal! "qy'
    let l:extracted_text = codecuts#Trim(@q)

    " Replace all occurances of the extracted content
    call codecuts#SelectInsideFunctionBody()
    execute 'normal! :s/'.l:extracted_text.'/'.l:new_name.'/ge'."\<cr>"

    " Create variable declaration
    call codecuts#GoToStartOfCurrentFunction()
    execute "normal! o".l:new_name.' = '.l:extracted_text.';'
endfunction

" Utility Functions {{{1

function! codecuts#IsMultiLine(type)
    return a:type ==# 'line' || a:type ==# 'V' || (a:type ==# 'v' && line("'<") != line("'>"))
endfunction

function! codecuts#Trim(the_string)
    return substitute(a:the_string,'\s\+$','','')
endfunction
