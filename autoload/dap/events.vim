function! dap#events#initialized(session, data)
  call dap#requests#set_all_breakpoints(a:session)
endfunction

function! dap#events#output(session, data)
	let l:body = a:data.body
	if !has_key(l:body, "category")
		let l:body.category = "console"
	endif
	if l:body.category != "telemetry"
		call dap#repl#console_print(l:body.output)
	endif
endfunction

function! dap#events#process(session, data)
  let a:session.processes[a:data.body.systemProcessId] = a:data.body
endfunction

function! dap#events#continued(session, data)
	let l:threadId = a:data.body.threadId
	let a:session.threads[l:threadId].running = v:true
	let a:session.stopped_thread_id = v:null
	if has_key(a:data.body, "allThreadsContinued")
		if a:data.body.allThreadsContinued
			call dap#session#set_all_threads_running(a:session) 
		endif
	endif
endfunction

function! dap#events#thread(session, data)
  let l:result = {
        \ "running": v:true,
        \ "id": a:data.body.threadId,
        \ }
  let a:session.threads[a:data.body.threadId] = l:result
endfunction

functio GetTopFrame(frames)
  for l:frame in a:frames
    if has_key(l:frame, 'source') && type(l:frame.source) == v:t_dict
      return l:frame
    endif
  endfor
  return a:frames[0]
endfunction

function! dap#events#stopped(session, data)
  " echo 'shit'
  let l:stopped = a:data.body
  call dap#session#add_stopped_session(a:session)
	let a:session.stopped_thread_id = l:stopped.threadId
  if has_key(a:session.threads, l:stopped.threadId)
    let a:session.threads[l:stopped.threadId].running = v:false
  else
    let a:session.threads[l:stopped.threadId] = {
          \ "id": l:stopped.threadId,
          \ "running": v:false,
          \ }
  endif
	if has_key(l:stopped, "allThreadsStopped")
		if l:stopped.allThreadsStopped
			call dap#session#set_all_threads_stopped(a:session)
		endif
	endif
  let to_jump = l:stopped.reason != 'pause'
  let l:thread = a:session.threads[l:stopped.threadId]
  let l:response = dap#requests#stack_trace(a:session, l:stopped.threadId)
  let l:stackFrames = l:response.body.stackFrames
  let l:current_frame = GetTopFrame(l:stackFrames)
  let a:session.current_frame = l:current_frame
  call writefile([json_encode(l:current_frame)], 'test.txt', 'a')
  let l:source = l:current_frame.source
  if type(l:source) == v:t_dict
    exec ':keepalt edit +'.l:current_frame.line.' '.l:source.path
    call sign_place(1, 'dap-stopped-group', 'dap-stopped', '%', {'lnum': l:current_frame.line, 'priority': 99})
  endif
endfunction

function! dap#events#exited(session, data)
endfunction

function! dap#events#terminated(session, data)
	call dap#session#on_terminated(a:session)
	call sign_unplace("dap-stopped-group")
	echo "Session Terminated"
endfunction

" use terminated for cleaning session but not exited
let g:dap_events_handlers = {
      \ "initialized": function('dap#events#initialized'),
      \ "output": function('dap#events#output'),
      \ "process": function('dap#events#process'),
      \ "thread": function('dap#events#thread'),
      \ "stopped": function('dap#events#stopped'),
			\ "continued": function('dap#events#continued'),
			\ "terminated": function('dap#events#terminated'),
      \ }

function! dap#events#get_event_handler(event_name)
  if has_key(g:dap_events_handlers, a:event_name)
    return g:dap_events_handlers[a:event_name]
  endif
  return  v:null
endfunction
