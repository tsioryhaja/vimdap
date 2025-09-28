let s:configs = []

function! dap#init#load_configs()
	if filereadable('.dap-adapters.json')
		let l:lines = readfile('.dap-adapters.json')
		let l:content = join(l:lines)
		let s:configs = json_decode(l:content)
	endif
endfunction

function! dap#init#start()
	call dap#init#load_configs()
	let l:data = ["What debugger should we launch"]
	let l:i = 1
	for l:config in s:configs
		call add(l:data, l:i . " - " . l:config.name)
		let l:i = l:i + 1
	endfor
	let l:choice = inputlist(l:data)
	let l:l_choice = len(l:data)
	let l:is_in_range = l:l_choice >= l:choice
	if l:choice > 0 && l:is_in_range
		let l:choice = l:choice - 1
		let l:conf = s:configs[l:choice]
		call dap#session#start_debug(l:conf.configuration, l:conf.adapter)
	endif
endfunction
