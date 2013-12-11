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
    execute "nnoremap "  g:codecuts_refactor_map_prefix.a:mapping  ":set operatorfunc=codecuts#".a:function_name."<CR>g@"
    execute "vnoremap "  g:codecuts_refactor_map_prefix.a:mapping  ":<c-u>call codecuts#".a:function_name."(visualmode())<CR>"
endfunction

function! codecuts#CreateMotionMapping(mapping, function_name)
    execute "onoremap ".a:mapping." :<c-u>call codecuts#".a:function_name."()<cr>"
    execute "vnoremap ".a:mapping." :<c-u>call codecuts#".a:function_name."()<cr>"
endfunction

" Operator Mappings {{{1
if g:codecuts_map_operators
    call codecuts#CreateOperatorMapping("rwv", "ReplaceWithVariable")
endif

" Motion Mappings {{{1
if g:codecuts_map_motions
    call codecuts#CreateMotionMapping("i,", "SelectInsideCalledFunctionParameter")
    call codecuts#CreateMotionMapping("a,", "SelectAroundCalledFunctionParameter")
endif

" Operators {{{1
" Replace With Variable {{{2
function! codecuts#ReplaceWithVariable(type, ...)
    if codecuts#IsMultiLine(a:type)
        echom "ReplaceWithVariable is only available with single line selections"
        return
    endif

    let l:new_name = input("Enter new variable name: ")

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
    let l:var_usage_name = <SID>CallFunction("ConvertToVariableName",l:new_name)
    call <SID>CallFunction("SelectReplaceWithVariableArea")
    execute 'normal! :s/'.l:extracted_text.'/'.l:var_usage_name.'/ge'."\<cr>"

    " Create variable declaration
    call <SID>CallFunction("GoToVariableDeclarationLocation")
    execute "normal! o".<SID>CallFunction("FormatVariableAssignment",l:new_name,l:extracted_text)
endfunction

" Motions {{{1
" Single Function Parameter (php) {{{2
function! codecuts#SelectInsideCalledFunctionParameter()
    execute "normal :\<c-u>\<cr>"
    let l:line = getline('.')
    let l:line_number = line('.')

    let l:boundaries = <SID>CallFunction("FindFunctionParameterBoundaries",l:line, col('.'), 1)
    call cursor(l:line_number, l:boundaries.start+1) " Add one because strings are zero based but columns are 1 based

    let l:difference = l:boundaries.end - l:boundaries.start

    silent! execute "normal! v".l:difference."l"
endfunction

" Around Single Function Parameter (php) {{{2
function! codecuts#SelectAroundCalledFunctionParameter()
    execute "normal :\<c-u>\<cr>"
    let l:line = getline('.')
    let l:line_number = line('.')

    let l:boundaries = <SID>CallFunction("FindFunctionParameterBoundaries",l:line, col('.'), 0)
    call cursor(l:line_number, l:boundaries.start+1) " Add one because strings are zero based but columns are 1 based

    let l:difference = l:boundaries.end - l:boundaries.start

    silent! execute "normal! v".l:difference."l"
endfunction

" Utility Functions {{{1

function! codecuts#IsMultiLine(type)
    return a:type ==# 'line' || a:type ==# 'V' || (a:type ==# 'v' && line("'<") != line("'>"))
endfunction

function! codecuts#Trim(the_string)
    let l:trimmed_string = substitute(a:the_string,'\s\+$','','')
    return substitute(l:trimmed_string,'^\s\+','','')
endfunction

" Generate filetype specific function name
function! s:FunctionName(function_name)
    return "codecuts#".a:function_name."_".&filetype
endfunction

" Call a filetype specific function
function! s:CallFunction(function_name,...)
    execute 'normal! :let l:result = call("'.<SID>FunctionName(a:function_name).'",a:000)'."\r"
    return l:result
endfunction
