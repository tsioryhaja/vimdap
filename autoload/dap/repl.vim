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
      call dap#repl#print(l:body.result, line('$'))
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
	let l:session = dap#session#get_stopped_sessions()
  let l:mode = v:null
  if has_key(a:parameter, 'mode')
    let l:mode = a:parameter.mode
  endif
  if l:mode == "anode"
    let l:placed = sign_getplaced(s:repl_buf, {"group": "anchor_dapinfo", "lnum": line('.')})
		let l:placed = l:placed[0]
    " call dap#repl#print({"value": string(l:placed), "sign": v:null})
		let l:len_signs = len(l:placed.signs)
		if l:len_signs > 1
			echoerr "weird situation where we hve two anchor on a same line"
		else
			if l:len_signs == 1
				let l:placed_sign = l:placed.signs[0]
				let l:sign_name = l:placed_sign.name
				let l:sign_name = substitute(l:sign_name, "nodeid_", "", "g")
				let l:sign_id = str2nr(l:sign_name)
				let l:select_node = dap#tree#get_node_by_id(l:sign_id)
				call s:rewrite_node(l:session, l:select_node)
			endif
		endif
  endif
endfunction

function s:rewrite_node(session, node)
	" echoerr string(a:node)
	let l:line = line('.')
	let l:render_result = dap#tree#render(a:session, a:node, a:node.rerender)
	let l:length = len(l:render_result)
	" echoerr string(l:length)
	let l:i = 0
	for l:line_value in l:render_result
		let l:lnum = l:line + l:i
    let l:placed = sign_getplaced(s:repl_buf, {"group": "dapinfo", "lnum": l:lnum})
		let l:placed = l:placed[0]
		for l:sign in l:placed.signs
			call sign_unplace("dapinfo", {"buffer": s:repl_buf, "id": l:sign.id})
		endfor
		" echoerr string(l:line_value)
		let l:anchor_placed = sign_getplaced(s:repl_buf, {"group": "anchor_dapinfo", "lnum": l:lnum})
		let l:anchor_placed = l:anchor_placed[0]
		for l:sign in l:anchor_placed.signs
			call sign_unplace("anchor_dapinfo", {"buffer": s:repl_buf, "id": l:sign.id})
		endfor
		let l:i = l:i + 1
	endfor
	let l:first = l:line
	let l:last = l:first + l:length - 1
	call deletebufline(s:repl_buf, l:first, l:last)
	if a:node.expanded
		let a:node.expanded = v:false
	else
		let a:node.expanded = v:true
	endif
	let l:rendered = dap#tree#render(a:session[0], a:node, a:node.rerender)
	let l:ii = - 1
	for l:to_render in l:rendered
		call dap#repl#print(l:to_render, l:line + l:ii)
		let l:ii = l:ii + 1
	endfor
endfunction

function s:unplace_signs(render_result, line_number)
	let l:i = 0
	for l:line_value in a:render_result
		let l:lnum = a:line_number + l:i
    let l:placed = sign_getplaced(s:repl_buf, {"group": "dapinfo", "lnum": l:lnum})
		let l:placed = l:placed[0]
		for l:sign in l:placed.signs
			call sign_unplace("dapinfo", {"buffer": s:repl_buf, "id": l:sign.id})
		endfor
		let l:anchor_placed = sign_getplaced(s:repl_buf, {"group": "anchor_dapinfo", "lnum": l:lnum})
		let l:anchor_placed = l:anchor_placed[0]
		for l:sign in l:anchor_placed.signs
			call sign_unplace("anchor_dapinfo", {"buffer": s:repl_buf, "id": l:sign.id})
		endfor
		let l:i = l:i + 1
	endfor
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
