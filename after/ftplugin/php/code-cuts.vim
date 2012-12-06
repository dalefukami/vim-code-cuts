" Operator-Pendings {{{1
" Around Function (php) {{{2
" TODO genericize the function detection for different file types?
" TODO restore the old search value
onoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>
vnoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>

" Function Name (php) {{{2
onoremap fn :<c-u>execute 'normal! ?\<function\>\s*&*\s*\zs\w*\ze\s*('."\r".'ve'<cr>

" Operators {{{1

let s:snip_mate_exists = exists('*MakeSnip')

" Create function {{{2
if s:snip_mate_exists
    let b:code_cuts_function_header = 'function_header'
    call MakeSnip('php', b:code_cuts_function_header,'${1:private }function ${2:FunctionName}(${3}) {')
    let b:snippet_code = "\<esc>A\<C-R>=TriggerSnippet()\<cr>"
else
    let b:code_cuts_function_header = 'private function function_name() {'
    let b:snippet_code = ""
endif

nnoremap <silent> <leader>cf :set operatorfunc=CreateFunction<CR>g@
vnoremap <silent> <leader>cf :<c-u>call CreateFunction(visualmode())<cr>

function! CreateFunction(type, ...)
    call WrapLines(a:type, b:code_cuts_function_header)
endfunction

function! WrapLines(type, header)
    if a:type ==# 'char' || a:type ==# 'line'
        " Mimic visual mode for consistency
        echom "mode: ".a:type
        execute "normal! `[v`]"
    endif
    execute "normal! :\<c-u>\<cr>`>o}\<esc>`<O".a:header.b:snippet_code
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
    call WrapLines(a:type, b:code_cuts_if_header)
endfunction

" Extract function {{{2
nnoremap <silent> <leader>ref :set operatorfunc=ExtractFunction<CR>g@
vnoremap <silent> <leader>ref :<c-u>call ExtractFunction(visualmode())<cr>

function! ExtractFunction(type, ...)
    echom "mode: ".a:type
    if a:type ==# 'char' || a:type ==# 'line'
        execute "normal! `[V`]d"
    else
        execute "normal! `<V`>d"
    endif
    execute "normal! :\<c-u>\<cr>".'?\<function\>\s*&*\s*\w*\s*('."\r".'/{'."\r".'%o'."\<esc>".'p'
    execute "normal! `[v`]"
    call CreateFunction(visualmode())
endfunction

