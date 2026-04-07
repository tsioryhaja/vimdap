let s:repl_buf = v:null
let s:int_write = 0

let s:nodes = []

function! dap#repl#evaluate_callback(text)
  let l:sessions = dap#session#get_stopped_sessions()
  for l:session in l:sessions
    call dap#repl#execute(l:session, a:text, s:repl_buf)
  endfor
endfunction

function! dap#repl#stacktrace_callback()
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  let l:sessions = dap#session#get_stopped_sessions()
  for l:session in l:sessions
		call dap#repl#stack_trace(l:session, s:repl_buf)
  endfor
endfunction

function! dap#repl#scopes_callback()
	if s:repl_buf == v:null
		call dap#repl#create_new_buf()
	endif
	let l:sessions = dap#session#get_stopped_sessions()
	for l:session in l:sessions
		call dap#repl#scopes(l:session, s:repl_buf)
	endfor
endfunction

function! dap#repl#execute(session, text, bufnr)
  if a:session.current_frame == v:null
    return
  endif
  let l:evaluate_result = dap#requests#sync_evaluate(a:session, a:text, "repl", a:session.current_frame.id)
  if l:evaluate_result.success == v:true
    let l:body = l:evaluate_result.body
    if l:body.variablesReference <= 0
      call printf(l:body.result)
			let l:line_count = getbufinfo(a:bufnr)[0].linecount
      call dap#repl#print(l:body.result, l:line_count, bufnr)
    else
      let l:node = dap#tree#make_nodes(l:body.variablesReference, '', v:true, 0, l:body.type, function("dap#tree#load_variable_children"))
      let l:node.rerender = l:node.sign
      let l:results = dap#tree#render(a:session, l:node, l:node.sign)
      if len(l:results) > 0
        let l:results[0] = {"value": l:body.result, "sign": v:null, "signs": []}
      endif
			call dap#repl#print_node_renders(results, a:bufnr)
    endif
  endif
endfunction

function! dap#repl#get_send_text()
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
  let l:texts = getbufline(s:repl_buf, 1, '$')
endfunction

function! dap#repl#trigger_actions_repl(mode)
	call dap#repl#trigger_actions({"mode": a:mode, "buffer": s:repl_buf})
endfunction

function! dap#repl#trigger_actions(parameter)
	let l:session = dap#session#get_stopped_sessions()
	let l:session = l:session[0]
  let l:mode = v:null
	if has_key(a:parameter, 'buffer')
		let l:bufnr = a:parameter.buffer
	else
		let l:bufnr = s:repl_buf
	endif
  if has_key(a:parameter, 'mode')
    let l:mode = a:parameter.mode
  endif
  if l:mode == "anode"
    let l:placed = sign_getplaced(l:bufnr, {"group": "anchor_dapinfo", "lnum": line('.')})
		let l:placed = l:placed[0]
		let l:len_signs = len(l:placed.signs)
		if l:len_signs > 1
			echoerr "weird situation where we hve two anchor on a same line"
		else
			if l:len_signs == 1
				let l:placed_sign = l:placed.signs[0]
				let l:sign_name = l:placed_sign.name
				let l:sign_name = substitute(l:sign_name, "nodeid_", "", "g")
				let l:sign_id = str2nr(l:sign_name)
				" echoerr l:sign_id
				let l:select_node = dap#tree#get_node_by_id(l:sign_id)
				" echoerr string(l:select_node)
				call s:rewrite_node(l:session, l:select_node, l:bufnr)
			endif
		endif
  endif
endfunction

function s:rewrite_node(session, node, bufnr)
	" echoerr string(a:node)
	let l:line = line('.')
	" echoerr string(a:node)
	let l:render_result = dap#tree#render(a:session, a:node, a:node.rerender)
	let l:length = len(l:render_result)
	" echoerr string(l:length)
	let l:i = 0
	for l:line_value in l:render_result
		let l:lnum = l:line + l:i
    let l:placed = sign_getplaced(a:bufnr, {"group": "dapinfo", "lnum": l:lnum})
		let l:placed = l:placed[0]
		for l:sign in l:placed.signs
			call sign_unplace("dapinfo", {"buffer": a:bufnr, "id": l:sign.id})
		endfor
		" echoerr string(l:line_value)
		let l:anchor_placed = sign_getplaced(a:bufnr, {"group": "anchor_dapinfo", "lnum": l:lnum})
		let l:anchor_placed = l:anchor_placed[0]
		for l:sign in l:anchor_placed.signs
			call sign_unplace("anchor_dapinfo", {"buffer": a:bufnr, "id": l:sign.id})
		endfor
		let l:i = l:i + 1
	endfor
	let l:first = l:line
	let l:last = l:first + l:length - 1
	call deletebufline(a:bufnr, l:first, l:last)
	if a:node.expanded
		let a:node.expanded = v:false
	else
		let a:node.expanded = v:true
	endif
	let l:rendered = dap#tree#render(a:session, a:node, a:node.rerender)
	let l:ii = - 1
	for l:to_render in l:rendered
		call dap#repl#print(l:to_render, l:line + l:ii, a:bufnr)
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
    let s:repl_buf = bufnr()
    nmap <buffer> <CR> :call dap#repl#trigger_actions_repl("anode")<CR>
    " let s:repl_buf = bufnr()
    setlocal nomodified
    autocmd TextChanged,TextChangedI <buffer> setlocal nomodified
    call prompt_setprompt(s:repl_buf, "DAP> ")
    call prompt_setcallback(s:repl_buf, function("dap#repl#evaluate_callback"))
  else
    execute "belowright sbuffer" . s:repl_buf
  endif
endfunction

function! dap#repl#console_print(text)
  if s:repl_buf == v:null
    call dap#repl#create_new_buf()
  endif
	call appendbufline(s:repl_buf, "$", a:text)
endfunction

function! dap#repl#print(text, tline, buffer)
  let l:cline = a:tline
  if l:cline != '$'
    let l:cline = l:cline + 1
  endif
  " if s:repl_buf == v:null
  "   call dap#repl#create_new_buf()
  " endif
  call appendbufline(a:buffer, a:tline, a:text.value)
  " echoerr a:text.sign
  if a:text.sign != v:null
    call sign_define(a:text.sign, {"text": "+"})
    " call sign_place(0, 'anchor_dapinfo', a:text.sign, a:buffer, {'lnum': line(l:cline)})
    call sign_place(0, 'anchor_dapinfo', a:text.sign, a:buffer, {'lnum': l:cline})
  endif
  for l:sign_name in a:text.signs
    call sign_define(l:sign_name)
    " call sign_place(0, 'dapinfo', l:sign_name, a:buffer, {'lnum': line(l:cline)})
    call sign_place(0, 'dapinfo', l:sign_name, a:buffer, {'lnum': l:cline})
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
  let l:l_count4 = l:l_count - 4
  let l:l_count2 = l:l_count - 3
  call deletebufline(s:repl_buf, l:l_count4, l:l_count2)
  call appendbufline(s:repl_buf, l:l_count4, "toto")
endfunction

function! dap#repl#clear_signs()
	if s:repl_buf != v:null
		call sign_unplace("*", {"buffer": s:repl_buf})
	endif
endfunction

function! dap#repl#print_node_renders(results, bufnr)
	let l:cline = getbufinfo(a:bufnr)[0].linecount
	let l:i = 0
	for l:result in a:results
		let l:c_line = l:cline + l:i
		call dap#repl#print(l:result, l:c_line, a:bufnr)
		let l:i = l:i + 1
	endfor
endfunction

function! dap#repl#stack_trace(session, bufnr)
	let l:threadId = a:session.stopped_thread_id
	let l:response = dap#requests#stack_trace(a:session, l:threadId)
  let l:stackFrames = l:response.body.stackFrames
  call writefile([json_encode(l:stackFrames)], 'stacktrace.txt', 'a')
	let l:root_node = dap#tree#make_nodes(1, "stack trace", v:true, 0, "", function("dap#tree#load_source_children"))
	let l:root_node.children = []
	for l:stackFrame in l:stackFrames
    if has_key(l:stackFrame, 'source') && type(l:stackFrame.source) == v:t_dict
			let l:name = l:stackFrame.name
			let l:referenceId = l:stackFrame.source.sourceReference
			let l:path = l:stackFrame.source.path
			let l:node = dap#tree#make_nodes(1, l:name, v:true, 1, "", function("dap#tree#load_source_children"))
			let l:child_path = dap#tree#make_nodes(0, "path", v:false, 2, "", function("dap#tree#load_source_children"))
			let l:child_path.value = l:path
			let l:child_line = dap#tree#make_nodes(0, "line", v:false, 2, "", function("dap#tree#load_source_children"))
			let l:child_line.value = l:stackFrame.line
			let l:node.children = [l:child_path, l:child_line]
			call add(l:root_node.children, l:node)
		endif
	endfor
	let l:results = dap#tree#render(a:session, l:root_node, l:root_node.sign)
  call writefile([json_encode(l:results)], 'stacktrace_result.txt', 'a')
	call dap#repl#print_node_renders(l:results, a:bufnr)
endfunction

function! dap#repl#scopes(session, bufnr)
	let l:threadId = a:session.stopped_thread_id
	let l:response = dap#requests#stack_trace(a:session, l:threadId)
  let l:stackFrames = l:response.body.stackFrames
  let l:current_frame = dap#events#get_top_frame(l:stackFrames)
	let l:scopes_response = dap#requests#scopes(a:session, l:current_frame.id)
	let l:scopes = l:scopes_response.body.scopes
	let l:root_node = dap#tree#make_nodes(1, "scopes", v:true, 0, "", function("dap#tree#load_variable_children"))
	let l:root_node.children = []
	for l:scope in l:scopes
		let l:node = dap#tree#make_nodes(l:scope.variablesReference, l:scope.name, v:false, 1, "reference", function("dap#tree#load_variable_children"))
		call add(l:root_node.children, l:node)
	endfor
	let l:results = dap#tree#render(a:session, l:root_node, l:root_node.sign)
	call dap#repl#print_node_renders(l:results, a:bufnr)
endfunction

" TODO: first thing to do is make one for the variables. You need get the scopes
" first and then load the variables from that after wards (look specs for
" request 'scopes' and then type 'Scope' and use the request variable after
" that)
"
" We also need to make the print usable with another buffer
" Use the function getbufinfo(bufnr)[0].linecount
" to get the number of line of a specific buffer
"
" Second thing then we also need to make it so that printing can be done for
" any buffer and not just the repl buffer so that anyone can make their own widgets
