# How AICB works: architecture and evidence

This page answers the questions that matter when a person or a coding agent decides
whether to trust an AICB answer: what AICB knows about a solution, how it stays
current, how it chooses context and how it performs on large codebases.

## Is AICB only a cache around Roslyn queries?

No. Roslyn supplies the parsed syntax, compiler symbols, semantic models and
compilations. AICB walks those models, records its own facts and consolidates them
into an analyzed solution model. MCP tools then query or traverse that model; they
do not start an unrelated Roslyn search for every question.

```text
Solution and project-shaping files
                ↓
        MSBuild workspace load
                ↓
 Syntax trees + Roslyn semantic models
                ↓
 Document facts: declarations, calls, types,
 DI registrations, tests, markup and metrics
                ↓
 Consolidated indexes and derived relationships
                ↓
 Tool-specific traversal / selection / rendering
```

The model is static and semantic: it describes what the code states, with
explicitly documented boundaries for what only happens at runtime. The analysis
sequence is described in
[How the analysis works](manual/general/04-how-the-analysis-works.md).

## What is kept in memory?

A live MCP session holds the analyzed solution graph and the Roslyn workspace that
produced it: declared types and members together with the facts and indexes behind
callers, type fan-in, implementations, tests, DI, markup, architecture, metrics and
side effects.

| Stage | Examples | When it happens |
|---|---|---|
| Roslyn input | Syntax trees, symbols, semantic models and compilations | While loading and analyzing documents |
| Recorded facts | Declarations, calls, type references, construction sites, test evidence and statically readable registrations | During the document walk |
| Consolidated relationships | Caller and type fan-in, implemented-by lists, resolved XAML references and transitive effect classifications | After the document walk |
| Question-specific result | Transitive impact closure, risk summary, filtered result lists and task context | When a tool is called |
| Rendered output | AI-Builder-MD in tag or YAML notation | When context is requested or exported |

AICB keeps the reusable semantic facts warm and calculates each answer from them on
demand, so follow-up questions are fast without every possible path being stored in
advance.

Each persistence surface has its own purpose:

| Surface | Stores | Does not store |
|---|---|---|
| Live MCP session | Analyzed graph plus the Roslyn workspace in one server process | Cross-process state or unsaved editor buffers |
| Remembered codebase | A persisted model that `recall_codebase` can rehydrate without Roslyn | A live workspace, reliable line numbers, the layer profile or every live-only insight |
| Saved snapshot | A named analysis baseline for later comparisons | A mutable live session |
| `<Solution>.aicb.json` | Portable layer, exclusion, test, suppression and analysis-scope configuration | Analysis results, sessions, snapshots or credentials |

`remember_codebase` persists the model of a live session, a later process can load it
with `recall_codebase`, and `refresh_remembered` brings it back to a full live
analysis. A recalled model reports when it no longer matches the source, so it is
never mistaken for a shared live workspace.

## What does AICB add beyond Roslyn?

Roslyn is the semantic foundation. AICB adds the questions a coding agent needs
answered, aggregated at symbol level:

- transitive change impact with production and test users kept apart;
- call, type, implementation and construction relationships per symbol instead of
  an unaggregated list of positions;
- test discovery with evidence tiers;
- Microsoft DI and MEF registrations and constructor-injection relationships;
- source-generated code, and XAML/AXAML, WinUI and Razor bindings, resources and
  type references;
- side-effect and external-call classification;
- layers, cycles, quality insights, metrics and change-policy checks;
- goal-driven selection and token-budgeted AI-Builder-MD rendering;
- provenance and optional `<ai>` annotations for meaning the compiler cannot infer.

A language server and AICB complement each other: the language server serves the
editor (unsaved buffers, navigable positions, fuzzy lookup, third-party analyzer
diagnostics), AICB serves the agent with aggregated answers about the saved code.
The comparison is in
[How AICB differs from a language server](manual/general/01-introduction.md#16-how-aicb-differs-from-a-language-server).

## How incremental refresh works

A session records the file set it analyzed. After saved edits, the next refresh
brings the warm Roslyn solution up to date: edited C# files, and C# files added,
renamed or removed where it is clear which project compiles them, are applied in
place, and the facts of documents the edit cannot have reached are reused. The
response identifies this as `mode: "incremental"`.

A change to project-shaping files - project, props, targets, solution and XAML or
Razor files - takes a full reload, as does `refresh_session(force: true)`. A project
added to or removed from the solution file is detected as well. A restore that
rewrote a project's assets file is picked up by an ordinary refresh; after a build,
use `force: true` when an earlier answer reported unresolved projects.

Reuse is deliberately conservative: when an edit could change how other documents
bind, AICB analyzes them again rather than serve a plausible stale relationship. The
regression suite compares an incrementally refreshed session with a separately
opened full reload for every supported edit shape and asserts that the incremental
path really ran.

A session has at most one refresh in flight; a concurrent caller joins it instead of
starting a second analysis. The complete operational contract is in
[Sessions and staleness](manual/mcp/03-sessions-and-staleness.md).

## How does AICB keep its answers consistent?

Each kind of relationship has its own index: who calls a method, who uses a type,
a property or an event, which types implement an interface, which markup refers to
a member. Every entry is filed under an identity that keeps overloads and explicit
interface implementations apart, so one name never merges two different symbols,
and a relationship that several parts of the analysis find is stored once.

Relationships that can only be resolved after the whole solution has been read -
XAML bindings, Razor references and the types a top-level program uses - are
resolved at the end of the analysis and then count like any other use. Answers that
follow chains, such as the transitive impact of a change, are worked out when you
ask.

## Do the GUI and MCP server share the same RAM graph?

They share the same analysis and rendering engine and, by default, the local
configuration database, but each process keeps its own analysis. An MCP session
belongs to one `aicb mcp` process; the default cache keeps up to eight sessions and
expires an idle one after 90 minutes, both configurable. An idle session also
releases its Roslyn solution after a configurable time and keeps its analysis graph.

Two agents connected to different server processes therefore never race on one
in-memory graph. They can still work on the same source tree, so each process
refreshes after relevant saved edits.

## How does AICB choose context for an agent?

The task-oriented tools start from explicit evidence rather than sending the whole
repository:

1. `pack_for_task` identifies the symbols named in a natural-language goal and
   expands their semantic neighborhood.
2. `prepare_task` adds covering tests and likely siblings such as a validator or a
   factory.
3. The named symbols stay pinned. Under budget pressure, AICB reduces detail around
   them instead of cutting a code block in the middle.
4. A leading bundle manifest reports seeds, tests, siblings, caps and omissions.
5. `measure` returns the exact token cost of planned answers before their payloads
   are requested.

The agent keeps the lead: it chooses the goal, reads the manifest and calls the
specialized tools for DI, markup or runtime configuration where the task needs them.
Task-bundle behavior is documented with
[`pack_for_task` and `prepare_task`](manual/mcp/09-tool-reference-markup-export-review-and-insights.md#92-packing-and-exporting-context).

MCP profiles size the tool list itself to the model: the built-in Local profile
serves 30 frequently used tools with compact descriptions for a model whose context
window makes every tool definition expensive.

## Where does static analysis stop?

- **Runtime behavior.** Reflection, runtime assembly scanning, interpreted code,
  dynamic configuration, serializers and consumers outside the solution can create
  relationships the static graph does not contain. An empty caller list is
  therefore reported as such, not as proof that code is unused.
- **Dependency injection.** AICB reads statically recognizable Microsoft-DI-shaped
  registrations, MEF export attributes and constructor injection. A registration
  produced at runtime is reported as dynamic, unknown or factory-shaped rather than
  guessed.
- **XAML and AXAML.** Bindings, resources and type references are resolved where
  their source and type can be established safely; an unknown data scope is left
  unjudged instead of being assigned to a plausible type.
- **Side effects.** The eight effect tokens (`io`, `network`, `database`,
  `serialization`, `logging`, `cache`, `messaging`, `unknown`) describe static
  contact with an outside-world API and propagate through known call edges. They
  tell you that a method can write a file, not which file or when.

## How does an answer disclose uncertainty?

Before treating an empty or short result as proof, inspect the response metadata:

| Signal | Meaning | Typical action |
|---|---|---|
| `staleness` | Saved source has moved since the session was analyzed, or an automatic refresh ran or failed | Save files and call `refresh_session` if needed |
| `incompleteProjects` | One or more project compilations could not resolve core references, so semantic edges may be missing | Restore, then `refresh_session`; after a build, `refresh_session(force: true)` |
| `totalFound` and `truncated` | The tool found more items than it returned | Raise the relevant cap or narrow the query |
| Bundle manifest / leading comment | Tests, siblings, types or methods were omitted under the token budget | Increase the budget or request the omitted axis directly |
| Dynamic/unknown placeholders | A relationship exists syntactically but its target cannot be established statically | Verify runtime configuration or construction code |

## How does AICB scale on large solutions?

There is no hard project-count limit. The cost of an analysis follows the shape of
the solution: loaded projects, C# documents, target-framework instances and the
density of the relationship graph. These controls keep large solutions practical:

| Control | What it reduces | Trade-off |
|---|---|---|
| `.slnf` | Projects loaded by MSBuild and analyzed by AICB | Code outside the filter is not analyzed |
| `analyzePreferredTfmOnly` | Duplicate analysis of multi-targeted projects | Relationships that exist only in another target framework are not seen |
| Warm sessions and incremental refresh | Repeated load and analysis work after saved edits | Project-shaping changes take a full reload |
| Persisted recall | Startup analysis when a recalled model is sufficient | No live workspace or line numbers until a refresh |
| `summaryOnly`, result caps, scopes and token budgets | Response size and agent context cost | They do not reduce the analysis itself |

The desktop app records per-phase load timings in `load-perf.log`, and `usage_report`
records per-tool latency and result sizes, so a team can measure its own solution.

### Benchmark

Measured with AICB `0.5.515.1` on 2026-11-06:

| Solution | Repository revision | C# LOC (git-tracked) | First analysis (cold) | Repeated question (warm) | Peak RAM | RAM after idle release |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `Serilog.sln` | `serilog/serilog` `2ef6364` | ~ 24,700 | 14.8 s | 139 ms | 901 MB | 379 MB |
| `src/MahApps.Metro.sln` | `MahApps/MahApps.Metro` `72099e3` | ~ 54,700 | 21.0 s | 178 ms | 2,574 MB | 865 MB |
| `RavenDB.sln` | `ravendb/ravendb` `5415dde` | ~ 1.76 M | 74.8 s | 2.15 s | 4,125 MB | 950 MB |

Method: the median of six runs per solution, each in a fresh `aicb mcp` process with
an empty configuration database and an empty design-time-build cache. Cold is the
first `solution_metrics` call on the restored solution, warm the second identical
call, both timed on the client. RAM is the working set of the server's process tree;
the idle-release value was read 11 minutes after the last answer, with the idle
release time set to 5 minutes. Machine: Windows 10 Pro, Intel Core i9-9900K
(8 cores / 16 threads), 31.9 GB RAM. These are measured data points on one machine,
not a performance guarantee for every solution.

## How does AICB handle updates?

- `server_info` reports the product version, build commit, database schema and any
  binary, configuration or analyzer drift.
- A persisted analysis records its payload schema and analyzer identity; when either
  is incompatible, AICB performs a fresh analysis instead of loading an unsafe model.
- Database migrations are forward migrations, and the desktop app never writes to a
  database created by a newer version. The database and application data survive an
  update, and optional automatic backups can archive them.
- To roll back, use the older version with a separate database or a backup made
  before the update.

Support follows the license: best effort through Issues and Discussions, and
individually agreed support, response targets and version maintenance under a
commercial agreement.

## Trust and integrity

- The Windows installer and programs are code-signed (publisher: Gregor Dadera), and
  every release publishes SHA-256 checksums.
- The CLI and MCP server make no outbound network connection of their own and do not
  modify the code they analyze; the [security policy](../SECURITY.md) describes the
  local-processing and network boundary.
- Tool calls are recorded locally for `usage_report` and never leave the machine.

## Where to continue

- [General reference manual](manual/general/README.md)
- [MCP server manual](manual/mcp/README.md)
- [Desktop app manual](manual/desktop-app/README.md)
- [Generated tool reference](TOOLS.md)
- [Security policy](../SECURITY.md)
