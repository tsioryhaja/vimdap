function! dap#tree#make_nodes(reference, name, expanded, level, _type)
  let l:expandable = v:false
  if a:reference > 0
    let l:expandable = v:true
  endif
  return {
        \ "name": a:name,
        \ "expandable": l:expandable,
        \ "expanded": a:expanded,
        \ "reference": a:reference,
        \ "value": v:null,
        \ "level": a:level,
        \ "type": a:_type
        \ }
endfunction

function! dap#tree#render(node)
  let l:result = ""
  let l:i = 0
  let l:children = []
  while l:i <= a:node.level
    let l:result = l:result . " "
  endwhile
  let l:result = l:result . a:node.name . " " . a:node.type . ": "
  let l:value = ""
  if a:node.expandable
    if a:node.expanded
      let l:value = l:value . '[-]'
    else
      let l:value = l:value . '[+]'
    endif
    if a:node.value != v:null
      " call the request to load it here
    else
      for l:child in a:node.value
        let l:c = dap#tree#render(l:child)
        call add(l:children, l:c)
      endfor
    endif
  else
    let l:value = a:node.value
  endif
  let l:result = l:result . l:value
  let l:to_return = [l:result]
  for l:cc in l:children
    call add(l:to_return, l:cc)
  endfor
  return l:to_return
endfunction

