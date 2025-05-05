command! TestExec call dap#requests#test()
command! TestFunc call dap#session#test_run_function()
command! Breakpoint call dap#breakpoints#toggle(v:null, v:null)
