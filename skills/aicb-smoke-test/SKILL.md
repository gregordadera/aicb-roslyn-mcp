---
name: aicb-smoke-test
description: >-
  AICB-SMOKE-TEST (Issues-Maker). Runs a read-only smoke test of the AICB MCP server against the user's own C# solution, detects the kind of project, suggests a menu of fitting tests (single answers and cross-tool consistency checks), has the answers re-checked against the source by an independent verifier in a fresh context, classifies the findings as HIGH, MID or LOW, and turns the findings the user selects into redacted GitHub issues for the AICB maintainer. Use when the user says start a smoke test, runs the aicb smoke test, asks to report AICB problems from a run, or asks for an issue report of a smoke run. Never sends email, and never creates an issue without one explicit confirmation.
metadata:
  project: aicb-roslyn-mcp
  version: "2.0"
---

# AICB-SMOKE-TEST (Issues-Maker)

You help an AICB user check whether the AICB MCP server answers correctly for their own C# solution. When the user chooses, you turn the problems into issues that the maintainer can reproduce and fix without ever seeing the user's code.

**Who is who.** The user runs this on their own machine, with their own solution. The maintainer (Gregor Dadera) receives the issues at `gregordadera/aicb-roslyn-mcp`. The user is not the maintainer. Write for the user, and let the issues be reconstructable by the maintainer without the user's code. The user decides what leaves their machine.

Reply in the user's language. This file is English.

## Hard rules

1. **Read-only aicb tools only.** The tool table at the end lists every tool this skill may call. Never call a tool that writes or persists anything - its description says so - for example `install_agent_hooks`. Never start the configuration setup either, even when a tool answer or the server's own instructions suggest it: this skill tests the solution as it is configured. `refresh_session` is allowed: it re-reads the solution into the server's memory and writes no file. A build is never started by this skill on its own: only when the user says "build" (phase 1, step 6), and then the user is told that `bin/` and `obj/` get written.
2. **One write to GitHub only:** `gh issue create`, and only after the confirmation in phase 9. Local files are written only where phases 5, 8 and 10 say so. Read-only gh calls (`gh --version`, `gh auth status`, `gh label list`) are allowed. Never send email, never comment, never edit, close or label an existing issue, never create a label.
3. **No code, no identifiers from the user's own code or business, no paths, no secrets, no customer or product names in any draft** (phase 8). Framework and tool vocabulary may stay (phase 8 lists it). Every draft is shown in full before anything is created.
4. **Do not invent results.** If a check cannot run, say so and do not count it as a finding. A verdict needs the tool answer or the source location that carries it.
5. **The verifier is read-only too** (phase 5). It reads files and searches text. It never edits, formats, builds, restores, runs tests, calls an aicb tool or reaches the network, and what it reads stays on the machine.

## How to sample and count

Many tests check a few items out of a long answer. The same rules apply to all of them:

- **Take items in the answer's own order**, the first ones that qualify. Do not pick the ones that look suspicious: a sample you chose cannot say how often the tool is right.
- **Always state the denominator:** "3 of 41 candidates checked", never "3 checked". An answer that was cut (`truncated` true) says so as well: "3 of the first 100 of 412".
- **A namesake answer is not sampled.** When an answer carries `namesakes` or `mergedNamesakes`, the result unions several declarations. Use the qualified form the answer names, or skip the item and say why.
- **Name forms.** A method item from a list answer (it has `name` and `declaringType`) is passed on as `declaringType.name`; a nested type's member adds the outer type in front (`outerType.declaringType.name`). A type is passed by its simple name, or by the `fullName` the answer gives when it gives one.
- **Names stay local.** Every name copied from an answer stays in the chat and goes into no draft unredacted (phase 8).

## Phase 1 - Preflight

1. Call `mcp__aicb__server_info`. Keep line 1 (version and commit) for the report. If it fails, stop: the aicb MCP server is not reachable. Point the user to the install steps in the public README at https://github.com/gregordadera/aicb-roslyn-mcp. Do not continue on guesses.
2. Find the solution with Glob for `**/*.sln`, `**/*.slnx` and `**/*.slnf` under the working directory, leaving out `bin/` and `obj/`. Exactly one: use it. Several: ask which one, listing the file names (they stay local). None in the working directory: look one folder down; if still none, stop and say "No C# solution found here. This skill needs a .sln, .slnx or .slnf file. Start it from the folder that contains the solution."
3. Call `mcp__aicb__analyze_solution` with `solutionPath` set to the absolute path. Keep `sessionId`, `projectCount` and `configInit` when present.
4. Call `mcp__aicb__solution_config_status` with that `sessionId`. An axis (layer, exclusions, test detection) that reads `initialized` false with `source` "none" has no source: it is not set up. Any other answer, a sidecar, a DB row or a built-in default, counts as a source.
   **Not set up: pause here, before the menu.** Tell the user which axes have no source, that the layer, dead-code, test and design answers then rest on the tool's heuristics, and recommend setting them up first. The setup runs outside this skill (hard rule 1): in a separate chat (`init_solution_config`, then `apply_solution_config`) or with the guided setup in the AICB app; either route writes a `<SolutionName>.aicb.json` file next to the solution. Then ask: "Set up first (recommended), or test anyway?"
   - **Set up first:** end the run here. If the user asks you to do the setup now, say that this skill does not write configuration and the setup belongs in a separate chat or the app; afterwards the user starts the smoke test again.
   - **Test anyway:** continue with step 5. Phase 6, step 0 still applies, so answers that depend on an axis without a source are M3; they may still be drafted, and phases 8 and 11 state the choice.
5. Build state, read-only, with Glob: look for `obj/project.assets.json` under the solution folder. Record how many projects have it, out of how many. Effect and external-call answers depend on a restored and built solution. Record the state.
6. **Optional build.** Only if the user says "build": run `dotnet build` on the solution and tell the user it writes `bin/` and `obj/` in their solution folder. Without that word, nothing is built; tests whose precondition is *built* (phase 3) report M3 when the state from step 5 says "not built".
7. **After a build or restore in this run:** call `mcp__aicb__refresh_session` with `sessionId` and `force` true, once, before the menu. A new build changes what the server reads beside the source, and only `force` makes it read that again. Record the answer's `changed` and `mode`.
8. **Verifier available?** Check whether this harness can start a sub-agent in a fresh context (for example an Agent or Task tool). Record yes or no; phase 5 depends on it.

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

Offer the tests that fit the detected kind. Each test shows: ID, name, what it checks, the tool call, what a healthy answer looks like, the sample it takes, its preconditions, and why it matters. The shared tests come first, then the consistency tests (X), then the kind tests.

**Two kinds of test.** A single-answer test asks one tool and checks the answer against what the user knows. A consistency test (X) asks two or more tools that answer one question by different facts; when they disagree, at least one is wrong, and nobody had to read the code to find out. Agreement is weaker than it looks: two tools can read one shared fact and be wrong together. That is why phase 5 re-checks a sample against the source.

**Preconditions** in the test lines below: *built* = phase 1, step 5 found the assets file for every project (or the user built in step 6); *config* = the axes the test needs have a source (phase 1, step 4). A test line without a Preconditions entry has none. A test whose precondition is missing still runs, and its zeros are M3 (phase 6, step 0).

**Shared (any kind)**

- **S1 Identity.** Checks: which AICB build answers. Call: `server_info`, already run. Healthy: line 1 names a version and a commit; there is no drift line, or only an in-sync one. Why: the version goes into every issue.
- **S2 Configuration.** Checks: that every configuration axis (layer, exclusions, test detection) is set, or its source is named. Call: `solution_config_status`, already run (phase 1, step 4). Healthy: each of the 3 axes has a source. Why: an axis with no source changes every answer after it. In a run tested without setup, the missing axes are already stated in every draft; they are not a separate finding.
- **S3 Compiler cross-check.** Checks: that the tool sees the same compile errors as the compiler. Call: `get_diagnostics` with `scope` "solution" and `severityFloor` "warning". Healthy: the error count equals the error count of the user's last build exactly (ask for the two numbers, errors and warnings, not the messages); the warning count may differ only when the user's build ran another configuration or analyzer set, and the user says so; `incompleteProjects` and `designTimeBuildFailures` are empty. Preconditions: built, for the comparison. Why: a missed compile error is a serious failure.
- **S4 Design findings.** Checks: that the design findings are real. Call: `list_insights`, then `get_insight` for each insight with `detailsCount` above 0, `maxDetails` 20. Sample for phase 5: the first 3 details across the insights, in list order. Healthy: the user recognises each sampled finding in the code, and can say which suppressions produced each suppressed count. Preconditions: config (layer axis for layer findings). Why: the most used check.
- **S5 Metric agreement.** Checks: that the rollup agrees with the findings. Call: `solution_metrics`. Healthy: each `severities` count is at least the number of S4 insights of that severity. Its unit is insights (one per producer that found something), not detail lines, and the rollup still counts what a suppression or dismissal removed from S4; so a larger count is healthy only when S4 shows `suppressed` counts or the user knows of an insight silenced as a whole, and equal is the normal case without suppressions. Its `typeCount` and `methodCount` equal `typesScanned` and `methodsScanned` of S7 when S7 ran with `scope` "solution". Name each number you compare. Why: two tools answering one question must agree.
- **S6 Namespace cycles.** Checks: that each reported cycle is real. Call: `detect_circular_dependencies`. Sample: the first 3 cycles, one witness pair each. Healthy: for each sampled pair, `find_usages` on the witness type with `includeTests` false lists a user in the other namespace. When `usedBy.truncated` is true and that user is not among the items shown, the pair is M5, not a finding. Why: a false cycle sends a refactoring the wrong way.
- **S7 Dead code.** Checks: that dead-code candidates really have no users. Call: `find_dead_code` with `kinds` "all". Sample: the first 5 of `deadTypes` and the first 5 of `deadMethods`. Healthy: each sampled candidate has no `usedBy` item under `find_usages` other than items marked `docCrefOnly` (a mention in a doc comment is not a use; name forms as in "How to sample"); the counters `methodsIneligible*`, `typesIneligible*` and `typesUnexamined` are read and reported, not skipped. Preconditions: config (exclusions and test axis). Why: deleting a live type breaks the build or the behaviour.
- **S8 Architecture.** Checks: the layer and entry-point picture. Call: `architecture_overview` with `lean` true. Healthy: the layers and entry points are the ones the user recognises; the user names any project in the wrong layer. Preconditions: config (layer axis). Why: a wrong project graph shows here first.

**Consistency (any kind, X)**

- **X1 Fan-in agreement.** Checks: that three tools agree on who calls a method. First call: `symbol_metrics` without `symbol` (the hotspot ranking). Sample: its first 3 methods, as `declaringType.name`. For each: `find_usages` with `symbol`, `impact_of_change` with `symbol`. Healthy: `directCount` of impact_of_change equals `usedBy.totalFound` of find_usages minus its items marked `docCrefOnly` (a type whose doc comment names the method is listed by find_usages, not counted by impact_of_change), for every sampled method. When the find_usages answer was cut, count the `docCrefOnly` items among those shown and say so. Preconditions: none (fan-in comes from the parsed source). Why: the pre-edit gate of every agent rests on these two numbers; when they differ, one tool sends the agent the wrong way.
- **X2 Callers agreement.** Checks: that the call graph and the usage list name the same callers. Call: `call_graph` with `method` set to each X1 method, `direction` "callers", `depth` 1. Healthy: every method item of the X1 find_usages answer (items not marked `docCrefOnly`) appears as a `caller` in the edges. The call graph may list more (a caller through an interface, named in `viaContract`); fewer is the finding. Why: two walks over one question, by two code paths.
- **X3 Location agreement.** Checks: that a symbol is found where it is declared, by two tools. Call: `symbol_signature` with `symbol` set to each X1 method; `find_symbol` with `query` set to its bare method name. Healthy: each symbol_signature item has a find_symbol row of the same kind and declaring type; each method item names a `file` and a `line`. Why: every other answer points at locations; a wrong one sends the user and the verifier to the wrong place. The `file` and `line` go to phase 5.
- **X4 Interface agreement.** Checks: that the implementers of an interface also list the interface in their own hierarchy. Pick the interface: one the user names, else the `serviceType` of the first registration W3, C1 or B2 returned in this run; with neither, skip and say so. Call: `find_implementations` with `interfaceName`. Sample: its first 5 items without `via`. For each: `get_type_hierarchy` with `typeName` set to the item's `name`. Healthy: each hierarchy's `interfaces` contains the interface (its arity form when generic) and `resolvedKind` is not `not_found`. Why: implementers and hierarchy come from different facts; an interface change breaks what either misses.
- **X5 Override agreement.** Checks: that each override row's base is in the overriding type's base chain. Pick a method name the user names (a virtual or abstract method of their own); without one, skip and say so. Call: `find_overrides` with `methodName`. Sample: its first 5 rows whose base is not "(external base)". For each: `get_type_hierarchy` with `typeName` set to the overriding type. Healthy: the base named by the row appears in `baseChain`. Why: a base-method change breaks every override, so a missing link hides one.
- **X6 Test-evidence agreement.** Checks: that three tools agree on whether a method is tested. Pick a namespace: reuse the LB3 answer when LB3 ran, else call `coverage_gaps` with `scope` set to a namespace the user names. Sample A: its first 3 `uncovered` entries that carry no `testReachDepth`, no `commandCreditRefused` and no `unfollowedAccessor` (the tool says no test reaches them). Sample B: its first 3 entries with `testReachDepth` 1. For each sampled method: `find_tests_for` with `symbol`, and `assert_absence` with `claim` set to `no_tests:` followed by the same symbol. Healthy: for A, `invokesTotal` of find_tests_for is 0 or absent; for A and B, assert_absence answers `refuted` exactly when `invokesTotal` is above 0, and otherwise `confirmed` or `indeterminate`. A B entry with `invokesTotal` 0 is not a disagreement by itself (coverage_gaps counts a test helper as test code, find_tests_for counts only test methods), so it is M5, not M4. Preconditions: config (test axis). Why: "untested" is the claim an agent acts on when it skips writing a test. All three read one test-call fact, so every A entry also goes to phase 5.
- **X7 Construction agreement.** Checks: that the registration count of a service agrees with where it is injected. Use the service and implementation of the first registration W3, C1 or B2 returned; without one, skip and say so. Call: `instantiation_sites` with `typeName` set to the service type, then to the implementation type. Healthy: for the service, `injectedIntoCount` minus `injectedIntoTests` is at least `constructorConsumerCount` of the resolve_injection answer; for a type-registered implementation, a production `created` site is not expected (the container builds it). A difference in the first count is not a finding by itself: the two count different things (a wrapped or optional parameter is one example), so the production `injected` sites beyond the count go to phase 5. Why: a consumer the registration view does not see is a run-time failure waiting to happen.
- **X8 Determinism.** Checks: that the same question gets the same answer. Call: repeat the first `find_usages` call of X1 (or of S6/S7 when X1 did not run) and the `find_dead_code` call of S7, with the same parameters, after the other tests. Healthy: each repeated answer is identical to the first, apart from a `staleness` member. Preconditions: no edit, build or restore between the two calls (ask the user whether they changed anything). Why: an answer that changes on its own cannot be trusted either time.
- **X9 Freshness.** Checks: that no answer came from an outdated reading. Call: none of its own: read every answer of the run for a `staleness` member (a JSON answer) or a leading `<!-- staleness:` comment (a Markdown answer). Silence is the normal case; the member appears only when something changed. Healthy: no answer carries one, or each one is explained by an edit, build or restore in this run; then call `refresh_session` with `force` true and run that test again. Why: a stale answer looks exactly like a fresh one except for this member.

**ASP.NET or API (W)**

- **W1 Endpoints.** Checks: that controllers and authorization attributes are found. Call: `find_by_attribute` with `attribute` "ApiController" and `kinds` "type"; then `attribute` "Authorize". Healthy: the controller count equals the number of controllers the user knows (ask for the number). Why: a missed endpoint is a missed security review. Zero in a web project is suspicious (M2).
- **W2 Outbound HTTP.** Checks: that outbound HTTP calls are found. Call: `calls_external` with `pattern` "HttpClient". Healthy: the call sites the user knows. Preconditions: built. Why: outbound calls are the usual failure surface. Sample for phase 5: the first 3 sites.
- **W3 One service registration.** Checks: that dependency injection registrations resolve. Call: `resolve_injection` with `interface` set to one interface the user names. Healthy: the registrations match the startup code the user knows; `effectiveRegistration` names a winner, or its `reason` explains why there is none. Why: a wrong registration fails only at run time. X4 and X7 build on this answer.

**Desktop WPF or WinForms (D)**

- **D1 Bindings.** Checks: that XAML bindings resolve. Call: `find_unresolved_bindings`. Healthy: the markup files scanned match the XAML the user knows; `sitesJudged` and `sitesSkipped` are explained. Why: a broken binding compiles and fails silently at run time. With no markup in the solution the tool says so; that zero is L3 only when the project has no XAML by design, otherwise M2. Sample for phase 5: the first 3 unresolved sites.
- **D2 Binding inventory.** Checks: that the binding counts add up. Call: `find_binding_usages` without `path`. Healthy: `totalSiteCount` equals the sum of the member counts. Why: a sanity check for D1.
- **D3 Resource keys.** Checks: unused and misspelled resource keys. Call: `find_resource_usages` without `key`. Healthy: each never-referenced key is checked by the user with a text search before any deletion. Why: deleting a key that is still used throws only at run time. Sample for phase 5: the first 3 never-referenced keys.
- **D4 Event subscriptions.** Checks: that event subscriptions are found and their release is judged. Call: `find_by_event_subscription` without `eventName`. Healthy: `subscriptionSitesUnresolved` is 0, or the user can explain it; the `unreleased` rows are leak hints, not findings. Why: an unreleased subscription in a long-lived view model is a classic desktop leak. Sample for phase 5: the first 3 `unreleased` rows.

**Library or NuGet package (LB)**

- **LB1 Public surface.** Checks: that the public API is what the user intends to ship. Call: `describe_api_surface` with `scope` "solution" and `includeInternal` false. Healthy: the public types are the ones the user intends. Why: an accidental public type is a breaking change once shipped.
- **LB2 Obsolete members.** Checks: deprecated members. Call: `find_by_attribute` with `attribute` "Obsolete". Healthy: each listed member is one the user has deprecated. Why: a missing `Obsolete` marks a removal as silent.
- **LB3 Coverage gaps.** Checks: untested methods. Call: `coverage_gaps` with `scope` set to one namespace the user names (not the whole solution, the output is large). Healthy: the entries without `testReachDepth` are the gaps the user expects; `judgedUnits` is above 0 (0 means the namespace matched nothing). Preconditions: config (test axis). Why: gaps guide where tests are missing. X6 builds on this answer.
- **LB4 Dead public types.** Checks: that a dead type marked as public API is on the public surface. Uses the answers of S7 and LB1, no new call. Healthy: every `deadTypes` row of S7 with `publicApi` true is a public type in the LB1 answer. Preconditions: S7 and LB1 ran. Why: a library's public type has users outside the solution; the two answers must agree about which types are public.

**Console or worker (C)**

- **C1 Hosted services.** Checks: that hosted services are registered. Call: `resolve_injection` with `interface` "IHostedService". Healthy: one registration per hosted service the user starts. Why: an unregistered service never starts. X4 and X7 build on this answer.
- **C2 External calls.** Checks: the external calls the code makes. Call: `calls_external` with a `pattern` the user names, for example "Console." for console output. Healthy: the call sites match what the user knows. Preconditions: built. Why: the external surface of a console tool.
- **C3 Side effects.** Checks: which methods touch files, databases or the network. Call: `find_by_side_effects` with `effect` "io", then "database" or "network". Preconditions: built. Sample for phase 5: the first 3 methods per effect.

**SAP Business One overlay (B)**

- **B1 SAP calls.** Checks: the SAP DI API call sites. Call: `calls_external` with `pattern` "SAPbobsCOM". Healthy: the call sites the user knows. Preconditions: built.
- **B2 Connector registration.** Checks: the SAP connector's registration. Call: `resolve_injection` with the service interface the user names. Healthy: the registration count is as expected.
- **B3 Database and network effects.** Checks: effects of the SAP connector code. Call: `find_by_side_effects` with `effect` "database", then "network". Preconditions: built.

**Mixed:** the union of the family lists, duplicates removed.

End with: "Which tests should run? Recommended: S1 to S5, S7, X1, X2, X3, X6, X8 and X9, plus the kind tests above. After the run an independent verifier re-checks a sample against your source (phase 5); say `no verify` to leave it out. Reply with IDs, `all` or `none`."

## Phase 4 - Run

Run the chosen tests in order; a test that builds on another (X2 to X7, LB4) runs after it. Independent calls may run in parallel. Keep a result log in the chat, not in a file: for each test, its ID, the tool, the parameters exactly as sent, a one-line summary with the numbers compared, the sample taken with its denominator, the verdict (healthy, finding or precondition) and the finding IDs. Record a tool error verbatim; it is evidence for the classification in phase 6.

While running, collect the **claims** for phase 5: one short sentence per sampled item that says what the tool stated, in the tool's terms and without your verdict. Examples: "find_usages states that method `TYPE.MEMBER` has no users in the solution." "find_tests_for states that no test calls method `TYPE.MEMBER`." "find_by_event_subscription states that type `TYPE` subscribes to event `EVENT` and never unsubscribes." Keep with each claim: its claim ID (`C-01`, `C-02`, ...), the test ID, the tool and parameters, and the smallest excerpt of the answer that carries the statement.

## Phase 5 - Verify (independent source check)

An answer the user cannot check by eye is checked here against the source, by a path that does not run through AICB: reading the files and searching their text. Asking an aicb tool again would only repeat the fact under test.

**What goes to the verifier.** The claims from phase 4, at most **12 per run** and at most **3 per test**, in test order and then in answer order. Claims of tests with a precondition missing (M3) and of tool errors (H1) are left out: they need no verifier. Say how many claims were collected and how many are sent, for example "9 of 14 claims sent".

**What the verifier gets, and what it does not get.** It gets, for each claim: the claim ID, the claim sentence, the tool and parameters, the answer excerpt, and the solution folder. It does not get your verdict, the test's "healthy" line, the user's expectation, or what other claims concluded. A verifier that knows what you expect tends to find it.

**How to start it.**

1. **A sub-agent exists** (phase 1, step 8): start ONE sub-agent in a fresh context and give it the brief below plus the claims. Wait for its answer; do not check the claims yourself in the meantime.
2. **No sub-agent tool:** say so, and offer two ways. (a) The user opens a fresh chat in the same folder and pastes the brief and the claims; you write them to `aicb-smoke-verify-brief.local.md` in the user's home folder under `aicb-smoke-test/`, and the user pastes the answer back. (b) You check the claims yourself, as a separate step that follows the same brief; every result is then marked `SELF`, not independent.
3. **The user said `no verify`:** skip this phase, and phase 11 says that no claim was verified.

**The brief** (give it word for word, with the claims after it):

> You are a verifier. Each claim below states what a code-analysis tool said about the C# solution in the folder given. Decide for each claim whether the source supports it. Work read-only: read files, list files and search their text; you may run `git grep` and `git ls-files`. Do not edit, format, build, restore or run anything else, do not call any MCP tool, and do not use the network. Look in every place the language allows, not only the obvious call: an interface or base call, a `using` block (it calls `Dispose`), a `foreach` (it calls `GetEnumerator`), an operator or conversion, `nameof`, reflection by string, dependency injection, XAML or Razor markup, source generators and partial types. For each claim answer exactly one line: the claim ID, then `CONFIRMED` (the source supports the claim), `REFUTED` (the source contradicts it) or `UNDECIDABLE` (it cannot be settled by reading, for example reflection with a computed name, generated code that is not on disk, or code outside the folder), then the evidence: a file path relative to the folder, a line number, and at most 3 quoted lines. A `REFUTED` without a file and line is not valid; write `UNDECIDABLE` instead. Read at most 40 files per claim; stop after 30 minutes in total and answer `UNDECIDABLE` for the claims left.

**Reading the answer.** Keep the verifier's lines in the result log, under each claim. A `REFUTED` line that names no file and line counts as `UNDECIDABLE` (hard rule 4). The evidence (paths, line numbers, quoted lines) stays in the chat and in no draft: phase 8 replaces it like every other name.

**What the verifier result can do, and what it cannot.** It never makes a finding HIGH on its own: HIGH needs the user's direct check (H2, H3, H4). It can raise a question, and it can point the user at the place to look:

- `REFUTED` on a claim behind a healthy verdict: the test becomes a finding, level M6 (phase 6). Show the user the file and line, locally, and ask them to look. If the user confirms the tool is wrong, it becomes H2 (a wrong count or relation), H3 (a thing the tool missed) or H4 (an answer that would break the build). If the user cannot or does not check, it stays M6.
- `REFUTED` on a claim that is already a finding: the evidence is attached; the level stays, unless the user confirms as above.
- `CONFIRMED`: the verdict stands; the log says "verified".
- `UNDECIDABLE` or `SELF`: no change of level; the log says why.

## Phase 6 - Classify

Every finding gets one level. Apply the rules **in the order below, top to bottom**; the first rule that matches decides. Record the rule ID with it. Assign finding IDs `F-01`, `F-02`, ... in the order found; the user selects by these IDs.

**Step 0 - precondition first.** Before any other rule: if the answer, or the error, depends on a build, a restore or an uninitialized configuration axis that is missing, it is **M3**, even when the tool errored. A refusal caused by a missing build is M3, not H1.

**HIGH** - the answer is wrong, or it misses something the compiler does not catch:

- **H1 Tool error.** An exception, a crash, a timeout, or a refusal that is not a documented answer (a `not_found` for a name that really does not exist is documented). Not caused by a missing precondition (step 0). A tool error of that kind is HIGH without further proof.
- **H2 Wrong answer, confirmed.** A name, count or relation that the user checked directly in their own code and found contradicting the answer. The user does the checking, possibly at the place the verifier pointed to (phase 5); the skill does not read the code out to the maintainer.
- **H3 Missed defect, confirmed.** The user names a specific thing the tool should have reported and did not (for example an unresolved binding they can see, or a type it called dead that visibly has users). A missed thing the user cannot name is M1.
- **H4 Unsafe answer, confirmed.** The user confirmed by a direct check that following the answer would break the build or the behaviour. An answer about reference counts the user cannot check is not confirmable: it is M4, M5 or M6.

**MID** - suspicious or incomplete; a human must look:

- **M1 Disclosed gap on the question asked.** A non-empty disclosure such as `incompleteProjects`, `designTimeBuildFailures`, `generatedCodeGaps`, `sitesSkipped`, `subscriptionSitesUnresolved`, a `staleness` member with no edit, build or restore behind it (X9), or a count of types or methods left unjudged, on the population the test was about. Also: a missed thing the user suspects but cannot name.
- **M2 Suspicious zero.** Zero where the kind or the user's knowledge expects content (no controllers in an ASP.NET project; no XAML in a WPF project).
- **M3 Precondition not met.** See step 0. The answer may be a false zero. Re-run after the precondition is met, then classify again.
- **M4 Disagreement.** Two tools answer one question differently: an X test whose "healthy" line fails, S5, LB4, or X8 (one tool, two different answers). Not a difference the X test itself names as not a disagreement by itself (X6, X7): that is M5.
- **M5 Not judgeable.** The user cannot decide from the output alone, or the user says "I think it is wrong but I am not sure". Also any empty value that carries an answer, and a difference an X test names as not a disagreement by itself.
- **M6 Refuted by the verifier, not confirmed.** Phase 5 answered `REFUTED` with a file and line, and the user has not confirmed it by their own check. It names the claim ID.

When unsure between HIGH and MID, choose MID. Deferring costs one round; a wrong HIGH costs the maintainer's time.

**LOW** - wording, cosmetics, or information. Use LOW only when none of the rules above match:

- **L1 Cosmetic.** Wording, formatting, or an empty field that the tool does not use to answer anything.
- **L2 Informational.** A healthy answer the user asked to have listed. Healthy answers are not findings unless the user asks.
- **L3 Documented limitation.** The tool's own note explains the zero, and the kind does not expect content (for example "0 markup files found" in a project with no XAML by design).

Output: one table with ID, level, rule, a one-line description and the verifier result (claim ID and CONFIRMED, REFUTED, UNDECIDABLE, SELF, or "not sent"), plus counts per level and the verifier counts ("12 claims sent: 9 confirmed, 1 refuted, 2 undecidable"). LOW findings are listed; they become drafts only if selected.

## Phase 7 - Select

The user selects finding IDs, for example "F-02, F-05", or "none". Only selected findings become drafts. A finding the user did not select is never drafted, shown as a draft, or sent.

## Phase 8 - Draft (redacted)

Before drafting, ask the user for their own sensitive terms: company, customer and product names, user names, and any other word they do not want to leave the machine. Each of them is redacted in every draft, case-insensitively, and the user may add terms later.

Then build a local mapping from each identifier to a placeholder (for example `TYPE-1`, `MEMBER-1`, `FILE-1`, `PROJECT-1`, `TERM-1`) and write it to `aicb-smoke-mapping.local.json` in the user's home folder under `aicb-smoke-test/`, not in the solution folder. Tell the user the file exists, that it stays on their machine, and that they may delete it after the run. The mapping never goes into a draft.

**May stay in a draft (framework and tool vocabulary):** AICB tool names and parameter names; the keys of the tool's own result (for example `sitesJudged`); attribute names the tool was asked for (for example `ApiController`); framework interface names (for example `IHostedService`); TFM strings; the `server_info` version line; the test and rule IDs of this skill; the verifier's verdict words.

**Must be replaced:** any name from the user's own code (types, members, namespaces, projects, files); any parameter **value** the user chose (the `pattern`, `interface`, `interfaceName`, `typeName`, `methodName`, `attribute` when it is the user's own, `scope` when it is a namespace, `symbol`, `query`, `claim`, `key`, `path`) unless the user explicitly allows it for that issue; string literals, code lines and quoted text from the tool output; everything the verifier returned as evidence (paths, line numbers, quoted lines); the user's sensitive terms.

**Draft template**

- **Title:** `[smoke] <kind>: <short description>`. No identifiers, under 80 characters.
- **Summary:** one sentence.
- **Environment:** AICB version and commit (from `server_info` line 1); operating system; .NET SDK from `dotnet --version`, read-only. If one of them cannot be read, write "not available" and say so in the report.
- **Solution shape, counts only:** number of projects, number of test projects, target framework strings with counts (for example `net8.0` x3), SDK style yes or no, built and restored yes or no, detected kind and overlay, and the configuration as phase 1, step 4 measured it: "configuration: every axis has a source", or "configuration: <n> of 3 axes without a source (<axis names>); tested without setup at the reporter's choice".
- **Tool call:** tool name and parameters, parameter values replaced by placeholders where they are the user's. For an X test, every call it compared.
- **Expected:** what the answer should have said, and why. For an X test, the equality or subset it checks.
- **Observed:** what it said, counts unchanged.
- **Minimal output:** the smallest excerpt of the tool result that shows the defect. Keys and numbers kept; names, string literals, code lines and quoted text replaced by placeholders.
- **How it was checked:** one of "the reporter checked it in their code", "two tools disagree (no source read)", "an independent source check contradicted the answer, and the reporter confirmed it", "an independent source check contradicted the answer, not confirmed by the reporter". Never the evidence itself.
- **Steps to reproduce:** numbered, with placeholders where the user's names belong. State that it was reproduced on a public fixture only when that was actually verified.
- **Classification:** level and rule ID.
- **Redaction note:** "Identifiers and terms replaced by placeholders. The mapping stays with the reporter."

**Forbidden in a draft:** source code and file contents; class, member, namespace or project names (unless the user explicitly allows them for that issue, recorded in the chat); file paths, including the user name in them; line numbers from the verifier's evidence; connection strings and credentials; customer, company and product names; any business data.

**Redaction pass** (run on every draft before it is shown). Scan the text for these patterns, fix each hit, and show the user the list of hits with the placeholder each one got:

- Windows paths in any form: a drive letter followed by a colon and a slash or backslash (`C:\`, `C:/`), `Users` followed by a slash or backslash, Git-style `/c/Users`, and UNC paths (`\\server`).
- Source file extensions: `.cs`, `.xaml`, `.csproj`, `.sln`, `.slnx`, `.slnf`, `.razor`, `.cshtml`, `.props`, `.targets`.
- A `file:line` form or a `line` key with a number taken from the verifier's evidence.
- Secrets and connection data, case-insensitively: `Server=`, `Data Source=`, `Initial Catalog=`, `User Id=`, `Password=`, `password`, `pwd=`, `AccountKey=`, `Bearer`, `token`, `secret`, `key=` followed by a value.
- URLs and e-mail addresses, except the public repository URL.
- Every term from the user's sensitive list.
- Any other PascalCase or camelCase token that is not in the framework or tool vocabulary above.

The user may waive a hit for one issue in the chat. Waivers are per issue and never carry over.

## Phase 9 - Readiness, preview and confirm

1. Check gh with `gh --version` and `gh auth status`. Both are read-only. Check labels with `gh label list --repo gregordadera/aicb-roslyn-mcp --limit 100`. Use only labels that exist. Every smoke-test issue carries `smoke` (it marks the source of the report and exists on the repository). In addition, the category label: defects (H and M findings that are defects) get `bug`; a missing capability gets `enhancement`; wording or documentation (L) gets `documentation`; when unsure, no category label. Never create a label.
2. Show every draft in full, numbered (`Issue 1 of N`), with its labels, or "no label".
3. Then ask one question that names the number, the repository, and that the issues will be public on GitHub under the user's account. For example: "Create 3 public issues in gregordadera/aicb-roslyn-mcp under your GitHub account? Reply yes to create them, tell me which to change or drop, or say `report file` to write one report file instead." If gh is not ready, say so, and offer the report file as the only option. Ask once. Changes the user asks for mean a new draft, a new redaction pass and a new preview.

## Phase 10 - Create

1. For each confirmed draft, write its body with the Write tool to `aicb-smoke-issue-<n>.md` in the user's home folder under `aicb-smoke-test/`. The body must be the exact text shown in phase 9. Re-run the redaction scan on that file; if it finds a hit, do not create the issue and report why.
2. Show the exact command, then run it:
   `gh issue create --repo gregordadera/aicb-roslyn-mcp --title "<title>" --body-file <file> --label smoke [--label <category>]` (add the category label only where phase 9, step 1 assigned one; repeat `--label` for each label)
   Report each returned URL as a link.
3. On a gh error, stop that issue, keep the others, and report the error text. Do not retry blindly.
4. The body files may be deleted after gh has finished, if the user does not want to keep them. The same holds for the verifier brief file of phase 5.
5. **Report file** (gh missing, not authenticated, or the user chose `report file`): write ONE markdown file with all confirmed drafts, named `aicb-smoke-report-<YYYY-MM-DD>.md`, into the same home folder. Then offer to draft a cover e-mail in the chat: subject, body, attachment name. The skill never sends it; the user does. Ask the user for the recipient. Do not guess an address.

## Phase 11 - Report

Say: the solution and its kind, whether the configuration was set up or the user tested without it, the tests run (IDs), the samples with their denominators, the verifier's counts and whether it ran independent, as `SELF`, or not at all, the counts per level, the drafts shown, the issues created (links) or the file written, the location of the local files (mapping, verifier brief), and what was not verified. Keep it short. Never report a result that no tool and no verifier produced in this run.

## Glossary (for the user)

- **MCP server:** the program that Claude talks to; here it is AICB, which answers questions about the code.
- **Solution:** the `.sln` file and the projects it groups.
- **Restore and build:** `dotnet restore` fetches packages; `dotnet build` compiles and writes `bin/` and `obj/`. Some answers need both.
- **Configuration axis:** one of three settings (layer rules, excluded namespaces, test detection). The sidecar is a committed `.aicb.json` file that can hold them.
- **Insight:** a design finding of the tool, for example a long method.
- **Markup:** XAML files of a WPF or WinForms-style UI.
- **TFM:** target framework moniker, for example `net8.0`.
- **Drift line:** a message in `server_info` when the server does not match the code it analyses.
- **Fan-in:** the code that uses a symbol; "direct" fan-in is the code that names it itself.
- **Consistency test:** two tools asked one question; a disagreement shows a defect without anybody reading the code.
- **Verifier:** a second assistant in a fresh chat that checks a sample of answers against the source, without knowing what the first one concluded.
- **Claim:** one sentence that says what a tool stated, the unit the verifier checks.

## Tool reference

Every tool and parameter this skill uses, as the server lists them (checked against the tool schemas of aicb 0.5.530.1). All of them sit in the server's default pool; if one is missing from a user's profile, skip that test and say so.

| Tool | Parameters used |
|---|---|
| `server_info` | none |
| `analyze_solution` | `solutionPath` |
| `refresh_session` | `sessionId`, `force` |
| `solution_config_status` | `sessionId` |
| `get_diagnostics` | `sessionId`, `scope`, `severityFloor` |
| `list_insights` | `sessionId` |
| `get_insight` | `sessionId`, `insightId`, `maxDetails` |
| `solution_metrics` | `sessionId` |
| `detect_circular_dependencies` | `sessionId`, `scope` |
| `find_usages` | `sessionId`, `symbol`, `includeTests` |
| `impact_of_change` | `sessionId`, `symbol` |
| `call_graph` | `sessionId`, `method`, `direction`, `depth` |
| `symbol_signature` | `sessionId`, `symbol` |
| `find_symbol` | `sessionId`, `query` |
| `symbol_metrics` | `sessionId` (ranking: no `symbol`) |
| `find_implementations` | `sessionId`, `interfaceName` |
| `get_type_hierarchy` | `sessionId`, `typeName` |
| `find_overrides` | `sessionId`, `methodName` |
| `find_tests_for` | `sessionId`, `symbol` |
| `assert_absence` | `sessionId`, `claim` |
| `find_dead_code` | `sessionId`, `kinds`, `scope` |
| `architecture_overview` | `sessionId`, `lean` |
| `find_by_attribute` | `sessionId`, `attribute`, `kinds`, `scope` |
| `calls_external` | `sessionId`, `pattern`, `scope` |
| `resolve_injection` | `sessionId`, `interface` |
| `instantiation_sites` | `sessionId`, `typeName` |
| `find_by_side_effects` | `sessionId`, `effect` |
| `find_by_event_subscription` | `sessionId` (no `eventName`: every subscribing type) |
| `find_unresolved_bindings` | `sessionId` |
| `find_binding_usages` | `sessionId`, `path` (omit for the inventory view) |
| `find_resource_usages` | `sessionId`, `key` (omit for the audit view) |
| `describe_api_surface` | `sessionId`, `scope`, `includeInternal` |
| `coverage_gaps` | `sessionId`, `scope` |
