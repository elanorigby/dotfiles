 " :SnowflakeBrowse (or <Leader>db) opens a NERDTree-style Snowflake browser

" Snowflake adapter for vim-dadbod that shells out to the `snow` CLI
" instead of `snowsql`.
"
" Why: snowsql is triggering MFA an annoying amount because
" dadbod-ui uses a new login per query. `snow` reads
" ~/.snowflake/connections.toml and authenticates without MFA.
"
" Wired up in after/plugin/dadbod_snowflake.vim via
"   let g:db_adapter_snowflake = 'snowflake_snow#'
" which is dadbod's documented override point (see s:prefix() in
" vim-dadbod/autoload/db/adapter.vim) -- redefining the bundled autoload
" function does not work, since it wins the runtimepath race.
"
" URLs carry only the database: snowflake:///SOURCE_DB
" Account, user, role and warehouse all come from the named connection.

if !exists('g:snowflake_dadbod_connection')
  let g:snowflake_dadbod_connection = 'dev'
endif

" Database name out of the URL path, e.g. snowflake:///SOURCE_DB -> SOURCE_DB
function! s:database(url) abort
  let parsed = db#url#parse(a:url)
  return substitute(get(parsed, 'path', ''), '^/', '', '')
endfunction

function! s:base(url) abort
  let cmd = ['snow', 'sql', '-c', g:snowflake_dadbod_connection]
  let db = s:database(a:url)
  if !empty(db)
    let cmd += ['--database', db]
  endif
  return cmd
endfunction

" Machine-readable output. `snow` offers only TABLE|JSON|JSON_EXT|CSV --
" no TSV -- so CSV it is, and the parser drops the header row.
" -q must be LAST: db_ui#schemas#query appends the bare query string as the
" final argv element, making this `snow sql ... -q <query>`.
function! snowflake_snow#filter(url) abort
  return s:base(a:url) + ['--format', 'csv', '-q']
endfunction

" Human-facing session: TABLE format is nicer to read.
function! snowflake_snow#interactive(url) abort
  return s:base(a:url) + ['--format', 'table']
endfunction

function! snowflake_snow#input(url, in) abort
  return s:base(a:url) + ['--format', 'table', '-f', a:in]
endfunction

" Skip dadbod's connection probe. db#connect() otherwise runs the adapter
" against an empty temp file to sniff for an auth prompt, and `snow` rejects
" that outright with "No SQL statements found to execute." -- which surfaces
" in the drawer as a connection-error mark against every database.
" Returning v:false short-circuits the probe (see db#connect in
" vim-dadbod/autoload/db.vim); `snow` handles its own auth via
" ~/.snowflake/connections.toml, so there is nothing to probe for.
" Called by db#adapter#call with no arguments, hence the optional signature.
function! snowflake_snow#auth_input(...) abort
  return v:false
endfunction

function! snowflake_snow#complete_database(url) abort
  let cmd = s:base(a:url) + ['--format', 'csv', '-q', 'show terse databases']
  return map(db#systemlist(cmd)[1:], { _, v -> split(v, ',')[1] })
endfunction

function! snowflake_snow#complete_opaque(url) abort
  return snowflake_snow#complete_database(a:url)
endfunction
