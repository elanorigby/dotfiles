" Snowflake schema browser for vim-dadbod-ui
" ==========================================
" Browse database -> schema -> table -> columns in a NERDTree-style drawer.
" Schemas also list the objects information_schema.tables does not report --
" semantic views, pipes, stages and procedures -- grouped by type. Views do
" appear in information_schema.tables, so they sit with the tables and keep
" their browsable column list.
" <CR> unfolds each level, the way it does on a NERDTree directory.
"
"   <Leader>d                    open the drawer (the one to reach for)
"   <Leader>db                   same, for Python buffers where jedi-vim
"                                claims <Leader>d for jedi#goto()
"   m  (inside the drawer)       query menu for the table or column under the
"                                cursor -- NERDTree's `m`, with queries
"   x  (inside the drawer)       collapse this node, or its parent -- repeat
"                                to walk back up, as NERDTree's x does
"   F / X / C / D (in drawer)    refresh all / schemas+tables / columns /
"                                database list. Also listed under `?`.
"   :SnowflakeBrowse             open the drawer
"   :SnowflakeRefresh            clear all cached metadata and re-discover
"   :SnowflakeRefreshDbs         re-discover databases only
"   :SnowflakeClearSchemaCache   drop cached schemas/tables only
"   :SnowflakeClearColumnCache   drop cached columns only
"   :SnowflakeSelfTest           check every upstream assumption this file
"                                makes -- run it after :PlugUpdate. Add ! to
"                                include live Snowflake queries.
"
" Everything fetched -- the database list, each database's schemas, tables
" and other objects, and each table's columns -- is cached to disk for 24h from
" when it was fetched, so anything expanded stays instant for the rest of
" the day and survives restarts. :SnowflakeRefresh overrides that.
"
" Three gaps in the stock setup, all patched from this one file so that
" :PlugUpdate never clobbers them:
"
"   1. vim-dadbod-ui has no Snowflake entry in its (script-local) s:schemas
"      dict, so the tree cannot populate. Patched by wrapping the public
"      accessor db_ui#schemas#get().
"   2. vim-dadbod's Snowflake adapter shells out to `snowsql`, whose MFA path
"      is unreliable -- verified failing 3/3 with `250001 Failed to connect`
"      while `snow sql` succeeded against the same account at the same
"      moment. Redirected to `snow`; see after/autoload/snowflake_snow.vim.
"   3. Connections are discovered from `snow` rather than hand-listed.
"
" NOTE: this lives in after/plugin/ rather than plugin_settings.vim on
" purpose. vim-dadbod-ui's plugin/db_ui.vim throws
" `E716: Key not present in Dictionary: "collapsed"` while being sourced by
" plug#end(), which silently aborts the remainder of plugin_settings.vim --
" so anything appended after `call plug#end()` there never runs. That is a
" pre-existing plugin bug, independent of this feature.

if exists('g:loaded_dadbod_snowflake')
  finish
endif
let g:loaded_dadbod_snowflake = 1

if !exists('g:snowflake_dadbod_connection')
  " Named connection from ~/.snowflake/connections.toml. `dev` is
  " DEV_DBT_ROLE; switch to 'sysadmin' for a wider view of the account.
  let g:snowflake_dadbod_connection = 'dev'
endif

" Wider than dadbod-ui's default 40.
let g:db_ui_winwidth = 70

" vim-dadbod's plugin/dadbod.vim gets listed in :scriptnames during startup
" but its globals (g:loaded_dadbod, g:db_adapters) never materialise, so
" db#connect() dies with `E121: Undefined variable: g:db_adapters` and every
" database shows a connection-error mark. Sourcing it explicitly here fixes
" it; the plugin's own g:loaded_dadbod guard makes this a no-op if it did
" load properly.
if !exists('g:loaded_dadbod')
  runtime! plugin/dadbod.vim
endif

" --- 1. Route the snowflake:// scheme at our `snow`-based adapter ----------
" dadbod's documented override point (s:prefix in db/adapter.vim). Necessary
" because after/autoload cannot override a bundled autoload file: the
" bundled path comes first in &runtimepath and wins.
let g:db_adapter_snowflake = 'snowflake_snow#'

" --- 2. Teach dadbod-ui how to introspect Snowflake -----------------------

" Local copy of dadbod-ui's s:results_parser. Duplicated because the
" original is script-local and unreachable; the cost of patching from
" after/ rather than forking the plugin.
function! s:results_parser(results, delimiter, min_len) abort
  if a:min_len ==? 1
    return filter(copy(a:results), '!empty(trim(v:val))')
  endif
  let mapped = map(copy(a:results), {_,row -> filter(split(row, a:delimiter), '!empty(trim(v:val))')})
  if a:min_len > 1
    return filter(mapped, 'len(v:val) ==? '.a:min_len)
  endif
  let counts = map(copy(mapped), 'len(v:val)')
  let min_len = max(counts)
  return filter(mapped, 'len(v:val) ==? '.min_len)
endfunction

" `information_schema` is unqualified so it resolves against the database
" passed as --database -- that is what makes one connection == one Snowflake
" database. parse_results drops row 0: `snow --format csv` always emits a
" header, unlike the TSV the bundled snowsql adapter would have produced.
let s:snowflake = {
      \ 'callable': 'filter',
      \ 'schemes_query': 'select schema_name from information_schema.schemata order by 1',
      \ 'schemes_tables_query': 'select table_schema, table_name from information_schema.tables order by 1,2',
      \ 'parse_results': {results, min_len -> s:results_parser(results[1:], ',', min_len)},
      \ 'default_scheme': '',
      \ 'quote': 1,
      \ 'filetype': 'sql',
      \ 'cell_line_number': 1,
      \ 'cell_line_pattern': '^.*$',
      \ }

" Snapshot the built-in schemes as DATA before redefining the accessor.
" Capturing function('db_ui#schemas#get') does NOT work: a funcref to an
" autoload function resolves by name at call time, so "the original" would
" resolve to our replacement and recurse until maxfuncdepth (verified).
runtime! autoload/db_ui/schemas.vim
if !exists('s:builtin')
  let s:builtin = {}
  for s:scheme in ['postgres', 'postgresql', 'sqlserver', 'mysql', 'mariadb',
        \ 'oracle', 'bigquery', 'clickhouse', 'sqlite', 'duckdb']
    let s:entry = db_ui#schemas#get(s:scheme)
    if !empty(s:entry)
      let s:builtin[s:scheme] = s:entry
    endif
  endfor
endif

function! db_ui#schemas#get(scheme) abort
  if a:scheme ==? 'snowflake'
    return s:snowflake
  endif
  return get(s:builtin, tolower(a:scheme), {})
endfunction

" --- 3. Table helpers -----------------------------------------------------
" Identifiers are quoted because Snowflake is
" uppercase and some columns contain spaces (e.g. "COMPANY ACCOUNT").
let g:db_ui_table_helpers = extend(get(g:, 'db_ui_table_helpers', {}), {
      \ 'snowflake': {
      \   'Columns': 'select column_name, data_type, is_nullable, character_maximum_length
      \     from information_schema.columns
      \     where table_schema=''{schema}'' and table_name=''{table}''
      \     order by ordinal_position',
      \   'List': 'select * from {optional_schema}"{table}" limit 200',
      \   'Describe': 'describe table {optional_schema}"{table}"',
      \   'Row count': 'select count(*) as row_count from {optional_schema}"{table}"',
      \ },
      \ }, 'keep')

" Which schemas to hide from the tree. Empty by default: INFORMATION_SCHEMA
" is 62 views per database and was hidden at first as clutter, but it is
" genuinely useful to browse -- it is how you find out what Snowflake exposes
" about pipes, grants, query history and the rest.
"
" Upstream filters with match(), a substring regex, so an entry like
" 'INFORMATION_SCHEMA' would also hide a schema merely containing that
" string. Anchor entries if you add any: ['^INFORMATION_SCHEMA$'].
"
" Assigned unconditionally: dadbod-ui has already defaulted this to [] by
" the time after/plugin runs, so a get(g:, ...) guard would never fire.
if !exists('g:snowflake_hide_schemas')
  let g:snowflake_hide_schemas = []
endif
let g:db_ui_hide_schemas = g:snowflake_hide_schemas

" --- 4. Inline columns under each table -----------------------------------
" Out of the box, unfolding a table lists the query helpers (List, Columns,
" ...) -- a menu of things to run, so the tree stops being a tree at the
" last level. This makes a table unfold to its actual columns instead, the
" way a NERDTree directory unfolds to files, with the helpers tucked under a
" collapsed "queries" node so they are still one keypress away.
"
" render_tables is script-local on a dict, so it cannot be patched at load
" time -- but db_ui#drawer#get() hands back the live instance, so the method
" is swapped on each drawer as it is created (see the autocmd at the end).

" Show a message *before* a blocking `snow` call and clear it after. Each
" call spawns a fresh process (~2.5s), and vimscript is single-threaded, so
" there is no way to animate a spinner while it runs -- the honest thing is to
" say what is being fetched, then say nothing once it lands.
"
" `redraw` is essential: without it Vim batches the echo and paints it only
" after the call returns, which is precisely when it stops being useful.
function! s:Working(msg) abort
  echohl ModeMsg
  echo 'Snowflake: ' . a:msg . '...'
  echohl None
  redraw
endfunction

function! s:WorkingDone(msg) abort
  " Overwrite rather than leave the stale "fetching..." on screen.
  echo empty(a:msg) ? '' : 'Snowflake: ' . a:msg
endfunction

function! s:FetchColumns(db, schema, table) abort
  let key = 'cols.' . a:db.key_name . '.' . a:schema . '.' . a:table
  let hit = s:CacheGet(key)
  if type(hit) == v:t_list
    return hit
  endif

  let query = printf(
        \ 'select column_name, data_type from information_schema.columns '
        \ . "where table_schema='%s' and table_name='%s' order by ordinal_position",
        \ a:schema, a:table)
  let scheme = db_ui#schemas#get('snowflake')
  let cols = []
  call s:Working('fetching columns for ' . a:schema . '.' . a:table)
  try
    " Same fallback upstream uses: conn once connected, else the raw url.
    let conn = !empty(get(a:db, 'conn', '')) ? a:db.conn : a:db.url
    let raw = db_ui#schemas#query(conn, scheme, query)
    " Drop the CSV header, then split name,type.
    for row in raw[1:]
      let parts = split(row, ',')
      if len(parts) >= 2
        call add(cols, {'name': parts[0], 'type': parts[1]})
      endif
    endfor
  catch /.*/
    " Don't cache a failure -- a transient `snow` hiccup would otherwise
    " persist as "(no columns found)" for a whole day.
    call s:WorkingDone('could not fetch columns for ' . a:schema . '.' . a:table)
    return []
  endtry

  call s:CachePut(key, cols)
  call s:WorkingDone(len(cols) . ' columns in ' . a:schema . '.' . a:table)
  return cols
endfunction

" Replacement for s:drawer.render_tables. Signature and the add() calls for
" table nodes match upstream (drawer.vim render_tables) so expand/collapse
" state and icons keep working; only the expanded body differs.
" The `dict` attribute is required: a plain funcref assigned to a dict key is
" not a method and `self` would be undefined inside it.
" Expansion state for the type groups, keyed '<db>.<schema>.<kind>'. Held
" here rather than on the db object so nothing upstream has to know about it.
let s:group_expanded = {}

" Installed on the drawer as sf_toggle_group, so upstream's call_method
" branch (s:method(item.type) -> drawer[item.type]()) dispatches straight
" here. It takes no arguments, so the group key comes from the cursor line.
function! s:ToggleGroup() abort dict
  let item = self.get_current_item()
  let gkey = get(item, 'sf_group', '')
  if empty(gkey)
    return
  endif
  let s:group_expanded[gkey] = !get(s:group_expanded, gkey, 0)
  return self.render()
endfunction

function! s:RenderTablesWithColumns(tables, db, path, level, schema) abort dict
  if !a:tables.expanded
    return
  endif

  if type(g:Db_ui_table_name_sorter) ==? type(function('tr'))
    let tables_list = call(g:Db_ui_table_name_sorter, [a:tables.list])
  else
    let tables_list = a:tables.list
  endif

  for table in tables_list
    let item = a:tables.items[table]
    " sf_table/sf_schema let the `m` menu identify what is under the cursor
    " without regex-parsing item.type or the display label.
    call self.add(table, 'toggle', a:path . '->' . table,
          \ self.get_toggle_icon('table', item), a:db.key_name, a:level,
          \ { 'expanded': item.expanded, 'sf_table': table, 'sf_schema': a:schema })

    if !item.expanded
      continue
    endif

    " Only Snowflake connections get inline columns; anything else keeps the
    " stock helper list so this patch cannot break another adapter.
    if a:db.scheme ==? 'snowflake'
      let cols = s:FetchColumns(a:db, a:schema, table)
      if empty(cols)
        call self.add('(no columns found)', 'noaction', 'table',
              \ ' ', a:db.key_name, a:level + 1, {})
      else
        " Pad names into a column so types line up.
        let width = max(map(copy(cols), 'len(v:val.name)'))
        for col in cols
          let label = col.name . repeat(' ', width - len(col.name) + 2) . col.type
          call self.add(label, 'noaction', 'table', ' ',
                \ a:db.key_name, a:level + 1,
                \ { 'sf_column': col.name, 'sf_type': col.type,
                \   'sf_table': table, 'sf_schema': a:schema })
        endfor
      endif
    endif

    " Query helpers, still available under the table.
    for [helper_name, helper] in items(a:db.table_helpers)
      call self.add(helper_name, 'open', 'table', g:db_ui_icons.tables,
            \ a:db.key_name, a:level + 1,
            \ { 'table': table, 'content': helper, 'schema': a:schema })
    endfor
  endfor

  " Non-table objects, as sibling groups after the tables. Snowflake schemas
  " hold pipes, stages, semantic views and procedures that
  " information_schema.tables does not report at all -- 125 pipes in
  " SOURCE_DB, 95 semantic views in BRAIN -- so without this they are
  " invisible in the tree.
  if a:db.scheme !=? 'snowflake' || empty(a:schema)
    return
  endif

  let objects = s:FetchObjects(a:db)
  for kind in s:object_kinds
    let names = get(get(objects, kind.key, {}), a:schema, [])
    if empty(names)
      continue
    endif
    let gkey = a:db.key_name . '.' . a:schema . '.' . kind.key
    let is_open = get(s:group_expanded, gkey, 0)
    call self.add(printf('%s (%d)', kind.label, len(names)),
          \ 'call_method', 'sf_toggle_group',
          \ self.get_toggle_icon('tables', {'expanded': is_open}),
          \ a:db.key_name, a:level, {'sf_group': gkey})
    if !is_open
      continue
    endif
    for name in names
      call self.add(name, 'noaction', 'table', ' ', a:db.key_name, a:level + 1,
            \ {'sf_object': name, 'sf_kind': kind.key, 'sf_schema': a:schema})
    endfor
  endfor
endfunction

" Non-table object kinds. information_schema exposes each in its own view
" with its own column names, so the query is a union with per-kind aliases.
" Order here is the order the groups appear under a schema.
" Views are deliberately NOT here: information_schema.tables already reports
" them, so they render as ordinary expandable nodes with their columns
" browsable. Adding a Views group as well listed every view twice.
let s:object_kinds = [
      \ {'key': 'semantic_view', 'label': 'Semantic views',
      \  'sql': "select \"SCHEMA\", \"NAME\" from information_schema.semantic_views"},
      \ {'key': 'pipe',          'label': 'Pipes',
      \  'sql': "select pipe_schema, pipe_name from information_schema.pipes"},
      \ {'key': 'stage',         'label': 'Stages',
      \  'sql': "select stage_schema, stage_name from information_schema.stages"},
      \ {'key': 'procedure',     'label': 'Procedures',
      \  'sql': "select procedure_schema, procedure_name from information_schema.procedures"},
      \ ]

" Fetch every non-table object in a database, grouped as
" {kind: {schema: [names]}}. Cached with the schema/table payload so it costs
" one extra query per database per 24h.
"
" Each kind is queried separately rather than as one UNION: a role without
" privileges on (say) semantic_views makes the whole union fail, and losing
" pipes because semantic views are unreadable would be a poor trade.
function! s:FetchObjects(db) abort
  let key = 'objects.' . a:db.key_name
  let hit = s:CacheGet(key)
  if type(hit) == v:t_dict
    return hit
  endif

  let scheme = db_ui#schemas#get('snowflake')
  let conn = !empty(get(a:db, 'conn', '')) ? a:db.conn : a:db.url
  let out = {}
  let total = 0

  for kind in s:object_kinds
    let out[kind.key] = {}
    try
      let raw = db_ui#schemas#query(conn, scheme, kind.sql . ' order by 1,2')
      for row in raw[1:]
        let parts = split(row, ',')
        if len(parts) < 2
          continue
        endif
        let [sch, name] = [trim(parts[0]), trim(parts[1])]
        if empty(sch) || empty(name)
          continue
        endif
        if !has_key(out[kind.key], sch)
          let out[kind.key][sch] = []
        endif
        call add(out[kind.key][sch], name)
        let total += 1
      endfor
    catch /.*/
      " No privilege on this view, or Snowflake does not expose it in this
      " edition. Leave the kind empty rather than failing the whole fetch.
    endtry
  endfor

  call s:CachePut(key, out)
  return out
endfunction

" Cached replacement for s:drawer.populate_schemas. Upstream fires both
" introspection queries (schemas, then every table in the database) on every
" expand, in every session -- for SOURCE_DB that is 19 schemas and 312 tables
" re-fetched each time. This caches the two result sets together and rebuilds
" the same db.schemas structure from them.
function! s:PopulateSchemasCached(db) abort dict
  let a:db.schemas.list = []
  if empty(a:db.conn)
    return a:db
  endif

  let scheme = db_ui#schemas#get(a:db.scheme)
  let key = 'schemas.' . a:db.key_name
  let cached = a:db.scheme ==? 'snowflake' ? s:CacheGet(key) : v:null

  if type(cached) == v:t_dict && has_key(cached, 'schemas') && has_key(cached, 'tables')
    let schemas = cached.schemas
    let tables = cached.tables
  else
    call s:Working('fetching schemas and objects for ' . a:db.name)
    let schemas = scheme.parse_results(
          \ db_ui#schemas#query(a:db, scheme, scheme.schemes_query), 1)
    let tables = scheme.parse_results(
          \ db_ui#schemas#query(a:db, scheme, scheme.schemes_tables_query), 2)
    call s:WorkingDone(printf('%s: %d schemas, %d tables',
          \ a:db.name, len(schemas), len(tables)))
    if a:db.scheme ==? 'snowflake' && !empty(schemas)
      call s:CachePut(key, {'schemas': schemas, 'tables': tables})
    endif
  endif

  " Below here mirrors upstream populate_schemas.
  let schemas = filter(copy(schemas), {i, v -> !self._is_schema_ignored(v)})
  let tables_by_schema = {}
  for [scheme_name, table] in tables
    if self._is_schema_ignored(scheme_name)
      continue
    endif
    if !has_key(tables_by_schema, scheme_name)
      let tables_by_schema[scheme_name] = []
    endif
    call add(tables_by_schema[scheme_name], table)
    call add(a:db.tables.list, table)
  endfor

  let a:db.schemas.list = schemas
  for schema in schemas
    if !has_key(a:db.schemas.items, schema)
      let a:db.schemas.items[schema] = {
            \ 'expanded': 0,
            \ 'tables': { 'expanded': 1, 'list': [], 'items': {} },
            \ }
    endif
    let a:db.schemas.items[schema].tables.list = sort(get(tables_by_schema, schema, []))
    call self.populate_table_items(a:db.schemas.items[schema].tables)
  endfor
  return a:db
endfunction

" Swap the methods onto each drawer instance as it is created. DBUIOpened
" fires after db_ui#drawer#new(), so the instance exists by now.
function! s:PatchDrawer() abort
  let drawer = db_ui#drawer#get()
  if type(drawer) == v:t_dict && !empty(drawer)
    let drawer.render_tables = function('s:RenderTablesWithColumns')
    let drawer.populate_schemas = function('s:PopulateSchemasCached')
    let drawer.render_help = function('s:RenderHelpWithSnowflake')
    let drawer.sf_toggle_group = function('s:ToggleGroup')
  endif
endfunction

augroup snowflake_dbui_drawer
  autocmd!
  autocmd User DBUIOpened call s:PatchDrawer()
augroup END

" --- 5. Metadata cache ----------------------------------------------------
" One JSON file on disk holding every kind of catalog metadata we fetch:
" the database list, each database's schemas+tables, and each table's
" columns. Entries expire 24h after they were written, so anything you have
" expanded stays instant for the rest of the day and survives vim restarts.
" :SnowflakeRefresh clears the lot; :SnowflakeClearColumnCache just columns.
"
" Keys are 'dbs', 'schemas.<db_key>' and 'cols.<db_key>.<schema>.<table>'.
" Each value is {'at': <unix time>, 'data': <whatever>}.

let s:cache_file = expand('~/.cache/vim/snowflake_catalog.json')
let s:cache_ttl = 24 * 60 * 60
let s:cache = {}
let s:cache_loaded = 0

function! s:CacheLoad() abort
  if s:cache_loaded
    return
  endif
  let s:cache_loaded = 1
  if !filereadable(s:cache_file)
    return
  endif
  try
    let s:cache = json_decode(join(readfile(s:cache_file), "\n"))
    if type(s:cache) != v:t_dict
      let s:cache = {}
    endif
  catch /.*/
    " Corrupt or half-written cache: start over rather than error on startup.
    let s:cache = {}
  endtry
endfunction

function! s:CacheSave() abort
  call mkdir(fnamemodify(s:cache_file, ':h'), 'p')
  call writefile([json_encode(s:cache)], s:cache_file)
endfunction

" Returns the cached data, or v:null when absent or older than the TTL.
function! s:CacheGet(key) abort
  call s:CacheLoad()
  let entry = get(s:cache, a:key, v:null)
  if type(entry) != v:t_dict || !has_key(entry, 'at') || !has_key(entry, 'data')
    return v:null
  endif
  if (localtime() - entry.at) >= s:cache_ttl
    return v:null
  endif
  return entry.data
endfunction

function! s:CachePut(key, data) abort
  call s:CacheLoad()
  let s:cache[a:key] = {'at': localtime(), 'data': a:data}
  call s:CacheSave()
endfunction

" Drop keys matching a prefix ('' clears everything). Returns how many went.
function! s:CacheClear(prefix) abort
  call s:CacheLoad()
  let doomed = empty(a:prefix)
        \ ? keys(s:cache)
        \ : filter(keys(s:cache), 'v:val[0:len(a:prefix)-1] ==# a:prefix')
  for key in doomed
    call remove(s:cache, key)
  endfor
  call s:CacheSave()
  return len(doomed)
endfunction

" --- 6. Discover connections from `snow` ----------------------------------
" No credentials here: `snow` reads ~/.snowflake/connections.toml.

function! s:DiscoverDbs() abort
  " Skips the SNOWFLAKE application db, USER$/personal dbs, dropped-user
  " leftovers and archives -- ordinary databases only.
  let query = "select database_name from information_schema.databases "
        \ . "where database_name not like 'SNOWFLAKE%' "
        \ . "and database_name not like 'USER$%' "
        \ . "and database_name not like 'DROPPED_USER$%' "
        \ . "and database_name not like '%_ARCHIVE' "
        \ . "order by 1"
  " Vim's systemlist() takes a shell string, not an argv list (unlike
  " Neovim's), so each argument is shellescape()d individually.
  let cmd = join(map(['snow', 'sql', '-c', g:snowflake_dadbod_connection,
        \ '--format', 'csv', '-q', query], {_, v -> shellescape(v)}), ' ')
  call s:Working('discovering databases')
  let out = systemlist(cmd)
  if v:shell_error
    echohl WarningMsg
    echomsg 'Snowflake: database discovery failed. Check `snow sql -c '
          \ . g:snowflake_dadbod_connection . ' -q "select 1"`.'
    echohl None
    return []
  endif
  " Drop the CSV header, keep bare uppercase identifiers.
  return filter(map(out[1:], {_, v -> trim(v)}), 'v:val =~# ''^[A-Z0-9_]\+$''')
endfunction

function! s:LoadDbs(force) abort
  let dbs = a:force ? v:null : s:CacheGet('dbs')
  if type(dbs) != v:t_list
    let dbs = s:DiscoverDbs()
    if !empty(dbs)
      call s:CachePut('dbs', dbs)
    else
      " Discovery failed. Fall back to a stale entry if there is one -- an
      " out-of-date drawer beats an empty one.
      call s:CacheLoad()
      let stale = get(s:cache, 'dbs', v:null)
      let dbs = type(stale) == v:t_dict ? get(stale, 'data', []) : []
    endif
  endif

  let g:dbs = {}
  for db in dbs
    let g:dbs[tolower(db)] = 'snowflake:///' . db
  endfor
  return len(dbs)
endfunction

" Nothing is loaded at startup -- not the cache, not the database list.
" Sourcing this file must never touch Snowflake or the cache file, because it
" happens on every `vim`, whatever the file being edited. Reading the cache
" eagerly is not free either: a stale entry falls through to s:DiscoverDbs()
" and blocks startup on `snow sql`, which is exactly the surprise this avoids.
" Everything is deferred to :SnowflakeBrowse, i.e. the session that actually
" wants the drawer.

function! s:Browse() abort
  if empty(get(g:, 'dbs', {}))
    echo 'Snowflake: discovering databases...'
    call s:LoadDbs(0)
    redraw!
  endif
  DBUI
endfunction

command! SnowflakeBrowse call s:Browse()

" Wipe everything and re-discover databases: use after creating a schema or
" table you need to see now, rather than waiting out the 24h TTL. Databases
" reload immediately; schemas, tables and columns refetch as you expand them.
command! SnowflakeRefresh call s:Refresh()
function! s:Refresh() abort
  call s:CacheClear('')
  echomsg 'Snowflake: cache cleared, found ' . s:LoadDbs(1) . ' databases'
endfunction

" Narrower variants, for when only one level has gone stale.
command! SnowflakeRefreshDbs echomsg 'Snowflake: found ' . s:LoadDbs(1) . ' databases'
command! SnowflakeClearColumnCache
      \ echomsg 'Snowflake: dropped ' . s:CacheClear('cols.') . ' cached column lists'
command! SnowflakeClearSchemaCache
      \ echomsg 'Snowflake: dropped ' . s:CacheClear('schemas.') . ' cached schema lists'

" <Leader>d is the one to reach for. <Leader>db does the same thing and is
" the fallback on Python buffers, where jedi-vim installs a buffer-local
" <Leader>d for jedi#goto() that shadows the global mapping.
nnoremap <Leader>d :SnowflakeBrowse<CR>
nnoremap <Leader>db :SnowflakeBrowse<CR>

" --- 7. The `m` query menu ------------------------------------------------
" NERDTree's `m` opens a menu of actions for the node under the cursor. Same
" idea, with the actions being queries: press `m` on a table or a column and
" pick from a list. Mechanism is lifted from
" nerdtree/lib/nerdtree/menu_controller.vim -- grow &cmdheight, echo the list,
" read raw keys with getchar(). The cursor never leaves the drawer, so the
" node under it stays valid for the whole menu.

" Queries per level. `sql` is expanded by us (not by dadbod-ui, whose
" substitution is skipped entirely when there is no table -- query.vim:121).
" Placeholders: {qtable} fully-qualified quoted table, {qcol} quoted column,
" {col} bare column name, {schema}, {table}.
let s:table_menu = [
      \ {'key': 'c', 'text': '(c)olumns', 'label': 'Columns',
      \  'sql': "select column_name, data_type, is_nullable, character_maximum_length\n"
      \       . "from {schema_ref}information_schema.columns\n"
      \       . "where table_schema = '{schema}' and table_name = '{table}'\n"
      \       . "order by ordinal_position"},
      \ {'key': 'p', 'text': '(p)review 200 rows', 'label': 'Preview',
      \  'sql': "select * from {qtable} limit 200"},
      \ {'key': 'r', 'text': '(r)ow count', 'label': 'RowCount',
      \  'sql': "select count(*) as row_count from {qtable}"},
      \ {'key': 'd', 'text': '(d)escribe table', 'label': 'Describe',
      \  'sql': "describe table {qtable}"},
      \ {'key': 'l', 'text': 'DD(l)', 'label': 'DDL',
      \  'sql': "select get_ddl('table', '{schema}.{table}') as ddl"},
      \ {'key': 'g', 'text': '(g)rants', 'label': 'Grants',
      \  'sql': "show grants on table {qtable}"},
      \ {'key': 'i', 'text': 'table (i)nfo -- size, rows, last altered', 'label': 'TableInfo',
      \  'sql': "select table_name, row_count, bytes, created, last_altered\n"
      \       . "from {schema_ref}information_schema.tables\n"
      \       . "where table_schema = '{schema}' and table_name = '{table}'"},
      \ ]

let s:column_menu = [
      \ {'key': 'd', 'text': '(d)istinct values with counts', 'label': 'Distinct',
      \  'sql': "select {qcol} as value, count(*) as rows\n"
      \       . "from {qtable}\ngroup by 1\norder by 2 desc\nlimit 100"},
      \ {'key': 'n', 'text': '(n)ulls and blanks', 'label': 'Nulls',
      \  'sql': "select count(*) as total_rows,\n"
      \       . "       count({qcol}) as non_null,\n"
      \       . "       count(*) - count({qcol}) as nulls,\n"
      \       . "       sum(case when trim(to_varchar({qcol})) = '' then 1 else 0 end) as blanks\n"
      \       . "from {qtable}"},
      \ {'key': 'r', 'text': '(r)ange -- min, max, distinct count', 'label': 'Range',
      \  'sql': "select min({qcol}) as min_value,\n"
      \       . "       max({qcol}) as max_value,\n"
      \       . "       count(distinct {qcol}) as distinct_values\n"
      \       . "from {qtable}"},
      \ {'key': 's', 'text': '(s)ample 100 non-null values', 'label': 'Sample',
      \  'sql': "select {qcol}\nfrom {qtable}\nwhere {qcol} is not null\nlimit 100"},
      \ {'key': 'p', 'text': '(p)rofile -- length stats', 'label': 'Profile',
      \  'sql': "select min(length(to_varchar({qcol}))) as min_len,\n"
      \       . "       max(length(to_varchar({qcol}))) as max_len,\n"
      \       . "       avg(length(to_varchar({qcol}))) as avg_len\n"
      \       . "from {qtable}\nwhere {qcol} is not null"},
      \ {'key': 'w', 'text': '(w)here this column = ...', 'label': 'Where',
      \  'sql': "select *\nfrom {qtable}\nwhere {qcol} = "},
      \ ]

" What is the cursor on? Returns {} when there is no menu for this line.
function! s:MenuContext() abort
  if &filetype !=? 'dbui'
    return {}
  endif
  let drawer = db_ui#drawer#get()
  if type(drawer) != v:t_dict || empty(drawer)
    return {}
  endif
  let item = drawer.get_current_item()
  if type(item) != v:t_dict || !has_key(item, 'sf_table')
    return {}
  endif
  let db = get(drawer.dbui.dbs, item.dbui_db_key_name, {})
  if empty(db)
    return {}
  endif
  return {
        \ 'kind': has_key(item, 'sf_column') ? 'column' : 'table',
        \ 'db': db,
        \ 'schema': item.sf_schema,
        \ 'table': item.sf_table,
        \ 'column': get(item, 'sf_column', ''),
        \ }
endfunction

function! s:ExpandSql(sql, ctx) abort
  let qtable = printf('"%s"."%s"', a:ctx.schema, a:ctx.table)
  let sql = substitute(a:sql, '{qtable}', escape(qtable, '\&~'), 'g')
  let sql = substitute(sql, '{schema}', escape(a:ctx.schema, '\&~'), 'g')
  let sql = substitute(sql, '{table}', escape(a:ctx.table, '\&~'), 'g')
  " information_schema is per-database, so qualify it when the connection is
  " pointed at a different database than the object being inspected.
  let sql = substitute(sql, '{schema_ref}', '', 'g')
  if !empty(a:ctx.column)
    let sql = substitute(sql, '{qcol}', escape('"' . a:ctx.column . '"', '\&~'), 'g')
    let sql = substitute(sql, '{col}', escape(a:ctx.column, '\&~'), 'g')
  endif
  return sql
endfunction

" Deterministic, unlike dadbod-ui's generate_buffer_name which appends a
" timestamp. Without the timestamp, opening the same query for the same object
" twice hits the existing-buffer branch in query.vim:107-115, which switches to
" that buffer and returns without re-running -- the "don't refetch" behaviour.
function! s:BufferName(db, ctx, label) abort
  let parts = [a:db.name, a:ctx.schema, a:ctx.table]
  if !empty(a:ctx.column)
    call add(parts, a:ctx.column)
  endif
  call add(parts, a:label)
  let slug = db_ui#utils#slug(join(parts, '-'))

  let tmp_location = get(db_ui#drawer#get().dbui, 'tmp_location', '')
  let dir = !empty(tmp_location) ? tmp_location : fnamemodify(tempname(), ':p:h')
  let name = printf('%s/%s', dir, slug)

  " Mark it temporary, else the drawer files it under Saved queries
  " (is_tmp_location_buffer, db_ui.vim:390).
  if index(a:db.buffers.tmp, name) ==? -1
    call add(a:db.buffers.tmp, name)
  endif
  return name
endfunction

function! s:RunMenuEntry(entry, ctx) abort
  let sql = s:ExpandSql(a:entry.sql, a:ctx)
  let name = s:BufferName(a:ctx.db, a:ctx, a:entry.label)
  let query = db_ui#drawer#get().get_query()
  call query.open_buffer(a:ctx.db, name, 'edit',
        \ {'table': a:ctx.table, 'schema': a:ctx.schema, 'content': sql})
endfunction

" The menu loop. Ported from nerdtree's MenuController.showMenu: &cmdheight is
" grown so the list fits above the status line, keys are read raw so a unique
" shortcut fires without Enter, and everything is restored in the finally --
" otherwise a stray exception leaves the command line tall for the session.
function! s:ShowMenu() abort
  let ctx = s:MenuContext()
  if empty(ctx)
    echo 'Snowflake: no queries here -- put the cursor on a table or a column.'
    return
  endif

  let entries = ctx.kind ==? 'column' ? s:column_menu : s:table_menu
  let header = ctx.kind ==? 'column'
        \ ? printf('%s.%s.%s', ctx.schema, ctx.table, ctx.column)
        \ : printf('%s.%s', ctx.schema, ctx.table)

  let saved_cmdheight = &cmdheight
  let saved_lazyredraw = &lazyredraw
  let selection = 0
  let chosen = -1

  try
    set nolazyredraw
    let &cmdheight = len(entries) + 3
    while 1
      redraw!
      echo 'Snowflake query menu -- ' . header
      echo 'j/k to move, <CR> to pick, Esc to cancel, or press a shortcut'
      echo repeat('-', 60)
      for i in range(len(entries))
        echo (i ==? selection ? '> ' : '  ') . entries[i].text
      endfor

      let key = nr2char(getchar())
      if key ==? 'j'
        let selection = (selection + 1) % len(entries)
      elseif key ==? 'k'
        let selection = (selection - 1 + len(entries)) % len(entries)
      elseif key ==# nr2char(27)
        break
      elseif key ==# "\r" || key ==# "\n"
        let chosen = selection
        break
      else
        let hits = filter(range(len(entries)), 'entries[v:val].key ==# key')
        if !empty(hits)
          let chosen = hits[0]
          break
        endif
      endif
    endwhile
  finally
    let &cmdheight = saved_cmdheight
    let &lazyredraw = saved_lazyredraw
    redraw!
  endtry

  if chosen >= 0
    call s:RunMenuEntry(entries[chosen], ctx)
  endif
endfunction

nnoremap <silent> <Plug>(SnowflakeMenu) :call <SID>ShowMenu()<CR>

" Install `m` in the drawer only. hasmapto() means a mapping you set yourself
" wins, matching db_ui#utils#set_mapping's opt-out convention.
augroup snowflake_dbui_menu
  autocmd!
  autocmd FileType dbui if !hasmapto('<Plug>(SnowflakeMenu)', 'n')
        \ | silent! nmap <buffer><nowait> m <Plug>(SnowflakeMenu)
        \ | endif
augroup END

" --- 8. Case-insensitive search inside the drawer -------------------------
" Everything in Snowflake is SCREAMING_SNAKE_CASE, so typing /adyen should
" find ADYEN_REPORTS without holding shift.
"
" 'ignorecase' is global-only -- `setlocal ignorecase` is silently accepted
" but sets it globally and leaks into every other buffer (verified). So it is
" toggled on entering a dbui window and restored on leaving, remembering the
" values that were in effect rather than assuming they were off.
"
" Note this also makes the drawer's own `/` searches and the `f`/`t` motions
" case-insensitive, which is the point.

function! s:DrawerCaseEnter() abort
  if exists('s:case_saved')
    return
  endif
  let s:case_saved = {'ignorecase': &ignorecase, 'smartcase': &smartcase}
  " smartcase off too: with it on, searching for an uppercase fragment like
  " /ADYEN would go back to being case-sensitive, and in a drawer of
  " all-uppercase names that is the common case rather than the exception.
  set ignorecase nosmartcase
endfunction

function! s:DrawerCaseLeave() abort
  if !exists('s:case_saved')
    return
  endif
  let &ignorecase = s:case_saved.ignorecase
  let &smartcase = s:case_saved.smartcase
  unlet s:case_saved
endfunction

" Restore is driven off the **leaving*  side rather than the arriving side:
" on WinLeave/BufLeave the drawer is still the current buffer, so &filetype is
" reliably 'dbui'. Testing &filetype on WinEnter does not work -- the event
" fires before the new window's options are in effect, so it still reads
" 'dbui' and the restore never runs (verified: the setting leaked).
augroup snowflake_dbui_case
  autocmd!
  autocmd FileType dbui call s:DrawerCaseEnter()
  autocmd BufEnter,WinEnter * if &filetype ==? 'dbui' | call s:DrawerCaseEnter() | endif
  autocmd BufLeave,WinLeave * if &filetype ==? 'dbui' | call s:DrawerCaseLeave() | endif
  autocmd VimLeavePre * call s:DrawerCaseLeave()
augroup END


" --- 9. Refresh shortcuts, listed in the ? help ---------------------------
" The cache commands were command-line only, which made them easy to forget
" when a newly created schema failed to appear. These bind them to keys in
" the drawer and add them to `?` so they are discoverable in place.
"
" render_help is script-local on the drawer dict, so it is swapped on the
" live instance the same way render_tables and populate_schemas are. It
" reproduces upstream's list (drawer.vim:375) and appends our own -- if
" upstream adds a mapping, this list will not show it until updated here.

function! s:RefreshAndRedraw(what) abort
  if a:what ==# 'all'
    call s:CacheClear('')
    call s:LoadDbs(1)
    let msg = 'everything'
  elseif a:what ==# 'schemas'
    call s:CacheClear('schemas.')
    let msg = 'schemas and tables'
  elseif a:what ==# 'columns'
    call s:CacheClear('cols.')
    let msg = 'columns'
  else
    call s:LoadDbs(1)
    let msg = 'database list'
  endif

  " Clearing the file cache is not enough on its own: dadbod-ui also holds
  " the schema/table lists in memory on each db object, so a db that is
  " already expanded would keep showing the stale tree. Drop that state and
  " collapse everything, so the next expand refetches.
  let drawer = db_ui#drawer#get()
  if type(drawer) == v:t_dict && !empty(drawer)
    for db in values(drawer.dbui.dbs)
      if db.scheme ==? 'snowflake'
        let db.expanded = 0
        let db.schemas = {'expanded': 0, 'list': [], 'items': {}}
        let db.tables = {'expanded': 0, 'list': [], 'items': {}}
      endif
    endfor
    call drawer.render()
  endif
  redraw
  echomsg 'Snowflake: refreshed ' . msg . ' -- expand a database to refetch'
endfunction

function! s:RenderHelpWithSnowflake() abort dict
  if g:db_ui_show_help
    call self.add('" Press ? for help', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
  endif

  if self.show_help
    call self.add('" o - Open/Toggle selected item', 'noaction', 'help', '', '', 0)
    call self.add('" S - Open/Toggle selected item in vertical split', 'noaction', 'help', '', '', 0)
    call self.add('" d - Delete selected item', 'noaction', 'help', '', '', 0)
    call self.add('" R - Redraw', 'noaction', 'help', '', '', 0)
    call self.add('" A - Add connection', 'noaction', 'help', '', '', 0)
    call self.add('" H - Toggle database details', 'noaction', 'help', '', '', 0)
    call self.add('" r - Rename/Edit buffer/connection/saved query', 'noaction', 'help', '', '', 0)
    call self.add('" q - Close drawer', 'noaction', 'help', '', '', 0)
    call self.add('" <C-j>/<C-k> - Go to last/first sibling', 'noaction', 'help', '', '', 0)
    call self.add('" K/J - Go to prev/next sibling', 'noaction', 'help', '', '', 0)
    call self.add('" <C-p>/<C-n> - Go to parent/child node', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>W - (sql) Save currently opened query', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>E - (sql) Edit bind parameters in opened query', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>S - (sql) Execute query in visual or normal mode', 'noaction', 'help', '', '', 0)
    call self.add('" <C-]> - (.dbout) Go to entry from foreign key cell', 'noaction', 'help', '', '', 0)
    call self.add('" <motion>ic - (.dbout) Operator pending mapping for cell value', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>R - (.dbout) Toggle expanded view', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
    call self.add('" --- Snowflake ---', 'noaction', 'help', '', '', 0)
    call self.add('" m - Query menu for the table/column under the cursor', 'noaction', 'help', '', '', 0)
    call self.add('" x - Collapse current node, or its parent (repeat to walk up)', 'noaction', 'help', '', '', 0)
    call self.add('" F - Refresh everything (cache is 24h; use after creating objects)', 'noaction', 'help', '', '', 0)
    call self.add('" X - Refresh schemas and tables', 'noaction', 'help', '', '', 0)
    call self.add('" C - Refresh columns', 'noaction', 'help', '', '', 0)
    call self.add('" D - Refresh the database list', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
  endif
endfunction

nnoremap <silent> <Plug>(SnowflakeRefreshAll)     :call <SID>RefreshAndRedraw('all')<CR>
nnoremap <silent> <Plug>(SnowflakeRefreshSchemas) :call <SID>RefreshAndRedraw('schemas')<CR>
nnoremap <silent> <Plug>(SnowflakeRefreshColumns) :call <SID>RefreshAndRedraw('columns')<CR>
nnoremap <silent> <Plug>(SnowflakeRefreshDbList)  :call <SID>RefreshAndRedraw('dbs')<CR>

augroup snowflake_dbui_refresh
  autocmd!
  autocmd FileType dbui silent! nmap <buffer><nowait> F <Plug>(SnowflakeRefreshAll)
  autocmd FileType dbui silent! nmap <buffer><nowait> X <Plug>(SnowflakeRefreshSchemas)
  autocmd FileType dbui silent! nmap <buffer><nowait> C <Plug>(SnowflakeRefreshColumns)
  autocmd FileType dbui silent! nmap <buffer><nowait> D <Plug>(SnowflakeRefreshDbList)
augroup END

" --- 10. :SnowflakeSelfTest -----------------------------------------------
" Everything in this file patches vim-dadbod-ui from the outside: four methods
" swapped onto the live drawer instance, one autoload function replaced, and a
" handful of upstream internals called directly. None of that is a documented
" API, and dadbod-ui swallows query errors -- so a breaking change upstream
" shows up as an empty or subtly wrong tree rather than an error.
"
" This checks each assumption in a couple of seconds. Run it after
" :PlugUpdate. `:SnowflakeSelfTest!` (with bang) adds live Snowflake queries;
" without the bang it only checks wiring, and makes no network calls.

function! s:TestResult(results, ok, name, detail) abort
  call add(a:results, {'ok': a:ok, 'name': a:name, 'detail': a:detail})
endfunction

function! s:SelfTest(live) abort
  let r = []

  " -- upstream internals we call directly ------------------------------
  for fn in ['db_ui#drawer#get', 'db_ui#schemas#query', 'db_ui#utils#slug',
        \ 'db_ui#table_helpers#get', 'db_ui#schemas#supports_schemes']
    call s:TestResult(r, exists('*' . fn), 'upstream fn ' . fn,
          \ exists('*' . fn) ? '' : 'MISSING -- upstream renamed or removed it')
  endfor

  " -- our adapter is routed and callable -------------------------------
  let routed = get(g:, 'db_adapter_snowflake', '') ==# 'snowflake_snow#'
  call s:TestResult(r, routed, 'adapter routed at snowflake_snow#',
        \ routed ? '' : 'g:db_adapter_snowflake = ' . string(get(g:, 'db_adapter_snowflake', 'unset')))

  let argv = []
  try
    let argv = db#adapter#dispatch('snowflake:///SOURCE_DB', 'filter')
  catch /.*/
    let argv = []
  endtry
  let argv_ok = len(argv) > 2 && argv[0] ==# 'snow' && argv[-1] ==# '-q'
  call s:TestResult(r, argv_ok, 'adapter argv shape',
        \ argv_ok ? join(argv, ' ') : 'got ' . string(argv) . ' -- expected snow ... -q last')

  " -- the schema entry ------------------------------------------------
  let sf = db_ui#schemas#get('snowflake')
  let sf_ok = type(sf) == v:t_dict && has_key(sf, 'schemes_query')
        \ && has_key(sf, 'schemes_tables_query') && has_key(sf, 'parse_results')
  call s:TestResult(r, sf_ok, 'snowflake schema entry',
        \ sf_ok ? '' : 'db_ui#schemas#get("snowflake") returned ' . string(sf))

  " Built-in schemes must still resolve -- our db_ui#schemas#get replacement
  " serves them from a snapshot, so a new upstream scheme silently vanishes.
  let pg = db_ui#schemas#get('postgres')
  call s:TestResult(r, has_key(pg, 'schemes_query'), 'built-in schemes still served',
        \ has_key(pg, 'schemes_query') ? '' : 'postgres entry lost -- check s:builtin snapshot list')

  " -- the four drawer overrides ---------------------------------------
  let drawer = db_ui#drawer#get()
  if type(drawer) != v:t_dict || empty(drawer)
    call s:TestResult(r, 0, 'drawer instance', 'no drawer yet -- open :SnowflakeBrowse first')
  else
    for [meth, want] in [['render_tables', 'RenderTablesWithColumns'],
          \ ['populate_schemas', 'PopulateSchemasCached'],
          \ ['render_help', 'RenderHelpWithSnowflake'],
          \ ['sf_toggle_group', 'ToggleGroup']]
      let got = string(get(drawer, meth, ''))
      let ok = got =~# want
      call s:TestResult(r, ok, 'override ' . meth,
            \ ok ? '' : 'not patched (is ' . got . ') -- DBUIOpened autocmd may not have fired')
    endfor

    " Internals our replacements call on self.
    for meth in ['add', 'get_toggle_icon', 'populate_table_items',
          \ '_is_schema_ignored', 'get_current_item', 'get_query']
      let ok = has_key(drawer, meth)
      call s:TestResult(r, ok, 'drawer.' . meth . ' exists',
            \ ok ? '' : 'MISSING -- our override calls self.' . meth)
    endfor

    " open_buffer is what the `m` menu hands its SQL to.
    let q = drawer.get_query()
    let ok = type(q) == v:t_dict && has_key(q, 'open_buffer')
    call s:TestResult(r, ok, 'query.open_buffer exists',
          \ ok ? '' : 'MISSING -- the m menu cannot open buffers')
  endif

  " -- our own wiring ---------------------------------------------------
  for cmd in ['SnowflakeBrowse', 'SnowflakeRefresh', 'SnowflakeRefreshDbs',
        \ 'SnowflakeClearSchemaCache', 'SnowflakeClearColumnCache']
    call s:TestResult(r, exists(':' . cmd) ==? 2, 'command :' . cmd, '')
  endfor

  let dbs = len(get(g:, 'dbs', {}))
  call s:TestResult(r, dbs > 0, 'g:dbs populated', dbs . ' databases')

  let cache_ok = filereadable(s:cache_file)
  call s:TestResult(r, cache_ok, 'cache file readable',
        \ cache_ok ? s:cache_file : 'absent (fine on a first run)')

  " -- drawer-local mappings -------------------------------------------
  " Only meaningful from inside the drawer; maparg is buffer-scoped.
  if &filetype ==? 'dbui'
    for [k, plug] in [['m', 'SnowflakeMenu'], ['F', 'SnowflakeRefreshAll'],
          \ ['X', 'SnowflakeRefreshSchemas'], ['C', 'SnowflakeRefreshColumns'],
          \ ['D', 'SnowflakeRefreshDbList']]
      let got = maparg(k, 'n')
      let ok = got =~# plug
      call s:TestResult(r, ok, 'mapping ' . k, ok ? '' : 'is ' . string(got))
    endfor
    for [k, plug] in [['o', 'DBUI_SelectLine'], ['q', 'DBUI_Quit'], ['R', 'DBUI_Redraw']]
      let got = maparg(k, 'n')
      let ok = got =~# plug
      call s:TestResult(r, ok, 'upstream mapping ' . k . ' intact', ok ? '' : 'is ' . string(got))
    endfor
  else
    call s:TestResult(r, 1, 'mappings (skipped)', 'run from inside the drawer to check these')
  endif

  " -- live queries (bang only) -----------------------------------------
  if a:live
    let scheme = db_ui#schemas#get('snowflake')
    let url = 'snowflake:///SOURCE_DB'
    try
      let raw = db_ui#schemas#query(url, scheme, scheme.schemes_query)
      let parsed = scheme.parse_results(raw, 1)
      let ok = len(parsed) > 0
      call s:TestResult(r, ok, 'live schemas query',
            \ ok ? len(parsed) . ' schemas, header dropped: '
            \      . (raw[0] =~? 'SCHEMA_NAME' ? 'yes' : 'NO -- parser drift') : 'no rows')
    catch /.*/
      call s:TestResult(r, 0, 'live schemas query', v:exception)
    endtry

    for kind in s:object_kinds
      try
        let raw = db_ui#schemas#query(url, scheme, kind.sql . ' limit 1')
        call s:TestResult(r, 1, 'live ' . kind.key . ' query', 'queryable')
      catch /.*/
        call s:TestResult(r, 0, 'live ' . kind.key . ' query',
              \ 'information_schema view unreadable: ' . v:exception)
      endtry
    endfor

    try
      let raw = db_ui#schemas#query(url, scheme, scheme.schemes_tables_query)
      let parsed = scheme.parse_results(raw, 2)
      let shape_ok = !empty(parsed) && len(parsed[0]) == 2
      call s:TestResult(r, shape_ok, 'live tables query',
            \ shape_ok ? len(parsed) . ' [schema,table] pairs' : 'shape wrong: ' . string(get(parsed, 0, [])))
    catch /.*/
      call s:TestResult(r, 0, 'live tables query', v:exception)
    endtry
  endif

  " -- report ------------------------------------------------------------
  let failed = filter(copy(r), '!v:val.ok')
  echohl Title
  echomsg printf('Snowflake self-test: %d/%d passed%s',
        \ len(r) - len(failed), len(r), a:live ? ' (with live queries)' : ' (wiring only)')
  echohl None
  for t in r
    if t.ok
      echomsg printf('  ok    %s%s', t.name, empty(t.detail) ? '' : '  -- ' . t.detail)
    else
      echohl ErrorMsg
      echomsg printf('  FAIL  %s  -- %s', t.name, t.detail)
      echohl None
    endif
  endfor
  return len(failed)
endfunction

" <bang>0 evaluates to 1 when ! is given, 0 otherwise -- so `!` means live.
command! -bang SnowflakeSelfTest call s:SelfTest(<bang>0)

" --- 11. `x` to collapse, NERDTree-style ----------------------------------
" NERDTree binds x to "close the parent of the node under the cursor" and X to
" "close all children recursively" (nerdtree/plugin/NERD_tree.vim:108-109).
" Here only lowercase x is used for that: uppercase X already refreshes the
" schema cache (section 9), and remapping it would be a worse trade than
" leaving the recursive variant out.
"
" Behaviour matches NERDTree's closeCurrentDir: if the cursor is on an
" expanded node, that node collapses; otherwise its parent collapses and the
" cursor moves there. That makes repeated x walk back up the tree.

function! s:CollapseCurrent() abort
  if &filetype !=? 'dbui'
    return
  endif
  let drawer = db_ui#drawer#get()
  if type(drawer) != v:t_dict || empty(drawer)
    return
  endif

  let index = line('.') - 1
  if index < 0 || index >= len(drawer.content)
    return
  endif
  let item = drawer.content[index]

  " On an expanded node, collapse it in place -- the common case, and what
  " you want after drilling into a schema and being done with it.
  if get(item, 'action', '') ==? 'toggle' && get(item, 'expanded', 0)
    return drawer.toggle_line('')
  endif

  " Otherwise walk up to the parent and collapse that, leaving the cursor on
  " it. Columns and query helpers are level+1 leaves, so this is the path that
  " fires from inside a table.
  if get(item, 'level', 0) <= 0
    " Already at a top-level database: collapse it if open, else nothing to do.
    if get(item, 'action', '') ==? 'toggle' && get(item, 'expanded', 0)
      return drawer.toggle_line('')
    endif
    return
  endif

  call drawer.goto_node('parent')
  let pindex = line('.') - 1
  if pindex < 0 || pindex >= len(drawer.content)
    return
  endif
  let parent = drawer.content[pindex]
  if get(parent, 'action', '') ==? 'toggle' && get(parent, 'expanded', 0)
    call drawer.toggle_line('')
  endif
endfunction

nnoremap <silent> <Plug>(SnowflakeCollapse) :call <SID>CollapseCurrent()<CR>

augroup snowflake_dbui_collapse
  autocmd!
  autocmd FileType dbui silent! nmap <buffer><nowait> x <Plug>(SnowflakeCollapse)
augroup END
