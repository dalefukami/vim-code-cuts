" Operator-Pendings {{{1
" Around Function (php) {{{2
" TODO genericize the function detection for different file types?
" TODO restore the old search value
onoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>
vnoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>

" Function Name (php) {{{2
onoremap ifn :<c-u>execute 'normal! ?\<function\>\s*&*\s*\zs\w*\ze\s*('."\r".'ve'<cr>

" Function Parameters (php) {{{2
" Note we insert an extra character to account for empty param lists
onoremap ifp :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*\zs('."\r".'aj'."\evt)"<cr>

" Operators {{{1

let s:snip_mate_exists = exists('*MakeSnip')

" Create function {{{2
if s:snip_mate_exists
    let b:code_cuts_function_header = 'function_header'
    call MakeSnip('php', b:code_cuts_function_header,'${1:private }function ${2:FunctionName}(${3}) {')
    let b:snippet_code = "A\<C-R>=TriggerSnippet()\<cr>"
else
    let b:code_cuts_function_header = 'private function function_name() {'
    let b:snippet_code = ""
endif

nnoremap <silent> <leader>cf :set operatorfunc=CreateFunction<CR>g@
vnoremap <silent> <leader>cf :<c-u>call CreateFunction(visualmode())<cr>

function! CreateFunction(type, ...)
    call WrapLines(a:type, b:code_cuts_function_header, 1)
endfunction

function! WrapLines(type, header, expand_snippet)
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

" Create if statement {{{2
if s:snip_mate_exists
    let b:code_cuts_if_header = 'if_header'
    call MakeSnip('php', b:code_cuts_if_header,'if( ${1:condition} ) {')
else
    let b:code_cuts_if_header = 'if() {'
endif

nnoremap <silent> <leader>ci :set operatorfunc=CreateIf<CR>g@
vnoremap <silent> <leader>ci :<c-u>call CreateIf(visualmode())<cr>

function! CreateIf(type, ...)
    call WrapLines(a:type, b:code_cuts_if_header, 1)
endfunction

" Extract function {{{2
nnoremap <silent> <leader>ref :set operatorfunc=ExtractFunction<CR>g@
vnoremap <silent> <leader>ref :<c-u>call ExtractFunction(visualmode())<cr>

function! ExtractFunction(type, ...)
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
    let l:components = GetFunctionExtractionComponents(@q,l:new_name)
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
    call WrapLines(visualmode(), l:components.function_header, 0)

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

" TODO: Return to spot where text was yanked or top of new method?
" TODO: Handle ==, ===, !=, +=, etc in the yanked lines when calculating
" required params
" TODO: Play nice
"       - Restore register q
"       - Restore previous search expression

function! GetFunctionExtractionComponents(text, method_name)
    let lines = split(a:text, "\n")
    let l:params = GetRequiredFunctionParameters(split(a:text,"\n"))
    let method_call = '$this->'.a:method_name."(".join(l:params,",").")"
    let is_assignment = 0
    if( len(lines) > 1 )
        let last_line = lines[-1]
        " Possible problem with == in the last line?
        let pieces = split(last_line, "=")
        if( len(pieces) > 1 )
            let method_call = pieces[0].' = '.method_call
            let pieces = pieces[1:]
            let lines[-1] = join(pieces, "=")
            let is_assignment = 1
        endif
    endif

    let l:function_header = 'private function '.a:method_name.'('.join(l:params,",").') {'
    return {"method_call": method_call, "method_body": join(lines,"\n"), "is_assignment": is_assignment, "function_header": l:function_header}
endfunction

function! GetRequiredFunctionParameters(lines)
    let l:line_info = []
    for l:line in a:lines
        let l:line_info = add(l:line_info, GetUsedVariablesForLine(l:line))
    endfor
    let l:results = []
    let l:assigned_before_accessed = []
    let l:accessed_before_assigned = []
    for l:info in l:line_info
        for l:var in l:info.accessed_vars
            if index(l:assigned_before_accessed, l:var) < 0
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

function! GetUsedVariablesForLine(line)
    let l:line_data = {"assigned_vars":[], "accessed_vars": []}
    let l:line_parts = split(a:line, '=')
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

" Used for rapid testing. Reload and run the command immediately displaying
" the results in a temp buffer
"nnoremap <leader>r :source $HOME/.vim/bundle/vim-code-cuts/after/ftplugin/php/code-cuts.vim<cr>:call Testit()<cr>
function! Testit()
    let g:test_lines = [
                \ "            $param1->callMethod();",
                \ "            $something = $param2 + $param3;",
                \ "            $new_var = $something + 1;",
                \ "            $param2 = $something + 1;",
                \ "$param4->callIt($param5);",
                \ "$do_it = $this->thing;",
                \ "$more_stuff->doSomething();"
                \ ]
    let g:result = GetRequiredFunctionParameters(g:test_lines)

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
