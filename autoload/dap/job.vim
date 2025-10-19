function! dap#job#spawn(commands, params)
	let l:OnStdout = a:params["stdio"][0]
	let l:OnStderr = a:params["stdio"][1]
	let l:OnExit = a:params["stdio"][2]
  if has('job')
    let l:second_params = {'mode': 'raw', 
          \ 'out_cb': {job_id, data -> l:OnStdout(job_id, data)},
          \ 'err_cb': {job_id, data -> l:OnStderr(job_id, data)},
          \ 'exit_cb': {job_id, data -> l:OnExit(job_id, data)},
					\ 'env': a:params.env,
          \ }
    let l:job_id = job_start(a:commands, l:second_params)
    return l:job_id
  else
    throw 'Use VIM with job support'
  endif
endfunction

function! dap#job#end_spawned(job_id)
	call job_stop(a:job_id)
endfunction

function! dap#job#send(job_id, data)
  if has('channel')
    call ch_sendraw(a:job_id, a:data)
  else
    throw 'Use VIM with channel support'
  endif
endfunction

function! dap#job#kill(job_id)
  call job_stop(job_id)
endfunction

function! dap#job#eval(job_id, data)
  if has('channel')
    return ch_evalraw(a:job_id, a:data)
  else
    throw 'Use VIM with channel support'
  endif
endfunction
