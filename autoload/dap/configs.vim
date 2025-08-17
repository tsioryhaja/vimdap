let g:adapters = {}
let g:configs = {}

function! dap#configs#create_sesion(configs)
  let l:adapter = a:configs.adapter
  let l:config = a:configs.configuration
  let l:session = dap#session#create(l:adapter, l:config)
endfunction

function! dap#configs#add_adapter(name, language, adapter)
  if !has_key(g:adapters, a:language)
    let g:adapters[a:language] = {}
  endif
  let g:adapters[a:language][a:name] = a:adapter
endfunction

function! dap#configs#add_config(configs)
  let g:configs[a:name] = a:configs
endfunction

