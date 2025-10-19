let s:channel_session = {}
let s:channel_job = {}
let s:stopped_session = []
let s:running_session = []

function OnStdout(channel_id, data)
  let l:messages = dap#utils#parse_messages(a:data)
  let l:session = s:channel_session[a:channel_id]
  for l:message in l:messages
    if l:message.type == 'response'
      call OnResponseStdout(l:session, l:message)
    elseif l:message.type == 'event'
      call OnEventStdout(l:session, l:message)
    endif
  endfor
endfunction

function OnStderr(job_id, data)
endfunction

function OnExit(job_id, data)
endfunction

function! HandelStdout(session, data)
  if has_key(a:session.request_callbacks, data)
  endif
endfunction

function OnResponseStdout(session, message)
	if !a:message.success
		echoerr a:message.message
		echoerr string(a:message.body)
	endif
  call writefile([json_encode(a:message)], 'test.txt', 'a')
  if has_key(a:session.request_callbacks, a:message.request_seq)
    let l:RequestResponse = a:session.request_callbacks[a:message.request_seq]
    call l:RequestResponse(a:session, a:message)
    unlet a:session.request_callbacks[a:message.request_seq]
    unlet l:RequestResponse
  endif
endfunction

function OnEventStdout(session, message)
  call writefile([json_encode(a:message)], 'test.txt', 'a')
  let l:EventReceived = dap#events#get_event_handler(a:message.event)
  if l:EventReceived != v:null
    call l:EventReceived(a:session, a:message)
  endif
endfunction



function! dap#session#create(adapter, config)
  let l:dap_session = {}
  let l:dap_session.seq = 1
  let l:dap_session.request_callbacks = {}
  let l:dap_session.messages = {}
  let l:dap_session.capabilities = {}
  let l:dap_session.adapter = a:adapter
  let l:dap_session.config = a:config
  let l:dap_session.job_ids = []
  let l:dap_session.breakpoints = dap#breakpoints#get_breakpoints()
  let l:dap_session.current_breakpoint_request = 0
  let l:dap_session.variables_request_seq_ref = {}
  let l:dap_session.processes = {}
  let l:dap_session.threads = {}
  let l:dap_session.current_frame = v:null
	let l:dap_session.stopped_thread_id = v:null
  " let l:dap_session.job_to_send = 0
  return l:dap_session
endfunction


function! dap#session#start(session)
  let l:adapter = a:session.adapter
  if l:adapter.type == 'executable'
    call dap#session#spawn(a:session)
    call dap#requests#initialize(a:session, function('dap#requests#response_initialize'))
		call add(s:running_session, a:session)
	elseif l:adapter.type == 'server'
  endif
endfunction

function! dap#session#on_terminated(session)
	let l:adapter = a:session.adapter
	if l:adapter.type == 'executable'
		call dap#session#end_spawned(a:session)
		call dap#session#remove_from_running_sessions(a:session)
	elseif l:adapter.type == 'server'
	endif
endfunction

function! dap#session#remove_from_running_sessions(session)
	let l:session_index = index(s:running_session, a:session)
	call remove(s:running_session, l:session_index)
endfunction

function! dap#session#remove_from_channel(session)
	for l:job in a:session.job_ids
		let l:channel = job_getchannel(l:job)
		if has_key(s:channel_session, l:channel)
			unlet s:channel_session[l:channel]
		endif
	endfor
endfunction

function! dap#session#request(session, command, data)
  if has_key(a:session, 'job_to_send')
    let l:params = {}
    let l:params.seq = a:session.seq
    let l:params.type = 'request'
    let l:params.command = a:command
    let l:params.arguments = a:data
    let l:message_params = dap#utils#create_message(l:params)
    call dap#job#send(a:session.job_to_send, l:message_params)
    let a:session.seq = a:session.seq + 1
  endif
endfunction

function! dap#session#send_request(session, command, data, on_result)
  " if a:session.job_to_send != 0
  let l:current_seq = a:session.seq
  if has_key(a:session, 'job_to_send')
    let a:session.request_callbacks[l:current_seq] = a:on_result
    let a:session.messages[l:current_seq] = {
          \ 'command': a:command,
          \ 'arguments': a:data,
          \ }
    call dap#session#request(a:session, a:command, a:data)
  endif
endfunction

function! dap#session#ask(session, command, data)
  if has_key(a:session, 'job_to_send')
    let l:params = {}
    let l:params.seq = a:session.seq
    let l:params.type = 'request'
    let l:params.command = a:command
    let l:params.arguments = a:data
    let l:message_params = dap#utils#create_message(l:params)
    let l:result = dap#job#eval(a:session.job_to_send, l:message_params)
    let l:result = dap#utils#parse_messages(l:result)
    let l:result = l:result[0]
    let a:session.seq = a:session.seq + 1
    call writefile([json_encode(l:result)], 'test.txt', 'a')
    return l:result
  endif
  return v:null
endfunction

function! dap#session#ask_request(session, command, data)
  let l:current_seq = a:session.seq
  if has_key(a:session, 'job_to_send')
    let a:session.messages[l:current_seq] = {
          \ 'command': a:command,
          \ 'arguments': a:data,
          \ }
    return dap#session#ask(a:session, a:command, a:data)
  endif
endfunction

function! dap#session#add_stopped_session(session)
  call add(s:stopped_session, a:session)
endfunction

function! dap#session#get_stopped_sessions()
  return s:stopped_session
endfunction

function! dap#session#get_running_sessions()
	return s:running_session
endfunction

function! dap#session#terminate_current()
	let l:sessions = dap#session#get_running_sessions()
	for l:session in l:sessions
		call dap#session#terminate(l:session)
	endfor
endfunction

function! dap#session#restart_current()
	let l:sessions = dap#session#get_running_sessions()
	for l:session in l:sessions
		call dap#session#restart(l:session)
	endfor
endfunction

function! dap#session#terminate(session)
	call dap#requests#terminate(a:session, v:false)
endfunction

function! dap#session#restart(session)
	call dap#requests#terminate(a:session, v:true)
endfunction

function! dap#session#spawn(session)
  let l:adapter = a:session.adapter
	let l:config = a:session.config
  if l:adapter is v:null
    throw 'No adapter configured for this new session'
  endif
  let l:command_to = [l:adapter.command] + l:adapter.args
	let l:spawn_params = {
				\ "stdio": [function('OnStdout'), function('OnStderr'), function('OnExit')],
				\ "env": {},
				\ }
	if has_key(l:config, "env")
		let l:spawn_params["env"] = l:config.env
	endif
  let l:job = dap#job#spawn(l:command_to, l:spawn_params)
  let a:session.job_to_send = l:job
  call add(a:session.job_ids, l:job)
  let l:jobinfo = job_info(l:job)
  let s:channel_session[job_getchannel(l:job)] = a:session
endfunction

function! dap#session#end_spawned(session)
	call remove(s:channel_session, job_getchannel(a:session.job_to_send))
	call dap#job#end_spawned(a:session.job_to_send)
	" call dap#session#remove_from_channel(a:session)
endfunction

function OnResult()
endfunction

function! dap#session#step_action(action)
	let l:sessions = dap#session#get_stopped_sessions()
	for l:session in l:sessions
		" for [l:key, l:thread] in items(l:session.threads)
		if l:session.stopped_thread_id != v:null
			let l:thread = l:session.threads[l:session.stopped_thread_id]
			if l:thread.running == v:false
				call dap#requests#step_action(l:session, a:action, l:thread.id, function("dap#requests#response_continue"))
			endif
		endif
		" endfor
	endfor
endfunction

function! dap#session#resume(session)
	let l:session_index = index(s:stopped_session, a:session)
	call remove(s:stopped_session, l:session_index)
endfunction

function! dap#session#set_all_threads_running(session)
	for [l:key, l:thread] in items(a:session.threads)
		let l:thread.running = v:true
	endfor
endfunction

function! dap#session#set_all_threads_stopped(session)
	for [l:key, l:thread] in items(a:session.threads)
		let l:thread.running = v:false
	endfor
endfunction

function! dap#session#start_debug(config, adapter)
	let l:session = dap#session#create(a:adapter, a:config)
	call dap#session#start(l:session)
endfunction
