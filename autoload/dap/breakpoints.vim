let g:breakpoints = {}

call sign_define('dap-breakpoint', {'text': 'B'})
call sign_define('dap-stopped', {'text': '>'})

let g:exception_breakpoints_filters = "default"
let g:exception_breakpoints_filter_options = v:null

function! dap#breakpoints#get_breakpoints_filters()
  return deepcopy(g:exception_breakpoints_filters)
endfunction

function! dap#breakpoints#set_breakpoints_filters(bp_filters)
  let g:exception_breakpoints_filters = deepcopy(a:bp_filters)
endfunction

function! dap#breakpoints#get_default_breakpoints_filters(session)
  let l:default_filters = []
  for l:d in a:session.capabilities.exceptionBreakpointFilters
    if l:d.default
      call add(l:default_filters, l:d.filter)
    endif
  endfor
  return l:default_filters
endfunction

function! dap#breakpoints#get_possible_breakpoint_filters(session)
  let l:default_filters = []
  for l:d in a:session.capabilities.exceptionBreakpointFilters
    call add(l:default_filters, l:d.filter)
  endfor
  return l:default_filters
endfunction

function! dap#breakpoints#toggle(condition, hit_condition)
  let l:breakpoint_data = dap#breakpoints#get_current_position(a:condition, a:hit_condition)
  call dap#breakpoints#add(g:breakpoints, l:breakpoint_data)
endfunction

function! dap#breakpoints#get_breakpoints()
  return g:breakpoints
endfunction

function! dap#breakpoints#get_current_position(condition, hit_condition)
  let l:bufid = bufnr()
  let l:position = getpos('.')
  let l:line = l:position[1]
  return dap#breakpoints#make_data(l:bufid, l:line, a:condition, a:hit_condition)
endfunction

function! dap#breakpoints#make_data(bufid, line, condition, hit_condition)
  let l:bufpath = bufname(a:bufid)
  let l:bufname = fnamemodify(l:bufpath, ':p:t')
  let l:breakpoint_data = {
        \ "name": l:bufpath,
        \ "buffer": a:bufid,
        \ "source": {
        \   "path": l:bufpath,
        \   "name": l:bufname,
        \   },
        \ "breakpoint": {
        \   "line": a:line
        \   },
        \ }
  if a:condition != v:null
    let l:breakpoint_data.breakpoint.condition = a:condition
  endif
  if a:hit_condition != v:null
    let l:breakpoint_data.breakpoint.hit_condition = a:hit_condition
  endif
  return l:breakpoint_data
endfunction

function! dap#breakpoints#add(container, data)
  let l:bufname = a:data.name
  if !has_key(a:container, l:bufname)
    let a:container[l:bufname] = {
          \ "name": a:data.name,
          \ "buffer": a:data.buffer,
          \ "source": a:data.source,
          \ "breakpoints": []
          \ }
  endif
  call add(a:container[l:bufname].breakpoints, a:data.breakpoint)
  return a:container
endfunction

function! dap#breakpoints#make_set_breakpoints_arguments(data)
  " let l:source = {
  "       \ "name": a:data.source.name,
  "       \ "path": a:data.source.path
  "       \ }
  let l:breakpoints = []
  let l:source = deepcopy(a:data.source)
  for l:bp in a:data.breakpoints
    let l:breakpoint = {"line": l:bp.line}
    let l:breakpoint = deepcopy(l:bp)
    call add(l:breakpoints, l:breakpoint)
  endfor
  let l:result = {
        \ "source": l:source,
        \ "breakpoints": l:breakpoints
        \ }
  return l:result
endfunction
