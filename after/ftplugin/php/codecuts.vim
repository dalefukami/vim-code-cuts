" Motion (Operator-Pending) Mappings {{{1
if g:codecuts_map_motions
    onoremap <buffer> afb :<c-u>call codecuts#SelectAroundFunctionBody()<cr>
    vnoremap <buffer> afb :<c-u>call codecuts#SelectAroundFunctionBody()<cr>
    onoremap <buffer> ifb :<c-u>call codecuts#SelectInsideFunctionBody_php()<cr>
    vnoremap <buffer> ifb :<c-u>call codecuts#SelectInsideFunctionBody_php()<cr>
    onoremap <buffer> ifn :<c-u>call codecuts#SelectInsideFunctionName()<cr>
    vnoremap <buffer> ifn :<c-u>call codecuts#SelectInsideFunctionName()<cr>
    onoremap <buffer> ifp :<c-u>call codecuts#SelectInsideFunctionParameters()<cr>
    vnoremap <buffer> ifp :<c-u>call codecuts#SelectInsideFunctionParameters()<cr>
    onoremap <buffer> i, :<c-u>call codecuts#SelectInsideSingleFunctionParameter_php()<cr>
    vnoremap <buffer> i, :<c-u>call codecuts#SelectInsideSingleFunctionParameter_php()<cr>
endif

" Operator Mappings {{{1
if g:codecuts_map_operators
    call codecuts#CreateOperatorMapping("cf", "CreateFunction")
    call codecuts#CreateOperatorMapping("ci", "CreateIf")
    call codecuts#CreateOperatorMapping("ef", "ExtractFunction")
endif

" Functions {{{1
" Operator-Pendings {{{2
" Around Function Body {{{3
" TODO genericize the function detection for different file types?
" TODO restore the old search value
" TODO: Make around function take the newline above function if it's empty
function! codecuts#SelectAroundFunctionBody()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_php()\r".'0V/{'."\r".'%'
endfunction

" Inside Function Body {{{3
function! codecuts#SelectInsideFunctionBody_php()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_php()\r0".'/{'."\rj0Vk0".'/{'."\r%k"
endfunction

" Inside Function Name (php) {{{3
function! codecuts#SelectInsideFunctionName()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_php()\rve"
endfunction

" Function Parameters (php) {{{3
function! codecuts#SelectInsideFunctionParameters()
    execute "normal! :call codecuts#GoToStartOfCurrentFunction_php()\rf(lvt)"
endfunction

" Single Function Parameter (php) {{{3
function! codecuts#SelectInsideSingleFunctionParameter_php()
    execute "normal :\<c-u>\<cr>"
    let l:line = getline('.')
    let l:line_number = line('.')

    let l:start_index = codecuts#findFunctionParameterStart(l:line, col('.'))
    call cursor(l:line_number, l:start_index+1) " Add one because strings are zero based but columns are 1 based

    silent! execute "normal! vt,"
    if l:line[col('.')] != ","
        execute "normal! t)"
    endif
endfunction

" Operators {{{2

let s:snip_mate_exists = exists('*MakeSnip')

" Create function {{{3
if s:snip_mate_exists
    let b:code_cuts_function_header = 'function_header'
    call MakeSnip('php', b:code_cuts_function_header,'${1:private }function ${2:FunctionName}(${3}) {')
    let b:snippet_code = "A\<C-R>=TriggerSnippet()\<cr>"
else
    let b:code_cuts_function_header = 'private function function_name() {'
    let b:snippet_code = ""
endif

function! codecuts#CreateFunction(type, ...)
    call codecuts#WrapLines(a:type, b:code_cuts_function_header, 1)
endfunction

function! codecuts#WrapLines(type, header, expand_snippet)
    if a:type ==# 'char' || a:type ==# 'line'
        " Mimic visual mode for consistency
        echom "mode: ".a:type
        execute "normal! `[v`]"
    endif
    let l:snippet_code = ""
    if a:expand_snippet
        let l:snippet_code = b:snippet_code
    endif
    execute "normal! :\<c-u>\<cr>`>o}\<esc>`<O".a:header."\<esc>".l:snippet_code
endfunction

" Create if statement {{{3
if s:snip_mate_exists
    let b:code_cuts_if_header = 'if_header'
    call MakeSnip('php', b:code_cuts_if_header,'if( ${1:condition} ) {')
else
    let b:code_cuts_if_header = 'if() {'
endif

function! codecuts#CreateIf(type, ...)
    call codecuts#WrapLines(a:type, b:code_cuts_if_header, 1)
endfunction

" Extract function {{{3
function! codecuts#ExtractFunction(type, ...)
    let l:new_name = input("Enter new function name: ")
    let l:append_semicolon_to_new_method = 0
    let l:append_semicolon_to_method_call = 0
    let l:return_result = 0
    " Ensure the right text is selected
    if a:type ==# 'char'
        let l:append_semicolon_to_new_method = 1
        let l:return_result = 1
        silent execute "normal! `[v`]"
    elseif a:type ==# 'line'
        let l:append_semicolon_to_method_call = 1
        silent execute "normal! `[V`]"
    elseif a:type ==# 'v' && line("'<") == line("'>") " Character-wise selection on single line
        let l:append_semicolon_to_new_method = 1
        let l:return_result = 1
        silent execute "normal! `<v`>"
    else
        let l:append_semicolon_to_method_call = 1
        silent execute "normal! `<V`>"
    endif

    execute 'normal! "qy'
    let l:components = codecuts#GetFunctionExtractionComponents(@q,l:new_name)
    " Change the text to the new call
    let l:postfix = l:append_semicolon_to_method_call ? ';' : ''
    silent execute 'normal! gvc'.l:components.method_call.l:postfix."\<esc>=="

    " Find the end of the current function
    silent execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\w*\s*('."\r".'/{'."\r".'%o'."\<esc>"
    " Ensure a line-wise paste
    let @q = l:components.method_body
    silent put q
    " Create function around new lines
    silent execute "normal! `[v`]"

    " Remove trailing whitespace from lines
    s/\s\+$//e

    " Wrap with the function
    call codecuts#WrapLines(visualmode(), l:components.function_header, 0)

    " Add a semicolon to the last line if deemed necessary
    let l:postfix = l:append_semicolon_to_new_method ? ';' : ''
    execute "normal! $%kA".l:postfix."\<esc>"

    " Add a return statement
    let l:prefix = (l:return_result || l:components.is_assignment) ? 'return ' : ''
    execute "normal! I".l:prefix."\<esc>"

    " Proper indentation of the new method - Doesn't seem to work for
    " multi-line creation?
    silent execute "normal! =a{"
endfunction

" TODO: Return to spot where text was yanked or top of new method? (Perhaps set marks or possibly just ensure that '' will get to the other one)
" TODO: Play nice
"       - Restore register q
"       - Restore previous search expression

function! codecuts#GetFunctionExtractionComponents(text, method_name)
    let l:lines = split(a:text, "\n")
    let l:params = codecuts#GetRequiredFunctionParameters(split(a:text,"\n"))
    let l:method_call = '$this->'.a:method_name."(".join(l:params,",").")"
    let l:is_assignment = 0
    if( len(l:lines) > 1 )
        let l:last_line = l:lines[-1]
        " Possible problem with == in the last line?
        let l:pieces = split(l:last_line, "=")
        if( len(l:pieces) > 1 )
            let l:method_call = substitute(l:pieces[0],'\s\+$','','').' = '.l:method_call
            let l:pieces = l:pieces[1:]
            let l:lines[-1] = join(l:pieces, "=")
            let l:is_assignment = 1
        endif
    endif

    let l:function_header = 'private function '.a:method_name.'('.join(l:params,",").') {'
    return {"method_call": l:method_call, "method_body": join(l:lines,"\n"), "is_assignment": l:is_assignment, "function_header": l:function_header}
endfunction

function! codecuts#GetRequiredFunctionParameters(lines)
    let l:line_info = []
    for l:line in a:lines
        let l:line_info = add(l:line_info, codecuts#GetUsedVariablesForLine(l:line))
    endfor
    let l:results = []
    let l:assigned_before_accessed = []
    let l:accessed_before_assigned = []
    for l:info in l:line_info
        for l:var in l:info.accessed_vars
            if index(l:assigned_before_accessed, l:var) < 0 && index(l:accessed_before_assigned, l:var) < 0
                if l:var ==# "$this"
                else
                    call add(l:results, l:var)
                    call add(l:accessed_before_assigned, l:var)
                endif
            endif
        endfor
        for l:var in l:info.assigned_vars
            if index(l:accessed_before_assigned, l:var) < 0
                call add(l:assigned_before_accessed, l:var)
            endif
        endfor
    endfor
    return l:results
endfunction

function! codecuts#GetUsedVariablesForLine(line)
    let l:line_data = {"assigned_vars":[], "accessed_vars": []}
    let l:line_parts = split(a:line, '[^=+-/*!><]\zs=\ze[^=]')
    if len(l:line_parts) < 1
        return l:line_data
    endif
    let l:accessor_part = l:line_parts[0]
    let l:assignment_part = ""
    " For now, assume only 2 parts match.
    " Cases that need to be handled are things like == or !=
    if len(l:line_parts) > 1
        let l:assignment_part = l:line_parts[0]
        let l:accessor_part = l:line_parts[1]
    endif
    let l:count = 1
    while matchstr(l:accessor_part,'$[0-9a-zA-Z_]\+',0,l:count) != ""
        call add(l:line_data.accessed_vars,matchstr(l:accessor_part,'$[0-9a-zA-Z_]\+',0,l:count))
        let l:count = l:count + 1
    endwhile
    call add(l:line_data.assigned_vars,matchstr(l:assignment_part,'$[0-9a-zA-Z_]\+'))

    return l:line_data
endfunction



" Utility Functions {{{1

function! codecuts#GoToStartOfCurrentFunction_php()
    execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\zs\w*\ze\s*('."\<cr>"
endfunction

function! codecuts#ConvertToVariableName_php(the_name)
    return "$".substitute(a:the_name,"^\\$","","")
endfunction

function! codecuts#FormatVariableAssignment_php(assignee,value)
    return codecuts#ConvertToVariableName_php(a:assignee).' = '.a:value.';'
endfunction

function! codecuts#SelectReplaceWithVariableArea_php()
    call codecuts#SelectInsideFunctionBody_php()
endfunction

function! codecuts#GoToVariableDeclarationLocation_php()
    call codecuts#GoToStartOfCurrentFunction_php()
endfunction

function! codecuts#findFunctionParameterStart(line, position)
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
    let l:closest_match = a:position
    while l:match != -1
        let l:match = match(l:sanitized_line,"[(,]", l:match+1)
        if l:match != -1 && l:match < a:position
            let l:closest_match = l:match
        endif
    endwhile
    return l:closest_match+1
endfunction

" Testing {{{1
" Used for rapid testing. Reload and run the command immediately displaying
" the results in a temp buffer
nnoremap <leader>r :source $HOME/.vim/bundle/vim-code-cuts/after/ftplugin/php/codecuts.vim<cr>:call codecuts#TestFindFunctionParameterStart()<cr>
function! codecuts#TestFindFunctionParameterStart()
    let g:test_buffer_name = "__TEST_BUFFER__"
    if bufexists(g:test_buffer_name)
        execute "normal! :".bufwinnr(g:test_buffer_name)."wincmd w\<CR>"
    else
        execute "normal! :vsplit ".g:test_buffer_name."\<CR>"
    endif
    normal! ggdG
    setlocal filetype=testbuffer
    setlocal buftype=nofile

    let g:lines = [
                \ ['Enclosed with commas', "$this->callFunction( $condition5, $arg2, $arg3 );", 37, 33],
                \ ['Enclosed with paren', "$this->callFunction( $condition5, $arg2, $arg3 );", 24, 20],
                \ ['Parens within param', "fun( $a->fun2()+2, $arg3 );", 15, 4],
                \ ['Parens within param and junk', 'fun( $a->fun2("some cool stuff, and more")+"crazy things", $arg3 );', 50, 4]
                \ ]

    for [test_name, test_string, position, expected] in g:lines
        let g:result = codecuts#findFunctionParameterStart(test_string, position)
        if g:result == expected
            call append('$','pass ['.test_name.']')
        else
            call append('$','fail ['.test_name.'] -- Expected ['.expected.']...Actual ['.g:result.']')
        endif
    endfor

endfunction

function! codecuts#Testit()
    let g:test_lines = [
                \ "            $param1->callMethod();",
                \ "            $something = $param2 + $param3;",
                \ "            $new_var = $something + 1;",
                \ "            $param2 = $something + 1;",
                \ "$param4->callIt($param5);",
                \ "$do_it = $this->thing;",
                \ "$more_stuff->doSomething();",
                \ "$test->blah($new_param);",
                \ "$test->blah($new_param);",
                \ "if( $condition1 === $condition2 ) {",
                \ "if( $condition3 == $condition4 ) {",
                \ "if( $condition5 != $condition6 ) {",
                \ "$assign1=$param6;",
                \ ]
    let g:result = codecuts#GetRequiredFunctionParameters(g:test_lines)

    let g:test_buffer_name = "__TEST_BUFFER__"
    if bufexists(g:test_buffer_name)
        execute "normal! :".bufwinnr(g:test_buffer_name)."wincmd w\<CR>"
    else
        execute "normal! :vsplit ".g:test_buffer_name."\<CR>"
    endif
    normal! ggdG
    setlocal filetype=testbuffer
    setlocal buftype=nofile
    call append(0,g:result)
endfunction
