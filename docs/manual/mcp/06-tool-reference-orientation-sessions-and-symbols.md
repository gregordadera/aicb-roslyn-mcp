[AICB - MCP Server](README.md) &middot; chapter 6 of 12

# 6 Tool reference: orientation, sessions and symbols

This chapter documents the MCP tools that orient you on a solution, manage the analysis session, and find individual symbols. It covers three groups:

- **Orientation, operating manual and server introspection** - `docs`, `list_skills`, `server_info`, `list_mcp_profiles`, `usage_report`, `architecture_overview`, `describe_api_surface`
- **Sessions and analysis** - `analyze_solution`, `refresh_session`, `get_diagnostics`, `inspect_session`, `list_sessions`
- **Finding symbols, signatures and single-symbol context** - `find_symbol`, `symbol_signature`, `get_context`, `explain_symbol`

The fan-in and impact tools (`find_usages`, `impact_of_change`, ...), the quality, testing and markup tools, and the multi-query meta-tools `batch` and `measure` are documented in the other tool-reference chapters.

## 6.1 About this chapter

**Session argument.** Most tools here take a `sessionId`. You can pass either the id returned by `analyze_solution` or the absolute path to a solution file (`.sln`, `.slnx` or `.slnf`). When you pass a path, the server analyzes the solution on first use and reuses it afterwards, so `analyze_solution` is optional. If the value is neither a known session id nor an existing solution file, the call fails with a message that says which of the two it was read as and what to do next: a solution path that does not exist is reported as such (and explicitly *not* as an expired session), a solution path on a host that cannot self-initialize points you to `analyze_solution`, and anything else is reported as an unknown or expired session id.

**Tool pool.** The server exposes a curated subset of its tools rather than all of them, because a long tool list measurably degrades an agent's tool choice. `core` tools are unioned into every profile; `extras` are the rest of the default pool; a tool marked "not in the default pool" exists but the active tool set does not expose it. The environment variable `AICB_MCP_TOOLS` (the values `lean` or `all`, or a comma-separated list of tool-class names) is an operator override; the configured profiles are visible through `list_mcp_profiles`, and the active one is pinned at server start with `aicb mcp --mcp-profile <id>`.

**Dispatch through `batch` and `measure`.** Tools marked as dispatchable below can be run as a sub-query of the `batch` and `measure` meta-tools; the others must be called directly.

**Capped lists.** Many tools return `{ items, count, totalFound, truncated }`: `count` is the length of the delivered list, `totalFound` the true total. The caps in this chapter are 100 (`find_symbol`), 50 (`symbol_signature`), 200 (`get_diagnostics`, `describe_api_surface`) and 80 entries per macro section in `architecture_overview`, whose layer map lists up to 2500 types and only per-layer counts above that.

**`nearest`.** When a name resolves to nothing, several tools return the closest declared name instead of a bare empty list, so a typo is distinguishable from a symbol that genuinely has no matches.

**Leading `note`.** A leading `note` field qualifies an answer that would otherwise be misread - above all a zero: the zero gets a denominator (how much was examined at all) and an explanation of which constructs the detector structurally cannot see.

**Writes.** All tools in this chapter are read-only, with two exceptions: `analyze_solution` and `refresh_session` change the in-memory session state. Neither writes files or a database.

| Tool | Purpose | Pool | `batch`/`measure` |
|---|---|---|---|
| `docs` | aicb's own operating manual | core | no |
| `list_skills` | capability map of the server | core | no |
| `server_info` | version, build commit, drift checks | core | no |
| `list_mcp_profiles` | the MCP profiles in the config DB | core | no |
| `usage_report` | server-side tool-call telemetry | core | no |
| `architecture_overview` | bounded whole-solution orientation | extras | yes |
| `describe_api_surface` | public API surface of a solution or namespace | extras | yes |
| `analyze_solution` | analyze and cache a solution | core | no |
| `refresh_session` | re-analyze the session's solution after edits | core | no |
| `get_diagnostics` | compiler errors and warnings without a build | core | yes |
| `inspect_session` | metadata about one cached session | not in the default pool | no |
| `list_sessions` | all currently cached sessions | not in the default pool | no |
| `find_symbol` | find a symbol by name | core | yes |
| `symbol_signature` | signature without the body | core | yes |
| `get_context` | token-budgeted single-symbol slice | core | yes |
| `explain_symbol` | symbol plus a chosen environment | core | yes |

## 6.2 Orientation, operating manual and server introspection

### `docs`

**Purpose.** The aicb operating manual - how to *use* the server, as opposed to what it can tell you about your code. The content is served by the same server that needs explaining. No session and no solution are needed.

**When to use.** Call it when you are new to aicb, when you want to know how a feature is meant to be driven, or when you need the vocabulary used in other answers.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `topics` | `string[]` | no | `null` | Page or route ids. Omit for the directory. A route id expands to its pages in reading order; repeats collapse, so asking for a route and one of its pages yields one copy. Unknown ids are named back to you rather than silently dropped. |

**Pages and routes**

| Id | Content |
|---|---|
| `overview` | What aicb is (and is not): the two products, the four things it deliberately does not do, and the three ways to run it. |
| `install` | Installing aicb and wiring it into a client: the dotnet tool, `aicb init`, and what it writes - the client's `.mcp.json` entry, the agent skill a tool install cannot deliver, and the blocking symbol guard. |
| `first-context` | From a `.sln` to your first context: self-init, then choosing between an overview, a symbol slice and the full export - and why the full export is rarely right. |
| `navigation` | Asking questions about the code: the question-to-tool table, the blast-radius call to make before editing shared code, and where plain text search is still right. |
| `solution-config` | Configuring a solution: layers, exclusions and test detection, the three setup calls, and why to commit the `.aicb.json` sidecar. |
| `glossary` | Glossary: session, facet, MCP profile, snapshot, insight, AI-Builder Markdown, tool pool. |
| `init` (route) | Every page, in reading order - the whole first run. |

**Response.** Markdown. Without `topics` you get the directory: one line per page and per route, each with an estimated size in tokens so you can budget before pulling. The estimate is a real tokenizer count, not a characters-divided-by-four rule of thumb; when no counter is available the size column is simply left out. If a requested id matches nothing, the answer names it and appends the directory.

**Notes and limits**

- If a rendered page suggests a tool that the active tool profile does not expose, a trailing note names those tools and both ways to widen the pool: an MCP profile (see `list_mcp_profiles`) or the `AICB_MCP_TOOLS` environment variable. The rest of the page applies unchanged.
- The same content is available as MCP resources - `acb://docs` for the directory, `acb://docs/{topic}` for a page or route - for clients that prefer attaching context over calling a tool.
- Not dispatchable through `batch`/`measure`.

### `list_skills`

**Purpose.** The server's capability map: a tool index naming *every* tool this server has, each exactly once, grouped by pool state - plus the sections that group tools by name: the always-on navigation core, the task facets (id, guidance, template slot and the facet's tool menu), the cross-cutting guidance styles, and the legacy functional bundles.

**When to use.** To discover specialized long-tail tools beyond the navigation core, and - the one question no other tool answers - to check whether a tool you want is merely outside the active pool rather than nonexistent.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `detail` | `string` | no | `null` (equals `"lean"`) | `"lean"` - bare names in their pool groups; `"full"` - additionally each tool's one-line description. Case-insensitive. |

**Response.** JSON with these fields:

| Field | Content |
|---|---|
| `about` | How to read the index (including the reachability rule below). |
| `tools.inPool.core` | The tools every profile exposes, listed in reach-for-them order, not alphabetically. |
| `tools.inPool.extras` | The rest of what the active tool set exposes right now, alphabetical. |
| `tools.outOfPool` | Tools that exist but are not exposed by the active tool set. |
| `core` | The navigation core section (about text + tool names). |
| `facets` | Each facet with `id`, `title`, `guidance`, `templateSlot` and its tool menu. |
| `styles` | The cross-cutting guidance styles with `id`, `title`, `guidance`. |
| `bundles` | The opt-in bundles with `id`, `title`, `about` and their tools. |
| `uncatalogued` | Registered tools that no facet menu and no bundle names (about text + names). |

In the lean projection each index entry is a bare name; with `detail: "full"` each entry is an object with `name` and `description`.

**Notes and limits**

- A name in `outOfPool` is proof the tool is real, not a denial. It becomes reachable through an MCP profile whose facet menu or bundle names it, or through the `AICB_MCP_TOOLS` override - except an uncatalogued tool, which no menu names, so only the override applies.
- An unknown `detail` value is rejected with the two valid values, rather than silently answered as the default.
- No session needed. Not dispatchable through `batch`/`measure`.

### `server_info`

**Purpose.** Name, version and build commit of the server - a quick reachability check - plus the config DB's schema version. The commit answers the question a version number cannot: *is the binary I am talking to built from the code I just landed?*

**When to use.** To confirm the server is reachable and current, and to diagnose a stale server after a rebuild, an update or a profile change.

**Parameters.** None.

**Response.** Plain text, built from up to seven parts:

1. The identity line: `aicb MCP server (AIContextBuilder) v<version> [(commit <sha>)] - Roslyn-based .NET context generator.` followed by the license notice (`(c) Gregor Dadera - free for private, hobby and educational use and qualifying organizations; see LICENSE.txt.`). A development build can include the full SHA; public release builds deliberately omit it.
2. `Config DB schema: user_version=<n> (<path>).` - a read-only read of the resolved config DB (the same one the DB-bound tools default to), so a post-migration check can read the schema version directly. Omitted when the server is DB-free or the DB is unreadable.
3. **Analyzer drift** - this binary's build commit against the HEAD of the repository holding the analyzed solution. It reports in-sync and ahead too, not only drift. Silent without an analyzed session, and on a repository that does not know this commit (any foreign solution). When git does not answer in time, it says `drift UNKNOWN` instead of staying silent.
4. **Version drift** - this binary against the config DB. It distinguishes a DB newer than this binary from a DB with pending migrations. For tool-pool drift it also distinguishes a profile produced by a newer build (rebuild/reinstall the standalone tool) from retired tool names still stored in the profile (open and save the profile in the GUI). The check is at tool-*name* level; a new parameter on an existing tool is not detected.
5. **Config drift** - the active MCP profile changed since this server started (a GUI edit in the "MCP Profiles" panel, or another process writing the config DB). Remedy: restart or reconnect to load the current skill pool (tools and instructions).
6. **Settings drift** - `SETTINGS DRIFT: usage recording was switched off in the main settings after this server started, and this server still records every tool call. Restart or reconnect the aicb MCP server to apply it.` (or the mirrored `switched on` form): the **Record MCP tool usage** switch in the desktop app's settings changed after this server started.
7. **Skill sync** - one `SKILL:` line per project root of the analyzed sessions that holds aicb skill files (up to four, then a count of the rest): whether the project's aicb skills match what this server serves. A line reads `SKILL: in sync with <profile> (<root>).` when everything matches; otherwise it names the files and the remedy - `out of date for <profile>` (run `aicb skills sync` in the project), `hand-written, not synced` (`aicb skills sync --adopt` takes it over), `edited inside aicb region` (move the edit below the `aicb:user` line, or adopt), or `SKILL: unreadable (...)`. The line of the server's own project starts with `auto sync on (this server rewrites this project's aicb-marked skill files after its first session), `; with automatic skill sync switched off, every line starts with `sync off (main settings), `.

**Notes and limits**

- When a development build reports a commit, compare it against `git rev-parse HEAD`. A version number can be identical across *different* builds; public release builds provide no commit-level comparison.
- Parts 3-7 are omitted when there is nothing to report; the config-DB line is omitted on a DB-free server. The `SKILL` lines appear only once a solution was analyzed, because the project roots come from the analyzed sessions; the probe only reads and never writes a skill file.
- Not dispatchable through `batch`/`measure`.

### `list_mcp_profiles`

**Purpose.** List the MCP profiles in the server's config DB.

**When to use.** To see which profiles exist, which one is active, and how each one narrows the tool set and shapes the rendered output - for example before deciding which profile to pin at server start.

**Parameters.** None.

**Requirements.** The server must be started with `--db-path`. Otherwise the call fails with a clean message: `MCP profiles require a config DB. Start the server with: aicb mcp --db-path <db>.`

**Response.** JSON, one entry per profile:

| Field | Content |
|---|---|
| `id` / `name` | The profile's identifier and display name. |
| `configuredSlots` / `availableSlots` | The configured template slots and the slots available to the profile. `General` appears in the configured set exactly when a profile-wide template is set. |
| `templateId` | The profile-wide template id; `null` means none. |
| `hasSkill` | Whether the profile carries a skill. |
| `toolSelection` | The effective tool set: the class-level CSV, or a `methods:`-prefixed function-name list when the profile curates individual tool functions; `null` means the lean core. |
| `isActive` | Whether this is the active profile. |
| render config | `tokenBudget`, `outputFormat` and `maxOvershootPercent`. A `null` `tokenBudget` or `maxOvershootPercent` means inherit: the template, then the active pipeline profile decides. |

**Notes and limits**

- The five built-in profiles (`mcp-profile/default`, `mcp-profile/full`, `mcp-profile/refactoring-focus`, `mcp-profile/debugging-focus`, `mcp-profile/local`) are listed beside your own, except one you hid in the GUI. A hidden built-in profile is listed when the server is pinned to it, flagged `isActive`.
- There is no runtime switch. Pin the profile at server start:

  ```text
  aicb mcp --mcp-profile <id>
  ```

- Not dispatchable through `batch`/`measure`.

### `usage_report`

**Purpose.** The server-side tool-call telemetry: every `tools/call` invocation the server has recorded into the config DB's `tool_calls` table - cross-client (corpus runs, foreign adopters), not this client's transcript.

**When to use.** To see how often each tool is actually used, how expensive and reliable it is, which clients and protocol eras are in play, and how much of the active tool pool the recorded traffic covers.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `topTools` | `int` | no | `30` | Cap on the per-tool breakdown, ranked by call count; clamped to 1-200. |
| `sinceDays` | `int` | no | `null` | Only count calls from the last N days (omit for the whole log); clamped to 1-3650. Narrows every figure (counts, percentiles, error classes, facets). The applied cutoff comes back as `windowSinceIso`, so an empty window is never mistaken for an empty table. |

**Read the scope first.** The telemetry filter sits on the `tools/call` pipeline only. A sub-query inside `batch` or `measure` records the parent call and no child row of its own - except that a recent-enough parent row carries a per-tool tally of what it dispatched, reported under `subQueries` (see below). A one-shot `aicb call` writes the same row under the client name `aicb-call` when it is given `--db-path`, and nothing without one. Every count here is therefore a **lower bound**, and a tool at 0 was not called *through this door* rather than not called. The response repeats this scope in `recordedVia`.

**Response.** JSON:

| Field | Content |
|---|---|
| `available` / `note` | `false` plus an explanatory note when the server is DB-free or the telemetry table is not readable. |
| `recording` | `"off"` when usage recording is switched off in the desktop app's settings (absent while it is on). The `note` then leads with the explanation: an MCP server or `aicb call` started with it off writes no rows, the figures stop at the last call recorded while it was on (`lastTs`), and when it was switched off is not recorded. |
| Totals | `totalCalls`, `errorCalls`, `errorRatePct`, `distinctTools`, `distinctSessions`, `clientSessions`, `firstTs`, `lastTs`, `clients`, `serverVersions`. `clientSessions` says how many MCP connections the recorded calls came from: `distinct`, `calls` (the calls that carry a connection id) and a `note` on what one id cannot separate - the subagents of one client session share their parent's connection, and `aicb call` and older rows carry no id. Omitted while no call in the window carries one. |
| `tools` | Per tool, ranked by call count: `tool`, `calls`, `errors`, `errorRatePct`, latency (`avgDurationMs`, `p50DurationMs`, `p90DurationMs`, `maxDurationMs`) and result size in characters (`avgResultChars`, `p50ResultChars`, `p90ResultChars`, `maxResultChars`). |
| `errorClasses` | Per tool with errors, a histogram of the exception *types* (e.g. `{"McpException": 3, "ArgumentException": 1}`). `McpException` is a guided failure the tool raised on purpose (expired session, unknown policy token); any other type is a defect suspicion worth chasing. |
| `argumentBindingErrors` | The subset of errors where the *caller* named an argument the tool does not have, so the call never reached the tool. Not derivable from `errorClasses` (the same `ArgumentException` is also what a guard inside a tool raises). Omitted when there were none. |
| `ignoredArgumentCalls` | Per tool: calls that answered although they sent an argument the tool does not have, so that argument had no effect - the success-side twin of `argumentBindingErrors`. Omitted when there were none. |
| `aliasApplied` | How often a tool was called with a parameter's accepted alias instead of its real name, i.e. how often callers were silently corrected. Omitted when that never happened. |
| `protocolVersions` | The share of calls per protocol revision. |
| `clientEras` | The (era × client) cross-tab from the client's own protocol-level identification, capped at 50 groups with `clientEraGroupsTotal` and `clientErasTruncated` disclosing the rest. |
| `preInstrumentationCalls` | Calls recorded before this instrumentation existed. A null protocol version in `protocolVersions` means exactly that - not an unknown client - and belongs in the denominator. |
| `facets` | How often each facet (the task axis of `prepare_task` / `pack_for_task` / `export_markdown`) was addressed. Omitted until a call has addressed one. |
| `poolCoverage` | How much of the *active* tool pool this door's traffic covers: `poolSize`, `poolToolsFired`, `poolToolsNeverCalled`, `neverCalledNote`, `outOfPoolCallsIncluded`, `outOfPoolTools`. |
| `subQueries` | The per-tool tally of sub-queries dispatched through `batch` (uncapped, unlike `tools`). A `measure` sub-query is left out (it runs the tool fully, but the caller consumes the size of the answer, not the answer), and a sub-query naming a tool the dispatch registry does not know is counted under the single literal `(unknown)`. Omitted while nothing has been dispatched. |
| `windowSinceIso` | The applied `sinceDays` cutoff. |

**Notes and limits**

- Read coverage from `poolCoverage`, not from `distinctTools`: that figure counts every tool called, including ones outside the pool, so holding it against the pool size overstates coverage. A name in `poolToolsNeverCalled` was never called *top-level*, which is not the same as never called - hence `neverCalledNote`. The note also names the span the list was measured over - the window cut, the oldest recorded call in it and how long ago that was - because a zero over one day and a zero over months are different statements. An empty window says the span is unknown: the list is unmeasured, not unused.
- The percentiles are the honest read for the right-skewed latency distribution: one warm-up call drags the average.
- This report is **not sufficient on its own for a prune decision**: a tool dispatchable through `batch`/`measure`, or reached by `aicb call` without `--db-path`, can be in real use and still read 0 here.
- Shapes only: no code content, no argument values, no exception *messages* (the type name only), and the session reference is hashed.
- The per-turn client-side view (tool sequences, how often a symbol question went to text search instead) lives in the agent harness's own transcripts, which this server never sees; the two windows differ.
- Not dispatchable through `batch`/`measure`.

### `architecture_overview`

**Purpose.** Orient on a whole solution *without* the firewall of full source. Renders a structural-only AI-Builder-Markdown overview: the macro/architecture graphs (layer map, service and class dependency graphs, role graph, entry points and entry-point flow, architecture flow, interface relations), a domain summary and a quality-hotspots section (the most complex methods and the most-coupled types) - but no per-type or per-file source-code blocks, so it stays bounded where `export_markdown` renders the entire solution.

**When to use.** First contact with an unfamiliar codebase; before a structural change; whenever you need the shape of the solution rather than one symbol. Afterwards, drill in with `get_context` or `explain_symbol`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `lean` | `bool` | no | `true` | Drop the `<AI_CONTEXT_SPEC>` / `<AI_CONTEXT_META>` format-rules preamble and any empty graph sections. `false` renders the full AI-Builder-Markdown document contract. |
| `includeTests` | `bool` | no | `false` | Include test projects. |
| `summaryOnly` | `bool` | no | `false` | Collapse ordinary macro sections to a count plus top-N entries instead of up to 80. The layer map becomes an aggregate with the total and one count per layer. |

**Response.** Markdown. Macro sections are capped at 80 entries with a `+N more` note. The layer map has its own bound: it lists every type up to 2500 types; above that it shows the total and one count per layer - never a sample - and its header names the bound and points to `export_markdown`, which keeps the full map. This keeps even a 200+-project monolith bounded. Method-level call graphs are deliberately omitted (use `call_graph` or `explain_symbol` for a specific symbol).

**The `<TRUNCATION>` block.** When anything was cut, the document leads with a `<TRUNCATION>` block: how many sections were capped, how many entries are shown of how many in total, and one `SECTION: shown of total` row per capped section - a layer map reduced to counts appears as `LAYER_MAP: 0 of N`. Read it before the sections: each `+N more` line states one section's loss, never the whole. No block means nothing was cut.

**Notes and limits**

- **Production-focused.** Test projects are excluded by default, because an architecture overview is otherwise flooded by every test method listed as an entry point plus its flow trace, which is not part of the production architecture. Set `includeTests: true` to include `*.Tests` / `*.Spec` projects in the graphs.
- Use `summaryOnly: true` on extreme solutions (200+ projects, heavy generics) where even the bounded overview would exceed the token cap and would otherwise return nothing.
- Multi-TFM solutions are deduplicated to one declaration per type, the newest target framework's where it has one - otherwise every hotspot and edge would appear once per target framework. A type only an older target framework declares is included, and the coupling counts take the references of every target framework (see "Multi-targeted projects" under "Recurring conventions across the catalog").
- Where the solution holds Visual Basic or F# projects that reference C# projects, the afferent-coupling (Ca) figures count C# references only, and the answer says so and names the projects.
- Recall-safe: works on live *and* recalled sessions. On a recalled session the quality-hotspot line counts are unavailable; complexity is still shown.
- Note: if every project in the solution classifies as a test project and `includeTests` is `false`, the production-focused view has no projects left, so every section derived from types (the macro graphs, entry points, quality hotspots, domain components) is empty by construction - not because the codebase has no architecture. A leading note says so and points to `includeTests: true`. If that classification is wrong, `solution_config_status` reports the test axis, and on a live session `init_solution_config` and `apply_solution_config` set it.
- Dispatchable through `batch`/`measure`.

### `describe_api_surface`

**Purpose.** List the public API surface of a solution or namespace - every externally visible type with its externally visible members (constructors, properties, fields, events, methods, user-defined operators), each as a compact declaration signature. The "header"/contract view: what a consumer of this assembly can actually reference, without the source bodies.

**When to use.** To review a public contract before changing it, to see what an assembly really exposes, or as the baseline for a contract comparison (save a snapshot with `save_session` and compare later with `compare_with_previous`; the dedicated contract-diff tools are outside the default pool).

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `scope` | `string` | no | `"solution"` | `"solution"` covers everything; a namespace prefix (e.g. `MyApp.Contracts`) narrows the surface. |
| `includeInternal` | `bool` | no | `false` | Additionally surface the internal family (`internal` / `private protected`) types and members. |
| `includeTests` | `bool` | no | `false` | Include test projects. |

**Response.** JSON: `scope`, `includeInternal`, an optional `note`, `typesScanned` and `types` (a capped envelope; the true total travels in the envelope). Each type carries `name`, `fullName`, `kind`, `accessibility`, `namespace`, `baseType`, `interfaces` and `members`; each member carries `kind` and `signature`. The type list is capped at 200; members per type are complete.

**Notes and limits**

- A type is included when its *own* declared accessibility is externally visible - `public` or the protected family (reachable by a subclass in another assembly); its members likewise.
- A property renders only the accessors that are themselves visible (`{ get; private set; }` shows as `{ get; }`); a `const` carries its value; an enum is listed as a type (its values are not in the model).
- Events follow the visibility rule of properties and render as their declaration, for example `public event EventHandler? Changed`: an interface event is listed, an explicit interface implementation is not.
- A `scope` prefix that matches no namespace gets a `note` ahead of `typesScanned: 0`, so an empty surface is not read as "nothing is public". The note says where to look instead: the namespace of a type the prefix names, the namespaces that contain the prefix as whole segments, or the closest namespace.
- A `partial` type is folded into one entry: members and interfaces of its declaration fragments are unioned, and a partial method's defining and implementing declarations count once. A multi-targeted type is listed once.
- Two documented simplifications: accessibility is the type's own declared modifier - the effective accessibility through the nesting chain is not computed, so a public member of a type nested in an internal type is still listed; and a type declared with no access modifier is stored as private, so a modifier-omitted (compiler-internal) top-level type is not surfaced even with `includeInternal: true`.
- Production-focused: test projects are excluded by default, because a shipped API surface is production code.
- Recall-safe: reads persisted accessibility and signature facts, so it works on live and recalled sessions.
- Dispatchable through `batch`/`measure`.

## 6.3 Sessions and analysis

### `analyze_solution`

**Purpose.** Analyze a C#/.NET solution with Roslyn and cache it for the session. Returns the `sessionId` used by the other tools.

**When to use.** Call it explicitly when you want the analysis up front, want to control which configuration applies (layer profile, config DB), or want the returned session metadata. It is optional: every session-taking tool accepts the absolute solution path directly and analyzes the solution on first use.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `solutionPath` | `string` | yes | - | Absolute path to the solution file to analyze (e.g. `C:\src\MyApp\MyApp.sln`). |
| `layerProfile` | `string` | no | `null` | Absolute path to a layer-mapping profile JSON. |
| `dbPath` | `string` | no | `null` | Absolute path to a config/master DB. |

**`layerProfile`.** Omit it to use the config DB's active layer profile (per-solution over app-global) when a config DB is resolved, else the `.aicb.json` sidecar's profile, else role-based heuristics. If the file you pass parses but contains no layer-mapping profile at all (no rules, no id, no name - the fingerprint of a schema-foreign file such as the `.aicb.json` sidecar passed by mistake), the call fails with an actionable error instead of silently degrading to heuristics. If you meant the sidecar, omit `layerProfile` - its layer profile is resolved automatically. Precedence: explicit profile > DB > sidecar > heuristics.

**`dbPath`.** When given:

- the DB's active namespace-exclusion list is applied during analysis (the same as the GUI and CLI);
- the DB's active test-detection profile (per-solution > global > default) is resolved for the session, so the test-aware tools honor it;
- and - unless an explicit `layerProfile` is given - the DB's active layer-mapping profile drives the analysis (dependency-graph layers and the layer map), matching the insights/metrics/CLI-gate path.

The layer profile, the exclusions and the test profile travel with the session, so downstream tools do not need `dbPath` again, and a later refresh re-analyzes with the layer profile and the exclusions. Omit `dbPath` to use the server's default config DB (the same one the GUI uses), if the server resolved one. Without any database the sidecar applies per axis, and where it is silent the defaults: the built-in exclusion list, the default test heuristic, role-based layers.

**Response.** JSON with these fields:

| Field | Content |
|---|---|
| `sessionId` | The id to pass to the other tools. |
| `solutionPath`, `solutionName` | The analyzed solution. |
| `projectCount` | Number of projects. |
| `fileSetHash` | The file-set hash used by `refresh_session` to detect changes. |
| `layerProfile` | The layer profile that applied. |
| `analyzePreferredTfmOnly` | Present only when `true`: the `.aicb.json` asked for the preferred target framework only, so `projectCount` counts one instance per logical project instead of one per target framework. |
| `lastAccessUtc` | Last access timestamp (ISO 8601). |
| `origin` | `Live` (fresh Roslyn run, line numbers intact) or `Recalled` (rehydrated from a stored snapshot, no live workspace, no line numbers). |
| `lineNumbersAvailable` | Whether line numbers are available for this session. |
| `configInit` | Present when a configuration axis (layer / exclusions / test) has not yet been initialized through the guided setup. |
| `agentWiring` | Present only when there is something to say about the calling agent's symbol-guard installation. |
| `designTimeBuildCache` | Present only when the design-time build of this load was not stored in the design-time-build cache: it gives the reason, and that the next load of this solution runs the design-time build again. A build that ran without a project's targeting pack is never stored, and a cached build of that kind is set aside instead of reused, so the remedy for a missing pack takes effect. |
| `notAnalysed` | Present only when the solution holds Visual Basic or F# projects: `projectCount` counts the C# projects the analysis walked, and this names the others, which are not analysed (see "Visual Basic and F# projects" under "Recurring conventions across the catalog"). Omitted on a recalled session. |

**`configInit`** carries `layerProfileNeedsInit`, `exclusionListNeedsInit`, `testProfileNeedsInit`, `anyUninitialized`, `hint`, the per-axis `autoInitLayer` / `autoInitExclusions` / `autoInitTest` flags (omitted while `false`), and a `directive` when at least one axis is both opted into auto-initialization and still uninitialized. Note the polarity: these flags mean *needs init*, while `solution_config_status` reports the same three axes as *initialized* - the opposite sense. The hint points to `solution_config_status`, then `init_solution_config` and `apply_solution_config`; the result is persisted to the DB and to the `.aicb.json` sidecar next to the `.sln`.

**Notes and limits**

- **Progress.** A client that sends a progress token receives progress notifications during a long analysis. The progress channel is bound by the protocol, not a parameter you pass.
- A load failure is translated into an actionable message rather than a generic invocation error. The most common cause is a project that targets a newer SDK/TFM or a platform SDK (Windows SDK, Windows App SDK, Aspire) that the analyzer's build host cannot load. A load refused because `global.json` pins an SDK that is not installed names the pin, the SDKs installed for the dotnet the build host actually uses, and the `rollForward` value that would admit one.
- **Project files.** A `TargetFrameworks` list with spaces after the semicolons or a trailing semicolon loads every target framework as a build does, on Windows, Linux and macOS. A file the build lists twice is compiled once, so it causes no false duplicate-definition errors. MSBuild item, property and metadata names spelled in another letter case are read as MSBuild reads them.
- **What is read.** Every C# source file of the loaded projects, committed `*.Designer.cs` and `*.g.cs` files included; files in build output (a project's `obj/` and `bin/` folders and its intermediate and output directories) are not. A file named `AssemblyInfo.cs` is not read as source; the assembly-level attributes it applies still count as type references. A folder named `bin`, `obj` or `.vs` that *contains* the project - a checkout under `~/bin/repo`, say - is the checkout's location, not build output, so such a solution is analysed normally on every operating system.
- **Platform.** The projects are loaded at the platform the sidecar key `designTimeBuildPlatform` names, if the solution file names it; without it, a solution that defines no `Any CPU` platform is loaded at the platform its default configuration builds its C# projects at, when they agree on one. `get_diagnostics` reports which (see there).
- Writes session state only - no files, no database. Not dispatchable through `batch`/`measure`.

### `refresh_session`

**Purpose.** Re-analyze the session's solution after *your* code edits. Without it, tools such as `find_usages`, `impact_of_change`, `list_insights` or `get_context` may keep answering from the stale pre-edit graph - a silent source of wrong results.

**When to use.**

1. You changed `.cs` files.
2. Call `refresh_session`.
3. Continue with the fan-in, quality or context tools.

Also call it with `force: true` after a restore or build that was meant to repair unresolved references.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `force` | `bool` | no | `false` | Re-analyze even when no source file has changed. |

**Response.** JSON: `changed`, `reason`, `session` (the same session metadata block `analyze_solution` returns) and `mode`. `mode` names the path the re-analysis took: `"incremental"` (document texts replayed - and added or removed C# files applied - into the warm snapshot, no MSBuild reload) or `"full-reload"`. It is absent when nothing was re-analyzed.

**Notes and limits**

- Cheap to call speculatively: a file-set hash check skips the expensive Roslyn re-run when nothing actually changed, and a C# file whose timestamp moved while its text stayed the snapshot's (a save without an edit) does not count as a change either.
- An edit of a `.cshtml` or `.razor` file counts as a change too: the call reports `changed: true` and re-analyzes with a full reload.
- An added, renamed or removed `.cs` file is applied to the live solution without an MSBuild reload when the files around it show which project compiles it; `mode` is then `incremental` and `reason` says `applied to the live solution, no MSBuild reload`. Where that is not clear, or when a `.xaml`, `.razor`, `.cshtml` or project file was added or removed, the full reload runs and the reason says so. Adding a project to or removing one from the `.sln`, `.slnx` or `.slnf` is seen as well: an unforced call then re-analyzes, and `reason` says that the project list changed; saving the solution file without changing its project list counts as no change. An ordinary full reload (not `force`, not a restore) also reuses what it can, and `reason` says how many documents were reused from the previous run.
- That check reads *source* files. A restore that rewrote a project's `project.assets.json` after the session was loaded is seen as well: the call then reloads through MSBuild and its `reason` names the project. A build alone is not seen. After one, an analysis that reported unresolved references retries once by itself; `force: true` is the deterministic way to demand it. It costs a full MSBuild reload, so leave it `false` for the normal after-an-edit refresh.
- `mode` is the only indicator when the incremental path stops engaging: answers stay correct, calls just get slow again.
- Note: when nothing was re-analyzed but the session's last analysis was incomplete, the answer carries a note explaining that a restore/build repairs that without touching a source file, and telling you to call again with `force: true`.
- Reuses the warm workspace. A recalled session has no live workspace and is rejected with a message pointing to `refresh_remembered` or `analyze_solution`.
- Writes session state only - no files, no database. Not dispatchable through `batch`/`measure`.

### `get_diagnostics`

**Purpose.** A fast pre-build gate: the compiler errors and warnings of the session's solution in seconds instead of a full `dotnet build`.

**When to use.** After editing `.cs` files, as a quick correctness check before you build or run anything. The recommended order is `refresh_session` first, then `get_diagnostics`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `severityFloor` | `string` | no | `"auto"` | Minimum severity to include: `"auto"`, `"error"`, `"warning"`, `"info"` or `"hidden"`. `"auto"` counts warnings as `"warning"` does, but when the compile has errors it lists only the errors, and `warningsNotListed` says how many warnings it left out of the list; `"warning"` lists both. |
| `scope` | `string` | no | `"solution"` | `"solution"` or a file-path substring (e.g. `MyApp.Core` or `Services/`) that filters the result. |
| `runSuppressors` | `bool` | no | `false` | Run the DiagnosticSuppressors that the projects' analyzer references declare, as a real build does, so a diagnostic they suppress is not counted. Off by default, because a suppressor is code of the analyzed solution and runs inside the server; the answer's `suppressors` member says where it would matter. |

**Order matters.** The diagnostics are compiled from the *session's* document snapshot, not from the files on disk. Under auto-refresh mode `off` they describe the pre-edit source - a freshly written error can answer `errorCount: 0`. Under the shipped `reactive` mode this tool is refreshed for you before it answers, so the explicit `refresh_session` call is redundant rather than wrong; calling it is the spelling that is correct in *every* mode. An answer computed from a graph known to be behind the disk leads with `verdict: "stale"` and `verdictReason` before any count, so reading the pre-edit state deliberately stays possible - it just cannot be mistaken for a clean bill.

**Response.** JSON with these fields:

| Field | Content |
|---|---|
| `verdict` / `verdictReason` | Lead before any count when the answer is not a clean measurement. `"inconclusive"` when a strict majority of scanned projects are incomplete; `"stale"` when the session's graph is behind the disk - edited source files, or a project whose restore rewrote its `project.assets.json` after the session was loaded (the reason names the project; call `refresh_session`, then ask again). If both hold, the wider negation (`inconclusive`) is the single-token verdict and the reason names both. |
| `scope`, `severityFloor` | The echoed request; under the default `auto` the echoed floor reads `"warning"`, the floor the counts are taken at. |
| `projectsScanned` | How many projects were compiled. |
| `errorCount`, `warningCount`, `infoCount` | Counts over the full, uncapped set. |
| `suppressedDiagnosticsTotal` | How many diagnostics the incomplete projects took with them. Present whenever at least one project is incomplete. |
| `warningsNotListed` | Under the default `auto` only, when the compile has errors and warnings: `count` (the warnings counted in `warningCount` but not listed) and a `note` naming `severityFloor: "warning"` to list them; the disclosures, `generatedCodeGaps` among them, still count those warnings. Placed right before `diagnostics`. Omitted whenever the list is the full one. |
| `diagnostics` | The diagnostics, capped at 200 - under the default `auto`, only the errors when there are any; the counts above reflect the full set. Each carries `id` (e.g. `CS0219`), `severity`, `message`, `location` (file:line), `category` and `project`, and `notBuiltBySolution: true` when it comes from a project the solution's build does not build (see `projectsNotBuiltBySolution`). |
| `incompleteProjects` | Projects whose compilation could not resolve its core references: project name, suppressed-diagnostic count, `affectedDependents` (the projects that transitively reference it and inherit the broken chain), and, where the cause is known, `cause` with its remedy - for example a missing targeting pack named with its version, or, for a project the solution itself never builds, the exact `dotnet restore "<project file>"` command, because a restore of the solution skips it. A project that declares no code of its own is not listed here (see `projectsWithoutCode`). |
| `projectsWithoutCode` | Projects that could not resolve their core references but declare no code of their own - a packaging project whose build compiles nothing, for example: `note` and `projects`, each with `project` and `suppressedDiagnostics`. Nothing of them is missing from the analysis, so they count neither in `incompleteProjects` nor in `incompleteRatio` or `suppressedDiagnosticsTotal`, and no restore is needed for them. |
| `referencedProjectsWithoutCode` | Projects that resolved their references but compiled no code while projects referencing them have counted errors: `diagnosticsInAffectedProjects`, a `note` and `projects`. |
| `projectsNotBuiltBySolution` | Counted errors and warnings that come only from projects the solution's default build configuration does not build: `errors`, `warnings`, a `note` and `projects`, each with `project`, `errors`, `warnings` and `infos`. The diagnostics stay in the counts; subtract these to compare with what `dotnet build` of the solution reports. |
| `unloadedProjectReferences` | References to projects in a language this analysis does not load - an F# or Visual Basic project that was never built (with the build command), or a C++ project (with the remedy) - where something of them is missing: `diagnosticsInAffectedProjects`, a `note` and `projects`, one entry per referencing project file. |
| `resourcesWithoutGeneratedClass` | Errors on a class that is the base name of a `.resx` file of the project while no generated class for it exists (no `Name.Designer.cs` beside the file): `errors`, a `note` and `projects`. |
| `languageVersionGap` | `CS8652` errors ("currently in Preview") in projects that do not ask for a preview language version: the code uses a C# version newer than the analyzer's compiler. `errors`, `hostCompiler`, `hostLanguageVersion`, a `note` and `projects`. |
| `incompleteRatio` | The share of incomplete projects among the scanned ones. |
| `cascadeClassifiedCount` | How many of the listed diagnostics are cascade-classified fallout of an incomplete dependency (each such item carries `cascadeFromIncomplete: true`). |
| `referenceBindingAdvisoriesSuppressed` | How many assembly-reference version-float advisories (`CS1701`/`CS1702`) were filtered out. |
| `reliable` | `false` when a strict majority of scanned projects are incomplete. |
| `generatedCodeGaps` | Code that a source generator or the WPF markup compiler writes is missing from a project. A generator reference that points at the output of a solution project built at another configuration or platform than this load builds it at is named as that - kind `not-built`, or a hedged `not-found` where it cannot be told whether the project holds a generator - not as an unrestored package; where the producing project declares no source generator, the reference is not listed at all. |
| `designTimeBuildFailures` | MSBuild reported a failure loading a project (a warning reads alike); its compiler options may be incomplete. A failure is listed under the project file it is about, and `reportedByBuildsOf` names the other project files whose builds reported it; a project whose load failed without sources counts as incomplete. A Visual Studio Web Site entry in a `.sln` (a URL or folder path with no project file) is in most cases not counted as a failure (such a solution is then cached, so its next open is fast); it still is when a loaded project lost a project reference; a missing `.csproj` stays a failure, and Web Site entries in a `.slnx` are not recognized. |
| `unrestoredProjects` | Projects that resolve their core references but have unresolved-name errors (`CS0246`/`CS0234`, and `CS0103`) and no `project.assets.json` where their restore writes it, or one that lacks the project's target framework: `unresolvedNameErrors`, a `note`, and `projects`, each with `project`, `searchedFrom` and `unresolvedNameErrors`, plus `missingTarget` (the target framework the restore output lacks) and `restoreCommand` (the restore that works for this project) where they apply. The note names the repair - `dotnet restore`, and on `NETSDK1147` `dotnet workload restore`; where the solution builds none of the affected projects, it leads with restoring the project file instead of the solution. Nothing is removed from the counts. Omitted when no such project exists. |
| `uninitializedSubmodules` | Git submodules that were never initialized (their folder is empty) while a project with `CS0246`/`CS0234`/`CS0103` errors names a path inside one in its build files (the project file, an import, the nearest `Directory.Build.props`/`.targets`): `unresolvedNameErrors`, a `note`, and `submodules`, each with `path`, `projects` and `unresolvedNameErrors`. Neither a restore nor a build brings those sources; the note names the repair, `git submodule update --init <paths>` in the repository root, then `refresh_session(force: true)`. The notes of `unrestoredProjects` and `generatedCodeGaps` add a sentence when their projects are among these. Omitted when no such submodule exists. |
| `missingCompileItems` | Compile items that a project with counted errors lists while no file exists at that path, so the compilation read each as an empty file - typically a file a pre-build step or a code generator writes that did not run: `errors`, a `note`, and `projects`, one entry per project file (every target framework of a multi-targeted project in one), each with `projectFile`, `projects` (the instance names), `files` (solution-relative, in full outside the solution folder) and `errors`. The note says which errors are likely this and the repair: run the build step, then `refresh_session(force: true)`. Omitted when no such item exists. |
| `designTimeBuildPlatform` | The platform decision of the load: `platform`, `solutionConfiguration`, `solutionPlatforms`, `projectsAtOtherPlatform`, `blockers` and a `note`; `source: "sidecar"` when the sidecar decided, and `refusedSidecarPlatform` when the sidecar value was refused. When the sidecar names a solution platform that maps the projects to another platform name (for example `Win32` built at `x86`), the `note` says so. Present when the load chose a platform, could not choose one, or refused the sidecar's value; `platform` is absent when no single platform could be chosen. Omitted when the solution defines `Any CPU`, builds every C# project at AnyCPU, or could not be read, and the sidecar names no platform. See the note below. |
| `suppressors` | Present when a DiagnosticSuppressor removed a diagnostic, or when an analyzer reference that declares one (NUnit.Analyzers, EF Core and the Razor compiler are common ones) did not run its suppressors in a project the answer counts a diagnostic in; omitted otherwise. `ran` says whether `runSuppressors` was set; `diagnosticsSuppressed` counts what the suppressors removed (per target framework); `notRun` names each reference whose suppressors did not run, with a `reason` and its `projects`; `diagnosticsInAffectedProjects` counts the diagnostics in those projects, where a real build may report fewer - a magnitude, not a verdict; `note` says what each half means. Without `runSuppressors`, the references are found by reading their metadata only, which runs none of their code. |

**Notes and limits**

- **`#pragma`-suppressed diagnostics are excluded**; `[SuppressMessage]` on a compiler warning changes nothing, as in a real build. Diagnostics that a DiagnosticSuppressor removes in a real build are counted unless you pass `runSuppressors: true` (see `suppressors`). A multi-targeted project that compiles the same source under several target frameworks reports each diagnostic once (deduplicated by id + location + message), not once per framework.
- **Incomplete projects are disclosed, not listed.** A project whose compilation cannot resolve its core references (`System.Object` missing - a targeting pack not installed for that TFM, or an unrestored project) would otherwise flood with thousands of bogus cascade errors. It is not listed as findings but appears under `incompleteProjects`. The same holds for a project whose .NET, ASP.NET Core, Windows Desktop or netstandard2.1 targeting pack is missing: it is reported as incomplete with the missing pack named in its `cause`, the remedy is `dotnet restore` followed by `refresh_session(force: true)`, and the design-time build cache does not keep such a build. A freshly created, never-built worktree reports *every* project there until it is built once - that is the unrestored state, not a defect, and one `dotnet restore` / `dotnet build` makes the fast gate work for the rest of the session.
- **Design-time build platform.** A solution that defines no `Any CPU` platform is loaded at the platform its default configuration builds its C# projects at, when they agree on one; where they do not, each project is loaded at its own default platform (AnyCPU for an SDK-style project), the `note` says why, and `blockers` lists the projects that prevented a choice where there are such projects. To set the platform yourself, put `"designTimeBuildPlatform": "x64"` into the solution's `.aicb.json` sidecar - a platform as the solution's configuration manager names it, such as `x64`, `ARM64` or `Any CPU`. A value the solution file does not name (as a solution platform, or as a platform it maps a C# project to), or one under which the solution maps its projects to several platforms, is refused and disclosed, and the automatic choice applies. The value is read on every full reload, so after editing it call `refresh_session` with `force: true`; an unforced refresh after an edit of the sidecar alone keeps the platform the session was loaded at. Where failures or missing generated code may come from the platform, the notes say so and name a build of the affected projects with `-p:Platform=<platform>`.
- The `inconclusive` verdict is deliberately rare: it fires only when a strict majority of projects are incomplete, because a judgment that triggers on every partly-restored solution is one you learn to ignore. The *disclosure* is not rationed the same way: whenever even one project is incomplete, the answer carries `incompleteRatio` and `suppressedDiagnosticsTotal` next to the counts.
- **Read `suppressedDiagnosticsTotal` as a magnitude, not as one half of a ratio with `errorCount`.** The two are counted under different rules: the total spans every severity from the floor up and is *not* deduplicated (a multi-targeted incomplete project contributes once per target framework), while `errorCount` counts errors only and *is* deduplicated across target frameworks. A total that dwarfs `errorCount + warningCount + infoCount` means this measured a fraction of the solution, even when no verdict is present.
- A core-resolved project whose dependency chain includes an incomplete project inherits the broken references and can list cascade ids although it compiles fine on a real build. Those diagnostics are never hidden: they stay listed, marked `cascadeFromIncomplete: true`, and counted in `cascadeClassifiedCount`, so `errorCount` is not read as "N real errors".
- Assembly-reference version-float advisories (`CS1701`/`CS1702`, which carry no source location) are binding-redirect noise from the analysis host's reference resolution and are never actionable from source; on core-resolved projects they are filtered out and their count disclosed.
- `scope` is a **post-filter, not a narrowing**: every project is still compiled and `projectsScanned` reports all of them, so latency is the same as a solution-wide call. Use `scope` to save response tokens, never to save time - for one quick check after an edit, one solution-wide call is as cheap as a scoped one.
- An unknown `severityFloor` is rejected with the list of valid values, `auto` included.
- The default `auto` keeps the answer of a large failing edit small: the list holds the errors, not the warnings. The cap still counts items, not characters, so 200 very long errors can still make a large answer.
- **Live-only:** diagnostics are not persisted, so this tool needs a live `analyze_solution` session; a recalled session is rejected (use `refresh_remembered` for a live one).
- Compiler diagnostics only - third-party Roslyn *analyzer* diagnostics are out of scope. The one opt-in exception is `runSuppressors: true`, which runs the projects' DiagnosticSuppressors (they remove compiler diagnostics, they add none). Loading an analyzer assembly for that also runs the constructors of the analyzers it declares, inside the server.
- Dispatchable through `batch`/`measure`.

### `inspect_session`

**Purpose.** Metadata about *one* cached session.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |

**Response.** The same session metadata block `analyze_solution` returns: session id, solution path and name, project count, file-set hash, layer profile, last access, origin (`Live`/`Recalled`) and line-number availability.

**Notes and limits**

- Not exposed by default. It belongs to the session plumbing group that no facet menu and no bundle names, so it is absent from `tools/list` and a direct call is refused unless the server is started with the `AICB_MCP_TOOLS` override naming `SessionTools`, for example:

  ```text
  AICB_MCP_TOOLS=SessionTools
  ```

- Not dispatchable through `batch`/`measure` either.

### `list_sessions`

**Purpose.** List all currently cached analysis sessions (id, solution path, project count, last access).

**Parameters.** None.

**Response.** One entry per cached session, in the same shape as `inspect_session`.

**Notes and limits**

- Not exposed by default, for the same reason as `inspect_session`: only the `AICB_MCP_TOOLS` override reaches it. Not dispatchable through `batch`/`measure`.

## 6.4 Finding symbols, signatures and single-symbol context

### `find_symbol`

**Purpose.** Find types, methods, properties, fields, events, enum members and operators whose name contains the query (case-insensitive).

**When to use.** Locate a symbol before calling `find_usages`, `call_graph` or `get_context`, or to disambiguate a name for `explain_symbol`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `query` | `string` | yes | - | A substring of the symbol name to search for (type, method, property, field, event, enum member or operator). |

**Aliases.** The tool schema advertises `query`, but `symbol` and `name` are accepted as stand-ins and are rewritten to `query` (a recorded caller confusion, kept as a tolerance). An explicit `query` always wins over an alias if you pass both.

**Response.** JSON: `items`, `count`, `totalFound`, `truncated`, on a zero-hit result `nearest`, and, where it applies, `generatedSourcesNote` - on a zero hit, and on a populated answer when the name is also a Razor component written only in markup (see below). Capped at 100. Each item carries `kind` (`type`, `method`, `property`, `field`, `event`, `enum_member` or `operator`), `name`, `declaringType`, `namespace` and `signature`, plus `project` where two hits would otherwise read alike - for example the same type declared under the same full name in two projects, which are kept as two hits - and `generated`, the label of the generated document, on a declaration a source generator wrote (see "Source-generated code" under "Recurring conventions across the catalog"). A type or member that only an older target framework of a multi-targeted project declares is found as well.

**Result order.** Results are ranked by match quality first - exact name, then case-insensitive exact, then prefix, then substring - and only within one rank by kind order. An exact match is therefore never hidden by the cap behind weaker substring hits. If the result is truncated, the exact and prefix matches are the ones you got; narrow the query (a longer substring) to see the weaker rest.

**Kind order.** Types are listed first, then methods, then properties (handwritten and source-generated; a generated property carries a `// source-generated` note in its signature), then fields, events and enum members, then user-defined operators and conversions. An enum member's signature is its qualified `Enum.Member` form - the string the fan-in tools take.

**Notes and limits**

- A user-defined operator is found by its *metadata* name: query `op_Equality`, `op_Addition` or `op_Implicit`, and `op_` lists them all. Every kind listed here is one that `find_usages` and `impact_of_change` resolve; an operator resolves by the same metadata name, with its uses - `a == b`, a cast, an implicit conversion - as its fan-in.
- Not indexed, so an empty answer is expected for them: local variables, parameters, labels and namespaces; C# generated into `obj/` that carries real declarations (protobuf/Grpc.Tools, T4, Refit); and a Blazor component written only in a `.razor` file. A zero-hit answer says which of these may apply in `generatedSourcesNote` - the `.razor` case names the component's file - and, unless the query names a `.razor`-only component, also names a source generator that did not run in the analysis, whose output could hold the declaration.
- A bare name that is both a C# member and a Razor component written only in markup (a constant `Snippets.AlertSimpleExample` beside a component `AlertSimpleExample.razor`) finds the member; when no C# type of that name is in the answer, `generatedSourcesNote` adds that the name is ALSO such a component, whose class has no symbol and no fan-in here, and names its file.
- When the query matches nothing, `nearest` names the closest declared symbol - a likely typo or case mismatch. A matched symbol never carries it.
- On a zero hit in a solution that holds Visual Basic or F# projects, the answer says `NOT ANALYSED` and names them: a declaration only they hold is absent from this index.
- Dispatchable through `batch`/`measure`.

### `symbol_signature`

**Purpose.** Return a symbol's signature(s) *without* the body - the type declaration, the method or operator signature, or a member's declaration (property, field, event, enum member, the last as its qualified `Enum.Member` form) - plus its XML `<summary>` documentation and its declaring file and start line.

**When to use.** Understand an API without reading the whole file or body, and navigate straight to the declaration.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `symbol` | `string` | yes | - | The exact (case-sensitive) type, method, property, field, event, enum-member or operator name. A member also takes `Type.Member` (that type's member only), a type a qualified name (`Ns.Type`, `Outer.Inner`), and `Type.Type` returns the type's declared constructors (kind `constructor`). A user-defined operator matches by its metadata name (e.g. `op_Equality`). |

**Response.** A capped envelope (`items`, `count`, `totalFound`, `truncated`), capped at 50, plus `nearest` when nothing matched and, where it applies, `generatedSourcesNote`. Each item carries `kind`, `name`, `declaringType`, `namespace`, `signature`, `summary`, `line` and `file`; a member of a nested type also carries `outerType`, the type it is declared in. One declaration compiled in two projects, or one type a source generator wrote into each of two projects, is two results, each with its `project`. A declaration a source generator wrote carries `generated`, the label of its generated document; its `file` is then that label's path, usually not a file on disk.

**Notes and limits**

- `file` is the fragment's *own* file: for a partial type, a method points at the file the method lives in, not at the first type fragment. It is omitted only when the snapshot carries no path.
- `line` is the line the declaration starts on, a leading attribute included - for types, methods, operators, properties, fields and events alike. It is `null` for an enum member and for a source-generated property, for which no line fact is modeled.
- Matching is exact, so a typo or case mismatch returns an empty list rather than an error; the `nearest` suggestion distinguishes "you spelled it differently" from "this symbol genuinely has no signature". Where the run skipped generated C# under `obj/`, a component lives only in a `.razor` file, or a source generator did not run, `generatedSourcesNote` names that third possibility: the declaration exists in code this index never read. Multiple results are returned for overloads or name collisions.
- A member that shares its bare name with a Razor component written only in markup is returned as usual, and `generatedSourcesNote` names the component as a different symbol, as in `find_symbol`.
- A qualified member query respects every segment: `Outer.Inner.Member` or `Ns.Type.Member` answers for the member of the type whose full name ends in that chain, also through a generic outer type (`Outer<T>.Inner.Save`), not for every type that carries the last type segment's name.
- Leaner than `get_context`, which returns the full source.
- Dispatchable through `batch`/`measure`.

### `get_context`

**Purpose.** Return a dense, token-budgeted AI-Builder-Markdown slice of the code around a symbol: the symbol's source plus its expanded neighborhood (direct dependencies and callees, depth 1). The fastest single-symbol retrieval.

**When to use.** Whenever you need one symbol's context. Prefer it over `export_markdown` (which renders the *whole* solution). If you need a chosen environment of one symbol (callers, tests, implementations, quality), use `explain_symbol`; to bundle a whole task from a natural-language goal, use `pack_for_task` or `prepare_task`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `symbol` | `string` | yes | - | The type or method simple name to center the slice on. Use `find_symbol` first to disambiguate. |
| `budget` | `int` | no | `null` | Token budget, floored at 8000. |
| `includeQualityMetrics` | `bool` | no | `false` | Also emit the `<QUALITY_HOTSPOTS>` section plus `complexity="..."` / `ce="..."` tag attributes. |
| `lean` | `bool` | no | `true` | Drop the `<AI_CONTEXT_SPEC>` format-rules preamble, the `<AI_CONTEXT_META>` block and empty graph sections. |

**`budget`.** Caps the slice in two ways: it compacts or drops method bodies, and - when the expanded neighborhood still overflows - it drops the least-relevant non-seed types entirely, ranked by closeness to the seed and in-slice fan-in. The seed symbol itself is never dropped: it renders with its full source when that fits the budget, otherwise as *structure* (identity, members, every method signature) with a leading note naming the measured size of the full-code render and the budget that would hold it. A type reduced to structure lists the signatures of every method it declares that does not already render as a method block, up to 80 lines and then a `(+N more)` line, under a comment such as `<!-- N declared methods, signatures only: the budget took this type's source out (see the budget note) -->`; the list counts against the budget. Without a value the slice still renders against a ceiling - the active MCP profile's token budget, else a default of about 10,000 tokens - that bounds the neighborhood. Pass a value for a tighter slice.

**`includeQualityMetrics`.** Set it when reviewing code quality or picking refactor targets: the slice additionally carries cyclomatic complexity and efferent coupling, as a `<QUALITY_HOTSPOTS>` section and as tag attributes on the sliced symbols. The afferent coupling (`ca=""` on a type tag, and the hotspot coupling line) counts the referencers in the whole solution, not only those the slice kept, so it is the number a full export prints.

**`lean`.** On a focused single-symbol slice the format-rules boilerplate is more than four times the actual signal, which is why it is dropped by default. The `PATH_LEGEND` and `COMPRESSION_LEGEND` (the decoding keys) and all non-empty sections are kept. Set `lean: false` for the full AI-Builder-Markdown document with the format contract.

**Response.** Markdown. A leading comment discloses how many types were dropped.

**Notes and limits**

- Multi-TFM solutions are deduplicated to one declaration per type, the newest target framework's where it has one - the same view `find_symbol` lists. A type only an older target framework declares can be the center, and the callers of every target framework count, so the numbers match `find_usages`. Two different projects of the same name are not merged. `export_markdown` deliberately keeps the unfiltered per-target-framework render.
- A type a source generator writes whole can be the center as well; its code block says that it has no source on disk.
- When several types share the name you pass (in different namespaces), every one of them renders, not only one.
- A slice centered on an interface pulls its implementing types - those that implement it directly, through a base class or through another interface, for a generic interface whatever type arguments they close it with. Under a budget the leading comment names how many types were dropped (`dropped N least-relevant types ...`).
- A partial type renders as one block per project it is compiled into: within each project its declaration fragments are folded, and a leading comment says which files. Where the type is compiled into more than one project (a linked file, a shared project), that comment names the project it was folded in (`<Type> in project <Name>`), also when the other project holds only a single fragment of it. The type name is namespace-qualified when another entry of the same comment has the same simple name - for example when two projects fold it.
- Dispatchable through `batch`/`measure`.

### `explain_symbol`

**Purpose.** Explain a symbol: its source *plus* a chosen environment, as one dense AI-Builder-Markdown slice - the cold read in a single call instead of four to six (a context slice plus the fan-in, implementation and test queries).

**When to use.** When you need to understand one symbol and its neighborhood at once: who calls it, what it calls, who implements it, which tests cover it.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | `string` | yes | - | Session id or absolute solution path. |
| `symbol` | `string` | yes | - | The type or method simple name, or the qualified `Type.Member` form. |
| `include` | `string[]` | no | `null` | The environment axes to include; any combination. |
| `budget` | `int` | no | `null` | Token budget, floored at 8000; behaves as in `get_context`. |
| `lean` | `bool` | no | `true` | As in `get_context`. |

**`symbol`.** A bare name that matches several declarations seeds them *all*, and every type that shares the name renders; the manifest says so and names the qualified form to use instead. The qualified `Type.Member` form focuses one declaration of a shared method name - the same string `find_usages`, `find_tests_for` and `impact_of_change` resolve.

**`include` axes** (case-insensitive):

| Axis | What it adds |
|---|---|
| `callers` | The members that reference the symbol, with their bodies, and their owner types as structure - not the calling types whole. A caller that references the symbol only from its structure (a field or property type, a base list) renders as that caller's own declaration. |
| `callees` | What the symbol calls or depends on, depth 1. This is the widest slice this server produces. |
| `implementations` | The types implementing it, if it is an interface - also those that get a generic interface through a base class or another interface, as `find_implementations` lists them. Every same-named type the axis lists renders. |
| `tests` | Its covering test cases. For a method, the method's own tests, bare or qualified - not the tests that read a same-named property. Strongest evidence first, at most 40; the manifest discloses a cap as `prepare_task` does (`(+N more, capped)`, with the share of contract rows when there are any). |
| `siblings` | Naming and file-convention kin. Every same-named type the axis lists renders. |
| `quality` | Complexity and efferent-coupling hotspot metrics. |

**Response.** Markdown with a leading *manifest* comment that discloses what each requested merge axis actually found - so `(none)` is an honest negative (no implementation, no caller, no test), not "not asked". A partial type renders as one block per project it is compiled into (its declaration fragments are folded; a leading comment says which files, and names the project where the type is compiled into more than one) instead of one identical block per file.

**Other kinds of the same name.** The callers axis answers for the center - the type or the method the symbol resolved to. When a bare name also names a property, field, event, enum member or operator elsewhere (for a type center, also a method), those members' users are not counted as the center's callers: a center nobody uses reads `callers: (none)`, and without the callers axis the manifest no longer states their fan-in as the center's. The manifest then carries a `namesakes:` segment, for example:

```text
namesakes: 'Clock' also names property TimeService.Clock (3 direct user(s)) - their users are not counted as the type's callers; find_usages takes the qualified Type.Member form to measure one
```

It names up to three forms per kind and then `and N more`, with each kind's direct user count, appears with or without a callers axis and also when the center has users of its own, and is absent for a qualified query and when no other kind of the name has users.

**Notes and limits**

- An empty `include` returns just the symbol's source; the manifest then names the axes you could have asked for, so that answer is a stated choice rather than a silent default. An `include` token that names no axis is reported as dropped, whether or not a sibling token was valid.
- `budget` behaves as in `get_context`: the center symbol is always kept - with its full source when that fits, otherwise as structure plus a leading note naming the measured size of the full-code render and the budget that would hold it. The bundled environment (callers, tests, siblings, implementations) is budget-bound and dropped to fit under a tight budget; a leading comment names the drops so you can ask for one by name. Without a value, the slice renders against the same ceiling as `get_context`.
- Recall-safe: reads persisted facts, so it works on recalled sessions. Prefer it over `export_markdown` for one symbol's world.
- Multi-TFM solutions are deduplicated to one declaration per type, the newest target framework's where it has one (matching `find_symbol`'s view); a type only an older target framework declares is found, and callers from every target framework count, as in `get_context`. A type a source generator writes whole can be explained; its code block says it has no source on disk.
- The callers line also counts the users it cannot render - in generated code or in markup - and points to `find_usages` for them.
- Dispatchable through `batch`/`measure`.

---

[&larr; 5 Calling tools: conventions, batch and aicb call](05-calling-tools-conventions-batch-and-aicb-call.md) &middot; [Contents](README.md) &middot; [7 Tool reference: impact, hierarchy, tests and DI &rarr;](07-tool-reference-impact-hierarchy-tests-and-di.md)
