function! dap#utils#parse_message(message)
  let l:s_message = split(a:message, '\r\n\r\n')
  if len(l:s_message) != 2
    return {'valid': false, 'error': 'unparsable data'}
  endif
  return json_decode(l:s_message[1])
endfunction

function! dap#utils#create_message(data)
  let l:message_data = json_encode(a:data)
  let l:message_length = len(l:message_data)
  return "Content-Length: " . l:message_length . "\r\n\r\n" . l:message_data
endfunction

function! dap#utils#parse_messages(data)
  let l:splitted = split(a:data, '\r\n\r\n')
  let l:i = 0
  let l:n = len(splitted) - 1
  let l:to_continue = v:true
  let l:current_content_length = 0
  let l:results = []
  while l:to_continue
    let l:current_value = l:splitted[l:i]
    if l:current_content_length > 0
      let l:current_value = l:current_value[l:current_content_length:]
    endif
    let l:current_value = l:current_value[16:-1]
    let l:current_content_length = str2nr(l:current_value)
    let l:i = l:i + 1
    let l:index_to = l:current_content_length - 1
    let l:new_data = l:splitted[l:i]
    let l:decoded = json_decode(l:new_data[0:l:index_to])
    call add(l:results, l:decoded)
    " if len(l:splitted[l:i]) <= l:current_content_length
    "   let l:to_continue = v:false
    " endif
    if l:i >= l:n
      let l:to_continue = v:false
    endif
  endwhile
  return l:results
endfunction
