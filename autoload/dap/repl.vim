let s:repl_buf = v:null
let s:int_write = 0

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

function! dap#repl#test_rewrite()
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  let l:l_count = getbufinfo(s:repl_buf)[0].linecount
  " call dap#repl#print("number of line: " . l:l_count)
  let l:l_count4 = l:l_count - 4
  let l:l_count2 = l:l_count - 3
  call deletebufline(s:repl_buf, l:l_count4, l:l_count2)
  call appendbufline(s:repl_buf, l:l_count4, "toto")
endfunction
