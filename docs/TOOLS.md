# Tool reference

Generated from the `tools/list` answer of `aicb 0.5.520.1` with the default
profile - the **54 tools** an agent sees after `aicb init`. Further tools are
one profile switch away (`aicb mcp --mcp-profile mcp-profile/full`); `list_skills` shows
the complete map, and the `docs` tool is the server's built-in manual.

Every tool that takes a `sessionId` also accepts the absolute path of a `.sln`, `.slnx` or
`.slnf` there and analyzes it on first use.

## Overview

| Tool | What it answers |
|---|---|
| [`analyze_solution`](#analyze_solution) | Analyze a C#/.NET solution (.sln, .slnx or .slnf) with Roslyn and cache the result as an in-memory session - the entry point of this server: it returns the session_id the other tools take as sessionId. |
| [`apply_solution_config`](#apply_solution_config) | Apply a proposed Layer Profile + Exclude-Namespaces + Test Profile configuration for a solution. |
| [`architecture_overview`](#architecture_overview) | Orient on a whole solution WITHOUT the firewall of full source. |
| [`assert_absence`](#assert_absence) | Check a NEGATIVE claim against the analyzed model and return confirmed / refuted / indeterminate with evidence. |
| [`batch`](#batch) | Run several read-only query tools in ONE round-trip against one shared session. |
| [`call_graph`](#call_graph) | Build a depth-limited call graph rooted at a method NAME. |
| [`calls_external`](#calls_external) | Find the code that calls an EXTERNAL member - BCL or package - whose key contains 'pattern'. |
| [`check_solution_config_drift`](#check_solution_config_drift) | Check whether a solution's active Layer Profile, Exclude-Namespaces and Test Profile still FIT the code. |
| [`compare_with_previous`](#compare_with_previous) | Diff the current session against a previously saved snapshot of the SAME solution - the newest by default, or the N-th previous via snapshotsBack (0=newest saved, 1=the one before, ...). |
| [`coverage_gaps`](#coverage_gaps) | List what is NOT covered in a scope: 'uncovered' - production methods no test code calls directly - and 'verifiedAbsent' - semantic axes a developer explicitly declared as 'none'. |
| [`describe_api_surface`](#describe_api_surface) | List the PUBLIC API SURFACE of a solution or namespace - every externally-visible type with its externally-visible members (constructors, properties, fields, events, methods, user-defined operators), each as a compact declaration signature. |
| [`detect_circular_dependencies`](#detect_circular_dependencies) | Detect circular NAMESPACE dependencies: groups of namespaces that depend on each other in a cycle - a modularity smell the compiler allows, unlike project-reference cycles. |
| [`docs`](#docs) | The aicb operating manual - how to USE this server, as opposed to what it can tell you about your code. |
| [`evaluate_change_set`](#evaluate_change_set) | Advisory policy gate: which code-quality / design-smell / layer-violation findings would this edit INTRODUCE? Ask BEFORE writing it. |
| [`explain_symbol`](#explain_symbol) | Explain a symbol: its source PLUS a chosen environment, as ONE dense AI-Builder-Markdown slice - the cold-read in a single call instead of 4-6 (get_context + find_usages + find_implementations + find_tests_for + ...). |
| [`export_markdown`](#export_markdown) | Render the cached analysis of a session as AI-Builder Markdown. |
| [`find_binding_usages`](#find_binding_usages) | List the {Binding ...} sites in the solution's .xaml and .axaml markup that name a member path, with what each one resolves against. |
| [`find_by_attribute`](#find_by_attribute) | Find symbols (types, methods, properties or fields) that carry a given ATTRIBUTE - a cross-cutting query that find_symbol (name-only) cannot do. |
| [`find_by_event_subscription`](#find_by_event_subscription) | Find the TYPES that subscribe to a C# event: a '+=' whose left side resolves to an event, anywhere in the type; external events too ('Button.Click'). |
| [`find_by_semantics`](#find_by_semantics) | Find types and methods by their resolved semantics: layer, role, domain, responsibility. |
| [`find_by_side_effects`](#find_by_side_effects) | Find code by its side-effect profile: what a method touches in the outside world. |
| [`find_dead_code`](#find_dead_code) | List dead-code suspects on two axes. |
| [`find_implementations`](#find_implementations) | List the types that implement an interface, in the solution or external (IDisposable). |
| [`find_overrides`](#find_overrides) | List the override-to-base relationships for methods of a given name - the class-inheritance counterpart to find_implementations (which covers interfaces). |
| [`find_resource_usages`](#find_resource_usages) | Resource-key fan-in across the solution's XAML/AXAML markup AND its C# sources - the question the C# symbol graph cannot answer because resources are wired by string key, not by symbol. |
| [`find_symbol`](#find_symbol) | Find types, methods, properties, fields, events, enum members and operators whose name contains the query (case-insensitive). |
| [`find_tests_for`](#find_tests_for) | Find the tests that likely cover a symbol: test methods that call it, read it, build it or are named after it. |
| [`find_unresolved_bindings`](#find_unresolved_bindings) | List silently broken XAML bindings: a {Binding X} whose root member does NOT exist on its confidently resolved DataContext view-model (typo, removed/renamed member, or wrong DataContext) - neither the compiler nor render-smoke tests catch it. |
| [`find_usages`](#find_usages) | List who uses a symbol (direct fan-in); impact_of_change adds closure and risk, calls_external covers external members. |
| [`get_context`](#get_context) | Return a dense, token-budgeted AI-Builder-Markdown slice of the code around a symbol: the symbol's source plus its expanded neighborhood (direct dependencies + callees, depth 1). |
| [`get_diagnostics`](#get_diagnostics) | Compiler errors and warnings without a build: every C# project of the session is compiled in memory, in seconds. |
| [`get_insight`](#get_insight) | Get the full detail of one insight (incl. the per-item Details list) by its id. |
| [`get_type_hierarchy`](#get_type_hierarchy) | Walk one type's inheritance in both directions: baseChain upward, derivedTypes downward, plus the interfaces the type declares. |
| [`impact_of_change`](#impact_of_change) | Estimate the blast radius of changing a symbol: direct users, their dependents, a risk level. |
| [`init_solution_config`](#init_solution_config) | Collect the raw material for the guided setup of a solution's Layer Profile, Exclude-Namespaces and Test Profile - step 1 of 2; apply_solution_config is the step that writes. |
| [`install_agent_hooks`](#install_agent_hooks) | Install the aicb symbol guard into this project for an agent harness, so a C#-symbol question is REFUSED on a text search and redirected to the tool that answers it. |
| [`instantiation_sites`](#instantiation_sites) | Find where a type is constructed and where it is injected: the narrow 'who creates or obtains an instance of X?' that find_usages (every reference) cannot answer. |
| [`list_insights`](#list_insights) | List code-quality / async / design-smell insights for a session (long methods, fat interfaces, unused types, missing async suffixes, many-parameter methods, ...). |
| [`list_mcp_profiles`](#list_mcp_profiles) | List the MCP profiles in the server's config DB - each with its id, name, the slots that have a template assigned (General appears exactly when a profile-wide template is set), the profile-wide templateId (null = none), whether it carries a skill, its effective tool-set (toolSelection: the class-level CSV, or a 'methods:'-prefixed function-name list when the profile curates individual tool functions; null = lean core), whether it is the active one, AND the render config it applies (tokenBudget / outputFormat / overflowPolicy - a null tokenBudget/overflowPolicy means inherit: the template then the active PipelineProfile decides). |
| [`list_skills`](#list_skills) | The server's capability map: a tools INDEX naming EVERY tool this server has - each exactly once, grouped into three lists by pool state (inPool.core = the tools every profile exposes, in reach-for-them order; inPool.extras = the rest of the active pool, alphabetical; outOfPool = exists but the active tool set does not expose it) - plus the sections that group them by name: the always-on navigation CORE (listed in no menu because it needs none), the task FACETS (id + guidance + template slot + the facet's tool menu), the cross-cutting guidance styles, and the legacy functional skill bundles. |
| [`measure`](#measure) | Report how BIG a read-only query's answer would be - its exact token count - WITHOUT returning the answer. |
| [`pack_for_task`](#pack_for_task) | Goal-driven context packing: given a natural-language task, seed on every symbol the goal names (type or method), expand the neighborhood, and return a token-budgeted AI-Builder-Markdown bundle - with goal-aware trimming that keeps the most task-relevant methods when the budget is tight. |
| [`prepare_task`](#prepare_task) | Build an EDIT-ready context bundle for a task goal: the source of the symbols the goal names, their dependency neighborhood, the test methods that cover them and 1-2 naming/file-convention siblings (the test, the factory, the validator you'd otherwise miss) - as one token-budgeted AI-Builder-MD document. |
| [`refresh_session`](#refresh_session) | Re-analyze the session's solution after YOUR code edits - call it once you have changed .cs files, otherwise find_usages / impact_of_change / list_insights / get_context may keep answering from the STALE pre-edit graph (a silent source of wrong results). |
| [`resolve_injection`](#resolve_injection) | Resolve a Microsoft DI or MEF registration: what is registered for a service, with lifetime and site. |
| [`review_context`](#review_context) | Assemble review context for a set of changed symbols in ONE call: per symbol its fan-in, the transitive change impact with a risk level, the types that implement it (if an interface) and the test methods that likely cover it. |
| [`save_session`](#save_session) | Persist the current session's analyzed model as a named Manual snapshot in an aicb DB, so a later session can diff against it with compare_with_previous. |
| [`server_info`](#server_info) | Report this SERVER's own identity and health: name, version, build commit, the config DB's schema version, and drift warnings about the server binary. |
| [`solution_config_status`](#solution_config_status) | Check whether a solution's Layer Profile, Exclude-Namespaces and Test Profile have been initialized via the guided setup, and which Layer Profile / Exclusion List / Test Profile is currently active. |
| [`solution_metrics`](#solution_metrics) | The solution-wide quality rollup in one call - the numbers the CLI '--fail-on' quality gate evaluates. |
| [`symbol_metrics`](#symbol_metrics) | Report method complexity: McCabe CYCLOMATIC complexity (independent paths) and COGNITIVE complexity (how hard the method is to follow: nesting is penalised, boolean-operator runs collapse), plus the parameter count - for one method by name, or as a ranking of the hotspots. |
| [`symbol_signature`](#symbol_signature) | Return a symbol's signature(s) WITHOUT the body: the type declaration, the method/operator signature or a member's declaration (property, field, event, enum member - the last as its qualified Enum.Member form), plus its XML &lt;summary> doc and its declaring file + start line - for understanding an API without reading the whole file/body, and for navigating straight to it. |
| [`usage_report`](#usage_report) | Report the server-side tool-call telemetry: what the CallTool filter recorded into the config DB's tool_calls table, across every client that used this DB - not this conversation's transcript. |
| [`verify_claim`](#verify_claim) | Verify a structured claim about a change by diffing two analyzed sessions (baseline → changed). |

### analyze_solution

Analyze a C#/.NET solution (.sln, .slnx or .slnf) with Roslyn and cache the result as an in-memory session - the entry point of this server: it returns the session_id the other tools take as sessionId.

Calling it is optional: every tool that takes a sessionId also accepts the absolute solution path and analyzes on first use, so do not call it just to run a query. Call it to read this answer first or to pass layerProfile / dbPath. After editing .cs files call refresh_session, not this: a second analyze_solution is a full reload into a new session.

Returns JSON: sessionId, solutionPath, solutionName, projectCount, fileSetHash, layerProfile, lastAccessUtc, origin, lineNumbersAvailable - plus, only when they apply, analyzePreferredTfmOnly, incompleteRun, configInit (config axes still to set up; see solution_config_status) and agentWiring (the agent's guard hooks are missing here).

When a scanned project could not bind even its core framework types, the answer carries incompleteRun (projects and repair), because every later answer of the session inherits that shortfall. Its absence is no all-clear: an unrestored project that still binds its framework is not flagged here; get_diagnostics names its errors.

It changes no source or project file: it opens the solution through MSBuild (whose design-time build can write generated files under obj/), reads the files as they are on disk (uncommitted edits included) and keeps the model in server memory - by default for 90 minutes after the last use, at most 8 sessions. A large solution can take minutes; with a client progress token it reports progress. If the client cancels, the analysis still finishes: a same-argument retry gets it if no file changed.

Parameters: normally pass only solutionPath; layer profile, namespace exclusions and test profile then come, per axis, from the server's config DB, else the committed &lt;Solution>.aicb.json beside the solution, else built-in heuristics. layerProfile overrides the layer axis only; dbPath reads all three from another config DB.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `solutionPath` | string | yes | Absolute path to the solution file to analyze (.sln, .slnx or .slnf). |
| `layerProfile` | string \| null |  | Optional absolute path to a layer-mapping profile JSON. Omit to use the config DB's active layer profile (per-solution > app-global) when a config DB is resolved, else the .aicb.json sidecar's profile, else role-based heuristics. |
| `dbPath` | string \| null |  | Optional absolute path to a config/master DB. When given, the DB's CONFIGURED namespace-exclusion list (per-solution row, else app-global default) is applied during analysis, same as the CLI; where the DB configured none, the committed .aicb.json sidecar's list applies, and only without a sidecar the DB's built-in default (a built-in default is not configuration - solution_config_status names the list in force and its source); the DB's active test-detection profile (per-solution > global > default) is resolved for the session so the test-aware tools (find_dead_code / coverage_gaps / symbol_metrics / find_tests_for / find_by_side_effects / assert_absence / prepare_task / list_insights / get_insight / solution_metrics) honor it; AND - unless an explicit layerProfile is given - the DB's active layer-mapping profile (per-solution > app-global) drives the analysis (dependency-graph layers + LAYER_MAP), matching the insights/metrics/CLI-gate path. All three travel with the session, so downstream tools honor them without re-passing dbPath. Omit to use the server's default config DB (the same one the GUI uses), if the server resolved one - so the GUI's per-solution exclusions + test + layer profile apply automatically; else the DB-free default (the built-in exclusion list, default test heuristic, role-based layers). When a config DB is resolved and a config axis (layer/exclusions/test) is not yet initialized via the guided setup, the response carries a configInit hint pointing to solution_config_status. |

### apply_solution_config

Apply a proposed Layer Profile + Exclude-Namespaces + Test Profile configuration for a solution. Creates a new custom layer profile / exclusion list / test profile (tagged with the source solution for provenance), activates them, and marks each touched slot initialized. proposalJson is a JSON object {"layerRules":[{"pattern":".Application.","matchType":"Contains","layer":"Application"}],"exclusions":[{"pattern":"System.","matchType":"StartsWith"},{"pattern":"System","matchType":"Exact"}]}; the test axis is given via testProposalJson {"testProjectRules":[{"pattern":".Tests","matchType":"EndsWith"}],"testAttributeNames":["Fact","Theory"]} (rules match PROJECT names) OR via testPreset = xunit|nunit|mstest|default. At least one axis must be non-empty (empty arrays/slots are skipped). matchType is Contains|StartsWith|EndsWith|Exact (an invalid matchType is rejected, not silently defaulted). An exclusion with "keep":true is a keep rule: a namespace it matches is never excluded; exclusions that are all keep rules leave the built-in list in force; the sidecar stores keep rules under "keepNamespaces". Writes to the config/master DB (the given dbPath, or the server's default - the GUI's - if omitted; created if missing) AND to the git-tracked &lt;SolutionName>.aicb.json sidecar next to the .sln (returned as sidecarPath - commit it so the config travels with the repo). An axis this call does not name keeps what the existing sidecar holds for it, and keys it does not know stay as they are. An existing sidecar that cannot be read (malformed, locked) is never rewritten: the call is refused before anything is written, and a file that becomes unreadable while the DB is written is left as it is too (the DB keeps the configuration, a warning says so); a keep rule the file puts inside 'exclusions' is moved to 'keepNamespaces'. A keep flag that is not a JSON boolean is rejected.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `dbPath` | string \| null |  | Absolute path to the aicb config/master SQLite DB to write the configuration into (created if missing). Omit to use the server's default config DB (the same one the GUI uses), if the server resolved one. |
| `proposalJson` | string \| null |  | Optional layer/exclusion proposal as a JSON object with 'layerRules' and/or 'exclusions' arrays (see tool description). Omit for a test-only apply. |
| `layerProfileName` | string \| null |  | Optional display name for the created layer profile. Omit for an auto-generated name. |
| `exclusionListName` | string \| null |  | Optional display name for the created exclusion list. Omit for an auto-generated name. |
| `layeringPolicy` | string \| null |  | Layer-mapping policy for the new profile: 'Advisory' (default) or 'Strict'. |
| `testProposalJson` | string \| null |  | Optional test-axis proposal as a JSON object {"testProjectRules":[{"pattern":".Tests","matchType":"EndsWith"}],"testAttributeNames":["Fact","Theory"]}. testProjectRules match PROJECT names. Mutually exclusive with testPreset. |
| `testPreset` | string \| null |  | Optional shortcut: clone a built-in test profile (xunit\|nunit\|mstest\|default) into a custom per-solution profile. Mutually exclusive with testProposalJson. |
| `testProfileName` | string \| null |  | Optional display name for the created test profile. Omit for an auto-generated name. |

### architecture_overview

Orient on a whole solution WITHOUT the firewall of full source. When anything was cut, the document LEADS with a &lt;TRUNCATION> block: how many sections were capped, how many entries are shown of how many in total, and one 'SECTION: shown of total' row per capped section - read it before the sections, because the per-section '+N more' lines below state one section's loss each and never the whole. Absent = nothing was cut. Renders a structural-only AI-Builder-Markdown overview: the macro/architecture graphs (layer map, service & class dependency graphs, role graph, entry points + entry-point flow, architecture flow, interface relations) plus a domain summary and a quality-hotspots section (the most complex methods + most-coupled types) - but NO per-type/per-file source-code blocks, so it stays bounded where export_markdown is a 27-29 MB firehose. BOUNDED AT SCALE: each macro section is capped at 80 entries with a '+N more' note; the layer map lists every type up to 2500 and per-layer counts above, so even a 200+-project monolith returns a usable orientation instead of overflowing the token cap (use export_markdown for the full set, or find_symbol / call_graph / get_context to drill in). PRODUCTION-FOCUSED: test projects are excluded by default (an architecture overview is otherwise dominated by every test method listed as an entry point + its flow trace, which is not part of the production architecture) - set includeTests=true to include *.Tests/*.Spec projects. Method-level call graphs are deliberately omitted (use call_graph / explain_symbol for a specific symbol). Multi-TFM solutions are deduplicated to one declaration per type, the NEWEST TFM's where it has one (without it every hotspot/edge appears once per TFM). Recall-safe: works on live AND recalled sessions (on a recalled session quality-hotspot line counts are unavailable, complexity is still shown). Use this FIRST to understand a codebase's shape, then get_context / explain_symbol to drill into a symbol.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `lean` | boolean |  | Lean mode (default TRUE): drop the &lt;AI_CONTEXT_SPEC>/&lt;AI_CONTEXT_META> format-rules preamble and any empty graph sections. Set false for the full AI-Builder-MD document contract. |
| `includeTests` | boolean |  | Include test projects (default FALSE - production focus: an architecture overview is otherwise flooded by every test method listed as an entry point + its flow trace, bloating the output with scaffolding that is not part of the production architecture). Set true to include *.Tests/*.Spec projects in the graphs. |
| `summaryOnly` | boolean |  | Summary mode (default FALSE): collapse each macro-section to a count + top-N entries instead of up to 80. Use on EXTREME/very-large solutions (200+ projects, heavy generics) where even the bounded overview exceeds the token cap and would otherwise return nothing. |

### assert_absence

Check a NEGATIVE claim against the analyzed model and return confirmed / refuted / indeterminate with evidence. Supported: 'no_tests:&lt;Symbol>' (the symbol has no detected covering test), 'absent:&lt;Symbol>.&lt;axis>' (the semantic axis is verified-absent - developer declared 'none', NOT merely unknown), and 'unknown:&lt;Symbol>.&lt;axis>' (the axis has no provenance entry at all). &lt;Symbol> is a bare name or the qualified Type.Member form - the same strings find_usages / find_tests_for / impact_of_change resolve, so the pre-edit gate's tools accept one vocabulary; a name that resolves to nothing declared says so ('resolves to no declared type or member'), which is a statement about the name, not a claim the code lacks it. axis is e.g. role/layer/domain/context/responsibility; an axis name not recorded anywhere in the solution returns 'indeterminate' with the actual recorded axes as evidence (a typo'd/invented axis is NOT silently 'confirmed'). Conservative in BOTH directions: a claim the model cannot prove is 'indeterminate', never falsely confirmed - and 'refuted' for a no_tests claim requires at least one STRONG covering test, as find_tests_for defines its tiers; the reason states the split between the strong tiers and the name-only matches, matching find_tests_for's invokesTotal. Tests that merely carry the symbol in their NAME yield 'indeterminate' with that split disclosed, not a refutation - a test named after a symbol is not proof it exercises it. Use to validate 'this service is untested' or 'role is explicitly unset' before relying on it.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `claim` | string | yes | The negative claim: 'no_tests:&lt;Symbol>', 'absent:&lt;Symbol>.&lt;axis>', or 'unknown:&lt;Symbol>.&lt;axis>'. |

### batch

Run several read-only query tools in ONE round-trip against one shared session. measure is the sibling that sizes each answer instead of returning it.

Use it when the questions do not depend on each other's answers; a solution path as sessionId is analyzed once.

queries is an array of {tool, args}: args is that tool's own arguments as a JSON object WITHOUT sessionId (omit it for a tool that takes none). Example: queries=[{"tool":"find_usages","args":{"symbol":"Foo"}},{"tool":"find_tests_for","args":{"symbol":"Foo"}}]. At most 16 per call: more fails the whole call, as does a sessionId that does not resolve.

Returns { results: [{tool, ok, result | error | omitted}], count, okCount, omittedCount (when any) }, in query order. A failing sub-query answers ok:false + error; the rest still return. A JSON tool's result is nested as an object, a Markdown tool's is the string. The answers share about 9000 tokens, small ones whole first. A large answer is never cut: a 'budget' tool's may be rendered smaller if its share reaches that tool's floor (see 'note'), else it carries 'omitted' (it ran; call it directly). Unknown arguments are ignored, named in 'note'.

Dispatchable is a fixed registry of read-only queries about the analyzed code, among them find_*/get_*/impact_of_change/symbol_signature/explain_symbol/calls_external/resolve_injection/symbol_metrics/list_insights. Refused per item, with the registry's names listed - call these directly where the profile exposes them: tools that mutate session state or write (such as analyze_solution/refresh_session/apply_solution_config/save_session/remember_codebase/export_markdown/install_agent_hooks), poor batch members (evaluate_change_set/init_solution_config/prepare_task/review_context), tools needing a second session or snapshot (semantic_diff/diff_review/verify_claim/compare_with_previous) and the session, configuration and server tools. A tool the active MCP profile does not expose is refused per item too, as a direct call would be - also when a refusal's list names it.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. Shared by ALL sub-queries - do NOT repeat it inside each query's args. |
| `queries` | array | yes | The read-only sub-queries: an array of { tool, args } objects. 'tool' is a read-only tool name; 'args' is that tool's argument object (without sessionId), omittable when the tool needs no arguments. Max 16. |

### call_graph

Build a depth-limited call graph rooted at a method NAME. direction='callees' follows project-internal calls outward; direction='callers' follows the inverse (who calls this). Returns (caller, callee) edges using method-lookup keys, cycle-safe and capped at 500 edges (truncated flag). A creation (new X(...)) is an edge to the constructor it binds, keyed 'Ns.X.X(params)', and both directions walk on through a constructor: into what it calls and creates, out to the code that creates the object. A local function's key ends in '@&lt;file>:&lt;start>:&lt;length>', character offsets rather than a line ('localFunctionKeyNote' repeats this when the answer holds one). A bare name is rooted at the name, NOT at one symbol: EVERY same-named declaration in the solution is a root and the graph is their union, so a common name (e.g. 'ExecuteAsync') can pull in unrelated members and inflate the payload. The qualified 'Type.Method' form roots only that type's declarations of the name, overloads included. With direction='callers' every node also brings in the callers of the interface and abstract members it implements, at every hop as impact_of_change does (a call through the contract is recorded there); 'viaContract' names those members with their implementation counts (one implementation: exact, several: a union) and the nodes that brought them in ('creditedBy'). 'generatedStops' counts the generated documents ('&lt;path> (generated)') among the callers: the walk does not continue past them to the callers of the members they declare. 'rootedAt' lists the declarations actually walked - check it when the result looks too big (then re-query a rarer or qualified name) and when it is empty (the name resolved to nothing, which an empty edge list alone does not tell you).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `method` | string | yes | The root method's name, bare or as 'Type.Method'. |
| `depth` | integer |  | Max traversal depth (1-10). Default 2. |
| `direction` | string |  | 'callees' (default) or 'callers'. |

### calls_external

Find the code that calls an EXTERNAL member - BCL or package - whose key contains 'pattern'. find_usages answers for solution symbols only; find_by_side_effects classifies the same calls into effect tokens.

Use it for AOT/trimming readiness, security surface or dependency footprint: pass the risky or external API as 'pattern', e.g. 'Process.Start' or 'DateTime.UtcNow'. It is the only search argument; there is no 'symbol'.

Returns scope, pattern, methodsScanned, matches - a capped envelope of at most 200 hits, sorted by type and name, not ranked - and testMatchesFiltered (units the test filter removed, outside methodsScanned; omitted at 0). A hit carries name, declaringType, namespace, matchedCalls (invoked methods and method groups, keys like 'System.IO.File.ReadAllText(string)') and matchedReads (external properties read or written, like 'System.DateTime.UtcNow'). The units scanned are methods plus every accessor and constructor with a body, under their metadata names (get_X, set_X, .ctor), and, unscoped, each top-level-statement file ('Program.cs (top-level)'); an initializer counts toward the constructor that runs it.

The pattern is a case-insensitive substring of the whole key, parameter list included, so a type name also hits the units that only pass that type to another API. It is an open vocabulary (no did-you-mean); empty is strong, not absolute. Not recorded: an external field read ('string.Empty'), a bare 'new X()', operators and conversions, indexers, event subscriptions and compiler-lowered calls (using, foreach, await). Cross-check a surprising empty against the declaring type ('DateTime', not 'DateTime.UtcNow'). A 'note' leads the answer when it is empty - it says when only the test filter emptied it - and when a project's core references did not resolve: an unresolved call records no key.

Read-only; works on a recalled session. Test-project code is excluded by default (includeTests=true includes it). scope is 'solution' or a namespace prefix, matched case-insensitively on segment boundaries.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `pattern` | string | yes | A substring of the external (BCL/third-party) call key to match (case-insensitive), e.g. 'Process.Start', 'File.', 'Assembly.Load', 'System.Reflection', 'JsonSerializer'. Required - a very broad pattern (e.g. 'System') truncates at 200. |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.Infrastructure') to narrow scope. |
| `includeTests` | boolean |  | Include test-project methods (default false - production focus; test setup/assertions calling external APIs would otherwise drown the signal). |

### check_solution_config_drift

Check whether a solution's active Layer Profile, Exclude-Namespaces and Test Profile still FIT the code. solution_config_status tells you WHICH configuration is active and where it comes from.

Use it on a solution configured a while ago, or when layer or exclusion results look off; a stale axis is rebuilt with init_solution_config and apply_solution_config. On a never-configured solution only exclusion.excludedApiAreas is evaluated.

Three conservative signals: layer - declared (own) namespaces that no rule of the active layer profile maps; exclusion - EXTERNAL referenced namespaces that the active exclusion list does not cover; test - projects the default heuristic classifies as test projects that the active custom test profile's rules do not match.

Returns JSON with layer, exclusion and test, each carrying source (db / sidecar / built-in / none), name, status, stale, considered (the denominator), sample (drifted names, items/count/totalFound/truncated, max 50) and reason (the drifted count against considered). status is 'stale' from 3 drifted names on for layer and exclusion, for test above a quarter of considered projects; else 'ok' (an 'ok' with a sample is still worth reading). 'built-in-preset' and 'not-configured': the axis was NOT judged, only a custom config is (a generic preset is a choice, not drift). exclusion.excludedApiAreas, on any status: excluded areas carrying the public API, each with the keepRule to add. sidecarProblem: the .aicb.json could not be read.

It changes no configuration and creates no solution row; a missing dbPath is refused, an empty one is not opened, an older one is upgraded on open (schema, built-in rows). It judges the configuration a plain analyze_solution resolves NOW, not a layerProfile the session was analyzed with. It needs a live session, not a recalled one.

Parameters: normally pass only sessionId (an absolute .sln/.slnx/.slnf path works too). Pass dbPath only if the session was analyzed with it; otherwise this judges a configuration the analysis did not use.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `dbPath` | string \| null |  | Optional absolute path to the aicb config/master DB. If given, the config the DB holds for the solution (per-solution row, then app-global default) takes precedence over the .aicb.json sidecar; a built-in default in the DB does not. Omit to fall back to the server's default config DB (the GUI's, if resolved), else only the .aicb.json sidecar next to the .sln. |

### compare_with_previous

Diff the current session against a previously saved snapshot of the SAME solution - the newest by default, or the N-th previous via snapshotsBack (0=newest saved, 1=the one before, ...). Optionally narrow the diff to a single type and/or method. Returns added/removed types plus, per changed type, added/removed methods and signature changes. Requires a sessionId and at least one earlier save_session; dbPath is optional and defaults to the server's standard config DB when omitted. Name-based, syntactic (no method-body diff). A 'note' leads the answer when the baseline was saved with the file-set hash the session still holds and the diff is empty: then it most likely compares one state with itself; with an equal hash saved by another analyzer build it says a difference can come from the analyzer.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The current session_id (the 'after' side of the diff). Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `dbPath` | string \| null |  | Optional absolute path to the aicb SQLite DB holding the saved snapshots. Omit to use the server's standard config DB. |
| `snapshotsBack` | integer |  | 0 = newest saved snapshot, 1 = the one before it, etc. (index into the per-solution history, newest first). |
| `typeName` | string \| null |  | Optional: restrict the diff to this type (simple name, case-insensitive). Omit for the whole-solution diff. A simple name ALSO matches the namespace-qualified form the diff renders for a type whose simple name collides in the solution - then the answer spans every type of that name and 'note' says which; pass one of those qualified names to narrow to a single type. Not a substring match: 'MyApi' never matches 'MyApiExtensions'. When a filter EMPTIES a diff that did have changes, 'note' says so and names the axis that missed, because 'isIdentical: true' then describes the filtered view and not the solution. On a diff that was ALREADY empty there is no note and none is owed: 'your filter matched nothing' and 'nothing changed' are the same state there, so a typo'd name and a real one answer identically - check the spelling with find_symbol rather than reading that agreement as confirmation. |
| `methodName` | string \| null |  | Optional: within that type, restrict to this method name (case-insensitive). Omit for all methods of the type. Same disclosure rule as typeName: if the type matched and this name matches none of its added/removed/signature-changed methods, the type is dropped from the answer and 'note' says which of the two filters came up empty - an empty view here is never evidence that the method is unchanged. |

### coverage_gaps

List what is NOT covered in a scope: 'uncovered' - production methods no test code calls directly - and 'verifiedAbsent' - semantic axes a developer explicitly declared as 'none'. find_tests_for asks the opposite question for one symbol.

THE LIST IS ONE HOP, NOT A COVERAGE MEASUREMENT: a method a test reaches THROUGH another method is listed although it is exercised. So read each entry's testReachDepth: the hops to the nearest directly called method (1 = one of those calls it), ABSENT when no test reaches it: the real gaps. The walk follows interface, abstract and virtual dispatch; an entry reached only that way carries viaDispatch. A missing depth is unknown, not measured, where marked: commandCreditRefused (a test may run its command beside another) or unfollowedAccessor (an unfollowed setter, indexer, event accessor or explicit interface getter calls it). outerType: the type a nested declaring type sits in.

Returns scope, a 'note' when uncovered is non-empty or no namespace matched, symbolsScanned, uncovered and verifiedAbsent (max 200 each), transitivelyReached, judgedUnits, testProjectsExcluded, testFixtureTypesExcluded, reachedOnlyThroughDispatch, commandCreditRefused and unfollowedAccessorCallers. uncovered is sorted by type and name; on a large scope the cap cuts alphabetically, so narrow it.

What counts: test code is every method of a test project, every test-attributed method and every method, constructor or getter of a type that declares one. Only ordinary methods are judged. A constructor is a hop (new X(...) reaches the bound overload and its callees), and so is a property read (into its getter). Abstract and interface declarations are excluded, and a weak test-name match does not count.

judgedUnits: the methods the list is drawn from, of symbolsScanned (0: no namespace matched); testProjectsExcluded and testFixtureTypesExcluded: what was set aside as test code.

Read-only. scope is 'solution' or a namespace prefix, case-insensitive, matched on segment boundaries. There is no test switch.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `scope` | string |  | 'solution' (default) or a namespace prefix to narrow which symbols are checked. |

### describe_api_surface

List the PUBLIC API SURFACE of a solution or namespace - every externally-visible type with its externally-visible members (constructors, properties, fields, events, methods, user-defined operators), each as a compact declaration signature. The "header"/contract view: what a consumer of this assembly can actually reference, WITHOUT the source bodies (like a public-API digest, not a firehose). A type is included when its OWN declared accessibility is externally visible - public or the protected family (reachable by a subclass in another assembly); its members likewise. A property renders only the accessors that are themselves visible (a { get; private set; } shows as { get; }), a const carries its value, an enum is listed as a type (its values are not in the model). includeInternal=true additionally surfaces the internal family. PRODUCTION-FOCUSED: test projects are excluded by default (a shipped API surface is production code) - set includeTests=true to include *.Tests/*.Spec projects. scope='solution' (default) covers everything; a namespace prefix narrows it, and one that matches no namespace gets a 'note' ahead of typesScanned 0. The type list is capped (the true total travels in the envelope; narrow by namespace or filter to see the rest); members per type are whole. Recall-safe (reads persisted accessibility + signature facts) → works on live AND recalled sessions. Known v1 simplifications: accessibility is the type's OWN declared modifier (effective accessibility through the nesting chain is not computed - a public member of a type nested in an internal type is still listed); a type declared with NO access modifier is stored as private by the analyzer, so a modifier-omitted (compiler-internal) top-level type is not surfaced even with includeInternal. Use it to review a public contract before changing it, or as the baseline for a contract comparison - save_session then compare_with_previous, or diff_public_contract, which is outside the default profile's pool.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `scope` | string |  | 'solution' (default - the whole solution) or a namespace prefix (e.g. 'MyApp.Contracts') to narrow the surface. |
| `includeInternal` | boolean |  | Include the internal family (internal / private-protected) types + members too (default FALSE = only the externally-visible public/protected surface). |
| `includeTests` | boolean |  | Include test projects (default FALSE - a shipped API surface is production code). Set true to include *.Tests/*.Spec projects. |

### detect_circular_dependencies

Detect circular NAMESPACE dependencies: groups of namespaces that depend on each other in a cycle - a modularity smell the compiler allows, unlike project-reference cycles. The layer-violation insight in list_insights checks the direction rule; this answers the orthogonal 'who is mutually entangled?'.

Use it before splitting an assembly or moving types between namespaces.

Returns scope, namespacesScanned, cyclesFound and cycles, at most 100. Each cycle is a strongly connected component of two or more namespaces and carries namespaces, size, projects, spansMultipleProjects, edgeCount, edgesTruncated and edges: one 'witness' type -> type reference per directed namespace pair (fromNamespace, toNamespace, fromType, toType, typeEdgeCount). Read the witnesses as EXAMPLES, not as a work list: edgeCount counts directed namespace pairs, and typeEdgeCount says how many distinct type references cross that one boundary. Where it is above 1, removing the shown reference leaves the edge standing. Cycles that span assemblies come first, then the largest. Witness edges are capped per cycle, and edgesTruncated says when; the namespace list is complete. A cycle inside one assembly is namespace organisation; one that spans assemblies means a namespace is reused across DLL boundaries.

Edges come from the type references a type's facts record by full name - member, field, parameter, return and typeof types, base class and interfaces among them - so a same-named type in two namespaces is never conflated, and external references are ignored.

cyclesFound 0 under scope 'solution' means no cycle among the scanned namespaces. Under a prefix it only means no cycle touches a namespace starting with that text, and an unknown prefix answers the same zero.

Read-only; works on a recalled session. Test projects are excluded by default (includeTests=true includes them). scope is 'solution' or a plain case-insensitive namespace prefix: it narrows the report, not the graph, and returns a whole cycle when one of its namespaces matches.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `scope` | string |  | 'solution' (default - all cycles) or a namespace prefix to report only cycles whose members include that prefix. |
| `includeTests` | boolean |  | Include test projects (default FALSE - production focus: a test->production reference is one-way and not an architecture cycle). Set true to include them. |

### docs

The aicb operating manual - how to USE this server, as opposed to what it can tell you about your code. Call it with no arguments for the directory (each page with a one-line summary and a token estimate, so you can budget); pass one or more page ids to read them, or the route id 'init' for the whole first run in order. Pages: 'overview' (what aicb is and is not, the three ways to run it), 'install' (getting the dotnet tool, `aicb init`, and what it writes - the client's .mcp.json entry and the agent skill a tool install cannot deliver; for setting aicb up somewhere else, or finishing a half-done setup), 'first-context' (from a .sln to your first context - and why the full export is rarely the right call), 'navigation' (which tool answers which question about the code, the blast-radius call before editing shared code, and where plain text search is still right), 'solution-config' (layers / exclusions / test detection and the .aicb.json sidecar), 'glossary' (session, facet, MCP profile, snapshot, insight, AI-Builder MD). Start here if you have not used aicb before. No session and no solution needed.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `topics` | array \| null |  | Optional page or route ids. Omit for the directory. A route id ('init') expands to its pages in reading order; repeats collapse, so asking for a route and one of its pages yields one copy. Unknown ids are named back to you rather than silently dropped. |

### evaluate_change_set

Advisory policy gate: which code-quality / design-smell / layer-violation findings would this edit INTRODUCE? Ask BEFORE writing it. Cheapest form - the edit you are about to make anyway: changes: [{filePath, oldText, newText}], the snippet being replaced and what it becomes (the shape an editor takes). The full file is rebuilt here from the analyzed document, so the payload is the size of the CHANGE, not of the file, and 'operation' defaults to 'modify'. oldText must occur EXACTLY ONCE - a missing or ambiguous anchor is an error, never a silently different edit; line endings are reconciled for you; an empty newText deletes the snippet. Full-text form still works and is required for add/delete: {filePath, operation: 'modify'|'add'|'delete', newContent}. Findings are a delta against the current session, so pre-existing debt is never blamed. The changeset is applied as an in-memory Roslyn overlay (NO disk write, the session is untouched) and the amended solution is re-analyzed. Verdict: pass / warn / block. Policy: 'block_on_critical' (default) | 'block_on_warning' | 'advisory' (an unknown policy is rejected, not silently treated as advisory). Advisory only - an MCP tool cannot block; the real blocking gate is the CLI '--fail-on'. The findings delta honors the session's explicit layer profile (analyze_solution(layerProfile) / sidecar) and its resolved test-detection profile on both sides; pass dbPath to also use that DB's active QualityProfile (producer thresholds + toggles) and its configured default layer profile (per-solution > app-global; the explicit session profile still wins) - same semantics as list_insights, so the gate judges by the same configured thresholds as the CLI gate. apply_change_set is out of scope. Pass absolute file paths matching the analyzed documents.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution (the baseline). Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `changes` | array | yes | The proposed file changes. Per change: filePath (absolute), plus EITHER the anchor patch oldText + newText (preferred - 'operation' may be omitted, it defaults to 'modify') OR the full new file text newContent with operation 'modify'/'add' ('delete' takes neither). |
| `policy` | string \| null |  | Policy: 'block_on_critical' (default) \| 'block_on_warning' \| 'advisory'. |
| `dbPath` | string \| null |  | Optional path to an AIContextBuilder SQLite DB. When set, producer thresholds + toggles come from that DB's active QualityProfile AND its configured default layer profile (per-solution > app-global) drives the layer-violation analysis on BOTH delta sides (an explicit analyze_solution(layerProfile) wins); omit to fall back to the server's default config DB (the GUI's, if the server resolved one), else the default profile + session axes, and the layer profile to the config DB the session was analysed against - the one its renders read. |

### explain_symbol

Explain a symbol: its source PLUS a chosen environment, as ONE dense AI-Builder-Markdown slice - the cold-read in a single call instead of 4-6 (get_context + find_usages + find_implementations + find_tests_for + ...). 'include' selects the environment axes (any combination): callers (the members that reference it, with their bodies, and their owner types as structure - not the calling types whole), callees (what it calls/depends on, depth 1), implementations (the types implementing it, if it's an interface), tests (its covering test cases), siblings (naming/file-convention kin), quality (complexity / efferent-coupling hotspot metrics). A partial type renders as ONE block per project it is compiled into (its declaration fragments are folded, a leading comment says which files) instead of one identical block per file; a file compiled into several projects whose block reads the same in each renders once, naming them. An empty include returns just the symbol's source - and then the manifest names the axes you could have asked for, so that answer is a stated choice rather than a silent default; an include token that names no axis is reported as dropped, whether or not a sibling token was valid. A leading manifest comment discloses what each merge axis actually found - so '(none)' is an honest negative (no impl / no caller / no test), not 'not asked' - unless its 'run:' segment says the analysis run was incomplete. Pass a type or method simple name (use find_symbol to disambiguate). Recall-safe (reads persisted facts); prefer it over export_markdown for one symbol's world. Multi-TFM solutions are deduplicated to one declaration per type (the NEWEST TFM's where it has one), as find_symbol lists them.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The type or method simple name to center on (use find_symbol to disambiguate), or the qualified Type.Member form to focus ONE declaration of a shared method name - the same string find_usages / find_tests_for / impact_of_change resolve. A bare name that matches several declarations seeds them all (a whole family can then be budget-capped), and the manifest says so and names the qualified form. |
| `include` | array \| null |  | Which environment axes to include (any combination, case-insensitive): callers, callees, implementations, tests, siblings, quality. Empty/omitted = just the symbol's source. |
| `budget` | integer \| null |  | Optional token budget (floored at 8000). Compacts/drops method bodies and, when the neighborhood overflows, drops the least-relevant types. The center symbol is always kept - with its full source when that fits, otherwise as STRUCTURE (identity, members, every method signature) plus a leading note that names the measured size of the full-code render and the budget that would hold it, so a 2000-line type under budget:8000 costs ~2000 tokens, not ~24000. The bundled environment (callers / tests / siblings / implementations) is BUDGET-BOUND - under a tight budget it is dropped to fit (a leading comment names the drops so you can ask for one by name). Omitted, the slice still renders against a ceiling (the active MCP profile's token budget, else a ~10000-token default budget) that bounds the merged environment - relevant above all with include=["callees"], whose outward neighborhood is the widest slice this server produces. |
| `lean` | boolean |  | Lean slice (default TRUE): drop the &lt;AI_CONTEXT_SPEC>/&lt;AI_CONTEXT_META> format-rules preamble and omit enabled-but-empty graph sections. Set false for the full AI-Builder-MD document with the format contract. |

### export_markdown

Render the cached analysis of a session as AI-Builder Markdown. No re-analysis - instant. NOTE: this renders the WHOLE solution - on a large codebase that is many megabytes, and an answer over the server's message ceiling (16,000,000 bytes as JSON unless AICB_MCP_MAX_RESPONSE_BYTES says otherwise) is not sent: the call is refused with its size, because MCP clients drop larger messages. Pass outputPath for anything but a small solution. For a bounded view prefer architecture_overview (whole-solution orientation, structural-only, no per-type source) or get_context / explain_symbol (one symbol's world). When the server has a config DB (the default: a plain 'aicb mcp' resolves the standard one), the active MCP profile drives the render: the chosen facet's template (detail presets, graphs, line numbers, quality metrics) is used; otherwise the full default render is used. Returns the Markdown; if outputPath is given it writes the file and returns a short confirmation (not the full content), so a large render does not flood the response.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `facet` | string \| null |  | Optional facet to render through - the task axis of this call: General (default), Exploration, Refactoring, Debugging, Review, Testing, Documentation, Architecture, or Performance. The facet picks the active MCP profile's matching template and appends a short work-style trailer with suggested next tools. Unknown/empty falls back to General; a facet whose slot has no template assigned falls back to the active context template. (The former name 'slot' is still accepted.) |
| `outputPath` | string \| null |  | Optional absolute path to write the Markdown to (UTF-8, no BOM). When given, the tool writes the file and returns a short confirmation (path + size) instead of the full markdown - so a large (whole-solution) render does not flood the response. |
| `format` | string \| null |  | Optional inner notation of the rendered Markdown: 'tag' (the established AI-Builder tag format) or 'yaml' (idiomatic YAML - a lossless re-notation, not a different selection of content). Pick whichever notation you parse more reliably. When given, this explicit value wins; when omitted, the active MCP profile's OutputFormat is used (profile-aware path), else yaml (the DB-free default). The .md branding is unchanged. Any other value counts as omitted: the profile's format (else yaml) applies, and the response starts with a note naming the ignored value. |

### find_binding_usages

List the {Binding ...} sites in the solution's .xaml and .axaml markup that name a member path, with what each one resolves against. find_usages carries a markup edge for a root member bound against the DataContext; this tool lists every site, redirected bindings included. find_unresolved_bindings checks whether a bound member exists on its view-model.

Use it before renaming or deleting a view-model member.

With a path: sites (view, line, path, form), siteCount, byForm, deeperSegmentSites(+Count), pathlessBindingCount, scannedFileCount, sitesTruncated, note. form is dataContext (no redirect), elementName, relativeSource, source or xBind (WinUI {x:Bind}; in byForm only when non-zero). A path matches as the whole path or as its ROOT segment: 'Foo' finds {Binding Foo} and {Binding Foo.Bar}. The 'Bar' of {Binding Foo.Bar} is a member of Foo's type and is reported apart in deeperSegmentSites. On an elementName or relativeSource binding a leading 'DataContext.' is the hop to the element's view-model: {Binding DataContext.Cmd, RelativeSource=...} is a site of 'Cmd'.

Without a path: the inventory - members (member, siteCount, byForm), most-bound first, with distinctMemberCount and totalSiteCount. Lists cap at 200; counts are true totals. pathlessBindingCount counts every binding without a plain member root (an empty {Binding}, {Binding Mode=OneWay}, an attached path) over the whole solution, whatever scope and form say.

The markup is read from disk at every call, so a markup edit needs no refresh_session. Only the {Binding} markup extension ({CompiledBinding} too in .axaml) and {x:Bind} are read: a binding built in code-behind, element-syntax &lt;Binding Path="..."/>, {TemplateBinding} and a path assembled at runtime are invisible here - zero sites means 'verify before renaming or deleting', not proof.

Read-only; test projects are scanned too. path is a case-sensitive markup path and is not resolved as a symbol. An unknown form matches nothing, and the note says so. scope is 'solution' or a substring of the view path.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `path` | string \| null |  | The exact (case-sensitive) bound member path, e.g. 'GestureLabel' or 'Foo.Bar'. Omit for the inventory view (every bound root member with its site counts). |
| `scope` | string |  | 'solution' (default) or a view-path substring (e.g. 'AIContextBuilder.UI/Views/Dialogs') to narrow which markup files are reported. |
| `form` | string \| null |  | Optional form filter: 'dataContext', 'elementName', 'relativeSource', 'source' or 'xBind'. Omit for all forms. Applies to both views. |

### find_by_attribute

Find symbols (types, methods, properties or fields) that carry a given ATTRIBUTE - a cross-cutting query that find_symbol (name-only) cannot do. The attribute name is matched format-independently: the last name segment, with an optional 'Attribute' suffix stripped, case-insensitive. So 'Obsolete', 'ObsoleteAttribute' and 'System.ObsoleteAttribute' all match the same symbols (types store the fully-qualified attribute class, methods/properties/fields store the source-syntax name - this reconciles both). The raw stored attribute list travels with each hit so you see the ground truth. kinds = 'all' (default - types + methods + properties + fields) / 'type' / 'method' / 'property' / 'field'. Member scanning surfaces a member-level attribute like a CommunityToolkit '[ObservableProperty]' (on a backing field or a modern partial property) or a '[JsonProperty]' that a type/method-only scan misses. Use it for '[Obsolete]', '[ApiController]', '[Authorize]', test attributes, etc. The 'method' axis includes constructors and accessors with a body (named .ctor / get_X / set_X), so a [JsonConstructor] or an [Obsolete] setter is found. A partial type is one type row; 'fullName' marks namesake type rows (Foo, Foo&lt;T>), 'project' the twin rows of a linked file, 'declaringTypeFullName' and 'signature' member rows that would read alike (overloads, members of nested or generic namesakes). Deterministic from Roslyn - works on recalled sessions. Capped at 200.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `attribute` | string | yes | The attribute to find (e.g. 'Obsolete', 'ApiController', 'Fact'). Suffix/namespace are normalized away - required. |
| `kinds` | string |  | Which symbol kinds to search: 'all' (default - types + methods + properties + fields), 'type', 'method', 'property', or 'field'. |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.Api') to narrow scope. |

### find_by_event_subscription

Find the TYPES that subscribe to a C# event: a '+=' whose left side resolves to an event, anywhere in the type; external events too ('Button.Click'). find_usages on a solution-declared event lists its (un)subscribing and raising METHODS.

Use it for 'who listens to this event?', where handlers are wired, and as a leak hint. A '+=' on a number, string or delegate field is no subscription and is skipped. XAML-wired handlers (Click="OnClick") are 'markupWires' (handler, viewCount, views), owe no '-=', are never 'unreleased'; no event is recorded with them, so eventName cannot match them.

Returns scope, event, typesScanned, subscriptionSitesChecked, subscriptionSitesUnresolved, matches (at most 200 types: name, namespace, events, unreleased, markupWires; sorted by namespace, name) and when they apply 'note', availableEvents, testMatchesFiltered. A partial type is one row ('files' when spread over several); 'fullName' marks namesakes, 'project' linked-file twins. A hit lists ALL event keys ('DeclaringType.EventName') the type subscribes to.

'unreleased' lists each subscription no '-=' of the type removes ('Event <- Handler'). A '-=' counts for the same event AND the same handler on ANY receiver, so an old/new swap reads released; a lambda never matches, so a lambda subscription is always listed; a subscription to an object the type owns is listed although it cannot outlive it. [] means each has a matching '-='; no list means not measured (see the note). A place to look, not a proven leak.

Reading an empty answer: availableEvents lists the events subscribed in scope; read testMatchesFiltered first if present. An EMPTY availableEvents means none was RECORDED - recognition needs a resolved left side. The site counts settle it: '0 of 0' is nothing to see, '0 of 7, 0 unresolved' a real absence, '0 of 7, 7 unresolved' an unmeasured scope.

Read-only; works on a recalled session. eventName matches exactly, never as a substring; omit it for every subscribing type. Test-project types are excluded unless includeTests=true.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `eventName` | string \| null |  | Filter to types subscribing to this event - the event name ('Click') or the qualified 'DeclaringType.EventName' key ('Button.Click'), case-insensitive. Omit to list every type with any subscription. |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.UI') to narrow scope. |
| `includeTests` | boolean |  | Include test-project types (default false - production focus; test setup that wires events would drown the signal). |

### find_by_semantics

Find types and methods by their resolved semantics: layer, role, domain, responsibility. Filters combine with AND, and each hit names where a matched value came from.

Use it for 'which types of layer X carry role Y?'. At least one filter is required.

layer and role match the WHOLE value, case-insensitively: role='View' is one view, not every ViewModel. Values that merely contain the query are counted in nearMisses (axis, value, symbols) and named in a leading 'note', never listed as matches. domain and responsibility are free text and match as a case-insensitive substring; responsibility exists on types only, so setting it matches no method. The echoed criteria show the mode ('role=View' vs 'domain~order').

Returns criteria, a 'note' when there are near misses, minConfidence, matches - at most 200 items (kind, name, declaringType, namespace, matched), types first - and when they apply availableAxisValues, unclassifiedAxes, verifiedAbsentAxes and nearMisses. matched lists per filtered axis the field, the value and its source: 'fact', 'ai', 'inferred' or 'none'.

The layer and role values the built-in inference assigns are listed on those parameters; there is no 'Repository' role and an enum gets none. A layer profile or an &lt;ai> annotation adds values in its own spelling ('viewmodel-item' beside 'ViewModel'). Nothing infers a domain: that axis matches only where an &lt;ai> annotation set one.

On zero matches availableAxisValues lists, for the queried axes, the values present under the same minConfidence (up to 50 per axis). A queried axis no symbol carries a value on at that confidence (so nothing can match it here) is in verifiedAbsentAxes when every symbol declares it 'none' via &lt;ai>, otherwise (only some declare it, or no symbol does) in unclassifiedAxes. A queried value missing from availableAxisValues is unknown at that confidence; if it is listed there, the AND of your filters was empty. An axis you did not query is in no list.

Read-only; test-project symbols are matched like production ones.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `layer` | string \| null |  | Match symbols whose resolved Layer EQUALS this (whole value, case-insensitive). The built-in inference assigns Domain / Application / Infrastructure / Presentation / Contracts; a layer profile adds its own names. Omit to not filter on layer. |
| `role` | string \| null |  | Match symbols whose resolved Role EQUALS this (whole value, case-insensitive). Inferred TYPE roles: Service, Helper, Model, Record, Interface, Builder, ViewModel, Converter, Controller, Middleware, Attribute, Exception, EntryPoint, ContractModel, Type - there is NO 'Repository' (a repository class is mostly 'Service'), and an enum gets no role. Methods use a category role (e.g. Query, Command, Mapping, Validation, Orchestration). &lt;ai>-asserted roles add values of their own. Omit to not filter on role. |
| `domain` | string \| null |  | Match symbols whose resolved Domain contains this (free text, set by an &lt;ai> annotation - nothing infers it). Omit to not filter on domain. |
| `responsibility` | string \| null |  | Match TYPES whose resolved Responsibility contains this (types only; free text). Omit to not filter. |
| `minConfidence` | string |  | Confidence floor: 'any' (default - include inferred guesses) or 'asserted' (only fact/ai). Any other value is rejected (not silently treated as 'any'). |

### find_by_side_effects

Find code by its side-effect profile: what a method touches in the outside world. Each unit carries effect tokens from a closed set - io, network, database, serialization, logging, cache, messaging, unknown ('unknown' = an external call the analysis could not classify) - or none, which makes it pure. calls_external lists the external calls and property accesses behind a token; an effect that comes from a 'new X()' or is inherited from a callee has no row there.

Use it for 'what hits the database or the network?' and to find pure methods. Effects are propagated along calls and creations: calling a method or building an object that writes a file counts as 'io'.

With neither effect nor purity, only impure units are listed. An effect or purity outside its vocabulary, or effect with purity='pure', is rejected with the valid values, never answered with a silent zero.

Returns scope, effect, purity, methodsScanned, matches - a capped envelope of at most 200 hits (name, declaringType, namespace, effects) - and when they apply 'note', availableEffects, methodsScannedNote and testMatchesFiltered. The units are methods plus every accessor and constructor with a body, under their metadata names (get_X, set_X, .ctor, .cctor), and, unscoped, each top-level-statement file ('Program.cs (top-level)'); the purity='pure' listing is methods-only. A hit does not say which of its effects are direct and which inherited.

On zero matches availableEffects lists the tokens present in scope, so an empty result reads 'valid token, nothing in scope records it'; the note quotes what the token means ('cache' = an external cache API, not an in-memory cache); it is omitted when nothing was scanned. A 'note' leads the answer when a project's core references did not resolve: an unresolved run reports methods as PURE that are not.

Read-only; works on a recalled session. Test-project code is excluded by default (includeTests=true includes it); testMatchesFiltered counts what the filter removed, units methodsScanned does not include.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `effect` | string \| null |  | Filter to methods carrying this effect token - exactly one of: io, network, database, serialization, logging, cache, messaging, unknown (case-insensitive; any other value is rejected, not answered with zero). Omit to not filter on a specific effect. |
| `purity` | string |  | 'any' (default), 'pure' (only side-effect-free methods), or 'impure' (only methods with at least one effect). |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.Infrastructure') to narrow scope. |
| `includeTests` | boolean |  | Include test-project methods (default false - production focus: a 'what hits the DB?' query is otherwise drowned by Seed*/Migrate_*/*RepositoryTests). Set true to also list the methods of test projects. |

### find_dead_code

List dead-code suspects on two axes. kinds='type': types with no incoming reference find_usages sees. kinds='method' (the default): PRIVATE methods whose recorded caller list is empty. kinds='all': both.

The default axis skips a private method a framework may call ([RelayCommand] or other framework attributes, partial methods, markup or designer event handlers, static Main, record PrintMembers, ShouldSerialize/Reset) or whose callers were not measured (unresolved references, explicit interface implementations). A nameof in an attribute (CanExecute) or a reflection lookup (GetMethod) counts as a use. *.Designer.cs and *.g.cs files are read for references, never judged.

Returns scope, a 'note' first when there is one, methodsScanned, deadMethods and - when the type axis ran - typesScanned and deadTypes: at most 200 items each (methods: name, declaringType, namespace; types: name, kind, accessibility, namespace, publicApi:true on a library's public type (publicApiNote); alike rows add declaringTypeFullName, signature, fullName or project). Counters, each omitted at zero: what was not judged - methodsIneligible and typesIneligible, each split by reason (methodsIneligibleNotPrivate, -FrameworkInvoked, -UnanalyzedCallers; typesIneligibleStructural, -TestScaffolding, -FrameworkActivated, -MarkupReferenced), typesUnexamined (what the type axis would have judged) - and the candidates the test filter removed, testMethodsFiltered and testTypesFiltered.

A listed candidate is a suspect: the note says what zero fan-in does not prove and how to confirm one. The type axis exempts what it cannot see being used: interfaces, static classes, *Extensions types, test scaffolding, framework- or reflection-activated and markup-referenced types. An empty answer without a note means an axis judged an eligible population and found nothing; for the method axis read methodsIneligible against methodsScanned.

Read-only; works on a recalled session. Test projects are excluded by default. Other non-blank kinds value runs both axes.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.Core') to narrow scope. |
| `includeTests` | boolean |  | Include test-project methods/types (default false - production dead-code; a private test-helper without callers is not production dead code). |
| `kinds` | string |  | 'method' (default): private methods with a measured, empty caller list - see the description for what that axis does not judge; 'type': types with no incoming reference; 'all': both. |

### find_implementations

List the types that implement an interface, in the solution or external (IDisposable). The interface counterpart to get_type_hierarchy (classes) and find_overrides.

Use it before changing an interface member, to find every type that must follow.

Returns items [{name, isAbstract (absent on interfaces and unknown kinds), kind, isTestProject, namespace, declaration, via, closes, through, generated (a generator's type)}], count, totalFound, truncated - at most 100, items without via first, then by name. 'declaration' = a generic's arity form ('PolicyWrap&lt;TResult>'); via:'back-edge' = known only from the interface's implementer list, 'inherited' = through a solution base class or interface, 'derived-interface' = an interface extending it (implements nothing). 'closes' = the type arguments closing a generic interface, through bases too ('ContentSavedNotification'; an open generic names its own type parameter); 'through' = the base or interface it comes through. Absent when empty or unreadable.

A closed query ('IHandler&lt;Saved>') keeps the types closing it with those arguments; typeArgumentFilter counts the others closing it otherwise (otherClosings) or only over their own type parameters (openClosings). typeArgumentBase keeps the types closing it with an argument that is, derives from or implements that type ('DeletedNotification&lt;T>'); typeArgumentBaseFilter gives familyTypes and leftOut. An unreadable closing stays, marked closing:'unresolved'.

Test-project implementers are excluded by default; testImplementationsFiltered counts them (absent = none).

An empty answer carries a 'hint' when the name is not an interface or no indexed type carries it (a did-you-mean if one is close), and a 'generatedCodeNote' when a generator that did not run may have added it. A leading 'note' marks the inventory partial when a project's core references did not resolve (restore or build, then refresh_session).

Read-only. interfaceName is the simple name, case-sensitive. Two interfaces sharing a simple name answer as one list.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `interfaceName` | string | yes | The interface's simple name, e.g. 'ICodeAnalyzer'. An arity suffix ('IConsumer`1' / 'IConsumer<T>', or 'IConsumer`0' for the non-generic namesake) filters to that arity; a bare name keeps the merged view of every arity. A concrete type argument ('IConsumer&lt;OrderPlaced>') keeps only the types that close it with that argument. |
| `includeTests` | boolean |  | Include test-project implementers (default false - production focus). |
| `typeArgumentBase` | string \| null |  | Optional: keep only the types that close the generic interface with a type argument that is this type or derives from or implements it - a simple name, case-sensitive, with an arity suffix for a generic ('DeletedNotification&lt;T>', 'ICancelableNotification'). Only solution types form the family; when none matches, typeArgumentBaseFilter carries a note. |

### find_overrides

List the override-to-base relationships for methods of a given name - the class-inheritance counterpart to find_implementations (which covers interfaces). Each row pairs an overriding method with the nearest ancestor in its base-class chain that declares the virtual/abstract method it overrides: 'Derived.M(params) overrides Base'.

One call answers both 'who overrides this virtual/abstract method?' (impact, before you change a base method) and 'what does this override?' (comprehension). For a type's base and derived types use get_type_hierarchy; for the callers of a method use find_usages.

Returns a capped envelope: items (the rows, sorted), count, totalFound, truncated - at most 100 rows. Empty items means no method of that name is an override. When the overridden base is a BCL/framework virtual outside the solution (object.ToString, Stream.Dispose) the row reads '... overrides (external base)'; one a source generator wrote reads 'Derived.M(params) (generated) overrides Base'.

Types render in their DECLARATION FORM ('Strategy&lt;T>.M(...) overrides ResilienceStrategy&lt;TResult>', the render get_type_hierarchy uses), so a generic and a non-generic namesake stay separate rows. A row carries no namespace: two same-named types that differ only by namespace collapse into one row, so read a row as the relationship, not as one attributed type; 'mergedNamesakes' names each such row and its types.

Read-only: it reads persisted facts and also works on a recalled session. Parameters: a qualified methodName ('Widget.ToString') matches nothing. There is no type filter, and each overload is a row of its own. An empty answer carries 'nearest' when a close declared method name exists - for a qualified methodName the bare method name.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `methodName` | string | yes | The method's exact (case-sensitive) simple name, e.g. 'ToString' or 'Dispose'. |

### find_resource_usages

Resource-key fan-in across the solution's XAML/AXAML markup AND its C# sources - the question the C# symbol graph cannot answer because resources are wired by string key, not by symbol. With a key: where it is DEFINED (x:Key, file:line), every REFERENCE (file:line + kind: 'static'/'dynamic' for the markup extension, since a theme-swapped brush must be dynamic; 'theme' for WinUI's {ThemeResource}; 'code' for a C# string literal equal to the key; 'callerMemberName' for a C# member named like the key that reads it through a [CallerMemberName] resource accessor), and same-file duplicate definitions (in a compiled resource dictionary a duplicate silently shadows a neighboring key; a same-named key in DIFFERENT files is usually a theme pair, so only same-file counts as a collision). themeReferenceCount and callerMemberNameReferenceCount appear only when not zero. Without a key: the audit view - every never-referenced key (deletion candidates; deleting a still-referenced key compiles clean and throws only at runtime) + all same-file collisions + every referenced key no markup defines: misspelledKeyCandidates (one slip from a defined key) and notDefinedInSolutionKeys (most often a theme's or the platform's key - unknown, not broken). Reads the CURRENT .xaml/.axaml/.cs files on disk (bin/obj/.vs excluded) - never stale after an edit, no refresh_session needed, works on recalled sessions. STRING keys only (a structural x:Key="{x:Type ...}" is out of scope); the ResourceKey= long form, the element &lt;StaticResource ResourceKey="..." /> and a markup extension the solution derives from StaticResourceExtension/DynamicResourceExtension are read. XML-commented markup is ignored. Still invisible: a key assembled at runtime, a non-.cs source, a resource-extension subclass from a referenced library, a library template resolving the key from its own dll - zero references means 'verify before deleting', not proof. Lists capped at 200.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `key` | string \| null |  | The exact (case-sensitive) resource key, e.g. 'TextPrimaryBrush'. Omit for the audit view (never-referenced keys, same-file collisions, keys no markup defines). |
| `scope` | string |  | 'solution' (default) or a view-path substring (e.g. 'AIContextBuilder.UI/') to narrow which files are reported. In the audit view the scope narrows the DEFINITIONS under audit; references still count solution-wide, so a key referenced outside the scope is not a false orphan. For the keys no markup defines it is the other way round: the scope narrows the REFERENCES under audit, and a definition anywhere in the solution counts. |

### find_symbol

Find types, methods, properties, fields, events, enum members and operators whose name contains the query (case-insensitive). Returns each match with kind ('type'/'method'/'property'/'field'/'event'/'enum_member'/'operator'), name, declaring type (a nested type's outer one; a member of a nested type adds 'outerType'), namespace, a signature, 'project' where two hits would read alike, and 'generated' (its document's label) on a generator's declaration. Use this to locate a symbol before find_usages / call_graph / get_context - every kind listed here is one find_usages / impact_of_change resolve. Types are listed first, then methods, then properties (handwritten + source-generated - a generated property carries a '// source-generated' note in its signature), then fields, events and enum members (an enum member's signature is its qualified Enum.Member form, the string the fan-in tools take), then user-defined operators + conversions. A user-defined operator is found by its METADATA name (query 'op_Equality' / 'op_Addition' / 'op_Implicit'; 'op_' lists them all). Not indexed, so an empty answer is expected for them: local variables, parameters, labels, namespaces, and C# generated into obj/ that carries real declarations (protobuf/Grpc.Tools, T4, Refit), and a Blazor component written only in a .razor file - a zero-hit answer says which in 'generatedSourcesNote'. Results are ranked by match quality FIRST - exact name, then case-insensitive exact, then prefix, then substring - and only within one rank by the kind order above, so the cap never hides an exact match behind weaker substring hits. Returns a capped envelope (items/count/totalFound/truncated), max 100 - if truncated, the exact/prefix matches are the ones you got; narrow the query (a longer substring) to see the weaker rest. If the query matches nothing, the response carries a 'nearest' suggestion - the closest declared name (a likely typo/case-mismatch); a match never carries one. With no nearest either, a 'note' says a missing name is not a missing feature.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `query` | string | yes | A substring of the symbol name to search for (type, method, property, field, event, enum member or operator). |

### find_tests_for

Find the tests that likely cover a symbol: test methods that call it, read it, build it or are named after it. Static evidence (coverage_gaps asks the reverse).

Use it before a change, to see what pins a symbol, and after, to pick tests. Only a method with a test attribute counts (default: Fact, Theory, Test, TestMethod, TestCase(Source)).

Returns items [{testType, testMethod, project, matchReason}] (+ 'testTypeFullName' where two read alike), count, totalFound, truncated (max 50), invokesTotal, dispatchTotal (omitted at 0) and an optional 'note' after the list. matchReason is one of eleven tiers, sorted: 'invokes' (it calls the target), 'invokes-via' (through one method or constructor), 'command' (it executes the target's command), 'command-via', 'accesses' (it reads or writes the target property or field; for a type, a static one), 'accesses-via', 'constructs' (it builds the target type; type and constructor queries only), 'constructs-via', 'dispatch' (it calls an interface, abstract or virtual member the target implements or overrides; a double may have run), 'dispatch-via' and 'name' (a guess: the test's or its class's name mentions the symbol - for Type.Member, both). The first eight are strong; invokesTotal counts them over the result and dispatchTotal the contract rows, the rest are name guesses.

Evidence reaches one call deep at most (the test's body and one method, constructor or getter it calls). The 'note' says so on an empty answer and on a non-constructor one whose strong rows are all '-via', and names other misleading cases: an undeclared name or type segment (name noise), an event or enum member (name tier only), a nested 'Outer.Inner' type, a constructor query, no strong row, contract rows, construction rows (matched by simple name), overloads unioned, tests left out for only reading a constant. 'namesakes': types sharing the name.

Read-only. symbol is case-sensitive: a type's simple name, a member name bare or as 'Type.Member' (only that type's member), or 'Type.Type' for the constructor.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The type name, or the member name - bare or in the qualified Type.Member form - to find covering tests for. |

### find_unresolved_bindings

List silently broken XAML bindings: a {Binding X} whose root member does NOT exist on its confidently resolved DataContext view-model (typo, removed/renamed member, or wrong DataContext) - neither the compiler nor render-smoke tests catch it.

Use it after renaming or removing view-model members. It judges the ROOT member of a binding path only. Where a member or a resource key is bound: find_binding_usages / find_resource_usages.

Covers WPF/WinUI .xaml (view-model via d:DesignInstance or a unique FooView->FooViewModel convention) and Avalonia .axaml ({Binding}/{CompiledBinding}, only via x:DataType). Conservative BY SKIPPING: a binding whose DataContext scope cannot be typed with certainty (ControlTemplate, any Style but the element's own inline one, runtime DataContext, keyed resources, a DataType-less template unless - WPF only - its host's ItemsSource types it, code-behind setting DataContext = this), or whose view-model has an unverifiable external base, is never flagged. Source-generated ([ObservableProperty]/[RelayCommand]) and inherited members count as resolved. A hit is evidence to verify at its line, not proof.

Returns JSON: count and unresolvedBindings (view, viewModel, member, line; one entry per site), plus markupFilesScanned and bindingSitesInMarkup from a live disk walk. The denominator of count: sitesJudged and sitesSkipped, by reason in sitesSkippedBy (both null on a recalled session); judgementNote names any gap to bindingSitesInMarkup. sitesSkippedByView lists each view's skipped sites by reason with their lines (capped at 100 views).

WinUI {x:Bind} is apart: each path segment is looked up on the page's x:Class or the template's x:DataType; one absent on a non-partial type is listed with form 'xBind' (viewModel = the type looked in). xBindSitesInMarkup/Judged/Skipped/SkippedBy appear only where x:Bind sites exist.

Read-only; LIVE analysis only: call refresh_session after edits (a recalled snapshot reports none, and a 'note' says so).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |

### find_usages

List who uses a symbol (direct fan-in); impact_of_change adds closure and risk, calls_external covers external members.

Use it before changing or deleting a symbol, not grep. What is listed depends on resolvedKind: 'type' - the types that reference it (a doc cref too: docCrefOnly), plus markup views; 'method' - its callers, overloads unioned ('overloads'; item 'calls': its own); 'property' or 'field' - its readers and writers; 'event' - its raisers and (un)subscribers; 'enum_member' - its references; 'operator' ('op_Equality') - its uses, casts too; 'constructor' ('Type.Type') - the type's construction and injection sites. Test users included.

Returns symbol, resolvedKind, usedBy (capped envelope: items, count, totalFound, truncated; max 100). An item is {name, file, line}, one per user: file is solution-relative, line where its declaration starts (not the reference); 'files' [{file, line}] for a type declared in several; absent if unknown; users sharing a name add 'fullName' (a type), 'project'. Optional members qualify it: 'note' ahead of the list (an empty or constructor answer, unresolved core references), 'namesakes' (several types share it, unioned), 'collision' (a same-named other kind, not counted), 'viaContract' + 'viaContractNote' (a qualified method's contract or virtual-base callers), 'selfReferences' (users on the member's own type), 'textuallyInvisibleUsers' (users not naming it), 'nearest' (on 'not_found': a close name), 'resourceKeyNote' (markup keys the type; those views: find_resource_usages).

An empty usedBy on a resolved symbol is not proof of dead code: entry points, DI, reflection, source generators and unrecorded markup leave no reference. 'not_found' is not 'undeclared': a delegate type and a qualified or nested type name answer it; 'note' may say why.

Read-only. symbol is case-sensitive. A type takes its simple name. A member takes 'Type.Member' for one type's, or a bare name: that answers for ONE kind, the first in the order above with users, unioned over its same-named members.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The exact (case-sensitive) type, method, property, field, event, enum-member or operator (metadata) name - the qualified Type.Member form for a member - or 'Type.Type' for a type's CONSTRUCTOR (see the tool description: the answer is the type's construction/injection sites, overloads unioned). |
| `includeTests` | boolean |  | Include users declared in test projects (default true). false lists production users only, BEFORE the 100-item cap, and 'testUsersFiltered' says how many were left out; viaContract keeps counting every caller. |

### get_context

Return a dense, token-budgeted AI-Builder-Markdown slice of the code around a symbol: the symbol's source plus its expanded neighborhood (direct dependencies + callees, depth 1). Pass a type or method simple name (use find_symbol first to disambiguate). budget caps the output in tokens (floored at 8000); omit for full bodies. The fastest single-symbol retrieval - prefer it over export_markdown (which renders the WHOLE solution) when you only need one symbol's context. Multi-TFM solutions are deduplicated to one declaration per type, the NEWEST TFM's where it has one (as find_symbol lists them; export_markdown keeps the unfiltered per-TFM render). Need a CHOSEN environment of one symbol (callers / tests / implementations / quality)? use explain_symbol. Bundling a whole task from a natural-language goal? use pack_for_task (read) or prepare_task (edit-ready: + covering tests & siblings).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The type or method simple name to center the slice on. |
| `budget` | integer \| null |  | Optional token budget (floored at 8000). Caps the slice TWO ways: it compacts/drops method bodies AND - when the expanded neighborhood still overflows - drops the least-relevant non-seed types entirely, ranked by closeness to the seed and in-slice fan-in. The seed itself is never dropped: it renders with its full source when that fits the budget, otherwise as STRUCTURE (identity, members, every method signature) with a leading note naming the measured size of the full-code render and the budget that holds it. A leading comment discloses how many types were dropped. Omitted, the slice still renders against a ceiling (the active MCP profile's token budget, else a ~10000-token default budget) that bounds the neighborhood; pass a value for a tighter slice. |
| `includeQualityMetrics` | boolean |  | When true, also emit the &lt;QUALITY_HOTSPOTS> section plus complexity=""/ce="" tag attributes for the sliced symbols (cyclomatic complexity, efferent coupling). Default false (leaner slice). Set true when reviewing code quality / picking refactor targets. |
| `lean` | boolean |  | Lean slice (default TRUE): drop the repeated &lt;AI_CONTEXT_SPEC> format-rules preamble and the &lt;AI_CONTEXT_META> block, and omit any enabled-but-empty graph section (the ones that would otherwise render just '- none'). On a focused single-symbol slice that boilerplate is >4x the actual signal. The PATH_LEGEND, COMPRESSION_LEGEND (decoding keys) and all non-empty sections are kept. Set false to get the full AI-Builder-MD document with the format contract. |

### get_diagnostics

Compiler errors and warnings without a build: every C# project of the session is compiled in memory, in seconds. For design findings: list_insights.

Use it after editing .cs files: refresh_session, THEN this - it compiles the session's snapshot, not the disk (an answer known to be behind it: verdict:'stale'). After a build call refresh_session(force: true); a restore needs no force.

Returns verdict (when stale or inconclusive), projectsScanned, errorCount, warningCount, infoCount and diagnostics: at most 200 items (the counts cover all); with errors, the default lists only them (warningsNotListed). A multi-targeted project reports a diagnostic once; #pragma-suppressed ones are excluded. No analyzer runs, not even the SDK's; source generators that load do run.

Disclosures:
- incompleteProjects, incompleteRatio, suppressedDiagnosticsTotal: projects whose core references did not resolve (an entry's cause names the remedy). Their diagnostics are counted, not listed; that total is a MAGNITUDE, not a ratio with errorCount. verdict:'inconclusive' + reliable:false: most projects are incomplete.
- projectsWithoutCode: unresolved, no code, not counted.
- unrestoredProjects (missingTarget, restoreCommand): restore output does not serve them.
- referencedProjectsWithoutCode: resolved, compiled empty; dependents' diagnostics counted.
- cascadeFromIncomplete:true on an item: inherited from an incomplete one.
- generatedCodeGaps: code a source generator or the WPF markup compiler writes is missing.
- unloadedProjectReferences (an unbuilt F#/VB or a C++ reference), resourcesWithoutGeneratedClass, languageVersionGap (a compiler older than the code).
- designTimeBuildFailures: MSBuild failed (or warned) loading a project; its options may be incomplete.
- suppressors: references whose DiagnosticSuppressors a real build runs (see runSuppressors).
- projectsNotBuiltBySolution: counted errors a solution build never reports (item: notBuiltBySolution).

Needs a live session; writes nothing. scope filters the ANSWER, not the work.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `severityFloor` | string |  | Minimum severity to include: 'auto' (default), 'error', 'warning', 'info', or 'hidden'. 'auto' counts warnings as 'warning' does, but when the compile has errors it lists only the errors (warningsNotListed says how many warnings it left out of the list); 'warning' lists both. |
| `scope` | string |  | 'solution' (default) or a file-path substring (e.g. 'MyApp.Core' or 'Settings.cs') that filters the RESULT. It is matched against a diagnostic's location as the answer prints it, so a directory separator is a backslash on Windows. It does not reduce the work: all projects are compiled either way (see the tool description) - it saves response tokens, not latency. |
| `runSuppressors` | boolean |  | Run the DiagnosticSuppressors the projects' analyzer references declare, as a real build does, so a diagnostic they suppress is not counted. Off by default: a suppressor is code of the analyzed solution and runs inside this server (see SECURITY.md); the answer's suppressors member says where it would matter. |

### get_insight

Get the full detail of one insight (incl. the per-item Details list) by its id. Discover ids via list_insights (the producers that found issues). Ids are producer-level. An unknown/typo'd id is rejected with the known producer ids; a registered producer that found nothing this session reports that explicitly (distinct from a typo - list_insights lists only producers WITH findings, so a 0-finding id is not discoverable there). Details default to the top 20 items (a '(... and N more)' marker discloses the rest); pass maxDetails to raise that cap for a full per-item drill-down. Pass dbPath to use the active QualityProfile from that DB (same semantics as list_insights, incl. the explicit-layerProfile precedence). Triage-filtered like list_insights, on BOTH axes: detail lines removed by a suppression ('by design', DB + sidecar) or by a dismissal ('seen', solution record) are gone, and 'suppressedDetailCount' reports the two ADDED TOGETHER (absent = none) - so it is not a count of sidecar entries. A producer silenced outright reports as 'registered but 0 hits'.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `insightId` | string | yes | The producer-level insight id, e.g. 'quality-long-methods' (discover via list_insights; an unknown id is rejected WITH the known ids). |
| `dbPath` | string \| null |  | Optional path to an AIContextBuilder SQLite DB. When set, producer thresholds + toggles come from that DB's active QualityProfile AND the configured default layer profile (DefaultLayerProfileName / per-solution) drives the layer-violation analysis (an explicit analyze_solution(layerProfile) wins). Omitted, the QualityProfile falls back to the server's default config DB (the GUI's, if resolved), else the default profile, and the layer profile to the config DB the session was analysed against - the one its renders read. |
| `maxDetails` | integer \| null |  | Optional cap on the returned Details list (default 20). Raise it (e.g. 200) for a full per-item drill-down of this insight; a '(... and N more)' marker still discloses any remainder beyond the value. Applies only to this call; ignored (default cap) when omitted or <= 0. |

### get_type_hierarchy

Walk one type's inheritance in both directions: baseChain upward, derivedTypes downward, plus the interfaces the type declares. The type-level counterpart to find_overrides; for the types that implement an interface use find_implementations.

Use it before changing a base class.

Returns type, resolvedKind (class, record, struct, interface, enum or 'not_found'), baseChain, interfaces and derivedTypes, a capped envelope (items, count, totalFound, truncated; at most 100). baseChain lists the nearest base first; when the chain leaves the solution the last entry NAMES the external base ('ObservableObject (external)'). derivedTypes is transitive, one entry per type, reading 'Derived : DirectBase' ('(generated)' marks generator output); test-project types are included, unmarked. interfaces holds what the type itself declares (not one inherited through a base class), for an interface its base interfaces. Every link is arity-qualified ('Foo&lt;T>' vs 'Foo'); types sharing a name are written by full name ('Ef.User : Core.User'), adding '[Project]' where the full name is shared too.

Optional members ahead of the lists qualify them: 'mergedNamesakes' (several declared types share the simple name; the view merges them), 'separatedNamesakes' (derivations from a same-named type that is NOT the resolved one, typically a framework base shadowed by an in-solution namesake, were excluded and are counted here), 'hint' (an interface query: derivedTypes covers class inheritance only), 'note' (unresolved core references: partial until restore or build, then refresh_session).

'not_found' (three empty lists): no type of that name is declared - also for an external base, a delegate type, a qualified 'Ns.Type' or 'Outer.Inner' form, or an arity suffix no declaration has. A trailing 'nearest' gives a close declared type name, for a qualified form the simple name.

Read-only; works on a recalled session. typeName is the simple name, case-sensitive. A bare name merges a generic type with its non-generic namesake ('mergedArities' says so).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `typeName` | string | yes | The type's exact (case-sensitive) simple name, e.g. 'GraphSectionRendererBase'. Add an arity suffix ('Repository&lt;T>' or 'Repository`1') to disambiguate a generic from a same-named non-generic type. |

### impact_of_change

Estimate the blast radius of changing a symbol: direct users, their dependents, a risk level.

Call it first, before editing a symbol other code names (rename, signature, default value): a compile checks names, not what consumers assume.

Returns directCount, transitiveCount (per declaration, tests included), productionImpactCount (transitive, no tests), risk, directImpact (max 20, find_usages items). risk reads productionImpactCount: 0 none, 1-4 low, 5-20 medium, over 20 high (dependents, not what the change means). If one cycle dominates a high closure, 'saturation' leads the counts and risk reads the direct production fan-in; 'cycleMembers' lists the cycle.

Per kind: a type - the types referencing it, transitively; a method or operator - its caller closure through interface/abstract dispatch; a property, field, event or enum member - the code touching it (transitive = direct). A qualified method counts its contract and virtual-base callers ('viaContract').

An interface or abstract method or type adds 'implementers' per contract (what a signature change breaks; an entry's 'namesakes' splits merged contracts), and risk reads 'riskBasis'.total = closure + production implementing types (on a type direct ones only, 'indirect' lists the rest; 'riskBasis'.note: no production caller).

Trailing, moving no count: 'registration' (only through DI), 'serializers' (a property's serializer sites), 'attachedProperty' (a dependency property's accessor or wrapper markup users).

Ahead of the counts: a 'note' on misleading numbers (directCount 0 on a resolved symbol - DI or reflection may reach it; unresolved core references; no production project; 'not_found': risk 'none' measures nothing, 'nearest': a close name; a private member), 'collision' (a same-named other kind, not counted), 'namesakes' (types sharing the name, one union), 'generatedSubject' (every declaration generated) and 'generatedStops' (generated documents the walk stops at).

Read-only. symbol resolves as in find_usages, a constructor ('Type.Type') excepted.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The exact (case-sensitive) type, method, property, field, event, enum-member or operator (metadata) name to assess - or the qualified Type.Member form for a member. |

### init_solution_config

Collect the raw material for the guided setup of a solution's Layer Profile, Exclude-Namespaces and Test Profile - step 1 of 2; apply_solution_config is the step that writes.

Use it when solution_config_status or the configInit hint of analyze_solution reports an axis as not initialized, or when check_solution_config_drift reports one as stale. Propose a mapping from the returned material, then call apply_solution_config with it. To only see what is configured, use solution_config_status.

Returns JSON: solutionPath; declaredNamespaces - the solution's own namespaces, the source for layer-mapping rules (no test-project namespaces; System/Microsoft/JetBrains ones only under a production project's assembly or root namespace); referencedNamespaces - every namespace a using directive names, the solution's OWN included, heaviest first (a hand-written global using ahead of any file count), each {namespace, documents} (hand-written files whose own using names it), plus generatedDocuments (build-written files, obj/) and globalUsingProjects / implicitGlobalUsing (an SDK implicit using) where they apply - neither says what the code leans on: only the external/framework ones are exclusion material, never exclude your own; testProjects - what the default heuristic classifies as test projects; detectedTestAttributes - the test-attribute MARKERS present in the code; testAttributeUses - the attributes each marker covers, with method counts (top 10; Fact covers ConditionalFact); frameworkApiAreas - areas the built-in exclusion list removes although at least 15% of the public method signatures name them (Dapper: System.Data), each with the keepRule to put into exclusions so the rest of the list still applies; proposalFormat - the JSON shape apply_solution_config expects. The first three lists are capped envelopes (items/count/totalFound/truncated, max 300); the other three are plain arrays.

Read-only: writes no config or DB row, marks nothing initialized. It needs a live session (no re-analysis); a recalled one is rejected.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |

### install_agent_hooks

Install the aicb symbol guard into this project for an agent harness, so a C#-symbol question is REFUSED on a text search and redirected to the tool that answers it. Writes the guard script plus the harness's wiring entry (.claude/settings.json, .codex/hooks.json or opencode.json; for Claude Code also a SessionStart hook that keeps the aicb skill files in step) and nothing else - no .mcp.json, no skills, and only inside the directory of the session's own solution. Omit 'harness' to install for the harness that is calling. An existing guard or wiring is kept unless force=true. Restart or reconnect the client afterwards, then call refresh_session so the session stops reporting the guard as missing.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `harness` | string \| null |  | Which harness to install for: claude-code, codex or opencode. Omit to use the harness the calling MCP client belongs to. |
| `force` | boolean |  | Overwrite an existing guard script and rewrite an existing wiring entry. |

### instantiation_sites

Find where a type is constructed and where it is injected: the narrow 'who creates or obtains an instance of X?' that find_usages (every reference) cannot answer. resolve_injection answers the other half - what is registered for a type.

Use it before changing a constructor, and to see whether anything but a test builds a type.

'created': a method, constructor, accessor or top-level code that runs 'new X(...)', a target-typed new or a record 'with'; a field or property initializer is attributed to the constructor the compiler runs it in, so such a site is named '.ctor' ('.cctor' for a static one). 'injected': a type that takes X as a constructor parameter - no container is consulted. A parameter wrapped in another type (Lazy&lt;X>) is recorded under the outer type, and an array of X is not a creation of X.

Returns typeName, a 'note' when there is one, createdByCount, createdByTests, injectedIntoCount, injectedIntoTests, sites - at most 200 items (name, declaringType, namespace, kind, isTestProject, 'generated' in generator output), created sites first - and 'nearest'. The four counts are true totals within scope. Test-project sites are included, not filtered: isTestProject marks each. A type the DI container builds has no recorded production site, so 'every site is a test' is not proof.

A 'note' covers two zeros and a test-only answer: with no site at all it names the construction paths this fact cannot see and the markup views naming the type; with injectedIntoCount 0 it names those of its interfaces something is injected under - a DI consumer takes the interface, so query that name. With every site a test (unscoped), it says so and names the markup views. 'nearest' gives a close declared name when no site was found and the name matches no declaration.

Read-only; works on a recalled session. typeName is matched on its simple name: namespace and generic arguments are dropped, namesakes are unioned, and an external type ('List') is a valid query. scope is 'solution' or a namespace prefix on the SITE's namespace.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `typeName` | string | yes | The type whose instantiation/injection sites to find (simple name; namespace + generic args are normalized away, e.g. 'OrderService' or 'List'). |
| `scope` | string |  | 'solution' (default) or a namespace prefix (e.g. 'MyApp.Core') to narrow which sites are scanned. |

### list_insights

List code-quality / async / design-smell insights for a session (long methods, fat interfaces, unused types, missing async suffixes, many-parameter methods, ...). Runs against the live analyzed solution; each insight is aggregated per producer, with the count of its detail lines ('detailsCount', all of them; get_insight lists the first 20). Pass dbPath to use the active QualityProfile (producer thresholds + toggles) from that DB; omit it for the default profile (DB-free). Honors the session's active test-detection profile (resolved by analyze_solution(dbPath)) for the production-focused producers. An explicit analyze_solution(layerProfile) drives the layer-violation insight and wins over the DB-configured profile (same precedence as solution_metrics and the CLI gate). THIS ANSWER IS TRIAGE-FILTERED, on BOTH triage axes: findings the solution marked intentional (a suppression - in the DB or in the git-tracked &lt;Solution>.aicb.json sidecar) AND findings a user dismissed as seen (in the solution record, NOT in the sidecar) are removed, and an insight whose findings are all gone does not appear at all. Every insight that lost lines carries 'suppressed' with the count of what BOTH axes removed together (absent = nothing filtered), so a shrinking number is never mistaken for a codebase that improved - but do not read that count as a sidecar entry count, because some of it is dismissal. Note 'title' is producer text computed BEFORE filtering, so on a partially filtered insight it still names the pre-filter total - 'detailsCount' + 'suppressed' are the real split. 'remediationCostMinutes' is a coarse order-of-magnitude estimate from fixed per-finding rules, not measured effort. Pass files - say the files a change touches - for the findings about the types they declare, with their detail lines.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `dbPath` | string \| null |  | Optional path to an AIContextBuilder SQLite DB. When set, producer thresholds + toggles come from that DB's active QualityProfile AND the configured default layer profile (DefaultLayerProfileName / per-solution) drives the layer-violation analysis (an explicit analyze_solution(layerProfile) wins). Omitted, the QualityProfile falls back to the server's default config DB (the GUI's, if resolved), else the default profile, and the layer profile to the config DB the session was analysed against - the one its renders read. |
| `files` | array \| null |  | Optional C# files, each absolute or relative to the solution folder: the answer keeps the findings about the types these files declare and becomes an object {files, notInSolution, insights}. 'files' are the ones the solution holds, solution-relative; 'notInSolution' the ones it does not (a deleted or non-C# file, a typo), as given. Each insight carries its in-scope 'details' with 'detailLocators' (up to 20, then a '(... and N more)' line), and 'detailsCount' counts the in-scope lines; 'title', 'remediationCostMinutes' and 'suppressed' stay the whole-solution numbers. A line matches by its locator's simple type name, so a same-named type elsewhere matches too, except on a member line whose member only that other type declares; a line about a file of top-level statements matches by that file; any other line with no type locator is left out, while an insight about the solution as a whole (no lines, no type locator) stays, with detailsCount 0. Omitted or empty: the solution-wide array above. |

### list_mcp_profiles

List the MCP profiles in the server's config DB - each with its id, name, the slots that have a template assigned (General appears exactly when a profile-wide template is set), the profile-wide templateId (null = none), whether it carries a skill, its effective tool-set (toolSelection: the class-level CSV, or a 'methods:'-prefixed function-name list when the profile curates individual tool functions; null = lean core), whether it is the active one, AND the render config it applies (tokenBudget / outputFormat / overflowPolicy - a null tokenBudget/overflowPolicy means inherit: the template then the active PipelineProfile decides). Requires the server to be started with --db-path. Use the ids with 'aicb mcp --mcp-profile &lt;id>' to pin the profile at server start - that is the only way to change it; there is no runtime switch tool.

### list_skills

The server's capability map: a tools INDEX naming EVERY tool this server has - each exactly once, grouped into three lists by pool state (inPool.core = the tools every profile exposes, in reach-for-them order; inPool.extras = the rest of the active pool, alphabetical; outOfPool = exists but the active tool set does not expose it) - plus the sections that group them by name: the always-on navigation CORE (listed in no menu because it needs none), the task FACETS (id + guidance + template slot + the facet's tool menu), the cross-cutting guidance styles, and the legacy functional skill bundles. Use it to discover specialized long-tail tools (e.g. get_insight, find_by_concurrency_risk, coverage_gaps, find_unresolved_bindings) beyond that core - and to check whether ANY tool you want is merely in outOfPool rather than nonexistent. Tools outside the active pool become reachable via an MCP profile whose facet menu or bundle names them (see list_mcp_profiles / 'aicb mcp --mcp-profile &lt;id>'), or via the AICB_MCP_TOOLS override. By default the answer omits the per-tool descriptions, which is what makes it cheap; pass detail="full" when you need them. No session needed.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `detail` | string \| null |  | How much per-tool text to include: "lean" (default) - bare names in their pool groups; "full" - additionally each tool's one-line description. Case-insensitive. |

### measure

Report how BIG a read-only query's answer would be - its exact token count - WITHOUT returning the answer. Use it to decide before you pull: whether a call is worth making, what 'budget' to pass a slice tool (get_context/explain_symbol/pack_for_task), or whether to narrow 'scope' first. Same shape as batch: pass the shared session_id once plus 'queries', an array of {tool, args} where 'args' is that tool's own arguments WITHOUT the sessionId. Example: queries=[{"tool":"explain_symbol","args":{"symbol":"OrderService","include":["callees"]}}] → {tool, ok, tokens, chars, returned, totalFound, truncated, budgetNote}. 'tokens' is the real tokenizer count (cl100k_base) of the exact text the tool would return; 'returned/totalFound/truncated' are passed through when the tool answers with a capped envelope, so you also see whether you would be seeing everything. The Markdown slice tools (get_context / explain_symbol / pack_for_task) have no such envelope - they disclose budget pruning in prose, so 'budgetNote' carries that disclosure verbatim: if it says types were dropped, the answer you are pricing is already CUT (an axis you asked for can be missing entirely), and a larger 'budget' is what buys it back. IMPORTANT: measure does NOT make the query cheaper to RUN - the server does the full work either way; it makes the answer cheap to INSPECT (you pay ~50 tokens instead of the answer). So measure to DECIDE, then call once - do not measure every call by reflex. Dispatches the same read-only tools as batch, and refuses the same ones for the same four reasons - mutation is only the first of them; the refusal message names which one applies. Like batch, sub-queries follow the ACTIVE POOL: an out-of-pool tool is refused per item. Max 16 queries per call.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. Shared by ALL queries - do NOT repeat it inside each query's args. |
| `queries` | array | yes | The read-only queries to measure: an array of { tool, args } objects, exactly as for batch. Max 16. |

### pack_for_task

Goal-driven context packing: given a natural-language task, seed on every symbol the goal names (type or method), expand the neighborhood, and return a token-budgeted AI-Builder-Markdown bundle - with goal-aware trimming that keeps the most task-relevant methods when the budget is tight. Name the symbols you care about in the goal (e.g. 'refactor OrderService.Cancel and Validate'). budget caps output tokens (floored at 8000). Multi-TFM solutions are deduplicated to one declaration per type (the NEWEST TFM's where it has one), as find_symbol lists them. For an EDIT-ready bundle that also pulls in the covering tests + naming/file siblings (and, on a profile-aware server, renders through the facet's template), use prepare_task instead.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `goal` | string | yes | The task description (name the relevant types/methods in it). Once the goal names a symbol exactly, its other words only steer the trimming and seed nothing of their own; a goal naming no symbol is matched by name segments instead ('cancel order' -> CancelOrder). |
| `budget` | integer \| null |  | Optional token budget (floored at 8000). Caps the slice TWO ways: it compacts/drops method bodies AND - when the expanded neighborhood still overflows - drops the least-relevant non-seed types entirely. Exact type names and exact method names with one owner are pinned; broad subword/ambiguous same-name families may be capped by closeness and in-slice fan-in. A leading comment discloses how many types were dropped. Omitted, the bundle still renders against a ceiling (the active MCP profile's token budget, else a ~10000-token default budget) that bounds the neighborhood; pass a value for a tighter bundle. |
| `includeQualityMetrics` | boolean |  | When true, also emit the &lt;QUALITY_HOTSPOTS> section plus complexity=""/ce="" tag attributes (cyclomatic complexity, efferent coupling) for the packed symbols. Default false. Set true when the task is a refactor/quality pass. |
| `lean` | boolean |  | Lean slice (default TRUE): drop the repeated &lt;AI_CONTEXT_SPEC>/&lt;AI_CONTEXT_META> preamble and omit enabled-but-empty graph sections ('- none'). Keeps PATH_LEGEND / COMPRESSION_LEGEND and all non-empty sections. Set false for the full AI-Builder-MD document. |
| `facet` | string \| null |  | Optional facet - the task axis of this call: General, Exploration, Refactoring, Debugging, Review, Testing, Documentation, Architecture, or Performance. pack_for_task always renders the lean bundle (its render deliberately stays template-free - use prepare_task for a template-shaped bundle); the facet appends a short work-style trailer with suggested next tools. (The name 'slot' is accepted too.) |

### prepare_task

Build an EDIT-ready context bundle for a task goal: the source of the symbols the goal names, their dependency neighborhood, the test methods that cover them and 1-2 naming/file-convention siblings (the test, the factory, the validator you'd otherwise miss) - as one token-budgeted AI-Builder-MD document.

Prefer this over pack_for_task when you're about to EDIT, not just read. pack_for_task packs the goal-seeded neighborhood alone, without covering tests and siblings. For one symbol use get_context or explain_symbol; for blast radius and test coverage as numbers use review_context.

Returns text, not JSON. It starts with a manifest comment (goal | seeds | tests | siblings | render) so you can see what was covered - and what was NOT ((none)); after a source edit a staleness comment precedes it. 'render' names the path that produced the body. 'template' is the default, because a plain 'aicb mcp' resolves the standard config DB: the chosen facet's template (graphs, detail, line numbers, quality) in the active profile's notation - YAML under the built-in profiles. 'lean' is the fallback of a server without a config DB: tag Markdown. Multi-TFM solutions are deduplicated to one declaration per type (the NEWEST TFM's where it has one), as find_symbol lists them.

Read-only. Parameters: a tight budget drops neighborhood types, tests and siblings first. A type the goal names, or the one owner of a method it names, is never dropped (too large, it renders as structure: members and signatures); the owners of a method name several types share can be dropped. A leading note names the drops. lean and includeQualityMetrics act on the lean render only, so not on a default server.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `goal` | string | yes | The task description - name the relevant types/methods in it (e.g. 'refactor OrderService.Cancel and its validation'). Once the goal names a symbol exactly, its other words only steer the trimming and seed nothing of their own; a goal naming no symbol is matched by name segments instead ('cancel order' -> CancelOrder). |
| `facet` | string \| null |  | Optional facet to work under - the task axis of this call: General (default), Exploration, Refactoring, Debugging, Review, Testing, Documentation, Architecture, or Performance. On a server with a config DB (the default: a plain 'aicb mcp' resolves the standard one) the facet's template shapes the render; it always appends a short work-style trailer with suggested next tools. (The former name 'slot' is still accepted.) |
| `budget` | integer \| null |  | Optional token budget (floored at 8000). Applies to BOTH the lean and the profile-aware template render path: it compacts/drops method bodies AND drops the least-relevant types when the neighborhood overflows. A type the goal names, and the one owner of a method name it names, is never dropped - one whose own source does not fit renders as structure (members and signatures). The owners of a method name several types share are capped like the neighborhood: some are reduced to structure, some dropped. The bundled covering tests/siblings are BUDGET-BOUND - under a tight budget they are dropped to fit (a leading comment names the drops so you can ask for one by name). Overrides any MCP-profile/template token budget. Omitted, the bundle still renders against a ceiling (the MCP profile's token budget, else the facet template's, else a ~10000-token default budget) that bounds the neighborhood. |
| `includeTests` | boolean |  | Include the test methods that cover the seeded symbols (default true). |
| `includeSiblings` | boolean |  | Include 1-2 naming/file-convention siblings of the seeded types (default true). |
| `includeQualityMetrics` | boolean |  | When true, also emit the &lt;QUALITY_HOTSPOTS> section plus complexity=""/ce="" tag attributes for the bundled symbols (lean path). Default false. Set true for a refactor/quality pass. |
| `lean` | boolean |  | Lean slice (default TRUE): on the lean-render path, drop the repeated &lt;AI_CONTEXT_SPEC>/&lt;AI_CONTEXT_META> preamble and omit enabled-but-empty graph sections ('- none'); keeps PATH_LEGEND / COMPRESSION_LEGEND, the manifest and all non-empty sections. Set false for the full AI-Builder-MD document. (Ignored on the profile-aware slot-template render path, which the active profile controls.) |

### refresh_session

Re-analyze the session's solution after YOUR code edits - call it once you have changed .cs files, otherwise find_usages / impact_of_change / list_insights / get_context may keep answering from the STALE pre-edit graph (a silent source of wrong results). Cheap to call speculatively: a W0 file-set-hash check skips the expensive Roslyn re-run when nothing actually changed, and a C# file whose timestamp moved while its text stayed the snapshot's (a save without an edit) does not count as a change either. That check reads SOURCE files. A restore that rewrote a project's assets file after the load is noticed anyway and reloads through MSBuild; a plain build is not seen - after one, an analysis that reported unresolved references retries once by itself, and 'force' is the deterministic way to demand a reload. Reuses the warm workspace. Returns { changed, reason, session, mode } - 'mode' names the path the re-analysis took ('incremental' = document texts replayed into the warm snapshot without an MSBuild reload, else 'full-reload') and is absent when nothing was re-analyzed. The incremental path can stop engaging without any visible symptom - answers stay correct, calls just get slow again - so 'mode' is how you notice.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `force` | boolean |  | Re-analyze even when no source file has changed. Use it after a restore/build that was meant to repair unresolved references - those live in build output the file-set hash does not cover, so an ordinary call can legitimately answer 'unchanged'. Costs a full MSBuild reload; leave false for the normal after-an-edit refresh. |

### resolve_injection

Resolve a Microsoft DI or MEF registration: what is registered for a service, with lifetime and site. Not usage (find_usages), implementers (find_implementations), construction (instantiation_sites).

It reads Add{Singleton,Scoped,Transient}, TryAdd*, descriptor adds built at the call, AddHostedService, project-local helpers registering their own type arguments, and a foreach over a static new(typeof(Service), typeof(Impl)) table. A key, and a closing, is a service of its own (IRepo&lt;A>, IRepo&lt;B>); open IRepo<> is read. Not read: a descriptor built elsewhere, AddHttpClient-style helpers, Scrutor, other containers. Umbraco collection builders are listed apart (collectionBuilders).

Returns JSON: registrations (serviceType, implementationType [= service if self/instance], lifetime, note, location, project, declaringMethod, key, targetFrameworks: a multi-targeted project's call is one row; note 'inferred, not read' = from a package helper's call shape AddSingletonAs&lt;T>().As&lt;I>(): lifetime from its name, never ambiguous or a winner) and: multiRegistration / registrationSites; ambiguous (possible conflict: ONE site registers several implementations of one service, receivers not compared, not consumed as a collection); effectiveRegistration (2+ calls: the winner a single-service resolve gets, read in ONE straight-line site; else null + reason); consumedAsCollection; constructorConsumerCount (plain ctor parameters); otherConsumers (GetService&lt;T> outside a registration factory, [Inject], @inject: per form); optionalDependencies (optional ctor parameters: yes/no/unknown).

An empty list says why: resolvedKind 'not_found' plus 'nearest' = no such name; else a 'note' names the forms not read and which the solution holds - empty means 'not statically visible', never 'not registered'.

Test projects count only with includeTests=true; testRegistrationsFiltered counts what that hid. interface is the SERVICE type (a self-registered class too); a closed form (IRepo&lt;A>) lists that closing and IRepo<> (typeArgumentFilter: the rest).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `interface` | string | yes | The interface simple or fully-qualified name, e.g. 'ICodeAnalyzer'. A simple name lists every type of that name; a qualified one ('App.Settings.IPanel') leaves out same-named types of other namespaces and says how many. A closed generic form ('IHandler&lt;Saved>') lists only the registrations serving that closing; 'IHandler' or 'IHandler&lt;T>' lists every closing. |
| `site` | string \| null |  | Optional: narrow to registrations whose file path contains this substring. |
| `includeTests` | boolean |  | Include registrations declared in test projects (default false - production focus). |

### review_context

Assemble review context for a set of changed symbols in ONE call: per symbol its fan-in, the transitive change impact with a risk level, the types that implement it (if an interface) and the test methods that likely cover it. It bundles what find_usages, impact_of_change, find_implementations and find_tests_for answer one symbol at a time.

Use this before reviewing or refactoring to see blast radius + test coverage at a glance. It does not name the callers (use find_usages or impact_of_change for that list) and returns no code (use explain_symbol).

Returns a JSON array ordered by symbol NAME - index it by 'symbol', never by request position. Per entry: symbol, resolvedKind, directUsages, transitiveImpact, risk (none/low/medium/high), implementations (names; test doubles are listed too, find_implementations filters them by default), coveringTests (testType, testMethod, project, matchReason), coveringTestsTotal, coveringTestsTruncated. An unresolved name reads resolvedKind 'not_found' with a 'note' and no risk; a 'note' also flags a risk graded on the direct fan-in or on implementers alone. For a bare name several types share, the counts are their union and no note says so - find_usages names the namesakes.

'coveringTests' is find_tests_for's list: strongest evidence first, capped at 50 per symbol. The cap keeps the 50 strongest rows: name guesses go first, strong rows too once there are more than 50. find_tests_for stops at the same 50, so narrow the symbol rather than re-query. 'invokesTotal' (strong rows) and 'dispatchTotal' (rows reaching the symbol through an interface or abstract member) count the WHOLE list and can exceed the rows shown; coveringTestsTotal minus both is the name guesses. For a qualified method, directUsages and transitiveImpact include callers credited through such a member - see 'viaContract' / 'viaContractNote'.

Read-only. Parameters: symbols must not be empty and takes the strings find_usages resolves - a type's simple name, or a member bare or as Type.Member.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbols` | array | yes | The changed type/method names to assemble review context for. |

### save_session

Persist the current session's analyzed model as a named Manual snapshot in an aicb DB, so a later session can diff against it with compare_with_previous.

Use it BEFORE a bulk mechanical change (a rename sweep, a signature migration) and call compare_with_previous afterwards. An ordinary edit needs no snapshot: git diff and the tests cover it.

Returns JSON: snapshotId, sessionId, solutionId, name, lineNumbersAvailable and totalSnapshots (the snapshots that DB now holds for this solution).

It writes to the aicb DB, not to the solution's source or configuration: one new snapshot row, plus the solution's record when the DB does not know the solution yet; a DB file that does not exist is created. Nothing is overwritten: every call adds a snapshot under a fresh id, and name is a label, not a key. The snapshot keeps the line spans, but a session recalled from it reports lineNumbersAvailable false: its lines mean 'as analyzed', not the current working tree.

Parameters: sessionId is a live or recalled session's id or an absolute .sln/.slnx/.slnf path. Omit dbPath to use the server's standard config DB (the same one the GUI uses); when the server resolved none, the call fails with 'dbPath is required'.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id whose current state to snapshot. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `name` | string | yes | Human-readable name for this snapshot (e.g. 'before refactor'). |
| `dbPath` | string \| null |  | Optional absolute path to the aicb SQLite DB to persist into. Omit to use the server's standard config DB. |

### server_info

Report this SERVER's own identity and health: name, version, build commit, the config DB's schema version, and drift warnings about the server binary. Needs no session - a reachability smoke-check.

Call it first after connecting and after an update or restart: the commit answers the question the version number cannot - 'is the binary I am talking to built from the code I just landed?'. It says nothing about a solution's configuration (solution_config_status: what is active; check_solution_config_drift: does it still fit the code), about which tools exist (list_skills) or about how they were used (usage_report).

Returns plain text, not JSON. Line 1 is the identity: 'aicb MCP server (AIContextBuilder) v&lt;version> (commit &lt;sha>)'. Compare the commit against `git rev-parse HEAD` (the full sha, so a short hash is its prefix): one version number can cover DIFFERENT builds. A build with no resolvable git revision omits the commit. 'Config DB schema: user_version=N (&lt;path>)' follows when a config DB is resolved.

Then, only when they apply: ANALYZER DRIFT - this build's commit against the HEAD of each repo of a solution this server analyzed, per repo with its solution and HEAD (it cannot tell which is yours); also in-sync and ahead; silent with no session; a repo not knowing this commit gets no line. SCHEMA DRIFT - the config DB's schema is newer than this binary: rebuild or reinstall. PENDING MIGRATION - the reverse: the DB is older; the line says how to migrate it. TOOL POOL DRIFT - the active profile lists tools this binary does not register: a newer build wrote it (rebuild or reinstall) or the tool was retired (re-save the profile). That check is tool-NAME level; a new parameter on an existing tool is not detected, the commit is the finer signal. CONFIG DRIFT - the active MCP profile changed since this server started: restart or reconnect to load the current tools and instructions.

Read-only: it reads the config DB's schema version and, for the analyzer line, queries git in the analyzed solution's repository.

### solution_config_status

Check whether a solution's Layer Profile, Exclude-Namespaces and Test Profile have been initialized via the guided setup, and which Layer Profile / Exclusion List / Test Profile is currently active. 'initialized' is an explicit marker for all three slots (stamped by apply_solution_config - it is NOT inferred from having an active id, which a user can also set manually via the Settings panel); the testProfile slot additionally reports the effective per-solution active test-detection profile. Pass the session_id; dbPath is optional - omit it to use the server's default config DB (the same one the GUI uses), if the server resolved one. With no DB (or an empty file) the answer comes from the sidecar and the built-in defaults, and no database is opened or created; a dbPath that does not exist is refused. Each slot names the config IN FORCE for the analysis - resolved exactly as analyze_solution resolves it - and its source: 'db' (the per-solution row or the app-global default), 'sidecar' (the committed .aicb.json applies, which it does whenever the DB configured nothing for the axis - a built-in default is not configuration), 'built-in' (the built-in exclusion list, applied when nothing configured one and no sidecar names one) or 'none' (the heuristic). A repo with a valid .aicb.json sidecar but no DB row reads initialized=true, source:sidecar, not a misleading uninitialized. Use this on solution start: if a slot is not initialized, offer to run init_solution_config + apply_solution_config.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `dbPath` | string \| null |  | Absolute path to the aicb config/master SQLite DB that holds the per-solution configuration. Omit to use the server's default config DB (the same one the GUI uses), if the server resolved one; with none, or an empty file, the sidecar answers alone. |

### solution_metrics

The solution-wide quality rollup in one call - the numbers the CLI '--fail-on' quality gate evaluates. symbol_metrics ranks single methods; list_insights shows the findings behind the severity counts.

Use it for a before/after number, or to try a gate expression.

Returns metrics {typeCount, methodCount, complexityMax, complexityAvg, methodsOverComplexityThreshold, ceMax, caMax}, scope (always 'production'), testMethodCount, testTypeCount, severities {critical, warning, info, ok}, debtMinutes, debtApprox, debtRating, complexityThreshold, qualityProfile, layerProfile (when one is in force), knownGateMetrics and, with failOn, gate {expression, passed, violatedClauses}. degradedProducers appears when an insight producer failed; severities and debt are then incomplete. debtMinutes is a coarse estimate from fixed per-finding rules, not measured effort; debtApprox rounds it (1 d = 8 h).

PRODUCTION code only - test projects, per the session's test profile, are excluded from every number, and testMethodCount / testTypeCount give the excluded side. Types are logical (partial fragments merged, multi-TFM deduplicated); methods exclude constructors and accessors. methodsOverComplexityThreshold counts STRICTLY greater than complexityThreshold, while symbol_metrics' minComplexity is inclusive. ceMax / caMax: coupling maxima (caMaxNote: same-named types could raise caMax). severities count insights - one per producer that found something - not findings. The rollup is NOT triage-filtered: suppressed and dismissed findings still count, as in the CLI gate, so debt and severities can be higher than what list_insights shows.

failOn takes the tokens in knownGateMetrics; this gate is advisory, the blocking one is the CLI's.

Profiles: the active QualityProfile of the config DB in force (see dbPath); the session's layer profile, else the one dbPath (or, omitted, the session's analysis DB) configures. Writes nothing of its own; an older dbPath DB is upgraded on open, as the server's own is at startup. Works on a recalled session.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `failOn` | string \| null |  | Optional quality-gate expression to evaluate against the rollup (CLI '--fail-on' syntax, e.g. 'critical>0 OR debt>120min OR ce-max>50'). An invalid expression or unknown metric is rejected with the known tokens. |
| `dbPath` | string \| null |  | Optional path to an AIContextBuilder SQLite DB. When set, the complexity threshold and producer toggles come from that DB's active QualityProfile (same semantics as list_insights); omit to fall back to the server's default config DB (the GUI's, if resolved), else the default profile. Omitted, the layer profile comes from the config DB the session was analysed against. |

### symbol_metrics

Report method complexity: McCabe CYCLOMATIC complexity (independent paths) and COGNITIVE complexity (how hard the method is to follow: nesting is penalised, boolean-operator runs collapse), plus the parameter count - for one method by name, or as a ranking of the hotspots. solution_metrics gives the solution-wide rollup.

Use it before touching an unfamiliar method, and to find where the complexity sits. Both metrics measure CODE SHAPE, not runtime cost; for a hot path use a profiler.

With symbol (mode 'symbol'): every method unit of that exact, case-sensitive name - bare for all same-named ones, 'Type.Member' for one type's. scope, includeTests, minComplexity and rankByCognitive are ignored. Accessors, constructors and operators answer by metadata name ('get_Items', '.ctor', 'op_Equality'); '.ctor' is every constructor unit of the solution, 'Type..ctor' one type's. Without symbol (mode 'ranked'): methods only, sorted by cyclomatic complexity descending - by cognitive with rankByCognitive=true - and filtered to complexity >= minComplexity (inclusive; 0 = no floor).

Returns scope, mode, metricMeaning, minComplexity, methodsScanned, methods - at most 200 items (name, declaringType, namespace, cyclomaticComplexity, cognitiveComplexity, parameterCount; project when two projects compile one type) - and when they apply 'note', minComplexityBoundary, 'nearest' (a close declared name when a lookup matched no method) and testMethodsFiltered. In a ranking, test-project methods are excluded by default (includeTests=true includes them); testMethodsFiltered counts those that cleared the floor, and the note names the strongest one when it would have ranked inside the shown list. The note also says when the two axes would have listed different methods.

An empty ranking means nothing cleared the floor - or the scope matched nothing: methodsScanned 0, plus a note. An empty lookup means no METHOD of that name; a bare property or type name gets a note saying so.

Read-only; works on a recalled session.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string \| null |  | Exact (case-sensitive) method name to report - bare (every same-named method) or in the qualified Type.Member form (that type's member only). Omit to rank all methods by complexity. |
| `minComplexity` | integer |  | When ranking (no symbol): only include methods whose ranking complexity (cyclomatic, or cognitive when rankByCognitive=true) >= this. 0 (default) = no filter. |
| `scope` | string |  | When ranking: 'solution' (default) or a namespace prefix to narrow scope. Ignored when symbol is given. |
| `includeTests` | boolean |  | When ranking: include test-project methods (default false - production hotspots; CC-heavy test harnesses would otherwise skew the top-N). Ignored in the by-name symbol lookup (which always returns the named method). |
| `rankByCognitive` | boolean |  | When ranking: rank + filter by COGNITIVE complexity instead of cyclomatic (default false). Both numbers are always present per method; this only changes the sort + minComplexity axis. Ignored in the by-name symbol lookup. |

### symbol_signature

Return a symbol's signature(s) WITHOUT the body: the type declaration, the method/operator signature or a member's declaration (property, field, event, enum member - the last as its qualified Enum.Member form), plus its XML &lt;summary> doc and its declaring file + start line - for understanding an API without reading the whole file/body, and for navigating straight to it. 'file' is the fragment's OWN file (a partial type's method: the file the METHOD lives in, not the first fragment's); it is omitted only when the snapshot carries no path. A declaration a source generator wrote adds 'generated', its generated document's label; its 'file' is that label's path, not on disk. 'line' is where the declaration starts, a leading attribute included; it is null for an enum member and a source-generated property (no line fact is modeled for them). Exact (case-sensitive) name match; multiple results for overloads or name collisions; one declaration compiled in two projects, or one type a generator wrote into each, is two results, each with its 'project'. A member also takes 'Type.Member' (that type's only), a type a qualified name ('Ns.Type', 'Outer.Inner') and a constructor 'Type.Type' (kind 'constructor', each declared overload; a primary constructor's line is null, a record's is not listed; on a type that declares none the list is empty and a 'note' says which constructor the type has implicitly, with no 'nearest'). A user-defined operator matches by its METADATA name ('op_Equality' / 'op_Implicit' / ...). Leaner than get_context (which returns the full source). Returns a capped envelope (items/count/totalFound/truncated), max 50. Matching is EXACT: a typo or case-mismatch returns an empty list, not an error - an empty answer thus carries 'nearest' (the closest declared name), which tells 'you spelled it differently' from 'this symbol genuinely has no signature' - and, where the run skipped generated C# under obj/, a 'generatedSourcesNote' naming the third possibility: the declaration exists in code this index never read.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sessionId` | string | yes | The session_id returned by analyze_solution. Also takes an absolute .sln/.slnx/.slnf path, analyzed on first use. |
| `symbol` | string | yes | The exact (case-sensitive) type, method, property, field, event, enum-member or operator name (e.g. 'op_Equality'), bare or qualified ('Type.Member', 'Ns.Type'), or 'Type.Type' for a type's constructors. |

### usage_report

Report the server-side tool-call telemetry: what the CallTool filter recorded into the config DB's tool_calls table, across every client that used this DB - not this conversation's transcript. list_skills shows the pool; this shows what was called.

Use it to see how often, how reliably and at what cost each tool is used. READ THE SCOPE FIRST: the filter sits on the tools/call pipeline. A one-shot `aicb call` writes the same row under the client name 'aicb-call' when given a --db-path, and nothing without one. A sub-query inside batch or measure records the PARENT call and no child row. So every count here is a LOWER BOUND, and a tool at 0 was not called THROUGH THIS DOOR rather than not called. A batch parent's row does carry a tally of its sub-queries, returned as subQueries: read it before calling a tool unused.

Returns totals (totalCalls, errorCalls, errorRatePct, distinctTools, distinctSessions, clientSessions, firstTs, lastTs, clients, serverVersions); tools, ranked by calls, each with errors, duration (ms) and result size (chars) as average, p50, p90 and max, plus - when non-zero - errorClasses (exception type names; McpException is a failure the tool raised on purpose), argumentBindingErrors (an argument the tool does not have), ignoredArgumentCalls (the call answered anyway) and aliasApplied; protocolVersions and clientEras (who called, on which protocol revision); facets; subQueries; recordedVia; and poolCoverage (poolSize, poolToolsFired, poolToolsNeverCalled, outOfPoolTools). Read coverage THERE, not from distinctTools: that figure counts every tool called including ones outside the pool, so holding it against the pool size overstates coverage.

The answer carries shapes only - names, counts, exception type names - no code, no argument values and no session reference. Without a readable config DB it answers available:false.

Read-only and session-less. sinceDays narrows every figure to the last N days (1..3650, so 0 means one day; omit it for the whole log); the cutoff comes back as windowSinceIso.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `topTools` | integer |  | Cap on the per-tool breakdown, ranked by call count (default 30; clamped to 1..200). |
| `sinceDays` | integer \| null |  | Only count calls from the last N days (omit for the whole log; clamped to 1..3650). |

### verify_claim

Verify a structured claim about a change by diffing two analyzed sessions (baseline → changed). Supported claim types (MVP): 'no_new_api' (no types/methods were ADDED AND no method signatures changed) and 'symbol_removed_unused' (the named symbol was removed AND had no usages in the baseline's static fan-in graph). Returns a verdict of confirmed / refuted / indeterminate with a reason + evidence. NOTE THE SCOPE OF 'no_new_api': it is about ADDITIONS and SIGNATURE CHANGES, so a REMOVAL does not refute it - a change set that only deletes public API is legitimately 'confirmed'. Removals are therefore never silent: the reason states the boundary and every removal the same diff records is listed as evidence, prefixed '-'. For the removal question ask verify_claim(symbol_removed_unused), or diff_public_contract (outside the default profile's pool). Conservative in BOTH directions: what the diff cannot prove is never falsely confirmed - and never falsely refuted either, because 'was not removed' is a claim about the change that is only made once the string resolves to something this diff could report on. A name that resolves to nothing, a property/field/event/enum member (the diff models types and methods only), and the simple name of a removed type the diff had to render by its FULL name because it is ambiguous, each return 'indeterminate' naming that cause - not a confident 'was not removed'. A removed method whose only baseline callers called an interface or abstract member it implemented (find_usages' viaContract) is 'indeterminate' too: such a call ran its body only when the instance was of its type, and the reason says whether that credit was exact. Baseline and changed must be two states: the same session twice, or two sessions of one solution with an equal file-set hash and an empty diff, answers 'indeterminate' and says so. Unsupported claim types return indeterminate.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `baselineSessionId` | string | yes | The baseline session_id (before the change). |
| `changedSessionId` | string | yes | The changed session_id (after the change). |
| `claimType` | string | yes | Claim type: 'no_new_api' or 'symbol_removed_unused'. |
| `symbol` | string \| null |  | The symbol name the claim is about (required for symbol_removed_unused) - a bare name or the qualified Type.Member form, the same strings find_usages / impact_of_change / find_tests_for resolve. A removed type whose simple name is ambiguous solution-wide is recorded under its FULL name; pass that full name for it. A namespace-qualified TYPE name is accepted here even when nothing was removed - this tool resolves it against the baseline's declared type identities, which the fan-in tools (simple name only) do not, and the answer then names the simple name to carry on with. A dotted name no namespace declares stays unresolved rather than falling back to whatever type carries its last segment. |
