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

function! dap#requests#set_breakpoints(session, breakpoints, on_result)
  for l:content in a:breakpoints
    let l:source = l:content[0]
    let l:data = l:content[1]
    let l:breakpoint_arguments = dap#breakpoints#make_set_breakpoints_arguments(l:data)
    call writefile([json_encode(l:breakpoint_arguments)], 'test.txt', 'a')
    call dap#session#send_request(a:session, "setBreakpoints", l:breakpoint_arguments, a:on_result)
  endfor
endfunction

function! dap#requests#response_set_breakpoints(session, result)
endfunction

function! dap#requests#set_all_breakpoints(session)
  let l:breakpoints = items(dap#breakpoints#get_breakpoints())
  let a:session.current_breakpoint_request = len(l:breakpoints)
  call dap#requests#set_breakpoints(a:session, l:breakpoints, function("dap#requests#response_set_all_breakpoints"))
endfunction

function! dap#requests#response_set_all_breakpoints(session, result)
  let a:session.current_breakpoint_request = a:session.current_breakpoint_request - 1
  if a:session.current_breakpoint_request <= 0
    call dap#requests#set_exception_breakpoints(a:session, function("dap#requests#response_set_exception_breakpoints"))
  endif
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

function! dap#requests#configuration_done(session, on_result)
  if has_key(a:session.capabilities, "supportsConfigurationDoneRequest")
    if a:session.capabilities.supportsConfigurationDoneRequest
      call dap#session#send_request(a:session, "configurationDone", {}, a:on_result)
    endif
  endif
endfunction


function! dap#requests#response_configuration_done(session, result)
endfunction
