" Operator-Pendings {{{1
" Around Function (php) {{{2
" TODO genericize the function detection for different file types?
" TODO restore the old search value
onoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>
vnoremap <buffer> af :<c-u>execute 'normal! ?\<function\>\s*&*\s*\w*\s*('."\r".'0V/{'."\r".'%'<cr>

" Function Name (php) {{{2
onoremap fn :<c-u>execute 'normal! ?\<function\>\s*&*\s*\zs\w*\ze\s*('."\r".'ve'<cr>

" Operators {{{1

" Create function {{{2
let s:snip_mate_exists = exists('*MakeSnip')
if s:snip_mate_exists
    let b:code_cuts_function_header = 'function_header'
    call MakeSnip('php', b:code_cuts_function_header,'${1:public }function ${2:FunctionName}(${3}) {')
else
    let b:code_cuts_function_header = 'private function function_name() {'
endif

nnoremap <silent> <leader>cf :set operatorfunc=CreateFunction<CR>g@
function! CreateFunction(type, ...)
    let l:snippet_code = ''
    if s:snip_mate_exists
        let l:snippet_code = "\<esc>A\<C-R>=TriggerSnippet()\<cr>"
    endif
    execute "normal! `[ma`]o}\<esc>`aO".b:code_cuts_function_header.l:snippet_code
endfunction
