function! codecuts#SelectReplaceWithVariableArea_sh()
    " Whole file
    normal! ggVG
endfunction

function! codecuts#ConvertToVariableName_sh(the_name)
    return "${".a:the_name."}"
endfunction

function! codecuts#FormatVariableAssignment_sh(assignee,value)
    return a:assignee.'='.a:value
endfunction

" TODO: Find a better spot to put new var declarations
function! codecuts#GoToVariableDeclarationLocation_sh()
    " Start of file
    normal! gg
endfunction
