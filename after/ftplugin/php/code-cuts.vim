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

function! s:CreateOperatorMapping(mapping, function_name)
    execute "nnoremap <buffer>"  g:codecuts_refactor_map_prefix.a:mapping  ":set operatorfunc=<SID>".a:function_name."<CR>g@"
    execute "vnoremap <buffer>"  g:codecuts_refactor_map_prefix.a:mapping  ":<c-u>call <SID>".a:function_name."(visualmode())<CR>"
endfunction

" Motion (Operator-Pending) Mappings {{{1
if g:codecuts_map_motions
    onoremap <buffer> afb :<c-u>call <SID>SelectAroundFunctionBody()<cr>
    vnoremap <buffer> afb :<c-u>call <SID>SelectAroundFunctionBody()<cr>
    onoremap <buffer> ifb :<c-u>call <SID>SelectInsideFunctionBody()<cr>
    vnoremap <buffer> ifb :<c-u>call <SID>SelectInsideFunctionBody()<cr>
    onoremap <buffer> ifn :<c-u>call <SID>SelectInsideFunctionName()<cr>
    vnoremap <buffer> ifn :<c-u>call <SID>SelectInsideFunctionName()<cr>
    onoremap <buffer> ifp :<c-u>call <SID>SelectInsideFunctionParameters()<cr>
    vnoremap <buffer> ifp :<c-u>call <SID>SelectInsideFunctionParameters()<cr>
endif

" Operator Mappings {{{1
if g:codecuts_map_operators
    call <SID>CreateOperatorMapping("cf", "CreateFunction")
    call <SID>CreateOperatorMapping("ci", "CreateIf")
    call <SID>CreateOperatorMapping("ef", "ExtractFunction")
    call <SID>CreateOperatorMapping("rwv", "ReplaceWithVariable")
endif

" Functions {{{1
" Operator-Pendings {{{2
" Around Function Body {{{3
" TODO genericize the function detection for different file types?
" TODO restore the old search value
" TODO: Make around function take the newline above function if it's empty
function! s:SelectAroundFunctionBody()
    execute "normal! :call <SID>GoToStartOfCurrentFunction()\r".'0V/{'."\r".'%'
endfunction

" Inside Function Body {{{3
function! s:SelectInsideFunctionBody()
    execute "normal! :call <SID>GoToStartOfCurrentFunction()\r0".'/{'."\rj0Vk0".'/{'."\r%k"
endfunction

" Inside Function Name (php) {{{3
function! s:SelectInsideFunctionName()
    execute "normal! :call <SID>GoToStartOfCurrentFunction()\rve"
endfunction

" Function Parameters (php) {{{3
function! s:SelectInsideFunctionParameters()
    execute "normal! :call <SID>GoToStartOfCurrentFunction()\rf(lvt)"
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

function! s:CreateFunction(type, ...)
    call <SID>WrapLines(a:type, b:code_cuts_function_header, 1)
endfunction

function! s:WrapLines(type, header, expand_snippet)
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

function! s:CreateIf(type, ...)
    call <SID>WrapLines(a:type, b:code_cuts_if_header, 1)
endfunction

" Extract function {{{3
function! s:ExtractFunction(type, ...)
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
    let l:components = <SID>GetFunctionExtractionComponents(@q,l:new_name)
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
    call <SID>WrapLines(visualmode(), l:components.function_header, 0)

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

function! s:GetFunctionExtractionComponents(text, method_name)
    let l:lines = split(a:text, "\n")
    let l:params = <SID>GetRequiredFunctionParameters(split(a:text,"\n"))
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

function! s:GetRequiredFunctionParameters(lines)
    let l:line_info = []
    for l:line in a:lines
        let l:line_info = add(l:line_info, <SID>GetUsedVariablesForLine(l:line))
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

function! s:GetUsedVariablesForLine(line)
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


" Replace With Variable {{{3
function! s:ReplaceWithVariable(type, ...)
    if <SID>IsMultiLine(a:type)
        echom "ReplaceWithVariable is only available with single line selections"
        return
    endif

    let l:new_name = input("Enter new variable name: ")
    let l:new_name = "$".substitute(l:new_name,"^$","","")

    " Select the text
    if a:type ==# 'char'
        silent execute "normal! `[v`]"
    else
        silent execute "normal! `<v`>"
    endif

    " Get the text
    execute 'normal! "qy'
    let l:extracted_text = <SID>Trim(@q)

    " Replace all occurances of the extracted content
    call <SID>SelectInsideFunctionBody()
    execute 'normal! :s/'.l:extracted_text.'/'.l:new_name.'/ge'."\<cr>"

    " Create variable declaration
    call <SID>GoToStartOfCurrentFunction()
    execute "normal! o".l:new_name.' = '.l:extracted_text.';'
endfunction

" Utility Functions {{{1

function! s:IsMultiLine(type)
    return a:type ==# 'line' || a:type ==# 'V' || (a:type ==# 'v' && line("'<") != line("'>"))
endfunction

function! s:GoToStartOfCurrentFunction()
    execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\zs\w*\ze\s*('."\<cr>"
endfunction

function! s:Trim(the_string)
    return substitute(a:the_string,'\s\+$','','')
endfunction

" Testing {{{1
" Used for rapid testing. Reload and run the command immediately displaying
" the results in a temp buffer
"nnoremap <leader>r :source $HOME/.vim/bundle/vim-code-cuts/after/ftplugin/php/code-cuts.vim<cr>:call Testit()<cr>
function! s:Testit()
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
    let g:result = <SID>GetRequiredFunctionParameters(g:test_lines)

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
