function! dap#events#initialized(session, data)
  call dap#requests#set_all_breakpoints(a:session)
endfunction

function! dap#events#output(session, data)
endfunction

let g:dap_events_handlers = {
      \ "initialized": function('dap#events#initialized'),
      \ "output": function('dap#events#output'),
      \ }

function! dap#events#get_event_handler(event_name)
  if has_key(g:dap_events_handlers, a:event_name)
    return g:dap_events_handlers[a:event_name]
  endif
  return  v:null
endfunction
