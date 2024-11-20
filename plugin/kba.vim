if exists("g:loaded_kba_plugin")
  finish
endif
let g:loaded_kba_plugin = 1

command! -nargs=0 KBACreateHeader call kba#KBACreateHeader()
command! -nargs=0 KBAUpdateHeader call kba#KBAUpdateHeader()

function! kba#KBAFindHeader()
  let boundary = '^---kba-v1---$'
  let created = '^CREATED: \(UNKNOWN\|\d\{8}\)$'
  let updated = '^UPDATED: \d\{8}$'
  let hash = '^HASH: sha256-[0-9a-fA-F]\+$'

  call cursor(0, 0)
  return search(join([boundary, created, updated, hash, boundary], '\n'))
endfunction

function! kba#KBAHasHeader()
  return kba#KBAFindHeader() > 0
endfunction

function! kba#KBAGetHash()
  let start = kba#KBAFindHeader()
  let hash_line = search('^HASH: sha256-[0-9a-fA-F]\+$')

  if hash_line > 0
    let content = getline(hash_line)
    let hash = split(content)[1]
    return hash
  endif
  return -1
endfunction

function! kba#KBASetHash(hash)
  let start = kba#KBAFindHeader()
  let hash_line = search('^HASH: sha256-[0-9a-fA-F]\+$')
  if hash_line > 0
    call setline(hash_line, "HASH: " . a:hash)
  endif
endfunction

function! kba#KBASetUpdated()
  let start = kba#KBAFindHeader()
  let updated_line = search('^UPDATED: \d\{8}$')
  if updated_line > 0
    call setline(updated_line, "UPDATED: " . strftime('%Y%m%d'))
  endif
endfunction

function! kba#KBAGenerateHash()
  call cursor(0, 0)
  let a = search('^---kba-v1---$')
  let b = search('^---kba-v1---$')

  let above = a < b ? a : b
  let below = a < b ? b : a

  let content = []

  call extend(content, getline(0, above - 1))
  call extend(content, getline(below + 1, line('$')))

  let plain_text = escape(join(content), '`')

  return 'sha256-' . trim(system('echo "' . plain_text . '" | sha256sum | cut -f1 -d" "'))
endfunction

function! kba#KBACreateHeader()
  call append(line(0), "---kba-v1---")
  call append(line(0), "HASH: sha256-0")
  call append(line(0), "UPDATED: " . strftime('%Y%m%d'))
  call append(line(0), "CREATED: " . strftime('%Y%m%d'))
  call append(line(0), "---kba-v1---")
  let hash = kba#KBAGenerateHash()
  call kba#KBASetHash(hash)
  call cursor(6, 0)
endfunction

function! kba#KBAAugmentWithHeader()
  call append(line(0), "---kba-v1---")
  call append(line(0), "HASH: sha256-0")
  call append(line(0), "UPDATED: " . strftime('%Y%m%d'))
  call append(line(0), "CREATED: UNKNOWN")
  call append(line(0), "---kba-v1---")
  let hash = kba#KBAGenerateHash()
  call kba#KBASetHash(hash)
endfunction

function! kba#KBAUpdateHeader()
  let pos = getcurpos()
  let has_header = kba#KBAHasHeader()
  if has_header
    let old_hash = kba#KBAGetHash()
    let new_hash = kba#KBAGenerateHash()
    if old_hash != new_hash
      call kba#KBASetHash(new_hash)
      call kba#KBASetUpdated()
      call cursor(pos[1], pos[2])
    endif
  else
    call kba#KBAAugmentWithHeader()
    call cursor(pos[1] + 5, pos[2])
  endif
endfunction
