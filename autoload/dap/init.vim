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
	let l:data = []
	let l:i = 0
	for l:config in s:configs
		call add(l:data, l:i . " - " . l:config.name)
		let l:i = l:i + 1
	endfor
	let l:choice = inputlist(l:data)
	echo "choice: " . l:choice
endfunction
