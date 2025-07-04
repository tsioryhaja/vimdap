function! dap#events#initialized(session, data)
  call dap#requests#set_all_breakpoints(a:session)
endfunction

function! dap#events#output(session, data)
endfunction

function! dap#events#process(session, data)
  let a:session.processes[a:data.body.systemProcessId] = a:data.body
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
  if has_key(a:session.threads, l:stopped.threadId)
    let a:session.threads[l:stopped.threadId].running = v:false
  else
    let a:session.threads[l:stopped.threadId] = {
          \ "id": l:stopped.threadId,
          \ "running": v:false,
          \ }
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

let g:dap_events_handlers = {
      \ "initialized": function('dap#events#initialized'),
      \ "output": function('dap#events#output'),
      \ "process": function('dap#events#process'),
      \ "thread": function('dap#events#thread'),
      \ "stopped": function('dap#events#stopped'),
      \ }

function! dap#events#get_event_handler(event_name)
  if has_key(g:dap_events_handlers, a:event_name)
    return g:dap_events_handlers[a:event_name]
  endif
  return  v:null
endfunction
