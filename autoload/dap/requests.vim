function dap#requests#test()
  echo "test"
endfunction

function! dap#requests#initialize(session, on_result)
  let l:initialize_params = {
        \ 'clientID': 'neovim',
        \ 'clientName': 'neovim',
        \ 'adapterID': 'nvim-dap',
        \ 'pathFormat': 'path',
        \ 'columnsStartAt1': v:true,
        \ 'linesStartAt1': v:true,
        \ 'supportsRunInTerminalRequest': v:true,
        \ 'supportsVariableType': v:true,
        \ 'supportsProgressReporting': v:true,
        \ 'supportsStartDebuggingRequest': v:true
        \ }
  call dap#session#send_request(a:session, 'initialize', l:initialize_params, a:on_result)
endfunction

function! dap#requests#response_initialize(session, result)
  let a:session.capabilities = a:result.body
  let l:config = a:session.config
  call dap#requests#launch_or_attach(a:session, function('dap#requests#response_launch_or_attach'))
endfunction

function! dap#requests#launch_or_attach(session, on_result)
  let l:config = a:session.config
  call dap#session#send_request(a:session, l:config.request, l:config, a:on_result)
endfunction

function! dap#requests#response_launch_or_attach(session, result)
endfunction

function! dap#requests#set_breakpoints(session, breakpoints)
  for l:content in a:breakpoints
    let l:source = l:content[0]
    let l:data = l:content[1]
    let l:breakpoint_arguments = dap#breakpoints#make_set_breakpoints_arguments(l:data)
    call writefile([json_encode(l:breakpoint_arguments)], 'test.txt', 'a')
    " call dap#session#send_request(a:session, "setBreakpoints", l:breakpoint_arguments, a:on_result)
    call dap#session#ask_request(a:session, "setBreakpoints", l:breakpoint_arguments)
  endfor
endfunction

function! dap#requests#response_set_breakpoints(session, result)
endfunction

function! dap#requests#set_all_breakpoints(session)
  let l:breakpoints = items(dap#breakpoints#get_breakpoints())
  call dap#requests#set_breakpoints(a:session, l:breakpoints)
	call dap#requests#set_exception_breakpoints(a:session, function("dap#requests#response_set_exception_breakpoints"))
endfunction

function! dap#requests#set_exception_breakpoints(session, on_result)
  let l:breakpoints_filters = dap#breakpoints#get_breakpoints_filters()
  if l:breakpoints_filters == "default"
    let l:breakpoints_filters = dap#breakpoints#get_default_breakpoints_filters(a:session)
  endif

  if len(l:breakpoints_filters) <= 0
    let l:breakpoints_filters = dap#breakpoints#get_possible_breakpoint_filters(a:session)
  endif
  let l:breakpoints_filters_arguments = {"filters":l:breakpoints_filters}
  call dap#session#send_request(a:session, "setExceptionBreakpoints", l:breakpoints_filters_arguments, a:on_result)
endfunction

function! dap#requests#response_set_exception_breakpoints(session, result)
  call dap#requests#configuration_done(a:session, function("dap#requests#response_configuration_done"))
endfunction

function! dap#requests#response_continue(session, result)
	if a:result.success == v:true
		call s:clear_all_params(a:session)
		call dap#session#resume(a:session)
		if has_key(a:result, "body")
			if has_key(a:result.body, "allThreadsContinued")
				if a:result.body.allThreadsContinued
					call dap#session#set_all_threads_running(a:session) 
				endif
			endif
		endif
		" call s:set_threads_running(a:session)
	endif
endfunction

function! dap#requests#step_action(session, action, threadId, on_result)
	let l:params = {
				\ "threadId": a:threadId
				\ }
	call dap#session#send_request(a:session, a:action, l:params, a:on_result)
endfunction


function s:clear_all_params(session)
	" remove the sign for the stopped
	call sign_unplace("dap-stopped-group")
	call dap#repl#clear_signs()
	call dap#tree#clear_nodes()
endfunction

function s:set_threads_running(session)
	for [l:key, l:thread] in items(a:session.threads)
		if l:thread.running == v:false
			let l:thread.running = v:true
		endif
	endfor
endfunction


function! dap#requests#configuration_done(session, on_result)
  if has_key(a:session.capabilities, "supportsConfigurationDoneRequest")
    if a:session.capabilities.supportsConfigurationDoneRequest
      call dap#session#send_request(a:session, "configurationDone", {}, a:on_result)
    endif
  endif
endfunction


function! dap#requests#response_configuration_done(session, result)
endfunction

function! dap#requests#variables(session, node, on_result)
  let a:session.variables_request_seq_ref[a:session.seq] = a:node
  let l:reference = a:node.reference
  let l:param = {"variablesReference": l:reference}
  call dap#session#send_request(a:session, "variables", l:param, a:on_result)
endfunction

function! dap#requests#response_variables(session, result)
  let l:req_seq = a:result.request_seq
  if has_key(a:session.variables_request_seq_ref, l:req_seq)
    let l:variable = a:session.variables_request_seq_ref[l:req_seq]
    let l:result = []
    for l:d in a:result.body.variables
      let l:node = dap#tree#make_nodes(l:d.variablesReference, l:d.name, v:false, l:variable.level + 1, l:d.type)
      if l:node.expandable == v:false
        let l:node.value = l:d.value
      endif
      call add(l:result, l:node)
    endfor
    let a:session.variables_request_seq_ref[l:req_seq].value = l:result
  endif
endfunction

function! dap#requests#sync_variables(session, node)
  let l:reference = a:node.reference
  let l:params = {"variablesReference": l:reference}
  return dap#session#ask_request(a:session, "variables", l:params)
endfunction

function! dap#requests#stack_trace(session, threadId)
  let l:params = {
        \ "startFrame": 0,
        \ "threadId": a:threadId,
        \ }
  return dap#session#ask_request(a:session, "stackTrace", l:params)
endfunction

function! dap#requests#sync_evaluate(session, expression, context, frameId)
  let l:params = {
        \ "expression": a:expression,
        \ "context": a:context,
        \ "frameId": a:frameId,
        \ }
  return dap#session#ask_request(a:session, "evaluate", l:params)
endfunction

function! dap#requests#terminate(session, restart)
	let l:params = {
				\ "restart": a:restart
				\ }
	return dap#session#ask_request(a:session, "terminate", l:params)
endfunction
