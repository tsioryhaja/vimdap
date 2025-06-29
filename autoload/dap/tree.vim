let s:nodes = []

function! dap#tree#node_sign_name(id)
  return "nodeid_" . a:id
endfunction

function! dap#tree#store_nodes(node)
  call add(s:nodes, a:node)
  let l:position = len(s:nodes)
  let l:position = l:position - 1
  let l:sign_name = dap#tree#node_sign_name(l:position)
  call sign_define(sign_name)
  return sign_name
endfunction

function! dap#tree#make_nodes(reference, name, expanded, level, _type)
  let l:expandable = v:false
  if a:reference > 0
    let l:expandable = v:true
  endif
  let l:node = {
        \ "name": a:name,
        \ "expandable": l:expandable,
        \ "expanded": a:expanded,
        \ "reference": a:reference,
        \ "value": v:null,
        \ "level": a:level,
        \ "type": a:_type,
        \ "sign": v:null,
        \ "length": 1
        \ }
  if l:expandable == v:true
    let l:node.sign = dap#tree#store_nodes(l:node)
  endif
  return l:node
endfunction

function! dap#tree#render(session, node)
  let l:result = ""
  let l:i = 0
  let l:children = []
  while l:i <= a:node.level
    let l:result = l:result . " "
    let l:i = l:i + 1
  endwhile
  let l:result = l:result . a:node.name . " " . a:node.type . ": "
  let l:value = ""
  if a:node.expandable
    if a:node.expanded
      let l:value = l:value . '[-]'
      if a:node.value == v:null
        let a:node.value = []
        " call the request to load it here
        let l:variables_value = dap#requests#sync_variables(a:session, a:node)
        for l:variable in l:variables_value.body.variables
          let l:new_node = dap#tree#make_nodes(l:variable.variablesReference, l:variable.name, v:false, a:node.level + 1, l:variable.type)
          let l:new_node.value = l:variable.value
          call add(a:node.value, l:new_node)
        endfor
      endif
      for l:child in a:node.value
        let l:c = dap#tree#render(a:session, l:child)
        for l:ch in l:c
          call add(l:children, l:ch)
        endfor
      endfor
    else
      let l:value = l:value . '[+]'
    endif
  else
    let l:value = l:value . a:node.value
  endif
  let l:result = l:result . l:value
  let l:to_return = [{"value": l:result, "sign": a:node.sign}]
  for l:cc in l:children
    call add(l:to_return, l:cc)
  endfor
  let a:node.length = len(l:to_return)
  return l:to_return
endfunction

