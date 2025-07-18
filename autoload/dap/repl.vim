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
      let l:node.rerender = l:node.sign
      let l:results = dap#tree#render(a:session, l:node, l:node.sign)
      if len(l:results) > 0
        let l:results[0] = {"value": l:body.result, "sign": v:null, "signs": []}
      endif
      " call dap#repl#print({"value": string(l:results), "sign": v:null})
			let l:cline = line('$')
			let l:i = 0
			for l:result in l:results
				let l:c_line = l:cline + l:i
        call dap#repl#print(l:result, l:c_line)
				let l:i = l:i + 1
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

function! dap#repl#trigger_actions(parameter)
  let l:mode = v:null
  if has_key(a:parameter, 'mode')
    let l:mode = a:parameter.mode
  endif
  if l:mode == "anode"
    let l:placed = sign_getplaced(s:repl_buf, {"group": "dapinfo", "lnum": line('.')})
    call dap#repl#print({"value": string(l:placed), "sign": v:null})
  endif
endfunction

function! dap#repl#create_new_buf()
  if s:repl_buf == v:null
    belowright new
    setlocal buftype=prompt bufhidden=hide noswapfile
    nmap <buffer> <CR> :call dap#repl#trigger_actions({"mode": "anode"})<CR>
    let s:repl_buf = bufnr()
    setlocal nomodified
    autocmd TextChanged,TextChangedI <buffer> setlocal nomodified
    call prompt_setprompt(s:repl_buf, "DAP> ")
    call prompt_setcallback(s:repl_buf, function("dap#repl#evaluate_callback"))
  else
    execute "belowright sbuffer" . s:repl_buf
  endif
endfunction

function! dap#repl#print(text, tline)
  let l:cline = a:tline
  if l:cline != '$'
    let l:cline = l:cline + 1
  endif
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  call appendbufline(s:repl_buf, a:tline, a:text.value)
  " echoerr a:text.sign
  if a:text.sign != v:null
    call sign_define(a:text.sign, {"text": "+"})
    " call sign_place(0, 'anchor_dapinfo', a:text.sign, s:repl_buf, {'lnum': line(l:cline)})
    call sign_place(0, 'anchor_dapinfo', a:text.sign, s:repl_buf, {'lnum': l:cline})
  endif
  for l:sign_name in a:text.signs
    call sign_define(l:sign_name)
    " call sign_place(0, 'dapinfo', l:sign_name, s:repl_buf, {'lnum': line(l:cline)})
    call sign_place(0, 'dapinfo', l:sign_name, s:repl_buf, {'lnum': l:cline})
  endfor
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
