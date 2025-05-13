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

function! dap#events#stopped(session, data)
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
