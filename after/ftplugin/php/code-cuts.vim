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
    " Ensure the right text is selected
    if a:type ==# 'char'
        let l:append_semicolon_to_new_method = 1
        let l:append_semicolon_to_method_call = 0
        silent execute "normal! `[v`]"
    elseif a:type ==# 'line'
        let l:append_semicolon_to_new_method = 0
        let l:append_semicolon_to_method_call = 1
        silent execute "normal! `[V`]"
    elseif a:type ==# 'v' && line("'<") == line("'>") " Character-wise selection on single line
        let l:append_semicolon_to_new_method = 1
        let l:append_semicolon_to_method_call = 0
        silent execute "normal! `<v`>"
    else
        let l:append_semicolon_to_new_method = 0
        let l:append_semicolon_to_method_call = 1
        silent execute "normal! `<V`>"
    endif

    let l:postfix = l:append_semicolon_to_method_call ? ';' : ''
    " Change the text to the new call and store the old text into a register
    silent execute 'normal! "qc$this->'.l:new_name."()".l:postfix."\<esc>"
    " Find the end of the current function
    silent execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\w*\s*('."\r".'/{'."\r".'%o'."\<esc>"
    " Ensure a line-wise paste
    silent put q
    " Create function around new lines
    silent execute "normal! `[v`]"
    let l:function_header = 'private function '.l:new_name.'() {'
    call WrapLines(visualmode(), l:function_header, 0)

    " Proper indentation of the new method
    silent execute "normal! =a{"
    " Add a semicolon to the last line if deemed necessary
    let l:postfix = l:append_semicolon_to_new_method ? ';' : ''
    execute "normal! $%kA".l:postfix."\<esc>"
endfunction

" TODO: Trim a character-wise selection
" TODO: Add return statement if character-wise
" TODO: For line-wise, if there's an = sign on the last line then remove the
" variable, return result from method, and assign method result to variable
" TODO: Return to spot where text was yanked or top of new method?
" TODO: Figure out parameters
" TODO: Play nice
"       - Restore register q
"       - Restore previous search expression



