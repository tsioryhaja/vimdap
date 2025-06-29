let s:repl_buf = v:null
let s:int_write = 0

let s:nodes = []

function! dap#repl#evaluate_callback(text)
  let l:sessions = dap#session#get_stopped_sessions()
  for l:session in l:sessions
    call dap#repl#execute(l:session, a:text)
  endfor
endfunction

function! dap#repl#execute(session, text)
  if a:session.current_frame == v:null
    return
  endif
  let l:evaluate_result = dap#requests#sync_evaluate(a:session, a:text, "repl", a:session.current_frame.id)
  if l:evaluate_result.success == v:true
    let l:body = l:evaluate_result.body
    if l:body.variablesReference <= 0
      call printf(l:body.result)
      call dap#repl#print(l:body.result)
    else
      let l:node = dap#tree#make_nodes(l:body.variablesReference, '', v:true, 0, l:body.type)
      let l:results = dap#tree#render(a:session, l:node)
      if len(l:results) > 0
        let l:results[0] = l:body.result
      endif
      for l:result in l:results
        call dap#repl#print(l:result)
      endfor
    endif
  endif
endfunction

function! dap#repl#get_send_text()
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  let l:texts = getbufline(s:repl_buf, 1, '$')
endfunction

function! dap#repl#create_new_buf()
  if s:repl_buf == v:null
    belowright new
    setlocal buftype=prompt bufhidden=hide noswapfile
    let s:repl_buf = bufnr()
    setlocal nomodified
    autocmd TextChanged,TextChangedI <buffer> setlocal nomodified
    call prompt_setprompt(s:repl_buf, "DAP> ")
    call prompt_setcallback(s:repl_buf, function("dap#repl#evaluate_callback"))
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
