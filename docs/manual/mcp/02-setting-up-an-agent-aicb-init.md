[AICB - MCP Server](README.md) &middot; chapter 2 of 12

# 2 Setting up an agent: aicb init

`aicb init` is the command that connects a project to an agent. It writes the files an MCP client reads - the server entry and the agent skills - and, for the agent harnesses the project uses, it installs the **symbol guard**: a hook that refuses a C# symbol search and redirects the agent to the semantic aicb tools.

The command only writes files. It opens no solution and starts no analysis: no Roslyn, no MSBuild, no database. You can run it in any project directory, before anything is built, and even in a directory that holds no solution at all - the guard itself only acts where a solution is present (see "When the guard stays silent").

## 2.1 What it writes at a glance

| Artifact | Location, relative to the project directory | Written when |
|---|---|---|
| MCP client entry | `.mcp.json` | always |
| Server entry for Codex / OpenCode | `.codex/config.toml` / `opencode.json` | for Codex or OpenCode when detected or named, also with `--hooks none` |
| Agent skills | `.claude/skills/<skill>/SKILL.md` | always; one skill by default, three with `--skills all` |
| Agent skills for Codex / OpenCode | `.agents/skills/<skill>/SKILL.md` | for Codex or OpenCode when detected or named |
| Symbol guard script(s) | `.claude/hooks/`, `.codex/hooks/` or `.opencode/plugins/` | for every harness that is detected or named |
| Skill-sync hook script | `.claude/hooks/aicb-skill-sync.mjs` | for Claude Code when it is detected or named |
| Harness wiring | `.claude/settings.json`, `.codex/hooks.json` or `opencode.json` | for every harness that is detected or named; for Claude Code it also wires the skill-sync hook under `SessionStart` |

The run attempts the artifacts in a fixed order: `.mcp.json` first, then the Codex and OpenCode server entries, then the skills, then **all** hook scripts, then **all** wiring entries. Harness detection happens before the first write, so the run can never count a directory it created itself as evidence that a harness is in use. Each artifact reports its own result - one failure does not cost the others and does not hide them.

Every file is written atomically: a temporary file in the same directory is filled first and then moved over the target. An interrupted run therefore cannot leave a truncated `.mcp.json` (which would silently remove every other MCP server you had registered).

## 2.2 Before you run it

`aicb init` assumes the `aicb` command is already installed. The .NET tool needs the .NET 10 SDK:

```sh
dotnet tool install -g aicb-roslyn-mcp
aicb --version
```

On Windows with the desktop app, install the Windows installer instead - it contains the same server and keeps one `aicb` per machine. If more than one `aicb` is on your `PATH`, `aicb init` warns you (see "What a run reports").

Then open a terminal in the project directory you want to wire up:

```sh
cd /path/to/your/project
aicb init
```

## 2.3 Options

| Option | Default | What it does |
|---|---|---|
| `--path <dir>` | the current directory | The project directory to wire up. A directory that does not exist is an error: `error: directory not found: <dir>`, exit code `1`. |
| `--force` | off | Overwrite artifacts that are already there. Without it, an existing aicb entry, guard script or wiring entry is left exactly as it is - which is what makes re-running the command safe. For a skill file, `--force` takes over one aicb did not mark as its own, like `aicb skills sync --adopt`; a skill file aicb wrote is kept in step without it. |
| `--skills <context\|all>` | `context` | `context` writes only `aicb-csharp-context`; `all` additionally writes the `aicb-code-review` / `aicb-code-simplifier` review pair and `aicb-usage-check`. |
| `--hooks <auto\|none\|all\|claude-code\|codex\|opencode>` | `auto` | Which harnesses get the symbol guard and its wiring. `auto` installs for the harnesses already used in this project; `none` installs no enforcement at all; `all` installs for all three; the three ids name one harness each. |

An unknown `--hooks` value is rejected before the directory is even checked, because a typo in your own text does not depend on the file system:

```text
error: --hooks '<value>' is not one of: auto, none, all, claude-code, codex, opencode
```

`--skills` accepts only its two values; anything else is rejected by the command-line parser before the command runs.

Started in your home directory, or in a drive root without `.git`, the run writes only `.mcp.json`: the skills, hook scripts and harness wiring are refused there (`refused`, with `point it at the project directory instead`), because a harness file in that place is the user-wide one and would reach every project.

## 2.4 Step by step: the first setup

1. Install `aicb` and confirm it answers: `aicb --version`.
2. Change into your project directory and run `aicb init`. Add `--skills all` if you also want the review pair and the usage check, or `--hooks none` if you want no enforcement.
3. Read the report. Every artifact gets one line; if a line says `refused`, nothing was written for that file, the exit code is `1`, and the line says what to fix. Repair the file and run the command again.
4. Restart or reconnect your MCP client - a client reads its server list at startup, and this is the one step `aicb init` cannot do for you.
5. Call `server_info` to confirm the connection. It needs no session, no solution and no build, so it is the cheapest proof that the wiring took.
6. Start asking questions: the agent passes the absolute path of your `.sln` as the session argument (self-init) and works with the semantic tools from then on.

## 2.5 The `.mcp.json` entry

The file is created in the project root if it does not exist, and receives exactly this entry:

```json
{
  "mcpServers": {
    "aicb": {
      "command": "aicb",
      "args": ["mcp"]
    }
  }
}
```

The `command` is the bare name of the globally installed tool, not a path, so the entry is portable. The file is written with indentation and a trailing newline, because it is hand-edited and usually kept in version control.

What happens when the file already exists:

| Situation | Line printed by the command |
|---|---|
| No file was there | `created with the aicb entry` |
| File existed, other servers kept, aicb added | `aicb entry added, existing entries kept` |
| An aicb entry existed and `--force` replaced it | `existing aicb entry replaced (--force)` |
| An aicb entry existed, no `--force` | `already has an aicb entry - left untouched` |
| The file cannot be used as a server list | `left untouched - not valid JSON, or a duplicate key, or the top level is not an object, or 'mcpServers' is not an object; fix or remove it and re-run` |

Notes on the refusal:

- It names all four possible causes on purpose, because three of them are valid JSON: a syntax check in your editor does not rule them out.
- The file is parsed strictly - no comments, no trailing commas. A tolerant read followed by a write would silently delete whatever the tolerance swallowed.
- Without `--force` an existing aicb entry is never touched. You may have pointed it at a wrapper script, a debug build or another binary, and silently rewriting that is the one way this command could break a working setup.
- With `--force` the entry is replaced in place, so it stays where you had it and the diff is a single hunk. Your other entries are kept either way, including their exact spelling - non-ASCII characters in unrelated lines are not rewritten.

### Three files with similar names

- `.mcp.json` - the **client's** file, in your project root. The running server never reads it; only `aicb init` reads it, to add its entry.
- `aicb.mcp.json` - **aicb's own** file, optional, in your user configuration directory. It sets the exposed tool set and the session cache for headless operation. Absent is the normal case.
- `<SolutionName>.aicb.json` - the per-solution sidecar next to your `.sln`: layers, exclusions, test detection. It belongs in your repository.

## 2.6 The agent skills

A skill is a `SKILL.md` file with YAML front matter that an agent harness loads from `.claude/skills/<name>/SKILL.md`. Its `description` is what an agent sees before deciding whether the skill applies, so it is written as a trigger.

| Skill | Written by | What it is |
|---|---|---|
| `aicb-csharp-context` | every run (default) | The manual for driving aicb itself, addressed to the agent |
| `aicb-code-review` | `--skills all` | The correctness half of a post-task review pair: finds bugs |
| `aicb-code-simplifier` | `--skills all` | The complexity half: finds over-engineering, not bugs |
| `aicb-usage-check` | `--skills all` | Reads `usage_report` at the end of a task: what this server was reached for, what went untouched, what it cost |

The names carry the `aicb-` prefix deliberately: `code-review` and `code-simplifier` are already taken in a typical Claude Code installation, and a skill that silently loses to a same-named neighbor is worse than one that is absent, because nothing reports the collision.

The three are opt-in because each is an opinion about how you should work, not part of the product - if you already have a review routine, aicb's should not turn up beside it unasked, and whether you audit your own tool use is your habit to choose.

### What `aicb-csharp-context` tells the agent

- **Setup**: how to install aicb and register the server.
- **Step 0 - the session**: every tool accepts the absolute `.sln` path directly as its session argument (self-init); no separate analyze step is needed, and the server reads live source, including uncommitted work.
- **Which tool answers which question**: a routing table from question to tool.
- **The pre-edit gate**: before any edit that changes a symbol other code names - a rename counts, and so do a signature, a default value or a shared enum, interface or DTO - the first call is `impact_of_change`. The trigger is how far the symbol reaches, not what kind of edit it is. The tool returns the transitive fan-in, including consumers a compile does not check: a count assertion in a test, a non-exhaustive `switch` statement, a parallel list that has to grow with yours.
- **How far to trust an answer**: a rank order of tool groups by how often they misled, with the practical rule that the less a tool is called, the more its answer is a lead rather than a fact.
- **Reading the results**: an empty result is not proof of absence; result lists are capped while the reported totals stay true.
- **After you edit**: `refresh_session` first, then `get_diagnostics`. The order is not cosmetic - `get_diagnostics` compiles the session's snapshot, so without the refresh it describes the code before your edit.
- **Symbol or text**: when plain text search is still the right tool - string literals, comments, log messages, config keys, non-C# files.
- **First run on an unfamiliar solution**: `solution_config_status`, then `init_solution_config` and `apply_solution_config` if a slot is uninitialized.
- **Limits**: C# only; opening a solution runs its MSBuild logic, so analyze only solutions you trust; the fan-in graph covers exactly two markup edge kinds.

### What the review pair tells the agent

Both skills are written as a workflow. They gather the pending diff first (pushed branch, `main`, last commit, plus uncommitted changes), then check their heuristics against aicb facts before judging. If aicb is not connected, both say so explicitly: `aicb-code-review` runs a build itself rather than skipping the checks silently, while `aicb-code-simplifier` works from reading alone.

- `aicb-code-review` runs aicb pre-checks on the changed solution - `refresh_session`, `get_diagnostics`, `impact_of_change` per changed symbol, `find_tests_for` and `coverage_gaps`, concurrency checks for async changes, the markup tools for XAML changes, and `list_insights` scoped to the changed files for the pre-existing smells the diff must not worsen - and then works through bug classes: logic errors, boundaries, null handling, state and lifecycle, resource leaks, error handling, concurrency, async pitfalls, data integrity and security.
- `aicb-code-simplifier` verifies its heuristics with usage, implementation and dead-code facts, and its size claims with `symbol_metrics` and `list_insights` on the changed files, and then applies lenses such as unnecessary abstraction, premature generalization, nested control flow that could be flat, dead branches, stale comments and verbose tests.

Both accept a `--high` mode (the default, a single pass) and a `--max` mode (parallel angle-finders for higher recall).

### Where the skills go

Skills are always written to `.claude/skills/`, where Claude Code reads them. When the project uses Codex or OpenCode, or `--hooks` names one of them, the same skills are also written to `.agents/skills/`: Codex reads skills from there and from `.codex/skills/`, OpenCode from there, `.claude/skills/` and `.opencode/skills/`, and both read the shared folder. OpenCode keeps one copy of a skill it finds under two of its folders.

The skill is written per project. If you want it available in every project instead of one, copy the folder `.claude/skills/aicb-csharp-context/` to the same path under your home directory.

### Keeping the skills in step: `aicb skills sync`

The aicb skills are rendered for the tools the project's server actually serves. A paragraph or table row that names a tool the active profile withholds is left out, and a skill whose required tool is withheld is not written at all - `aicb-usage-check`, for example, needs `usage_report`, which the `Local` profile withholds. A skill therefore never sends the agent to a tool the server would refuse.

A skill file aicb writes has two parts. The front matter and everything from the line `<!-- aicb:begin ... -->` to `<!-- aicb:end -->` is aicb's and is rewritten whenever the served tools change; everything after it, starting at the line `<!-- aicb:user ... -->`, is yours and is kept byte for byte. A file without aicb's marker - one you wrote yourself, or one an earlier `aicb init` wrote - is never touched without an explicit take-over.

```sh
aicb skills sync [--project <dir>] [--adopt]
```

| Option | Effect |
|---|---|
| `--project <dir>` | The project to sync. Default: the project holding the current directory - the nearest directory upwards that has `.git` or `.claude`, below your home directory. Without one, the command stops and asks for `--project`. |
| `--adopt` | Take over skill files that are not in sync form: a hand-written copy (no aicb marker) is replaced, and an edit inside the aicb part is overwritten. Your part below the `aicb:user` line is kept. |
| `--auto` | Run as an automatic caller - the mode the Claude Code session-start hook uses (see below). Cannot be combined with `--adopt`. |

The command starts no server and opens no solution. It reads which tools the project's server serves from the project's `.mcp.json` aicb entry - the profile it pins with `--mcp-profile`, its `--db-path`, and `AICB_MCP_TOOLS` - and otherwise from the active profile of the configuration database. It prints one line per skill file (`in sync`, `created`, `rewritten`, `adopted`, `removed`, `kept`, `skipped`, `outdated` (when nothing could be written) or `failed`, each with the reason) and, when it changed a file, `The change takes effect at the next agent start.` An explicit `aicb skills sync` writes even when automatic skill sync is switched off in the desktop app's settings; a skill file aicb wrote and nobody edited is removed when the served tools no longer include one it requires.

**Automatic skill sync.** Two automatic callers keep the files in step without you running the command, both on by default:

- **The MCP server** rewrites the aicb-written skill files of the project it was started in, once per process, after its first session there - for Claude Code under `.claude/skills/`, for Codex and OpenCode under `.agents/skills/`. A solution opened by path from another project is left alone.
- **The Claude Code session-start hook** that `aicb init` and `install_agent_hooks` install (`.claude/hooks/aicb-skill-sync.mjs`, wired under `SessionStart` for session start-up) runs `aicb skills sync --auto` before the first prompt and asks Claude Code to reload the skills. It does nothing when automatic sync is switched off, when the project's `.mcp.json` has no aicb entry, or when that entry starts another command than `aicb`. Codex and OpenCode get no such hook; for them the server's own sync applies.

Both rewrite only files aicb wrote and only their aicb part; neither creates nor deletes a file. Switch both off with **Keep agent skill files in sync** in the **MCP Server** section of the desktop app's settings. A project set up by an earlier version gets the hook by running `aicb init` or `install_agent_hooks` once more. `server_info` shows whether a project's skills match what the server serves (the `SKILL` line, see `server_info`).

## 2.7 The symbol guard

The guard is the enforcement half of the setup: the skills tell an agent what aicb is for, and the hook makes the switch happen whether or not the agent read them. Besides this guard, aicb installs exactly one other hook: the Claude Code session-start hook that keeps the skills in step (see "Keeping the skills in step: `aicb skills sync`"). No other hook or plugin of any kind is installed.

It is a Node.js script that the harness runs before a tool call (`PreToolUse` in Claude Code and Codex, `tool.execute.before` in OpenCode). For Claude Code and Codex the wiring starts it with `node`, so Node.js has to be available on your `PATH`. The guard fails open: any error inside it results in "allow", so a broken hook can never break your tools.

### The one thing it refuses

A **Grep** call whose pattern is a single C# symbol - a PascalCase identifier of three or more characters (optionally starting with `I`), or a `Type.Member` pair - is denied, unless one of the two exits below applies. The agent does not get search results; it gets this message:

```text
aicb-guard: this is a C# SYMBOL query (pattern='<pattern>'). grep misses overloads,
aliasing, partial types and interface dispatch - use the semantic MCP tools instead:
mcp__aicb__find_usages (who uses X) / find_symbol (where is X) / explain_symbol (what is
X) / calls_external (external BCL/NuGet member) / impact_of_change (blast radius). No
separate analyze step needed: pass the .sln directly as sessionId (sessionId="<abs path
to .sln>") and the tool self-initializes. If this is genuinely a TEXT search (string
literal / comment / log / config), restrict it to the file type (Grep glob e.g. "*.xaml"
or "*.md") or open the specific file with Read. If an aicb answer about this name does
not cover your question, this Grep is allowed once that aicb call is made.
```

The last sentence appears in Claude Code only, the one harness whose session record the guard can read.

This is the only hard block, and it has two exits (see below). A shell command is never hard-blocked, because a shell command can do anything - `Bash` calls that look like a symbol sweep only get a note.

Note: the message names the tools in the `mcp__aicb__...` form that Claude Code uses. Other harnesses may present the same tools without that prefix; the agent should use whatever form its own tool list shows.

### Two ways past the refusal

- **After an aicb call on the same name** (Claude Code): when the session - the main agent or one of its subagents - has already called an aicb tool with the symbol in its arguments, the Grep is allowed with the note `aicb-guard: '<pattern>' allowed - this session already asked aicb about it (<tool>). A text search on top is fine when that answer did not cover the question. ...`. A failed call counts; a session or file path among the arguments does not. The exit is for the agent that asked aicb first and needs more than the answer gave.
- **Where aicb is not available** (every harness): when the session record shows that aicb's tools were removed or its server failed, or, without such a record, when no configuration file the harness reads mentions aicb at all, the Grep is allowed with the note `aicb-guard: '<pattern>' allowed - aicb is not available here (<reason>), so a text search is the only search there is. ...`. Any mention of aicb in those files counts as available, so in doubt the guard refuses.

### What it only warns about

| What the agent does | What the guard does |
|---|---|
| `Grep` with a multi-name alternation (`A\|B\|C`), every branch symbol-shaped | Allows, with a note: no MCP tool accepts a multi-name pattern, and the one-call semantic form is `batch` with several `find_usages` sub-queries |
| `Grep` with a mixed alternation (symbol-shaped and plain-text branches) | Allows, with a note naming the symbol branches |
| `Grep` on a single symbol after an aicb call on that name, or where aicb is not available | Allows, with a note naming the reason (see "Two ways past the refusal") |
| `Bash` with `grep`, `rg` or `findstr` on a symbol-shaped pattern | Allows, with a note preferring the semantic tools |
| First `Edit`, `Write` or `MultiEdit` on a `.cs` file in a session | Allows, with a reminder to run `impact_of_change` first and `refresh_session` + `get_diagnostics` after |
| Codex `apply_patch` touching a `.cs` file | The same reminder, once per session (shared with the edit reminder) |
| `Read` of a file of 50 KB or more without `offset`/`limit` | Allows, with a note to read a slice instead - once per session |
| `Read` of a file of 100 KB or more without `offset`/`limit` | The same note, every time |
| `dotnet build` or `dotnet test` | Allows, with a note that `refresh_session` + `get_diagnostics` pre-checks compile errors without a build - once per session |

Everything except the refusal is a non-blocking reminder. Only the refusal prevents anything; the reminders cost a little context and nothing else.

### When the guard stays silent

- **No `*.sln` directly in the project directory** - the guard is completely quiet in a non-.NET project or in a directory that only contains sub-projects.
- **A search scoped away from C#** - a `glob` whose every piece ends in a literal non-C# extension (for example `*.xaml`, `*.md`, `*.mjs`), a non-C# `type`, or a `path` that points at one concrete file. A negated glob (`!*.md`), a wildcard in the extension (`*.c?`, `*.verified.*`) and a glob list that includes `*.cs` still count as a search over C# files. A file-scoped search is a targeted text scan, not a codebase-wide symbol sweep.
- **A pattern with regex structure** - groups, character classes, quantifier braces (`()[]{}`) or `=>`. Such a pattern is a text search, never a bare symbol query.
- **Plain text by shape** - all-lowercase or snake_case names, UPPER_SNAKE constant or config keys, phrases containing spaces, paths and version strings are not symbol-shaped and pass through.

If you are blocked on a genuine text search, the same two routes work: restrict the search to a file type, or open the file with `Read`.

### Marker files

To keep the once-per-session notes from repeating on every call, the guard writes small marker files:

- Location: `<project>/<harness directory>/cache/nudge-<session>-<key>` - for example `.claude/cache/` for Claude Code, `.codex/cache/` for Codex, `.opencode/cache/` for OpenCode.
- Keys: `edit-cs`, `read-big`, `dotnet-build`.

The harness directory is derived from the guard's own location, so a guard installed for OpenCode never creates a `.claude/` directory in a project that has never run Claude Code.

Note: these marker files are harmless and can be deleted at any time; the guard recreates them as needed. `aicb init` does not add a `.gitignore` entry for the folder, so add one yourself if you do not want them in version control.

### Installing it for a harness deliberately

`--hooks auto` installs for the harnesses it detects. To install for a specific one regardless of detection, name it: `--hooks claude-code`, `--hooks codex`, `--hooks opencode`, or `--hooks all` for all three. To install nothing, use `--hooks none` - the rest of the run (the `.mcp.json` entry and the skills) still happens.

## 2.8 Harness detection with `--hooks auto`

`auto` is the default because writing enforcement for a harness a project does not use is not neutral: it drops configuration files into a repository you would then have to explain.

For Claude Code, a `CLAUDE.md` file in the project directory is evidence by itself: `init` never writes one, so its presence shows the project's own use. Otherwise detection asks whether a **marker directory** exists in the project - `.claude/`, `.codex/` or `.opencode/`. A marker counts as evidence when it contains at least one entry that `aicb init` itself would not have written there, because `init` creates `.claude/skills/` on every run and must not read its own side effect as proof that Claude Code is in use. Two boundary cases are deliberate:

- An **empty** marker directory counts as evidence.
- A non-empty marker counts only when it has at least one child that aicb does not create itself. For `.codex/`, `hooks/` and `cache/` are self-created; for `.opencode/`, `plugins/` and `cache/` are self-created. A marker containing only those children therefore does not count.

The price of this rule is a false negative in the safe direction: if your `.claude/` directory contains only your own `skills/` folder and the project directory has no `CLAUDE.md`, `auto` does not recognize Claude Code. You then get the explicit line

```text
No agent harness detected here, so no symbol guard was installed and this run registered the server only in .mcp.json (read by Claude Code). Pass --hooks claude-code|codex|opencode (or --hooks all) to wire one anyway - for Codex and OpenCode that also registers the server in their own config.
```

and install it yourself with `--hooks claude-code`. Nothing is installed unasked.

Only the project directory itself is checked for `CLAUDE.md`; a file in a parent folder or a `CLAUDE.local.md` does not count. Codex and OpenCode have no such file (`AGENTS.md` is read by several harnesses and identifies none of them). The reverse case: a project that keeps a `CLAUDE.md` for another agent also gets the Claude Code guard; `--hooks` with an explicit harness, or `--hooks none`, overrides the detection.

## 2.9 What a run reports

Each artifact gets one line in the format `<label> <path> - <detail>`, with the labels padded to equal width:

| Label | Meaning |
|---|---|
| `created` | The file did not exist and was written |
| `updated` | An existing file was changed (an added or replaced entry, a rewritten aicb skill, or a `--force` replacement) |
| `kept` | The file was already in the desired state and was left untouched |
| `refused` | The file was not touched, because touching it could have destroyed something |
| `removed` | An aicb-written skill file nobody edited was removed, because the served tools no longer include one it requires |

A sample run in a Claude Code project:

```text
created  C:\work\MyApp\.mcp.json - created with the aicb entry
created  C:\work\MyApp\.claude\skills\aicb-csharp-context\SKILL.md - agent skill aicb-csharp-context written for mcp-profile/default
created  C:\work\MyApp\.claude\hooks\aicb-symbol-guard.mjs - aicb symbol guard written
created  C:\work\MyApp\.claude\hooks\aicb-skill-sync.mjs - aicb skill sync hook written
created  C:\work\MyApp\.claude\settings.json - Claude Code: created with the aicb symbol guard wired
updated  C:\work\MyApp\.claude\settings.json - Claude Code: aicb skill sync (SessionStart) wired, existing entries kept

The symbol guard is installed and it BLOCKS: a C# symbol search is refused and redirected to the aicb tools, not merely discouraged. Worth knowing before it surprises you.
  Remove it for Claude Code: delete the aicb entry from C:\work\MyApp\.claude\settings.json
  Skip it next time: aicb init --hooks none (that writes no enforcement - it does not remove what is already there).

Restart or reconnect your MCP client, then call server_info to confirm it took.
```

The paragraph after the file list appears only when the run actually installed a guard. It says three things: that the guard blocks rather than discourages, how to remove it (naming the actual wiring file), and that `--hooks none` governs the **next** run rather than undoing an installation.

In a Codex project the run also registers the server and writes the skill a second time:

```text
created  C:\work\MyApp\.mcp.json - created with the aicb entry
created  C:\work\MyApp\.codex\config.toml - Codex CLI server list: created with the aicb entry
created  C:\work\MyApp\.claude\skills\aicb-csharp-context\SKILL.md - agent skill aicb-csharp-context written
created  C:\work\MyApp\.agents\skills\aicb-csharp-context\SKILL.md - agent skill aicb-csharp-context written
created  C:\work\MyApp\.codex\hooks\aicb-symbol-guard.mjs - aicb symbol guard written
created  C:\work\MyApp\.codex\hooks.json - Codex CLI: created with the aicb symbol guard wired
```

and ends, after the guard paragraph, with the step only you can take:

```text
Codex reads .codex/config.toml only in a project it trusts. Open Codex in this folder once and trust it, or the aicb entry stays invisible to it.
```

For OpenCode the server entry goes into `opencode.json` (`OpenCode server list: created with the aicb entry`), the file that also carries its guard wiring.

If more than one `aicb` is on your `PATH`, every run also prints a warning, because each MCP client starts the **first** one and updating another one changes nothing a client runs:

```text
warning: "aicb" is installed 2 times. Every MCP client starts the FIRST one; updating another one changes nothing a client runs.
  runs    C:\Program Files\AIContextBuilder\cli\aicb.exe - Windows installer (AI Context Builder)
  ignored C:\Users\you\.dotnet\tools\aicb.exe - .NET tool (dotnet tool install -g aicb-roslyn-mcp)
  Keep one. With the desktop app: keep the installer and run 'dotnet tool uninstall -g aicb-roslyn-mcp' (installed before 0.5.465.11: 'dotnet tool uninstall -g AIContextBuilder'). Without it: uninstall "AI Context Builder" in Windows Settings > Apps.
```

The run ends with the step it cannot take for you:

```text
Restart or reconnect your MCP client, then call server_info to confirm it took.
```

Exit codes: `0` on success, `1` if `--hooks` was invalid, the target directory did not exist, or at least one artifact was refused (`error: nothing was written for at least one artefact (see above).`).

## 2.10 Turning the guard off, or removing it

- **Install nothing next time**: `aicb init --hooks none`. This writes no enforcement, but it does not remove an installation that is already there.
- **Remove an installed guard**: delete the aicb entry from your harness's own configuration file - `.claude/settings.json`, `.codex/hooks.json` or `opencode.json`. For Claude Code and Codex this is the `PreToolUse` entry whose command names `aicb-symbol-guard.mjs`; for OpenCode it is the plugin entry `./.opencode/plugins/aicb-symbol-guard.ts`. Every run that installs a guard prints the path of the file to edit.
- **Remove the skill-sync hook** (Claude Code): delete the `SessionStart` entry whose command names `aicb-skill-sync.mjs` from `.claude/settings.json`. To keep the hook but stop it from writing, switch off **Keep agent skill files in sync** in the desktop app's settings instead.
- **Remove the files as well** (optional): the guard script(s) under `.claude/hooks/`, `.codex/hooks/` or `.opencode/plugins/`, the skill-sync script `.claude/hooks/aicb-skill-sync.mjs`, and the `cache/` marker directory.
- **Keep an edited guard**: an existing guard script is never overwritten without `--force`, exactly because a customized exemption list is the most likely thing to lose. The same holds for an existing wiring entry.

## 2.11 What this means for your agent workflow

After a default `aicb init` in a Claude Code project, the following changes for the agent working in that project:

1. A `Grep` search for a C# symbol name is **refused**, and the agent is redirected to the aicb tool that answers the question properly. Once the agent has asked aicb about that name in the session, or where aicb is not available, the search goes through with a note.
2. An `Edit`, `Write` or `MultiEdit` on a `.cs` file produces a one-time-per-session reminder to run `impact_of_change` before the change.
3. A `Read` of a file of 50 KB or more without a slice produces a reminder once per session; at 100 KB or more, every time.
4. `dotnet build` or `dotnet test` produces a one-time-per-session reminder about the faster diagnostics path.
5. The project gains a `cache/` folder with marker files under the harness directory.
6. The agent has the `aicb-csharp-context` skill available, whose description makes it load on any C# symbol question.
7. At session start, the skill-sync hook brings the aicb skills in step with the tools the server serves before the first prompt.

Only the first point prevents something. The others cost a little context and nothing else. The files land in your project, so you can commit them to share the setup with everyone working on the repository.

### What the server tells your agent

Independently of the installation, the server reports the wiring state to the calling agent. The report exists only when there is something to say: when the harness is wired, the field is absent and the answer is byte-for-byte unchanged.

- **Wired**: no hint.
- **Recognized harness, not wired**: the agent is told the project does not wire the guard for its harness, that the guard turns the rule from advice into enforcement, and how to install it - with `aicb init --hooks <id>` or the `install_agent_hooks` tool - followed by the rule in words.
- **Unrecognized client, or a client that announced no name**: the agent is told that aicb ships wirings for Claude Code, Codex CLI and OpenCode and has none for it, and it is given the rule in words. On such a harness the sentence itself is the mechanism.

The hint travels as a JSON field `agentWiring` on the session information and as a leading Markdown comment `<!-- aicb agent wiring: ... -->` on raw-Markdown answers such as `get_context` and `architecture_overview`, which cannot carry a JSON field.

### Installing from inside an agent: `install_agent_hooks`

The MCP tool `install_agent_hooks` is the second entry point for the guard. It writes **only** the guard script and the wiring entry - for Claude Code also the session-start hook that keeps the aicb skills in step - and no `.mcp.json` and no skills; it is the one aicb tool that writes into your project's agent configuration on request.

| Parameter | Required | Meaning |
|---|---|---|
| `sessionId` | yes | A session id, or the absolute `.sln` / `.slnx` / `.slnf` path (self-init) |
| `harness` | no | `claude-code`, `codex` or `opencode`. Omit it to use the harness the calling MCP client belongs to. An unknown name, or an unnamed client with no `harness` argument, is refused with the list of known ids |
| `force` | no | Overwrite an existing guard script and rewrite an existing wiring entry (default `false`) |

There is no path parameter: the target directory is the one holding the solution the `sessionId` resolves to. The response reports the harness, the project directory, whether the run succeeded, one entry per artifact (path, outcome, detail), and the step the caller has to take next:

```text
Restart or reconnect the MCP client so it loads the new wiring, then call refresh_session to clear the agentWiring hint on this session.
```

The two staleness windows it names are different: the client reads its configuration at startup, and the session keeps its analyze-time answer until it is refreshed. Installing hooks writes no source file, so a `refresh_session` alone is enough to clear the hint - no re-analysis is needed.

Note: `install_agent_hooks` is not available through `batch` or `measure`, so a call an agent believes is a read can never perform an installation.

### The built-in manual

The server also carries its own manual as the `docs` tool. `docs()` without arguments returns the directory with a token estimate per page; `docs("install")` returns the page that mirrors this chapter from inside the agent, and the route `docs("init")` returns the whole first-run sequence in reading order. It is a useful answer when an agent asks how aicb is set up in a project it cannot see.

---

[&larr; 1 Overview and connecting a client](01-overview-and-connecting-a-client.md) &middot; [Contents](README.md) &middot; [3 Sessions and staleness &rarr;](03-sessions-and-staleness.md)
