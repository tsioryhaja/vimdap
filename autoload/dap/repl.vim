let s:repl_buf = v:null

function! dap#repl#execute(text)
endfunction

function! dap#repl#create_new_buf()
  if s:repl_buf == v:null
    belowright new
    setlocal buftype=prompt bufhidden=hide noswapfile
    let s:repl_buf = bufnr()
    setlocal nomodified
    autocmd TextChanged,TextChangedI <buffer> setlocal nomodified
  else
    execute "belowright sbuffer" . s:repl_buf
  endif
endfunction

function! dap#repl#print(text)
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  call appendbufline(s:repl_buf, "$", a:text)
endfunction

function! dap#repl#text_append_text()
  call dap#repl#print("shit")
endfunction
