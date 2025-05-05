function! dap#job#spawn(commands, on_stdout, on_stderr, on_exit)
  if has('job')
    let l:second_params = {'mode': 'raw', 
          \ 'out_cb': {job_id, data -> a:on_stdout(job_id, data)},
          \ 'err_cb': {job_id, data -> a:on_stderr(job_id, data)},
          \ 'exit_cb': {job_id, data -> a:on_exit(job_id, data)},
          \ }
    let l:job_id = job_start(a:commands, l:second_params)
    return l:job_id
  else
    throw 'Use VIM with job support'
  endif
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
