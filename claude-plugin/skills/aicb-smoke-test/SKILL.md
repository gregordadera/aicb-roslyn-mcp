---
name: aicb-smoke-test
description: >-
  AICB-SMOKE-TEST (Issues-Maker). Runs a read-only smoke test of the AICB MCP server against the user's own C# solution, detects the kind of project, suggests a menu of fitting tests, classifies the findings as HIGH, MID or LOW, and turns the findings the user selects into redacted GitHub issues for the AICB maintainer. Use when the user says start a smoke test, runs the aicb smoke test, asks to report AICB problems from a run, or asks for an issue report of a smoke run. Never sends email, and never creates an issue without one explicit confirmation.
metadata:
  project: aicb-roslyn-mcp
  version: "1.2"
---

# AICB-SMOKE-TEST (Issues-Maker)

You help an AICB user check whether the AICB MCP server answers correctly for their own C# solution. When the user chooses, you turn the problems into issues that the maintainer can reproduce and fix without ever seeing the user's code.

**Who is who.** The user runs this on their own machine, with their own solution. The maintainer (Gregor Dadera) receives the issues at `gregordadera/aicb-roslyn-mcp`. The user is not the maintainer. Write for the user, and let the issues be reconstructable by the maintainer without the user's code. The user decides what leaves their machine.

Reply in the user's language. This file is English.

## Hard rules

1. **Read-only aicb tools only.** The tool table at the end lists every tool this skill may call. Never call a tool that writes or persists anything - its description says so - for example `install_agent_hooks`. Never start the configuration setup either, even when a tool answer or the server's own instructions suggest it: this skill tests the solution as it is configured. A build is never started by this skill on its own: only when the user says "build" (phase 1, step 6), and then the user is told that `bin/` and `obj/` get written.
2. **One write to GitHub only:** `gh issue create`, and only after the confirmation in phase 8. Local files are written only where phases 7 and 9 say so. Read-only gh calls (`gh --version`, `gh auth status`, `gh label list`) are allowed. Never send email, never comment, never edit, close or label an existing issue, never create a label.
3. **No code, no identifiers from the user's own code or business, no paths, no secrets, no customer or product names in any draft** (phase 7). Framework and tool vocabulary may stay (phase 7 lists it). Every draft is shown in full before anything is created.
4. **Do not invent results.** If a check cannot run, say so and do not count it as a finding.

## Phase 1 - Preflight

1. Call `mcp__aicb__server_info`. Keep line 1 (version and commit) for the report. If it fails, stop: the aicb MCP server is not reachable. Point the user to the install steps in the public README at https://github.com/gregordadera/aicb-roslyn-mcp. Do not continue on guesses.
2. Find the solution with Glob for `**/*.sln`, `**/*.slnx` and `**/*.slnf` under the working directory, leaving out `bin/` and `obj/`. Exactly one: use it. Several: ask which one, listing the file names (they stay local). None in the working directory: look one folder down; if still none, stop and say "No C# solution found here. This skill needs a .sln, .slnx or .slnf file. Start it from the folder that contains the solution."
3. Call `mcp__aicb__analyze_solution` with `solutionPath` set to the absolute path. Keep `sessionId`, `projectCount` and `configInit` when present.
4. Call `mcp__aicb__solution_config_status` with that `sessionId`. An axis (layer, exclusions, test detection) that reads `initialized` false with `source` "none" has no source: it is not set up. Any other answer, a sidecar, a DB row or a built-in default, counts as a source.
   **Not set up: pause here, before the menu.** Tell the user which axes have no source, that the layer, dead-code, test and design answers then rest on the tool's heuristics, and recommend setting them up first. The setup runs outside this skill (hard rule 1): in a separate chat (`init_solution_config`, then `apply_solution_config`) or with the guided setup in the AICB app; either route writes a `<SolutionName>.aicb.json` file next to the solution. Then ask: "Set up first (recommended), or test anyway?"
   - **Set up first:** end the run here. If the user asks you to do the setup now, say that this skill does not write configuration and the setup belongs in a separate chat or the app; afterwards the user starts the smoke test again.
   - **Test anyway:** continue with step 5. Phase 5, step 0 still applies, so answers that depend on an axis without a source are M3; they may still be drafted, and phases 7 and 10 state the choice.
5. Build state, read-only, with Glob: look for `obj/project.assets.json` under the solution folder. Record how many projects have it. Effect and external-call answers depend on a restored and built solution. Record the state.
6. **Optional build.** Only if the user says "build": run `dotnet build` on the solution and tell the user it writes `bin/` and `obj/` in their solution folder. Without that word, nothing is built; tests that need a build (C3, B1, B3) report M3 when the state from step 5 says "not built".

## Phase 2 - Project kind

Use only text reads of project files: Glob and Grep on `*.csproj`, `*.props`, `*.targets` and `packages.config`. Do not search or read C# source for this step.

Signals, counted per non-test project:

- **Desktop WPF:** `UseWPF` true. **Desktop WinForms:** `UseWindowsForms` true.
- **ASP.NET or API:** `Sdk="Microsoft.NET.Sdk.Web"`, or a reference to `Microsoft.AspNetCore.*` or Blazor.
- **Worker:** `Sdk="Microsoft.NET.Sdk.Worker"`.
- **Console:** `OutputType` Exe or WinExe, with none of the desktop, web or worker signals.
- **Library or NuGet package:** `OutputType` Library and `IsPackable` true, or a `PackageId` set. A plain class library without packaging counts for nothing: it is supporting code.
- **SAP Business One add-on (overlay):** a reference or package whose name contains `SAPbobsCOM`. It is reported together with any kind.
- **Test project (excluded from the decision):** `IsTestProject` true, or a reference to `Microsoft.NET.Test.Sdk`, `xunit`, `NUnit` or `MSTest`.
- **UI frameworks not listed above** (MAUI, WinUI, Avalonia, Blazor WebAssembly alone): no signal. Ask the user which kind applies. Do not guess.

Decision:

1. No non-test project carries a signal (only plain libraries, or nothing): ask the user.
2. Exactly one family among the signalled projects: that is the kind.
3. Several families: the kind is **mixed**, and the menu offers the tests of each family.
4. Only signals from unlisted UI frameworks: ask the user.
5. Add the SAP overlay when its signal is present.

Report one kind line, the signals that decided it as counts and SDK or package names (never file names), and let the user correct it.

## Phase 3 - Menu

Offer the tests that fit the detected kind. Each test shows: ID, name, what it checks, the tool call, what a healthy answer looks like, and why it matters. The shared tests come first. The recommended set is S1 to S5 and S7 plus the kind tests. The user picks by ID, `all`, or `none`.

**Shared (any kind)**

- **S1 Identity.** Checks: which AICB build answers. Call: `server_info`, already run. Healthy: identity line present, no drift line or an in-sync one. Why: the version goes into every issue.
- **S2 Configuration.** Checks: that every configuration axis (layer, exclusions, test detection) is set, or its source is named. Call: `solution_config_status`, already run (phase 1, step 4). Healthy: each axis has a source (phase 1, step 4). Why: an axis with no source changes every answer after it. In a run tested without setup, the missing axes are already stated in every draft; they are not a separate finding.
- **S3 Compiler cross-check.** Checks: that the tool sees the same compile errors as the compiler. Call: `get_diagnostics` with `scope` "solution" and `severityFloor` "warning". Healthy: the counts agree with the user's last build (ask for the two numbers, not the messages), and `incompleteProjects` and `designTimeBuildFailures` are empty. Why: a missed compile error is a serious failure.
- **S4 Design findings.** Checks: that the design findings are real. Call: `list_insights`, then `get_insight` for each insight with `detailsCount` above 0, `maxDetails` 20. Healthy: each finding is recognisable in the code; each suppressed count is explained, meaning the user can say which suppressions produced it. Why: the most used check.
- **S5 Metric agreement.** Checks: that the rollup agrees with the findings. Call: `solution_metrics`. Healthy: its severities agree with the S4 counts; its `typeCount` and `methodCount` agree with the scanned counts of S7 when S7 was run. Why: two tools answering one question must agree.
- **S6 Namespace cycles.** Checks: that each reported cycle is real. Call: `detect_circular_dependencies`. Healthy: each witness pair can be confirmed with `find_usages`. Why: a false cycle sends a refactoring the wrong way.
- **S7 Dead code.** Checks: that dead-code candidates really have no users. Call: `find_dead_code` with `kinds` "all". Healthy: each candidate has zero users under `find_usages`; the ineligible counts are read, not skipped. Why: deleting a live type breaks the build or the behaviour.
- **S8 Architecture.** Checks: the layer and entry-point picture. Call: `architecture_overview` with `lean` true. Healthy: the layers and entry points are the ones the user recognises. Why: a wrong project graph shows here first.

**ASP.NET or API (W)**

- **W1 Endpoints.** Checks: that controllers and authorization attributes are found. Call: `find_by_attribute` with `attribute` "ApiController" and `kinds` "type"; then `attribute` "Authorize". Healthy: the count matches the controllers the user knows. Why: a missed endpoint is a missed security review. Zero in a web project is suspicious (M2).
- **W2 Outbound HTTP.** Checks: that outbound HTTP calls are found. Call: `calls_external` with `pattern` "HttpClient". Healthy: the call sites the user knows. Why: outbound calls are the usual failure surface.
- **W3 One service registration.** Checks: that dependency injection registrations resolve. Call: `resolve_injection` with `interface` set to one interface the user names. Healthy: the registrations match the startup code the user knows. Why: a wrong registration fails only at run time.

**Desktop WPF or WinForms (D)**

- **D1 Bindings.** Checks: that XAML bindings resolve. Call: `find_unresolved_bindings`. Healthy: the markup files scanned match the XAML the user knows; `sitesJudged` and `sitesSkipped` are explained. Why: a broken binding compiles and fails silently at run time. With no markup in the solution the tool says so; that zero is L3 only when the project has no XAML by design, otherwise M2.
- **D2 Binding inventory.** Checks: that the binding counts add up. Call: `find_binding_usages` without `path`. Healthy: `totalSiteCount` agrees with the sum of the member counts. Why: a sanity check for D1.
- **D3 Resource keys.** Checks: unused and misspelled resource keys. Call: `find_resource_usages` without `key`. Healthy: each never-referenced key is checked by the user with a text search before any deletion. Why: deleting a key that is still used throws only at run time.

**Library or NuGet package (LB)**

- **LB1 Public surface.** Checks: that the public API is what the user intends to ship. Call: `describe_api_surface` with `scope` "solution" and `includeInternal` false. Healthy: the public types are the ones the user intends. Why: an accidental public type is a breaking change once shipped.
- **LB2 Obsolete members.** Checks: deprecated members. Call: `find_by_attribute` with `attribute` "Obsolete". Healthy: each listed member is one the user has deprecated. Why: a missing `Obsolete` marks a removal as silent.
- **LB3 Coverage gaps.** Checks: untested methods. Call: `coverage_gaps` with `scope` set to one namespace the user names (not the whole solution, the output is large). Healthy: the gaps are the ones the user expects. Why: gaps guide where tests are missing.

**Console or worker (C)**

- **C1 Hosted services.** Checks: that hosted services are registered. Call: `resolve_injection` with `interface` "IHostedService". Healthy: one registration per hosted service the user starts. Why: an unregistered service never starts.
- **C2 External calls.** Checks: the external calls the code makes. Call: `calls_external` with a `pattern` the user names, for example "Console." for console output. Healthy: the call sites match what the user knows. Why: the external surface of a console tool.
- **C3 Side effects.** Checks: which methods touch files, databases or the network. Call: `find_by_side_effects` with `effect` "io", then "database" or "network". Needs a built and restored solution (phase 1, step 5). On an unbuilt solution an empty answer is M3, not a finding.

**SAP Business One overlay (B)**

- **B1 SAP calls.** Checks: the SAP DI API call sites. Call: `calls_external` with `pattern` "SAPbobsCOM". Healthy: the call sites the user knows. Needs a built solution (M3 otherwise).
- **B2 Connector registration.** Checks: the SAP connector's registration. Call: `resolve_injection` with the service interface the user names. Healthy: the registration count is as expected.
- **B3 Database and network effects.** Checks: effects of the SAP connector code. Call: `find_by_side_effects` with `effect` "database", then "network". Needs a built solution (M3 otherwise).

**Mixed:** the union of the family lists, duplicates removed.

End with: "Which tests should run? Recommended: S1 to S5 and S7 plus the kind tests above. Reply with IDs, `all` or `none`."

## Phase 4 - Run

Run the chosen tests in order. Independent calls may run in parallel. Keep a result log in the chat, not in a file: for each test, its ID, the tool, the parameters exactly as sent, a one-line summary, the verdict (healthy, finding or precondition) and the finding IDs. Record a tool error verbatim; it is evidence for the classification in phase 5.

## Phase 5 - Classify

Every finding gets one level. Apply the rules **in the order below, top to bottom**; the first rule that matches decides. Record the rule ID with it. Assign finding IDs `F-01`, `F-02`, ... in the order found; the user selects by these IDs.

**Step 0 - precondition first.** Before any other rule: if the answer, or the error, depends on a build, a restore or an uninitialized configuration axis that is missing, it is **M3**, even when the tool errored. A refusal caused by a missing build is M3, not H1.

**HIGH** - the answer is wrong, or it misses something the compiler does not catch:

- **H1 Tool error.** An exception, a crash, a timeout, or a refusal that is not a documented answer (a `not_found` for a name that really does not exist is documented). Not caused by a missing precondition (step 0). A tool error of that kind is HIGH without further proof.
- **H2 Wrong answer, confirmed.** A name, count or relation that the user checked directly in their own code and found contradicting the answer. The user does the checking; the skill does not read the code out to the maintainer.
- **H3 Missed defect, confirmed.** The user names a specific thing the tool should have reported and did not (for example an unresolved binding they can see, or a type it called dead that visibly has users). A missed thing the user cannot name is M1.
- **H4 Unsafe answer, confirmed.** The user confirmed by a direct check that following the answer would break the build or the behaviour. An answer about reference counts the user cannot check is not confirmable: it is M4 or M5.

**MID** - suspicious or incomplete; a human must look:

- **M1 Disclosed gap on the question asked.** A non-empty disclosure such as `incompleteProjects`, `designTimeBuildFailures`, `generatedCodeGaps`, `sitesSkipped`, or a count of types or methods left unjudged, on the population the test was about. Also: a missed thing the user suspects but cannot name.
- **M2 Suspicious zero.** Zero where the kind or the user's knowledge expects content (no controllers in an ASP.NET project; no XAML in a WPF project).
- **M3 Precondition not met.** See step 0. The answer may be a false zero. Re-run after the precondition is met, then classify again.
- **M4 Disagreement.** Two tests answer one question differently (S5 is the usual case).
- **M5 Not judgeable.** The user cannot decide from the output alone, or the user says "I think it is wrong but I am not sure". Also any empty value that carries an answer.

When unsure between HIGH and MID, choose MID. Deferring costs one round; a wrong HIGH costs the maintainer's time.

**LOW** - wording, cosmetics, or information. Use LOW only when none of the rules above match:

- **L1 Cosmetic.** Wording, formatting, or an empty field that the tool does not use to answer anything.
- **L2 Informational.** A healthy answer the user asked to have listed. Healthy answers are not findings unless the user asks.
- **L3 Documented limitation.** The tool's own note explains the zero, and the kind does not expect content (for example "0 markup files found" in a project with no XAML by design).

Output: one table with ID, level, rule and a one-line description, plus counts per level. LOW findings are listed; they become drafts only if selected.

## Phase 6 - Select

The user selects finding IDs, for example "F-02, F-05", or "none". Only selected findings become drafts. A finding the user did not select is never drafted, shown as a draft, or sent.

## Phase 7 - Draft (redacted)

Before drafting, ask the user for their own sensitive terms: company, customer and product names, user names, and any other word they do not want to leave the machine. Each of them is redacted in every draft, case-insensitively, and the user may add terms later.

Then build a local mapping from each identifier to a placeholder (for example `TYPE-1`, `MEMBER-1`, `FILE-1`, `PROJECT-1`, `TERM-1`) and write it to `aicb-smoke-mapping.local.json` in the user's home folder under `aicb-smoke-test/`, not in the solution folder. Tell the user the file exists, that it stays on their machine, and that they may delete it after the run. The mapping never goes into a draft.

**May stay in a draft (framework and tool vocabulary):** AICB tool names and parameter names; the keys of the tool's own result (for example `sitesJudged`); attribute names the tool was asked for (for example `ApiController`); framework interface names (for example `IHostedService`); TFM strings; the `server_info` version line. The maintainer needs them to reproduce.

**Must be replaced:** any name from the user's own code (types, members, namespaces, projects, files); any parameter **value** the user chose (the `pattern`, `interface`, `attribute` when it is the user's own, `namespace`, `symbol`, `key`, `path`) unless the user explicitly allows it for that issue; string literals, code lines and quoted text from the tool output; the user's sensitive terms.

**Draft template**

- **Title:** `[smoke] <kind>: <short description>`. No identifiers, under 80 characters.
- **Summary:** one sentence.
- **Environment:** AICB version and commit (from `server_info` line 1); operating system; .NET SDK from `dotnet --version`, read-only. If one of them cannot be read, write "not available" and say so in the report.
- **Solution shape, counts only:** number of projects, number of test projects, target framework strings with counts (for example `net8.0` x3), SDK style yes or no, built and restored yes or no, detected kind and overlay, and the configuration as phase 1, step 4 measured it: "configuration: every axis has a source", or "configuration: <n> of 3 axes without a source (<axis names>); tested without setup at the reporter's choice".
- **Tool call:** tool name and parameters, parameter values replaced by placeholders where they are the user's.
- **Expected:** what the answer should have said, and why.
- **Observed:** what it said, counts unchanged.
- **Minimal output:** the smallest excerpt of the tool result that shows the defect. Keys and numbers kept; names, string literals, code lines and quoted text replaced by placeholders.
- **Steps to reproduce:** numbered, with placeholders where the user's names belong. State that it was reproduced on a public fixture only when that was actually verified.
- **Classification:** level and rule ID.
- **Redaction note:** "Identifiers and terms replaced by placeholders. The mapping stays with the reporter."

**Forbidden in a draft:** source code and file contents; class, member, namespace or project names (unless the user explicitly allows them for that issue, recorded in the chat); file paths, including the user name in them; connection strings and credentials; customer, company and product names; any business data.

**Redaction pass** (run on every draft before it is shown). Scan the text for these patterns, fix each hit, and show the user the list of hits with the placeholder each one got:

- Windows paths in any form: a drive letter followed by a colon and a slash or backslash (`C:\`, `C:/`), `Users` followed by a slash or backslash, Git-style `/c/Users`, and UNC paths (`\\server`).
- Source file extensions: `.cs`, `.xaml`, `.csproj`, `.sln`, `.slnx`, `.slnf`, `.razor`, `.cshtml`, `.props`, `.targets`.
- Secrets and connection data, case-insensitively: `Server=`, `Data Source=`, `Initial Catalog=`, `User Id=`, `Password=`, `password`, `pwd=`, `AccountKey=`, `Bearer`, `token`, `secret`, `key=` followed by a value.
- URLs and e-mail addresses, except the public repository URL.
- Every term from the user's sensitive list.
- Any other PascalCase or camelCase token that is not in the framework or tool vocabulary above.

The user may waive a hit for one issue in the chat. Waivers are per issue and never carry over.

## Phase 8 - Readiness, preview and confirm

1. Check gh with `gh --version` and `gh auth status`. Both are read-only. Check labels with `gh label list --repo gregordadera/aicb-roslyn-mcp --limit 100`. Use only labels that exist. Every smoke-test issue carries `smoke` (it marks the source of the report and exists on the repository). In addition, the category label: defects (H and M findings that are defects) get `bug`; a missing capability gets `enhancement`; wording or documentation (L) gets `documentation`; when unsure, no category label. Never create a label.
2. Show every draft in full, numbered (`Issue 1 of N`), with its labels, or "no label".
3. Then ask one question that names the number, the repository, and that the issues will be public on GitHub under the user's account. For example: "Create 3 public issues in gregordadera/aicb-roslyn-mcp under your GitHub account? Reply yes to create them, tell me which to change or drop, or say `report file` to write one report file instead." If gh is not ready, say so, and offer the report file as the only option. Ask once. Changes the user asks for mean a new draft, a new redaction pass and a new preview.

## Phase 9 - Create

1. For each confirmed draft, write its body with the Write tool to `aicb-smoke-issue-<n>.md` in the user's home folder under `aicb-smoke-test/`. The body must be the exact text shown in phase 8. Re-run the redaction scan on that file; if it finds a hit, do not create the issue and report why.
2. Show the exact command, then run it:
   `gh issue create --repo gregordadera/aicb-roslyn-mcp --title "<title>" --body-file <file> --label smoke [--label <category>]` (add the category label only where phase 8, step 1 assigned one; repeat `--label` for each label)
   Report each returned URL as a link.
3. On a gh error, stop that issue, keep the others, and report the error text. Do not retry blindly.
4. The body files may be deleted after gh has finished, if the user does not want to keep them.
5. **Report file** (gh missing, not authenticated, or the user chose `report file`): write ONE markdown file with all confirmed drafts, named `aicb-smoke-report-<YYYY-MM-DD>.md`, into the same home folder. Then offer to draft a cover e-mail in the chat: subject, body, attachment name. The skill never sends it; the user does. Ask the user for the recipient. Do not guess an address.

## Phase 10 - Report

Say: the solution and its kind, whether the configuration was set up or the user tested without it, the tests run (IDs), the counts per level, the drafts shown, the issues created (links) or the file written, the mapping file's location, and what was not verified. Keep it short. Never report a result that no tool produced in this run.

## Glossary (for the user)

- **MCP server:** the program that Claude talks to; here it is AICB, which answers questions about the code.
- **Solution:** the `.sln` file and the projects it groups.
- **Restore and build:** `dotnet restore` fetches packages; `dotnet build` compiles and writes `bin/` and `obj/`. Some answers need both.
- **Configuration axis:** one of three settings (layer rules, excluded namespaces, test detection). The sidecar is a committed `.aicb.json` file that can hold them.
- **Insight:** a design finding of the tool, for example a long method.
- **Markup:** XAML files of a WPF or WinForms-style UI.
- **TFM:** target framework moniker, for example `net8.0`.
- **Drift line:** a message in `server_info` when the server does not match the code it analyses.

## Tool reference

Every tool and parameter this skill uses, as the server lists them (checked against the tool schemas of aicb 0.5.515.1). All of them sit in the server's default pool; if one is missing from a user's profile, skip that test and say so.

| Tool | Parameters used |
|---|---|
| `server_info` | none |
| `analyze_solution` | `solutionPath` |
| `solution_config_status` | `sessionId` |
| `get_diagnostics` | `sessionId`, `scope`, `severityFloor` |
| `list_insights` | `sessionId` |
| `get_insight` | `sessionId`, `insightId`, `maxDetails` |
| `solution_metrics` | `sessionId` |
| `detect_circular_dependencies` | `sessionId`, `scope` |
| `find_usages` | `sessionId`, `symbol` |
| `find_dead_code` | `sessionId`, `kinds`, `scope` |
| `architecture_overview` | `sessionId`, `lean` |
| `find_by_attribute` | `sessionId`, `attribute`, `kinds`, `scope` |
| `calls_external` | `sessionId`, `pattern`, `scope` |
| `resolve_injection` | `sessionId`, `interface` |
| `find_by_side_effects` | `sessionId`, `effect` |
| `find_unresolved_bindings` | `sessionId` |
| `find_binding_usages` | `sessionId`, `path` (omit for the inventory view) |
| `find_resource_usages` | `sessionId`, `key` (omit for the audit view) |
| `describe_api_surface` | `sessionId`, `scope`, `includeInternal` |
| `coverage_gaps` | `sessionId`, `scope` |

Note: `find_usages` takes `symbol` as the exact name, copied from an earlier tool answer (S6, S7). Those names stay in the chat and never go into a draft unredacted.
