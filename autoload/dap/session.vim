let s:jobid_session = {}
let s:process_job = {}
let s:channel_session = {}
let s:channel_job = {}

function OnStdout(channel_id, data)
  " echo s:channel_session[a:job_id]
  " echo s:jobid_session
  " try
  " let l:session = s:channel_session[a:job_id]
  " call writefile([a:data, json_encode(l:shit)], 'test.txt', 'a')
  " catch
  "   " call writefile(['\n', a:data], 'test.txt', 'a')
  "   echo "shit"
  " endtry
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
  " let l:dap_session.job_to_send = 0
  return l:dap_session
endfunction


function! dap#session#start(session)
  let l:adapter = a:session.adapter
  if l:adapter.type == 'executable'
    call dap#session#spawn(a:session)
    call dap#requests#initialize(a:session, function('dap#requests#response_initialize'))
  endif
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
  " if a:session.job_to_send != 0
  let l:current_seq = a:session.seq
  if has_key(a:session, 'job_to_send')
    let a:session.messages[l:current_seq] = {
          \ 'command': a:command,
          \ 'arguments': a:data,
          \ }
    return dap#session#ask(a:session, a:command, a:data)
  endif
endfunction

function! dap#session#spawn(session)
  let l:adapter = a:session.adapter
  if l:adapter is v:null
    throw 'No adapter configured for this new session'
  endif
  let l:command_to = [l:adapter.command] + l:adapter.args
  let l:job = dap#job#spawn(l:command_to, function('OnStdout'), function('OnStderr'), function('OnExit'))
  let a:session.job_to_send = l:job
  call add(a:session.job_ids, l:job)
  let l:jobinfo = job_info(l:job)
  let s:jobid_session[l:job] = a:session
  let s:process_job[l:jobinfo.process] = a:session
  let s:channel_session[job_getchannel(l:job)] = a:session
  let s:channel_job[job_getchannel(l:job)] = l:job
endfunction

" function! dap#session#start(session)
"   call dap#session#spawn(a:session)
"   call dap#requests#initialize(a:session, function('dap#requests#response_initialize'))
" endfunction

function OnResult()
endfunction

function! dap#session#test_run_function()
  " let l:adapter = {'command': 'python', 'args': ['test.py']}
  " echo dap#utils#create_message(l:adapter)
  " let l:Testd = function('dap#requests#test')
  " call l:Testd()
  let l:config = {
        \ 'request': 'launch',
        \ 'program': 'main.py'
        \ }
  let l:adapter = {
        \ 'type': 'executable',
        \ 'command': 'python',
        \ 'args': ['C:\tools\debugpy\bundled\libs\debugpy\adapter']
        \ }
  let l:session = dap#session#create(l:adapter, l:config)
  call dap#session#start(l:session)
  " let l:session = dap#session#create(l:adapter, l:config)
  " call dap#session#spawn(l:session, function('OnResult'))
endfunction
