# Changelog

Versions follow `Major.Minor.Series.Build`. The build number rises by one for every
change that lands, so gaps between published versions are normal - not every build is
released.

## 0.5.511.1 (unreleased) - resolve_injection judges each target framework on its own, impact_of_change finds the markup users of dependency properties, and a token budget shortens methods before it drops them

**Who is affected.** Everyone on the MCP server: reconnect your client once - 6 tools of the
default profile have a new description (`apply_solution_config`, `architecture_overview`,
`find_by_semantics`, `find_implementations`, `find_tests_for`, `impact_of_change`). No tool or
parameter was added, removed or made required, no default changed, and the tools outside the
default profile kept their descriptions. The handshake no longer declares
`resources.listChanged` (see "Loading, `batch` and the server").

**Scripts that read these answers should check the following:**

- `find_implementations`: `isAbstract` is left out on interface rows and on rows whose kind is
  not known (`via: "back-edge"`). Before, every row carried it, and an interface read `true`.
  Treat a missing key as "does not apply".
- `impact_of_change`: the `attachedProperty` block appears for more fields, and its entries can
  carry a new `kind: "wrapper"`.
- `find_by_semantics`: a new list `verifiedAbsentAxes`; an axis that moves into it leaves
  `unclassifiedAxes`.
- `resolve_injection`: in a multi-targeted project, `optionalDependencies` holds one entry per
  parameter under the project's own name with a new `targetFrameworks` list, instead of one entry
  per target framework. Some answers that read `no` now read `unknown`.
- Exported Markdown under a token budget: a new method form `compact="budget"`, and the budget
  header gains `used`, a breakdown of what was trimmed and, for a pipeline profile's budget,
  `scope: methods only` (see "Exported Markdown").
- `aicb analyze`: the wording of the layer-profile and test-profile notes on stderr changed, and
  the test-profile note can be absent.
- Coupling numbers move down where a type uses one generic type with several type arguments: Ce,
  `ceMax` in `solution_metrics`, the max-Ce rule of the quality gate and the namespace lines of
  `QUALITY_HOTSPOTS` (see "Side effects, coupling and code quality").

**After updating:** every snapshot and saved session of an earlier version is analyzed afresh the
first time a session is restored from it, and a codebase remembered with an earlier version is
recalled as `stale` until `refresh_remembered`. In the desktop app, the Insights debt trend reads
"not comparable" until two analyses have been stored by this version, and the Solutions tab marks
the snapshot counts of earlier versions with a `*` (see "Desktop app"). The configuration database
is not changed by this version, so an older desktop app still opens it.

### Who uses this symbol and what a change reaches

- **`impact_of_change` names the markup users of a dependency property.** Markup sets and binds
  a dependency property through its wrapper property and never names the field, so changing the
  field showed no markup user. The `attachedProperty` block now also appears for a plain
  dependency property of WPF or Avalonia and lists its wrapper property with the XAML/AXAML files
  that use it, as an entry with `kind: "wrapper"`. An attached property that also has a wrapper
  property gets both kinds of entry, and the `note` says which applies. As before, the block moves
  no count and not the risk.
- **The serializer note of `impact_of_change`** also recognises `[JsonPropertyName]` written with
  a namespace alias (`[J::JsonPropertyName]`).
- **`find_implementations`** no longer marks an interface that extends the queried one as
  abstract, and no longer claims `isAbstract: false` for a row whose kind it does not know (see
  above).
- **`coverage_gaps` follows two more routes from a test to a method:** through the command the
  MVVM toolkit generates for a `[RelayCommand]` method, and from a test that reads a type's static
  state into the static constructor and the initializers that set it, also across several types.
    Such methods now carry `testReachDepth`, the number of hops from the nearest tested method,
  instead of reading as reached by no test; they stay in the list, since no test calls them
  directly. An initializer of a field nothing reads stays unreached.
- **Fewer false dead-code candidates:** Avalonia code-behind (`*.axaml.cs`) counts as used by its
    markup like WPF code-behind already did, a `Tests`, `Fixtures` or `Probes` folder directly under
  a project counts as test scaffolding like a nested one, and `find_production_dead` (outside the
  default profile) exempts the methods of a code-behind or test-scaffolding class in all of its
  files, not only in the one that shows what the class is.
- **`symbol_signature`** prints a constructor's parameters with their nullable mark and default
  value (`string? name = null`), like a method's.
- **`find_by_semantics` tells "declared none" from "no data".** When nothing matches, an axis on
  which every symbol declares `none` through an `<ai>` annotation is listed in the new
  `verifiedAbsentAxes`; before, it stood in `unclassifiedAxes` like an axis nobody had classified.
  An axis declared `none` on only some symbols stays where it was.

### Side effects, coupling and code quality

- **Multi-targeted projects get their full side effects.** Only one framework's copy of a method
  received the effects it reaches through the methods it calls, so an answer that read another
  copy could show fewer effects than the method has. Every copy now carries the effects of its own
  calls, and a call into another multi-targeted project counts the copy the caller compiles
  against. This shows in `find_by_side_effects`, `explain_symbol`, the `SEMANTICS` of exported
  Markdown and the insights built on side effects.
- **`Trace.Assert`, `Trace.Fail` and Code Contracts are checks.** A method calling them was marked
  `logging` (Trace) or `unknown` (Contracts), and its callers inherited that. They now count as no
  effect at all, like `Debug.Assert`; `Trace.WriteLine` and the other `Trace` output stays
  `logging`, and a call inside the checked expression keeps its own effect.
- **A broad catch with only exclusions is reported.** `catch (Exception ex) when (ex is not
  OperationCanceledException)` swallows everything else, but any `when` filter used to make a
    catch count as selective. A filter that only excludes exception types (`is not`, `!(ex is A)`,
  combined with and, or and not) no longer exempts it; any other filter still does.
- **One generic type is one coupling.** `Box<Order>` and `Box<Invoice>` counted as two efferent
  couplings and now count as one; generic types of different arity stay separate. This moves Ce
  on types and namespaces, `ceMax` in `solution_metrics`, the max-Ce rule of
  `aicb analyze --fail-on`, the `ce` values and namespace ranking of `QUALITY_HOTSPOTS` and the Ce
    row of the desktop app's symbol details. A namespace's use of a generic type it declares itself
  no longer counts as outgoing. Where exported Markdown lists a type's injected and used types, it
  still lists every closing; other dependency lists, such as the one in the desktop app's symbol
  details, now show each generic type once, like the Ce row. A quality gate tuned to the old
  numbers may now pass where it failed.
- **Framework API areas ignore signatures an outside interface dictates.**
  `init_solution_config` (`frameworkApiAreas`) and `check_solution_config_drift`
  (`exclusion.excludedApiAreas`) report excluded namespaces that carry much of a solution's public
    surface. A public method that implicitly implements an interface the solution does not declare,
  such as `Convert` of WPF's `IValueConverter`, counted toward that share, so a UI-heavy solution
  could see an area it never chose. Such methods now count on neither side, like overrides and
  explicit implementations already did.

### Dependency injection (`resolve_injection`)

- **Each target framework is judged on its own.** In a multi-targeted project an optional
  constructor dependency is one entry with a `targetFrameworks` list, and each framework's copy is
  checked against the registrations that framework compiles (a registration under `#if NET8_0`
  no longer counts for `net10.0`). Copies with different verdicts stay separate entries.
  `ambiguous` no longer flags two registrations that sit in mutually exclusive framework
  branches, since no single container holds both. A constructor is counted once per declaration,
  not once per framework, so a by-type `yes` is no longer withheld as `unknown`.
- **`unknown` instead of `no` where a library may register the service.** An optional dependency
  on a service of a referenced library, with no registration the server could read, was answered
  `no`. When the code in view calls a registration helper of that library (for example
  `services.Configure(...)`), the answer is now `unknown`, and the reason names the call and where
  it is. Without such a call, and for a service the solution declares itself, it stays `no`.
- **Registration keys:** a helper whose key parameter defaults to a constant other than a string
  (`int key = 3`, an enum member, `default`) and is called without that argument now reports that
  constant as the key instead of `(dynamic)`.
- **Closed generics:** a type argument nested in a constructed generic (`Outer<int>.Inner`) keeps
  its outer type in the row, so two closings of the outer are two services, and a query that
  differs only there is listed as unresolved rather than matched. A solution's own type named
  `String` or `Nullable` is no longer taken for the BCL type.

### Solution configuration

- **The exclusion example excludes `System` itself.** `init_solution_config` (`proposalFormat`)
  and the description of `apply_solution_config` showed only
  `{"pattern":"System.","matchType":"StartsWith"}`. A proposed list replaces the built-in one, so a
  list copied from that example stopped excluding the types declared directly in `System`
  (`Action`, `Func` and the like). The example now adds `{"pattern":"System","matchType":"Exact"}`.
  If you applied a configuration built from the old example, add that rule.

### Exported Markdown

- **A token budget shortens methods before it drops them.** Before, a budget kept a method whole
  or removed it. Now a method under a tight budget first loses its code (a comment says so where
  the code was), then becomes a one-line signature `<METHOD compact="budget">`, then is listed by
  name in a note per type, and only then disappears. More methods stay visible at the same budget,
   and a budget that fits changes nothing. The compression legend explains the new form
  where it occurs. A parser that knew only `compact="isolated"` should accept `compact="budget"`.
  The heuristic settings of a Compression Rules profile no longer influence what a budget trims;
  they still drive the method tree's automatic compression in the desktop app.
- **The budget header says more.** It adds `used`, the measured size of the delivered document
  (where the export could measure it), and breaks the trimmed methods down into without code,
  signature only, name only and dropped. A pipeline profile's budget counts only the methods, not
    the whole document, and the header now marks that with `| scope: methods only`. Adding `used`
  does not push the delivered document over a size cap.
- **The compression legend** explains the method blocks of a context slice that carry line
    numbers, and in most cases no longer counts a method tag that appears inside printed source
  code.
- **`LAYER_MAP` lists more types:** helper, converter, attribute, exception and middleware types
  get a row, and mapper types where an `<ai>` annotation names the role. Such a row reads
  `Unknown` when no layer profile, annotation or project name gives the type a layer.
  `architecture_overview` keeps the per-type map up to 2,500 types (before: 2,000) before it
  switches to counts per layer.

### Loading, `batch` and the server

- **A clearer load error from the MCP server:** a solution with two projects whose project files
  share a name in the same solution folder used to fail with advice about SDKs, workloads and
  restore. The error now says what it is and that moving one project to another solution folder or
  renaming one project file fixes it.
- **`batch`** names the dropped one of two alternative spellings of the same parameter in its
  ignored-arguments note, as a direct call already did.
- **The handshake no longer declares `resources.listChanged`.** The server never sent that
  notification, and the list of resources does not change while it runs; `tools.listChanged` went
  the same way in 0.5.510.1.
- **`aicb mcp` ends when the client closes stdin**, also while a `subscriptions/listen` request is
  open. Before, such a server stayed until the client killed it.
- A project file or XAML page that declares a DTD is treated as unreadable by test-project
    detection and the binding analysis too, as the other readers of a solution's files already did.

### `aicb analyze`

- **`--emit-session-db` keeps the newest 10 automatic snapshots per solution.** Every fresh run
  used to add one and none was ever removed. Snapshots you saved by hand, and those a saved
  session or a run refers to, are never removed. If the cleanup cannot run, a warning goes to
  stderr and the command still succeeds; a snapshot that cannot be deleted stays until a later run
  removes it.
- **The profile notes name what uses the profile in this run.** The layer-profile note always names
  the rendered Markdown and adds the quality gate or the snapshot debt only when they run; the
  test-profile note names only those two and is left out when neither runs. Both now also appear
  when a stored snapshot is reused.

### Desktop app

- **Deleting an entry other entries use asks first.** On the master-data pages, Delete now names
  how many entries refer to the one you delete and what happens to them, and No leaves everything
  as it was. An entry nothing refers to is deleted without a question.
- **Insight todos can be cancelled.** A Cancel button beside "Mark done" withdraws queued work,
  and the line reads "Cancelled" until you queue it again.
- **The Insights "Max MD size" slider remembers its value.** It starts at 60,000 on a fresh
  install, keeps the last value you set, and travels with a configuration export. Before, it
  started from the pipeline profile's budget every time.
- **Pipeline profiles call their budget a "Method Budget",** with help text saying it counts only
  the methods, so the document can be many times larger. The Settings page is now called
  "MD Profiles", and the run-type tooltip no longer promises Pipeline runs for a future version.
- **Numbers counted under other rules are marked.** The debt trend in the Insights header shows a
  delta only between two analyses counted the same way and otherwise reads "not comparable", with
  the reason in its tooltip. In the Solutions tab, a snapshot count stored under other or unknown
  rules ends in `*` and is shown muted.
- **A failed save no longer leaves unsaved values in effect** on the Storage page and for "Apply as
  Active" on the library pages (a save that reached the database keeps the choice). The automatic
  first run of the Insights page is tried again on the next load if saving that it ran failed, and
  choosing the same layout selection again after a failed save now stores it instead of being
  ignored.

### Licence and README

- The links in `EULA.md` and `LICENSE.txt` name the repository `aicb-roslyn-mcp`. In `EULA.md`
  they now stand on a line of their own, so a site that shows the file as plain text no longer
  glues `).` onto the address. The agreement text and its version (0.6) are unchanged.
- The README shows the MCP client configuration right under "Install" and has a "Tools" section
  with the questions agents ask most.

### Other changes

- The README's GitHub Action example pins this release (`@v0.5.511.1` with `version: 0.5.511.1`).
- The public tool reference (`docs/TOOLS.md`) describes this release.
- The three manuals and their PDFs still describe 0.5.505.1; the changes above are not in them yet.

## 0.5.510.1 (2026-10-29) - call_graph walks through constructors, a cancelled analysis waits for the retry, and a file shared by several projects renders once

This release collects more changes than usual, so its entry is longer than usual too. The
sections below follow the questions you ask the server; the desktop app and `aicb init` come
last.

**Who is affected.** Everyone on the MCP server: reconnect your client once - 20 tools of the
default profile have a new description or parameter description (`analyze_solution`,
`call_graph`, `check_solution_config_drift`, `explain_symbol`, `find_by_event_subscription`,
`find_by_semantics`, `find_implementations`, `find_resource_usages`, `find_symbol`,
`find_tests_for`, `find_unresolved_bindings`, `find_usages`, `impact_of_change`,
`init_solution_config`, `list_insights`, `resolve_injection`, `save_session`, `server_info`,
`solution_config_status`, `symbol_signature`), and outside the default pool so do
`find_by_resource_leak`, `find_god_objects`, `recall_codebase`, `remember_codebase` and
`type_dependency_path`. No tool or parameter was added, removed or made required, and no default
changed. The handshake no longer declares `tools.listChanged` (see "MCP protocol").

**Scripts that read these answers should check the following:**

- `init_solution_config`: the items of `referencedNamespaces` are objects now
  (`{namespace, documents, ...}`, heaviest first) instead of plain strings in alphabetical order.
  Read `.namespace` for the name.
- `resolve_injection`: a multi-targeted project's registration is one row with a new
  `targetFrameworks` list instead of one row per target framework, and `project` carries no
  framework suffix on such a row, so `matchCount`, `testRegistrationsFiltered` and
  `multiRegistration` can drop. `GetService` calls inside a registration factory leave
  `otherConsumers`.
- `find_implementations`: the items are ordered differently (direct implementers first), and an
  interface that extends the queried one is marked `via: "derived-interface"`.
- `find_tests_for`: two new `matchReason` values (`command`, `command-via`) and an optional
  `testTypeFullName` on rows that would otherwise read alike.
- `find_usages` and `impact_of_change`: two new `textualBindingKinds`, `viaImplementation` and
  `viaUsingDisposal`, always present (at 0 where they do not apply).
- Answers of a session recalled from an older snapshot: the label `GENERATED CODE NOT KNOWN` is
  replaced by three labels (see "Remembered codebases").
- Coupling numbers (`ce`, Ce in hotspots and `solution_metrics`) move: some up, because code-only
  references now count, and many down, because a type's own nested types and the array or
  nullable spellings of one type no longer count extra (see "Coupling, quality and effects").
  Anyone tracking them over time sees a one-time step.

**After updating:** every snapshot and saved session of an earlier version is analyzed afresh the
first time a session is restored from it (`compare_with_previous` still compares against an older
snapshot as it was stored, so a comparison across the update can show differences that come from
the new analysis), a codebase remembered with an earlier version is recalled as `stale` until
`refresh_remembered`, and the first open of each solution runs a full design-time build once
(the build cache of earlier versions is not reused). The configuration database is not changed by
this version, so an older desktop app still opens it. Projects set up with `aicb init`:
`aicb init --force` refreshes the installed symbol guard and the `aicb-csharp-context` skill, and
also rewrites aicb's own server entries (see "`aicb init`, the symbol guard and the skill").

### Analysis runs and sessions

- **A client that cancels `analyze_solution` no longer throws the analysis away.** Before, a
  client with a hard timeout cancelled the load, and the retry started from scratch, so a solution
  that took longer than the client's deadline could never be analyzed. Now the analysis keeps
  running and lands in the server's session cache. A later `analyze_solution` with the same
  arguments, within ten minutes after the analysis finished, gets that result in well under a
  second - as long as nothing it read has changed since (source files, solution and project files,
  build files in the folder and above it, the `.aicb.json` file, a restore) and the analysis was
  complete. Otherwise it analyzes again. A solution with a project outside its own folder is always analyzed again. This works
  wherever the server is started, not only in the solution folder.
- **The "analysis is running" message tells you what to do.** A call that waits too long behind a
  running analysis still gets an error, but the message now says the analysis keeps running, that
  its session is cached when it ends, and that a retry after that is answered from the cache. A
  call with a different layer profile or database is told that its retry runs its own analysis.
  A load stopped by a server shutdown says so instead of showing a bare cancellation.
- **The first call of any tool with a solution path reports progress** when the client asks for
  progress, as `analyze_solution` always did. A cancelled first call returns at once instead of
  holding on until the load ends, and its result can be picked up by a later `analyze_solution`.
- **Closing the client stops a running analysis.** When the client closes the connection while an
  analysis or a refresh runs, the server now exits within about a second instead of finishing the
  work first, however long that took.
- **Editing a `.cs` file that no project compiles no longer reloads the solution:**
  `refresh_session` answers `changed: false` and names the skipped file ("C# file(s) outside every
  compilation"), where it ran a full reload before. It still reloads when build files above the
  solution folder changed or a project lies outside it. A renamed non-C# file is named on both
  sides ("file added", "file removed").
- **Files imported from outside the solution folder are watched.** A project file that pulls in
  an MSBuild file from outside the solution folder with an explicit `<Import>` (also through
  `Directory.Build.props` or `.targets`) did not count as a change when you edited that file:
  `refresh_session` said `changed: false`, and the design-time build cache answered with the old
  build. Both notice the edit now. Imports
  added by the SDK itself, and imports whose path needs an MSBuild evaluation, are still not
  followed.
- **The restore note no longer asks for `force`.** The note about projects without restore output
  now says to run `dotnet restore`, then `refresh_session` - an ordinary refresh already notices a
  restore; it no longer asks for `force: true`.
- **`server_info` speaks per solution.** Its ANALYZER DRIFT line compared the server's build with
  one analyzed repository - whichever came first, possibly another client's - and called it "the
  repo it is analyzing". Now each analyzed solution folder (up to four, most recently used first)
  gets its own line naming the solution, a non-zero distance names the commit and branch it was
  counted against, and the answer says that `server_info` cannot tell which session is yours. A
  folder in a repository that does not contain the server's build commit gets no line; when the
  probed folders are all such and more were not probed, it says `drift NOT MEASURED` and names
  them. Scripts that read this line must expect one line per solution.
- **A "not found" can point at a stale checkout.** When `find_usages` or `impact_of_change` find
  no symbol of that name, the answer now adds how many commits that touch `.cs` files the analyzed
  checkout is behind `origin/HEAD`, as of your last fetch (nothing is fetched). It is silent when
  the checkout is current or ahead, or has no `origin/HEAD`.
- **Every slice tool says when the analysis run was incomplete.** When some projects could not
  resolve their references (typically never restored or built), a short list of users or a
  "(none)" in the tests looked like an honest result. Now `get_context` and `pack_for_task` start
  with a comment line `<!-- run: THIS ANALYSIS RUN WAS INCOMPLETE ... -->` that names the
  projects (five at most, then a count) and the repair, and the leading manifest of `prepare_task`
  and `explain_symbol` carries a `run:` segment saying that a "(none)" on the callers,
  implementations or tests axes is not a measured negative. The line counts against the token
  budget. On a complete run nothing changes. `find_by_concurrency_risk` names the projects without
  restore output too, because two of its risk kinds come up short there.
- **An empty configuration database file stays empty.** A zero-byte file passed to a tool as its
  `dbPath` is treated as no database: no tool writes tables into it any more (before, some calls
  grew it to hundreds of kilobytes), and the answer carries a `configDbNote` saying so. The
  server's own start option `aicb mcp --db-path` still sets up its database in the file it is
  given.
- **The text that `explain_symbol` and `prepare_task` repeat from your input** (the symbol, the
  goal) is still cut at 120 characters, but the cut no longer splits a character such as an emoji
  into two halves.

### Who uses this symbol (`find_usages`, `impact_of_change`)

- **References that only exist in code count as dependencies.** A type named only through a static member
  (`Math.PI`-style), a method group, `typeof`, `nameof`, a cast or a pattern, a typed local, or a
  creation inside an accessor, constructor or initializer is now a dependency of the type that
  writes it: it is in that type's dependency list, the target lists it under `USED_BY`, and it
  counts toward Ce and Ca. `find_usages` already listed such users; the dependency lists and the
  coupling numbers now agree with it.
- **Array creations count.** A type named only in an array creation (`new T[3]`, `new T[] { }`,
  jagged and multi-dimensional arrays, `new List<T>[3]`, `stackalloc T[n]`) had no user, so
  `find_usages` answered 0, `impact_of_change` answered 0 with risk `none`, and `find_dead_code`
  called the type dead. Now the type that writes the creation is a user, and `T` (not `T[]`) is the
  dependency.
- **`Dispose` through `IDisposable` has callers.** A qualified `Type.Dispose` or
  `Type.DisposeAsync` query showed 0 callers when the callers got the object from a factory typed
  as the interface (`using var s = pool.PushScope();`) or disposed it through the interface. Those
  callers are now credited, also where a factory builds the object through one private helper or
  is the only production implementation of an interface member, and the answer carries a
  `viaBclInterface` block (counts of disposers and of the callers that obtain the object, and the
  factories) under
  `viaContract`. Callers that cannot be told apart between same-named nested types are counted as
  `ambiguous` in the note instead of credited; then `verify_claim` answers
  `indeterminate` instead of confirming that the method is unused, and the `explain_symbol`
  manifest says how many callers could not be attributed. A bare `Dispose` query takes no such
  credit.
- **Two more kinds of users the source never names:** `viaImplementation` (the user hands on a
  value of another solution type that implements or derives from the queried one - it breaks with
  that type, not this one) and `viaUsingDisposal` (on a `Dispose` query, the user disposes with
  `using` - it breaks only if the type stops being disposable). Users that were `unclassified`
  move into them, and `textualBindingNote` says what breaks each.
- **`impact_of_change` labels what is reached only through dependency injection.** On a type, a
  new `registration` block names the part of the impact that exists only through a
  `Microsoft.Extensions.DependencyInjection` registration (`Add*`, `TryAdd*`, `ServiceDescriptor`):
  a rename dependency, not a use. Counts and risk do not change; the edge is labelled, not
  dropped. The label stays off where the registering code names the type in any other way (a cast,
  an array, a constraint, an attribute), so it errs on the side of silence. Autofac and
  non-generic `AddSingleton(typeof(X), ...)` registrations are not recognized.
- **`impact_of_change` on a property lists where it may be serialized:** a new `serializers` block
  names the methods that name the property's type beside a serializer call (System.Text.Json,
  Newtonsoft.Json, XmlSerializer, DataContract, YamlDotNet, MessagePack and the HTTP JSON
  extensions), and `namePinnedBy` names a `[JsonPropertyName]` that keeps the wire name stable
  (System.Text.Json only). It is a name match, not a data-flow proof, and the note says so.
- **`impact_of_change` on an attached property's field** (a static `XProperty` registered with
  `RegisterAttached`) adds an `attachedProperty` block that lists the `GetX` and `SetX` accessors
  and the markup files that use them (up to ten each). The counts and the risk are unchanged.
- **A generic and a non-generic type of the same name are kept apart** in the transitive part of
  `impact_of_change`: a reference written as `Gadget<T>` no longer counts as one to a
  non-generic `Gadget`. Transitive counts can only shrink; the direct answer still covers every
  arity of the name. `type_dependency_path` walks the same graph now, so a path exists exactly
  when `impact_of_change` lists the type; a step prints the full name where several types share a
  simple name.
- **`find_usages` on a type a view declares as a resource** adds a `resourceKeyNote`: the views
  that use it through `{StaticResource key}` are listed by `find_resource_usages`, not here.
- **Better "nearest" suggestions.** A mistyped member of a type you named (`Type.Membr`) is now
  suggested in its qualified form (`Type.Member`), and a name you cut short (`OrderViewM`) is
  steered to the name it begins rather than to a similar-looking one. A very short name (under five
  characters) no longer gets a guessed typo correction, which mostly pointed at an unrelated name;
  a short name that differs only in letter case is still suggested. The price: a real typo in a
  short name now goes without a suggestion.
- **`find_symbol` with no hit and no suggestion** adds a `note` that a missing name proves a
  missing string, not a missing feature.
- **`explain_symbol` on a method name several types declare:** where a member of one of those
  types calls another type's method of that name, the calling member is now shown with its code,
  and the manifest says so (up to eight such types, the rest counted). Such queries are also
  faster.

### Markup: XAML views, Razor views and top-level programs

- **Bindings in an element's own inline style count.** A `{Binding}` inside a `DataTrigger`, a
  `Condition` or a `Setter` of the style an element declares for itself (`<X.Style><Style>`) is now
  a markup use of the view-model member and is judged by `find_unresolved_bindings`. Keyed or
  implicit styles, a style passed as a setter value, item-container styles, and a template inside
  the style stay unread, and the zero-fan-in note of `find_usages` says which.
- **The view-model code assigns counts, also beside a design-time hint.** When production code
  sets a view's `DataContext` (`DataContext = this`, an assigned base class, two different assigned
  types), the view's bindings now count as uses of every type it assigns, not only of the type the
  markup names. A view's own `ViewModel` property, or a member of an assigned base type, no longer
  looks unused. Where the assigned type does not agree with the markup's hint,
  `find_unresolved_bindings` skips the page's view-model bindings under the new reason
  `codeAssignedDataContext` instead of judging them against the hint; that removes a class of false
  reports seen in ReactiveUI-style views.
- **`find_resource_usages` lists keys no markup defines.** Its audit view now also names every
  referenced resource key that no markup in the solution defines, split into
  `misspelledKeyCandidates` (one slip from a defined key, with `nearestDefined`) and
  `notDefinedInSolutionKeys` (most often a theme's or the platform's key - unknown, not broken).
  The earlier fields are unchanged.
- **Handlers wired in XAML are found.** `find_by_event_subscription` read only `+=`, so a handler
  wired in markup (`Click="OnClick"`, `Loaded=`, a `CommandBinding`) was missing, and a type that
  wired only in markup had no row. Each row now carries `markupWires` (per handler the number of
  views and up to ten of them), and a markup-only type appears with an empty `events` list. A
  markup wire carries no event name, so `eventName` cannot select it; under such a filter
  `markupWireTypesNotFiltered` and a note count what was left out. At the 200-row cap rows with C#
  events are kept first. Answers grow, in one measured case to three times their size.
- **Released and unreleased subscriptions:** each row of `find_by_event_subscription` also carries
  `unreleased`, the subscriptions no matching `-=` on the same type releases. An empty list means
  everything is released, an omitted list means not measured (a note says why).
- **Code-behind split over two files is one type for the dead-code tools.** A class with a
  `*.xaml.cs` code-behind and a second hand-written partial file could be reported dead through
  the second file, and a handler the markup wires could be reported as an unused private method
  there. Now the markup exempts the type in every file and its wired handlers count in every file;
  every other member is still judged. This mattered mostly where the generated half is missing
  (an unbuilt WPF project) and in Avalonia.
- **Razor views and top-level programs credit what they use without spelling it.** A compiled
  Razor view and a file of top-level statements now credit types by one rule, which only ever adds
  users:
  - a view credits the types of a method it calls (declaring, return and parameter types), so a
    view that calls a member of an `@inject`ed service is a user of that service type;
  - a view credits the type a record `with` produces and the type a collection expression
    converts to; a top-level program credits the type a `var` infers (`var`, `foreach`, `using`,
    `out var`);
  - both credit what an unspelled form carries: type arguments and array element types
    (`var xs = holder.Items` of a `List<Hidden>` credits `Hidden`, `Point?` credits `Point`), the
    type arguments of a containing generic (`dictionary.Values`), pointer and function-pointer
    types, tuple and deconstruction elements, and the locals a `var` pattern declares.
- **`resolve_injection` reads Razor `@inject` from the files a project compiles.** A view the
  project excludes no longer counts as a consumer, and a view linked in from another folder now
  does. A project that compiles no Razor file (runtime-compiled views, older frameworks) keeps
  reading its folder as before. When a Razor file cannot be read, the note now says so instead of
  counting nothing.

### Call graph and flow

- **`call_graph` follows object creation.** A `new X(...)` was not an edge in `call_graph`, and a
  callers walk stopped at a constructor. Now a creation is an edge to the constructor it binds
  (keyed `Ns.X.X(params)`, the form `find_usages` takes), and both directions walk on through it:
  callees into what the constructor calls and creates (`: base(...)` and `: this(...)` included),
  callers out to the code that creates the object. Answers grow (in one measured repository a
  quarter of the answers moved, about half again as many bytes), and the 500-edge cap is reached
  more often. A graph cannot be rooted at a constructor; `trace_flow` does not follow creations.
- **`call_graph` takes `Type.Method`.** A qualified name rooted nothing; now it roots that type's
  declarations, overloads included. A bare name behaves as before.
- **Callers through interfaces.** With `direction: "callers"`, every node now also brings in the
  callers of the interface or abstract members it implements, at every hop. Those members are
  named in a new `viaContract` block with their implementation count (one = exact, several = a
  union) and the nodes that brought them in (`creditedBy`).
- **The flow sections of the export show creations:** ENTRY_POINT_FLOW lists an entry point's
  creations, a top-level program whose only use of the project is a creation appears in
  ENTRY_POINTS, and ARCHITECTURE_FLOW gains an edge for a creation of an architectural type.

### Implementations of interfaces

- **A closed query reads as the compiler reads it.** `find_implementations` with a closed
  interface name now finds what C# would bind: `IHandler<string?>` finds the closers of
  `IHandler<string>`, `IHandler<Nullable<int>>` finds the `int?` closers, a tuple without element
  names matches a named one. A solution type named `String` is no longer merged with the keyword
  `string`. Where the facts cannot decide, the closing is reported as unread
  (`closing: "unresolved"`) rather than as another closing. `resolve_injection` matches a
  `Nullable<int>` query to an `int?` registration too.
- **Direct implementers first.** The items of `find_implementations` were sorted by name only, so
  on a page cut at 100 the types that implement the interface themselves could fall off behind
  types that inherit it. Now items without `via` come first, then by name; the set and the counts
  are unchanged. An interface that extends the queried one stays in the list, marked
  `via: "derived-interface"`, so it no longer looks like an implementer.

### Tests (`find_tests_for`)

- **Tests that run a generated command are found.** A test that reaches a method only by running
  the command a CommunityToolkit `[RelayCommand]` generates for it was invisible. Two new strong
  tiers: `command` (the test reads the generated command and executes it) and `command-via` (the
  same through one helper method, or through a `[RelayCommand]` method that calls the target). A
  `CanExecute` check alone does not count. When `assert_absence` refutes "X has no tests", it says
  how many of the tests run the generated command.
- **Same-named test classes are told apart.** Two test classes of one name in different
  namespaces were merged into one row; now each has its own, and `testTypeFullName` appears on the
  rows that would otherwise read alike. The tests axis of `explain_symbol` and the other slice tools
  no longer shows a same-named test class that never reaches the symbol.
- **The two-hop limit is said wherever it applies.** When every strong row reaches the symbol
  through one method in between (`invokes-via`, `accesses-via` and the like), the answer now leads
  with the note that the evidence reaches two hops at most - for types, methods, operators,
  properties and fields. Before, only an empty answer said it.
- **Tests that only read a constant** of a type are counted in the note of a type answer, with the
  member query that lists them.
- **Test attributes are matched as words.** A custom attribute counts as a test marker when the
  marker is a whole word at the start or end of its own name: `[FactMySql]`, `[Fact_Slow]`,
  `[SkippableFact]` count; `[Factory]`, `[Artifact]`, `[Latest]` no longer do (a production
  `[Factory]` method made its type a test fixture before). `[TestCaseSource]` is a default marker.
  The attributes by which `find_dead_code` exempts test, routing and generator types are matched as
  whole words too (test markers at the start or end of the name, the others at its end), so some
  types that were exempted by a lookalike attribute are judged now. If you configured a custom
  marker that only matched inside a longer name, check it.

### Dependency injection (`resolve_injection`)

- **Null-conditional registrations are read:** `services?.AddSingleton<IFoo, Foo>()` and every
  other `?.` form was not a registration at all.
- **A receiver that changes is noticed.** When the service collection variable is reassigned (or
  passed `ref`/`out`, or written in a lambda) between registrations, `effectiveRegistration`
  answers `winner: null` and names the line, since the calls may go to different collections. The
  fluent `services = services.AddX()` form stays readable.
- **Same-named types are kept apart.** `multiRegistration` and `ambiguous` are judged per service
  type, not per simple name, so two different types of one name, each registered once, no longer
  read as a conflict. A qualified query (`App.Settings.IPanel`) keeps only that type and counts the
  namesakes it left out.
- **One row per call in a multi-targeted project.** Identical rows of each target framework are one
  row, with `targetFrameworks`; a call only some frameworks compile stays apart and the note names
  it with its frameworks. In one measured library a query went from 183 rows to 65.
- **The container's own wiring is not a consumer.** A `GetService` call inside a lambda passed to a
  registration (`AddSingleton<IFoo>(sp => sp.GetRequiredService<Foo>())`) no longer counts in
  `otherConsumers`; the note says how many were left out and where. `ambiguous` is described as a
  possible conflict.
- **Wrapper registrations that forward a parameter are read.** A registration made through a
  project helper inside a method that hands on its own parameter was dropped; it is a row at that
  method now. An instance or key that is forwarded reads `(dynamic)`, except where the parameter
  type is exact (a sealed class or a value type). A helper nobody calls that passes a fixed service
  on to another helper keeps its body line as a row.
- **Unusual spellings of the queried type are read.** A nested type of a generic type
  (`Outer<int>.IInner`), reflection names (`+` for nesting, `` `1[[...]] `` for type arguments,
  assembly-qualified names) and a nested type's own closing are understood. A name with stray
  whitespace or brackets is answered for the cleaned name and the note says how it was read. A
  query that names no type at all (`App.`) is now an input error with a clear message, in the
  tool and in `aicb call`.

### Exported Markdown and context slices

- **A file compiled into several projects renders once.** A source file linked into several
  projects rendered one identical FILE block per project. Where the block reads the same in every
  project, it is written once with a `CompiledInto: A, B, C` line, the other projects carry a
  one-line pointer to it, and FILE_INDEX lists the file once. Copies that read differently (an
  `#if` per project, for example) keep their own block. Because budgets count rendered text, the
  room this frees is filled with more types: on one measured multi-assembly library the whole
  export shrank to about half, and a `get_context` answer kept all 16 types instead of 12.
- **A type's namespace is its own.** A file with several namespace blocks, a nested block or a
  type in the global namespace named its first namespace for every type. Now each type carries its
  own, and the FILE header lists the namespaces of the types it holds (`(global namespace)` for
  the global one). `find_structural_twins` uses the type's own namespace too.
- **A partial method is one method.** A partial method declared and implemented in source was two
  METHOD blocks, was listed twice by `find_symbol`, and its context could come from the empty
  declaration. Now it is one method that carries the declaration's documentation where the
  implementation has none.
- **An `<ai layer>` on one part of a partial type applies to every part** of that type in its
  project and to their methods, so one type no longer renders with two layers.
- **Clearer method sentences.** A method whose only act is a throw read "modifies state"; it now
  reads "Can throw an exception". A method without a body read "Self-contained"; it now reads
  "Declares no body". A method that only calls external code gets a sentence. An interface method
  takes its sentence from a concrete implementation, not an abstract one.
- **Method code extracts are exact far more often.** The extract of a method no longer pulls in a
  preceding expression-bodied member, a type header, a comment or a preprocessor line, and a `<`
  operator in a default value no longer breaks overload matching (measured on one large
  repository: exact extracts up from about 91 % to over 99 %).
- **Multi-line initializers** in `Fields:` and `Props:` lists are printed on one line, with line
  breaks shown as `\n`, so a reader no longer mistakes their content for tags.
- **The YAML and JSON forms** no longer nest a line of foreign text ending in `/>` (XAML in a
  string, for example) as a tag, which produced phantom keys and could make the JSON conversion
  fail on a large export. Their spec text now says it describes the tag form they were converted
  from. Converting documents with many same-named keys is much faster (seconds to milliseconds).
- **Slices count coupling over the whole type.** In `explain_symbol` and the other slice tools,
  `ce` and the QUALITY_HOTSPOTS line count over the type's full declaration, and where the slice
  prints `ce`, the `<DEPENDENCIES>` block ends with an `OutsideThisSlice:` group naming the counted
  dependencies the slice does not show, so the number and the list agree.
- **Local function labels** in call lists and flows no longer carry an absolute source path.
- **Smaller fixes:** a bullet marker is stripped from your prompt rules only where it is one
  (`-1 means no limit` keeps its minus, `**Never**` its emphasis); the COMPRESSION legend says each
  sub-block appears only where it has content; a budget raised to the 8,000-token floor renders
  exactly what the floor renders, with the raise note on top; a `prepare_task` template render that
  produces only whitespace falls back to the lean render.

### Coupling, quality and effects

- **A type's own nested types are no outgoing coupling.** Using its own nested types counted as
  efferent coupling: Ce was inflated, and the DEPENDENCIES block listed them. They are left out of
  Ce, the DEPENDENCIES block, the hotspot line, `solution_metrics` and the desktop app's symbol
  detail now. Where a short name could also mean another type of that name (in the solution or in
  a referenced package), it stays counted. `find_usages` on a nested type still lists the outer
  type, and Ca is unchanged.
- **One entry per type, whatever its spelling.** `Dim[]`, `Point?` or a pointer beside `Dim` and
  `Point` were separate dependency entries, so Ce counted one type two or more times. They fold
  into one entry now; Ce can only drop.
- **A documentation link is no layer edge.** A type named only in a `<see cref>` no longer raises
  a layer violation; `nameof` still counts.
- **Namespace coupling** credits the namespace of the type a reference provably means, not every
  type of that name.
- **The circular-dependency insight reads as a set:** "N namespaces reference each other:
  {A, B, C}" instead of an arrow path whose steps need not all exist.
- **Cognitive complexity** scores a run of `or`/`and` pattern combinators.
- **Role spelling:** an `<ai>` role that differs from an inferred role only in letter case is
  written the inferred way, so one role no longer shows up twice.
- **`Debug.Assert` is not logging, `HttpRequestOptions` is not network.** A call of
  `Debug.Assert` or `Debug.Fail` no longer gives a method the `logging` effect, and neither do
  its callers inherit it; reading `HttpRequestOptions` no longer counts as `network`. Effect
  filters return fewer methods where that was all they did.
- **The security insight covers top-level programs.** `security-sensitive-calls` now reports
  risky calls written in top-level statements, as a line for the file
  (`App/Program.cs (top-level): ...`) whose locator has a `file` and no type or member, and the
  title counts methods and top-level files. `list_insights` with `files` keeps such a line when its
  file is in the list. Scripts that read insight locators must accept a locator with only a `file`.
- **`find_god_objects` names the test class it filtered.** With the default
  `includeTests: false`, when the largest test-project class would rank within the list, a note
  names it and the place it would take, and how to include it.
- **`evaluate_change_set` no longer blocks a change for adding a test.** A complex method whose
  "a test reaches it" line improved because the change set added a test counted as a new finding,
  so `block_on_warning` blocked it; now only losing the last test counts. `diff_review` uses the
  same gate. A new overload whose line reads exactly like an existing one is reported.
- **`find_by_complexity_and_coverage`** keeps overloads apart, so a covered overload no longer
  appears uncovered because of its namesake. `find_structural_twins` and `check_pattern_drift` say
  how many methods a type name also names, and print owners with colliding names in full.
- **`find_by_resource_leak` checks the exception path.** A disposable your code creates and then
  awaits across before handing it on or disposing it, with nothing protecting it if an exception is
  thrown, is reported in a new `exceptionPathTypes` list, with `exceptionPathLocalsChecked` as the
  count of what was judged. The earlier results are unchanged.
- **`find_by_semantics` names the axes without values.** On an empty answer, a queried axis on
  which nothing carries a value at your confidence was simply missing; it is now listed in
  `unclassifiedAxes`, so every queried axis is in exactly one of the two lists.

### Solution configuration

- **`solution_config_status` works without a database:** without `dbPath` it answers from the
  `.aicb.json` file and the defaults, and opens or creates nothing. A `dbPath` that does not exist
  is still refused.
- **`init_solution_config` weighs the referenced namespaces** (see "Who is affected"): each item
  counts the hand-written files that use it (`documents`), build-written files are counted apart
  (`generatedDocuments`), and the list starts with the heaviest. Test attributes found only inside a longer name are no longer reported.
- **Excluded framework areas are flagged.** `init_solution_config` (`frameworkApiAreas`) and
  `check_solution_config_drift` (`exclusion.excludedApiAreas`) name an area the exclusion list
  removes (the built-in one for `init_solution_config`, yours for the drift check) although a large
  share of your public API names it (`System.Data` in a data-access
  library, for example), with the keep rule to add. On a never-configured solution, the drift check
  evaluates this one signal.
- **Project names with brackets keep their name.** A project file such as `Foo(Legacy).csproj` was
  merged with `Foo.csproj`; only a trailing group that looks like a target framework, such as
  `(net8.0)`, is dropped now (so `Foo(v2)` still merges with `Foo`).

### Remembered codebases

- **Three labels instead of one.** In a session recalled from an older snapshot,
  `GENERATED CODE NOT KNOWN` is replaced by `GENERATOR GAPS NOT KNOWN`,
  `UNINDEXED CODE NOT KNOWN` and `MARKUP-ONLY COMPONENTS NOT KNOWN`, one per missing fact, and all
  six "NOT KNOWN" notes now read alike: what the snapshot lacks, what that means for this answer,
  and that `refresh_remembered` fills it in. Match `NOT KNOWN:` if a script looks for them. Live
  sessions are not affected.
- **Automatic snapshot cleanup keeps pinned snapshots.** When the cap on automatic snapshots
  removed old ones, a snapshot that a saved session or run still pointed at could be deleted. It
  is kept now, and the cleanup no longer reads every snapshot to decide (on a large database:
  seconds to milliseconds).

### MCP protocol

- **The handshake no longer declares `tools.listChanged`.** Both `initialize` and
  `server/discover` answered `"tools": {"listChanged": true}`, although the server never sends a
  tool-list notification - the tool list is fixed for the life of the server process, and a profile
  switch takes effect at the next start. They answer `"tools": {}` now, and a
  `subscriptions/listen` is no longer granted `toolsListChanged`. `tools/list` is unchanged. A
  client that waited for such notifications can treat the list as static, which it is.
- **`batch` records misspelled arguments of its sub-queries,** so `usage_report` counts such a
  batch call among the calls with unrecognized arguments.

### `aicb init`, the symbol guard and the skill

- **The symbol guard knows `.slnx` and `.slnf`.** The guard `aicb init` installs recognized a
  solution root only by a `.sln` file, so it switched itself off in a repository that has only a
  `.slnx` or `.slnf`. All three forms count now.
- **The guard reads search patterns fully:** a brace pattern (`*.{xaml,cs}`) is judged by every
  member, not the first, and a search that only excludes some files (`rg -g '!*.md'`,
  `grep --exclude=*.md`) is treated as a search that still covers `.cs` files.
- **The `aicb-csharp-context` skill** now asks, before an edit, to check the two channels the C#
  fan-in does not carry: markup (`find_binding_usages`, `find_resource_usages`) and text that
  tests pin (a description, a message string). Its markup paragraph was rewritten.
- `aicb init` keeps files that exist; run `aicb init --force` to replace the installed guard and
  skill with these versions. `--force` also rewrites aicb's own server entry in `.mcp.json` and in
  the Codex and OpenCode configuration, and its hook wiring, so a hand-edited aicb entry is replaced.
- **`list_skills`** explains that a core tool can be outside the pool because the active profile
  denies it or because `AICB_MCP_TOOLS` hides it.
- The descriptions and help texts that named `.sln` alone (`--solution`, `aicb call --sln`, the
  memory and session tools) name `.sln`, `.slnx` and `.slnf`.

### Desktop app

- **The MCP usage panel shows your pool on a fresh install.** It knew the active profile's tools
  only after the profile editor had been opened; now the pool tile reads, for example, "13 of 54",
  the tools never called are listed, and the export carries the pool.
- **The protocol revision is explained correctly.** The panel no longer says the client's SDK
  version fixes the protocol revision: it explains that the revision is the one each call arrived
  on, how the two ways of connecting differ, and why two rows of one client version can differ only
  in revision.
- **All solution pickers accept `.sln`, `.slnx` and `.slnf`** (the Layer Profiles, Namespace
  Exclusions and Relocate Solution pickers offered `.sln`, one of them `.slnx` too).
- **Snapshots load faster:** the Snapshots tab, the snapshot history of the Solutions tab and the
  Insights debt trend no longer read the stored analyses to fill their lists (on a large database:
  about a quarter of a second to a few milliseconds for the Snapshots tab).
- **Recent lists and database switches are sturdier:** a failed write of a recent list no longer
  leaves a phantom entry or fails the solution load or database switch it belongs to; the Storage
  page shows the warning of a switch that succeeded. Blank entries in a hand-edited settings file
  are dropped.
- **The IN USE tooltip on master data tells the truth:** deleting such an entry is not blocked;
  the entries that reference it then point at one that no longer exists.
- **The symbol detail** leaves a type's own nested types out of its dependencies and its Ce; a
  top-level line of the security insight offers no reveal, suppress or dismiss action (it has no
  type to point at).
- The selection rule "exclude test classes" also excludes a type that declares a test method, with
  all its partial parts.

### Other changes

- The README's GitHub Action example pins this release (`@v0.5.510.1` with `version: 0.5.510.1`).
- The public tool reference (`docs/TOOLS.md`) describes this release.
- The three manuals and their PDFs still describe 0.5.505.1; the changes above are not in them yet.

## 0.5.505.1 (2026-10-26) - find_usages lists production users on request, find_implementations names what each implementer closes a generic interface with, and get_diagnostics lists only the errors of a failing compile

**Who is affected.** Everyone on the MCP server: reconnect your client once - 14 tools of the
default profile have a new description (`calls_external`, `compare_with_previous`,
`find_by_attribute`, `find_by_event_subscription`, `find_by_side_effects`, `find_implementations`,
`find_tests_for`, `get_diagnostics`, `impact_of_change`, `list_insights`, `refresh_session`,
`resolve_injection`, `usage_report`, `verify_claim`), and four tools gain an optional parameter
(`find_usages`' `includeTests`, `find_implementations`' `typeArgumentBase`, `get_diagnostics`'
`runSuppressors`, `list_insights`' `files`). No tool or parameter was removed or made required.
**Scripts that read `get_diagnostics`' list:** the default `severityFloor` is now `auto`; when the
compile has errors, `diagnostics` lists only the errors and `warningsNotListed` counts the warnings
it left out. Pass `severityFloor: "warning"` for the previous answer; the counts are unchanged.
**Scripts that compare `textualBindingKinds`:** two new kinds (`viaClosedGenericBase`,
`viaInheritedMember`) are always present, at 0 where they do not apply, and users that moved into
them leave `unclassified`. A snapshot or saved session from an earlier version is analyzed afresh
the first time it is used, and a codebase remembered with an earlier version is recalled as
`stale` until `refresh_remembered`. The configuration database is updated the first time this
version opens it (four new columns of the local usage record, below); an older desktop app does
not open a database a newer version has updated.

### Usage and impact

- **`find_usages` can list production users only:** with `includeTests: false`, users declared in
  test projects leave the list before the 100-item cap, so a heavily tested symbol shows its
  production fan-in, and `testUsersFiltered` counts the users left out. A user that cannot be
  placed in a project stays listed. For the constructor form (`Type.Type`) test creation sites are
  left out and the note counts them. An answer whose users were all in tests says so instead of
  "nothing recorded". The default (`true`) answers as before.
- **A same-named type of another arity or namespace is a user:** a type such as
  `Identity<T1, T2> : Identity`, or `Ef.User : Core.User`, that derives from, holds or creates the
  queried type is listed by `find_usages` and `impact_of_change`; before, it was dropped as a
  reference to itself. A base type of the same name outside the solution is not counted.
  `namesakes` now also names a generic and a non-generic type of one name (`Foo` and `Foo<T>`),
  and a user whose name is the queried name itself carries its `fullName`.
- **Two more kinds of textually invisible users** in `find_usages` and `impact_of_change`:
  `viaClosedGenericBase` (a user that calls a member inherited from a generic base class another
  type closes over the queried type, such as `OrderRepository : RepositoryBase<Order>`) and
  `viaInheritedMember` (a user that derives from the queried type through another base class and
  calls or overrides a member it inherits from it). `textualBindingNote` says what breaks them and
  what does not.
- **A WPF view takes the view-model production code assigns to it:** where neither a design-time
  hint nor the `FooView`/`FooViewModel` naming ties a view to a view-model, the one type production
  code assigns to its `DataContext` (`new MainWindow { DataContext = shell }`) makes the view's
  bindings count as users of that view-model's members. Assignments in test projects do not
  count, and a view assigned two different types takes none. `find_unresolved_bindings` is
  unchanged.

### Implementations of interfaces

- **`find_implementations` names how each implementer gets a generic interface:** `closes` lists
  the type arguments it closes the interface with, directly or through its bases (`Saved, IContent`),
  and `through` names the base class or interface it gets it through when its own base list does
  not name the interface.
- **`typeArgumentBase` filters by a family of type arguments:** it keeps the implementers that
  close the interface with an argument that is the named type or derives from or implements it
  (`DeletedNotification<T>`), also through a base class. An implementer whose closing cannot be
  read stays in the list, marked `closing: "unresolved"`. `typeArgumentBaseFilter` reports the
  family size and what was left out, and a note says when the interface is not generic or no
  solution type has that name.
- **An interface that extends the queried one at any depth is listed** by `find_implementations`
  (`via: "inherited"`), `explain_symbol` and `review_context`; before, a non-generic interface's
  implementers stopped at the first level. `impact_of_change` lists such interfaces under `indirect`, for a generic contract as for a
  non-generic one, so they no longer raise the risk; a class that gets the interface through a
  derived interface stays a direct implementer.

### `get_diagnostics`

- **The default lists the errors first:** see "Who is affected". The answer of a large failing edit
  shrinks to its errors (in one measured case from about 78,000 to about 19,000 characters, every
  error listed).
- **Analyzer suppressors are named, and run on request:** a new `suppressors` block names the
  analyzer references of the solution's projects that declare a DiagnosticSuppressor (NUnit
  analyzers, Entity Framework Core and the Razor compiler declare some) and how many diagnostics
  their projects report, because a real build may report fewer. They are found by reading the
  references' metadata, which runs none of their code. With `runSuppressors: true` exactly those
  analyzer assemblies are loaded and their suppressors run, as a real build runs them; loading such
  an assembly also runs the constructors of the analyzers it declares, inside the server.
- **A restore since the session was loaded makes the answer `stale`** (unless it is already
  `inconclusive`), and `verdictReason` names the project, because the diagnostics were compiled
  against the references before the restore (errors such as CS0246 may not exist in a real
  build).

### Sessions and refresh

- **A restore after the load is picked up by an ordinary refresh:** `refresh_session` reloads the
  solution through MSBuild when a project's restore rewrote its assets file after the session was
  loaded, and `reason` names the project; an automatic refresh that a source edit starts does the
  same. A restore on its own does not start the automatic refresh. A plain build is still not
  seen; `force: true` remains the deterministic reload.
- **Adding, renaming or removing a C# file no longer reloads the solution** where the files around
  it show which project compiles it: `mode` is `incremental` and `reason` says the change was
  applied to the live solution. Where that is unclear, or for a markup or project file, the full
  reload runs and `reason` says so. A full reload also reuses what it can, and its `reason` says
  how many documents were reused.
- **An answer that is a JSON array carries its staleness too:** `list_insights` (and any
  session-bound answer that is an array) is followed by a separate `{"staleness": {...}}` block when
  the session was stale or refreshed automatically; the array itself is unchanged.

### Task packs and context documents

- **A goal that names `Type.Member` seeds that member on that type:** `pack_for_task` and
  `prepare_task` no longer seed every member of that name in the solution and bundle all their
  tests. A member the type inherits seeds the base class or interface that declares it. A member
  qualified by an interface also seeds the member its production implementations run. The goal's
  own names rank first; when the cap of 24 seeds cut matching declarations, `prepare_task`'s
  manifest says how many.
- **Covering tests are listed strongest evidence first** in `prepare_task`, and a capped list says
  how many of the tests found reach a seed only through an interface or abstract member.
  `explain_symbol`'s test axis discloses its cap the same way.
- **A document a token budget pruned lists only the callers it renders** in `USED_BY` and the
  method caller lists; before, a three-type document could list hundreds of callers it did not
  contain. The budget now goes to code, so the same budget can keep more types.
- **`QUALITY_FINDINGS` in a partial document are judged over the whole solution** and listed for
  the types the document renders, so a type is no longer reported as unused because its users were
  cut out; the section says so in a comment line.
- **`ca` in a partial document is the number a full export prints:** the afferent coupling on a
  type tag and on the `QUALITY_HOTSPOTS` line is counted over the whole solution the document was
  cut from, and `ca="n/a"` no longer appears; a type nothing references reads `ca="0"`.
- **The budget header counts the types a budget removed:** when a token budget is enforced, both
  header forms end in `| types: N dropped, M to structure`, the bypassed form included.
- **A method's context sentence counts what it reaches through the methods it calls:** a method
  that writes a file only through a helper reads like one that writes it itself (`SEMANTICS`,
  `explain_symbol`, `get_context`). Its role stays its own work, an interface method takes its
  implementations' new sentence, and an `<ai>` value an author wrote still wins.
- **A context template can set how far a `prepare_task` bundle grows** around the symbols a task
  names (`Expansion around the MCP start point`, desktop app, below); the manifest names the
  setting when it is used. Empty, the default, changes nothing.
- The YAML and JSON notations of `export_markdown` no longer swallow the rest of the document after
  an included file whose code fence carries an info string such as "c#".

### Insights and checks

- **`list_insights` takes the files of a change:** with `files`, the answer lists the findings
  about the types those files declare, with their detail lines (up to 20 per finding), and names
  each path the solution does not hold in `notInSolution`. Without `files` the answer is the array
  it always was. The `aicb-code-review` and `aicb-code-simplifier` skills call it this way.
- **Without a configuration database the insight tools say whose thresholds judged:**
  `list_insights`, `get_insight` and `solution_metrics` carry a `configDbNote` naming the built-in
  quality profile. With `aicb call`, the note of an array answer goes to stderr, so stdout stays
  one JSON document.
- **`find_tests_for` says when no row is strong evidence:** a list of only name guesses and
  contract rows carries a note that it does not show that anything pins the symbol.
- **A comparison of a state with itself is not evidence:** `verify_claim` answers `indeterminate`
  when baseline and changed are the same state, and `compare_with_previous` adds a note when the
  snapshot was saved from the source state the session still holds: with an empty diff it says the
  comparison is with itself, and from another analyzer build that a difference can come from the
  analyzer.
- **A partial type is one row** in `find_by_event_subscription`, the type axis of
  `find_by_attribute`, `find_dead_code` (judged as a whole, so the half of a partial `Program`
  without `Main` is no longer dead) and `find_god_objects`; in the first two, rows that would read
  alike add `fullName` or `project`.
- `find_by_side_effects(purity: "pure")` explains in `methodsScannedNote` why its `methodsScanned`
  is smaller than that of the other listings, and `find_by_code_traits(trait: "reflection")`
  explains in `traitReading` how it differs from the exported `UsesReflection` flag.

### Dependency injection

- **Umbraco collection builders are listed in `resolve_injection`:** when the query names a
  builder's collection, item type, builder or a collected type, a `collectionBuilders` block lists
  each builder's operations (`append`, `insertBefore`, `remove`, `replace`, `clear` and the others)
  in writing order. They are not registrations: what the collection holds at runtime depends on the
  order the composers run in, and the block says so.

### Usage record and `server_info`

- **`usage_report` names the window its never-called list covers**, and adds `clientSessions` (how
  many client connections the calls came from) and, per tool, `ignoredArgumentCalls` (calls that
  answered although they sent an argument the tool does not have).
- **Each call recorded through the server keeps** the MCP profile and the automatic-refresh mode it
  ran under, the names of arguments the tool does not have (never values) and a random id per
  server start; one recorded through `aicb call` keeps only the argument names. A failed call's
  recorded error message names such arguments. One solution path spelled two ways counts as
  one session.
- **`server_info` says `drift UNKNOWN`** when git did not answer in time, instead of staying silent
  as for a foreign repository.

### `aicb init` and the symbol guard

- **A `CLAUDE.md` in the project directory is evidence of Claude Code:** `aicb init` with
  `--hooks auto` now installs the Claude Code guard in a project whose `.claude/` folder holds only
  its own skills.
- **The guard lets a refused Grep through in two cases**, with a note: once the session has asked
  an aicb tool about that name (Claude Code), and where aicb is not available in the session or
  its configuration (every harness). A `glob` whose every pattern ends in a literal non-C#
  extension (`*.mjs`, for example) counts as a text search; a negated glob does not.

### Desktop app

- **The filters above the solution tree sit in three fixed rows**, so a narrow sidebar stays
  tidy.
- **The Insights page header names the quality profile** the last analysis ran under
  (`Profile: <Name>`); a template's profile wins over the one chosen in Settings.
- **Templates:** a new `Expansion around the MCP start point` field under `Profile overrides`
  sets how far a `prepare_task` bundle grows when the server or the CLI renders through the
  template; the expansion slots of the selection engine drive the GUI tree only, and their tooltips
  say so. A running server reads a template change after a restart.

### Other changes

- Several programs that open one database at the same moment (the desktop app and servers of
  parallel sessions) update it once; before, the second could fail with a migration error.
- The README's GitHub Action example pins this release (`@v0.5.505.1` with `version: 0.5.505.1`).
- The three PDF manuals and the manual chapters describe this release.

## 0.5.504.1 (2026-10-21) - Razor views and Avalonia markup count as usage, every implementer of a generic interface is found, and Program.cs counts in full

**Who is affected.** Everyone on the MCP server: reconnect your client once - 8 tools of the
default profile have a new description (`calls_external`, `explain_symbol`, `find_by_side_effects`,
`find_dead_code`, `find_implementations`, `find_resource_usages`, `instantiation_sites`,
`resolve_injection`); no tool or parameter was added, removed or made required. **Scripts that
compare `find_implementations`' `via`:** on an open query (`IHandler`, `IHandler<T>`) some items
that said `via: "back-edge"` now say `via: "inherited"`, and on a closed query
(`IHandler<Saved>`) such an item carries no `via`. A snapshot or saved session from an
earlier version is analyzed afresh the first time it is used. A codebase remembered with an
earlier version is recalled as `stale`, and until `refresh_remembered` the answers concerned say
what the old snapshot does not know (`VIEWS NOT KNOWN`, `GENERATED CODE NOT KNOWN`, `TOP-LEVEL CREATIONS
NOT KNOWN`, `TOP-LEVEL EFFECTS NOT KNOWN`), also on a solution without views. The first open of
each solution after the update takes the full design-time build once. The configuration database
is not changed.

### Razor views count as usage

- **MVC and Razor Pages views:** the code the Razor generator compiles from `.cshtml` views is
  read. What a view calls, reads or names is a use credited to the view (`<path>.cshtml (razor)`);
  a type injected in a `_ViewImports.cshtml` is credited to that file once, and `@attribute [X]` is
  a use of `X`. `find_usages`, `impact_of_change`, `find_dead_code` and `find_production_dead`
  follow.
- **Views that were not read are counted:** where the generator did not compile some views (a
  runtime-compiled view in a plain `Microsoft.NET.Sdk` project, a generator that did not run), a
  `VIEWS NOT READ` note gives their number and projects on a zero fan-in and on the dead-code candidate lists. A session
  restored with `recall_codebase` carries the same note.
- **Editing a `.cshtml` or `.razor` file marks the session stale**, and `refresh_session`
  analyzes it again; before, a `.razor` edit went unnoticed.
- **A Blazor component written only in markup is named beside a same-named C# member** - in
  `generatedSourcesNote` of `find_symbol` and `symbol_signature`, in `collision` of `find_usages`
  and `impact_of_change`, and in `get_type_hierarchy`'s `not_found`.

### Avalonia and XAML markup

- **Avalonia `.axaml` views are read like WPF `.xaml`:** a handler wired to an event
  (`Click="OnSave"`) is a use of the code-behind method, and a property set in markup (attribute,
  property element, `Setter`, attached property) is a use of that property. A bare `Setter` under a
  `Style Selector` is a use of the styled type's property, also in a nested `^` style; a selector
  naming several types or none records nothing. A `Classes.accent="True"` toggle is not counted as a use of a
  `Classes` member.
- **Nested types written `prefix:Outer+Inner`** are read in `{x:Type}`, `x:Static`, `DataType`,
  `TargetType`, `d:DesignInstance`, attached-property owners and markup extensions, so
  `find_unresolved_bindings` judges against the nested type and the nested type gains its markup
  users.
- **`find_resource_usages` reads three more key channels:** WinUI's `{ThemeResource}` (kind
  `theme`), a resource markup extension the solution derives itself (counted as its base's kind),
  and a C# member whose name is the key, read through a `[CallerMemberName]` accessor (kind
  `callerMemberName`). New counts `themeReferenceCount` and `callerMemberNameReferenceCount`
  appear when not zero.

### Every implementer of a generic interface

- **`find_implementations` and `impact_of_change` find the types that implement a generic
  interface of the solution through a base class, another interface or further down**
  (`Update : HandlerBase<Saved>`, `Leaf : Update`); before, many of them were missing. On an open
  query such items say `via: "inherited"`. A closed query no longer lists the
  subclasses of an unrelated base class of the same name, and a non-generic interface nested in a
  generic type also gets its indirect implementers.
- **The context tools pull them too:** `get_context`, `pack_for_task` and `prepare_task` centered
  on a generic interface include every implementer, and say what a budget dropped
  (`prepare_task` where its manifest says `render: lean`, as on a server without a configuration
  database).
- A type in the global namespace and a namespaced type of the same simple name are no longer
  taken for each other in `find_implementations` and in `impact_of_change`.

### `Program.cs` with top-level statements counts in full

- **Every type the top-level code names is used by that file** (`<path>/Program.cs (top-level)`):
  `typeof`, type arguments such as `AddTransient<I, Impl>()`, casts, patterns, declared locals and
  the types of a called method's signature. Before, only object creation and a static qualifier
  counted. `find_usages`, `impact_of_change` and `find_dead_code` follow; a bare name that is both a
  type and a member can now answer for the type.
- **A `new` there is a creation site** in `instantiation_sites`, `lifecycle_of` and `find_usages`'
  constructor form (`Type.Type`); a namespace scope leaves it out.
- **`calls_external` and `find_by_side_effects` list each such file as one unit** beside the
  methods, with the effects of what it calls; `methodsScanned` counts it. A namespace-scoped query
  and `purity='pure'` stay methods-only, and `list_insights` still judges methods only.

### Dependency injection

- **`resolve_injection` counts consumers outside the constructor** in the new field
  `otherConsumers`, one entry per form with `consumers`, `sites` and up to three `examples`:
  `locator` for `GetService<T>()`, `GetRequiredService<T>()`, `GetService(typeof(T))` and their
  keyed forms (also through `?.`), and `inject-property` for `[Inject]` properties and Razor
  `@inject`. `constructorConsumerCount` keeps its meaning. A service named only by an `@inject`
  (such as `NavigationManager`) is now found instead of `not_found`.
- **MEF exports are registration rows:** `[Export]` of `System.ComponentModel.Composition` or
  `System.Composition` (also a derived attribute) on a class or on its members, with the note
  `MEF export` and the lifetime from the creation policy or `[Shared]`. MEF rows never make an
  answer `ambiguous` and never win `effectiveRegistration`; with two or more MEF exports and no
  Microsoft DI registration, the reason says that MEF composes by contract. The empty answer's
  note names MEF.
- A registration in a project outside the solution folder shows a relative `location`
  (`..\...`) instead of the bare file name.

### Dead code

- **An explicit interface implementation whose interface did not bind** (a missing reference) is
  no longer listed by `find_dead_code`; it counts under `methodsIneligibleUnanalyzedCallers`.
- **A library's public API is marked:** in `find_dead_code` and `find_production_dead`, a type a
  library exposes (and in `find_production_dead` such a type's public or protected method) carries
  `publicApi: true`, and `publicApiNote` says that consumers outside the solution are not seen.
  Nothing is left out.
- **A MEF part** (an export attribute on the type or on one of its members) is no longer reported
  as unused by `find_dead_code`, the type axis of `find_production_dead` or `list_insights`.

### More precise names and context

- **A qualified member query reads every segment** (`Outer.Inner.Member`) in `find_usages`,
  `impact_of_change`, `find_tests_for`, `symbol_signature`, `symbol_metrics` and the context tools;
  a qualifier that names none of the same-named types answers `not_found`, in `find_usages` and
  `impact_of_change` with a note naming them,
  and `find_usages` adds `namesakes` where the type part still names several types.
  `Outer<T>.Inner.Member` resolves.
- **A generic type parameter is no longer a use of a type named like it** (a `struct T`), in
  `find_usages`, `impact_of_change`, `find_dead_code` and the coupling numbers.
- **`explain_symbol` answers for the type or method it centers on:** where the same bare name also
  names a property or another member elsewhere, the callers axis no longer lists that member's
  readers, a method's tests axis lists only the method's own tests, and a new `namesakes:` segment
  in the manifest names the other kinds and their user counts.
- **A partial type compiled into several projects** (a linked file, a shared project) renders one
  block per project in `get_context`, `explain_symbol`, `pack_for_task` and `prepare_task`
  (`render: lean`), and the partial note names the project.
- **A type a token budget reduces to its structure lists the signatures** of the methods it does
  not show in full (up to 80 lines); before, `prepare_task`'s default `template` render listed
  none, and a type that kept some of its methods dropped the others without a word. Where
  quality metrics are rendered, its `members` counts what the type declares in its project.

### `get_diagnostics` says more about what is missing

- **`missingCompileItems`** names compile items the build lists without a file on disk (often a
  file a build step writes), per project file, with the errors they likely explain and the repair.
- **`uninitializedSubmodules`** names git submodules that were never initialized and that a
  project with unresolved names points into, with a `submodules` list and the
  `git submodule update --init` command.
- **A source generator referenced from another configuration or platform output** of a project in
  the solution is reported as `not-built` (or `not-found` where it cannot be told whether that
  project holds a generator) instead of as an unrestored package; where that project
  declares no generator, the entry is gone.
- Repeated runs of a solution in which a referenced C# project has an unresolved type no longer
  report different error counts; before, some runs reported extra errors.

### Faster

- The first `resolve_injection` call in a process is much faster on large solutions.
- `find_production_dead` (Full Select profile) answers in seconds on large solutions where it ran
  for minutes, for every `kinds` value.
- Two more solution shapes open again quickly from the design-time build cache: a project that
  lists a compile item without a file, and a `.sln` with Visual Studio Web Site entries. In most
  cases such an entry no longer counts as a failed design-time build; it still does when a project
  lost a project reference. A missing `.csproj` is still a failure, and Web Site entries in a
  `.slnx` are not recognized.

### Other changes

- A session restored with `recall_codebase` keeps the generated-code notes (`generatedSourcesNote`,
  `generatedCodeNote`, the markup-only component note, `missingGeneratedCode` in `find_dead_code`);
  before, they were dropped.
- The README's GitHub Action example pins this release (`@v0.5.504.1` with `version: 0.5.504.1`).

## 0.5.503.1 (2026-10-17) - Signed Windows downloads, resolve_injection reads far more registrations, and markup counts as usage

**Who is affected.** Everyone on the MCP server: reconnect your client once - 9 tools of the
default profile have a new description (`architecture_overview`, `find_dead_code`,
`find_implementations`, `find_symbol`, `find_usages`, `get_type_hierarchy`, `impact_of_change`,
`resolve_injection`, `symbol_signature`); no tool or parameter was added, removed or made
required. **Scripts that compare `resolve_injection`'s `serviceType`: it now carries the type
arguments of a generic service** (`IHandler<Saved>`, `IHandler<>` for an open registration).
A snapshot, saved session or remembered codebase from an earlier version is analyzed afresh the
first time it is used. The configuration database is not changed. Windows users get signed
downloads.

### Signed Windows downloads

- **The installer and the programs in the ZIP are code-signed**, with a timestamp: the setup and
  its uninstaller, `gui\aicb-ui.exe`, `cli\aicb.exe` and the product's own `AIContextBuilder*.dll`
  files. Windows names the publisher **Gregor Dadera** (file properties, tab *Digital
  Signatures*). Windows SmartScreen can still warn about a new release until it has enough
  download history; *More info -> Run anyway* continues as before. The .NET tool package is
  unchanged; nuget.org signs it.

### `resolve_injection` reads far more registrations

- **Registration helpers of your own, whatever their name:** an extension method in the solution
  that registers its type arguments, a `Type`, a factory or an instance is followed into its body,
  also when it calls another helper or is keyed. Such rows say `via <helper>` in their `note`, a
  keyed helper is read with each call's own key, and a type a factory lambda produces is read as
  that type. The helper's own registration line is listed once, at the calls read through it.
- **`ServiceDescriptor` registrations and hosted services:** `Add`, `TryAdd`, `TryAddEnumerable`
  and `Replace` with a descriptor the call builds, and `AddHostedService<T>()` (as a Singleton
  `IHostedService`), are read; the rows carry the method in their `note`. `TryAddEnumerable` and
  `AddHostedService` rows are not reported as conflicts.
- **Package helper chains** such as `AddSingletonAs<T>().As<I>()`, whose body sits in a package,
  appear as rows marked `inferred, not read`; they never decide `ambiguous` or the effective
  registration.
- **A closed generic query** (`resolve_injection("IRepo<Order>")`) lists the registrations of that
  closing and the open registrations that serve every closing; `typeArgumentFilter` counts what was
  left out. `ambiguous` is judged per closed service type. **Each row's `serviceType` now carries
  its type arguments** - breaking for a script that compared it with a bare name.
- **An empty answer says why:** the note names the forms that are not read and which of them the
  solution uses (package registration helpers, assembly scans, convention-based registration,
  other containers).
- **Repeat queries are fast:** further `resolve_injection` calls on an unchanged solution reuse
  the first call's work, also inside `batch` and `measure`; after an edit the next call reads the
  solution again.

### `find_implementations`

- **A closed generic query** (`find_implementations("IHandler<Saved>")`) lists only the types that
  implement the interface with that type argument; `typeArgumentFilter` counts the other closings
  and open generic bases, and an implementer whose closing could not be decided is marked
  `closing: "unresolved"`. An open query answers as before.
- **External interfaces through your own base types:** for an interface not declared in the
  solution (`IDisposable`), types that get it through a base class or interface of the solution
  are listed with `via: "inherited"`.

### Markup counts as usage

- **WPF XAML:** a handler wired to any event (`Loaded="OnLoaded"`, `SelectionChanged`, attached
  events, `EventSetter`) is a use of the code-behind method, and a property set in markup
  (attribute, property element, `Setter`, `Trigger`, `Condition`, attached properties also under a
  URI prefix such as `lib:`) is a use of that property. `find_usages` names the `.xaml`
  file and `find_dead_code` no longer lists such members. In Avalonia `.axaml` files, event wires and
  property sites are not read yet.
- **Blazor `.razor`:** members named in `@code` blocks, in code-block statements and in component
  parameter values written without `@` count, and so do calls through an injected member
  (`@inject`, `[Inject]`, also from `_Imports.razor`) or through the component's own fields and
  properties (a `@ref` field included). A component written only as a `.razor` file gets a note
  naming its file instead of a bare `not_found`.

### More code counts

- **Committed generated files are read:** a `*.Designer.cs` or `*.g.cs` that is part of the
  repository (designer halves, resource accessors, checked-in generator output) is analyzed, so its
  types and event wiring count and handlers wired in a designer file are no longer dead; the same
  names in build output stay out. Machine-written code itself is never reported by the quality
  tools. On WinForms code, effects reached through a designer's `InitializeComponent` now count
  toward the handwritten constructor that calls it.
- **Attributes at every position:** an attribute on a parameter, return value, type parameter,
  local function or lambda is a use of the attribute type; an assembly- or module-level attribute
  is credited to its file, shown as `<file> (assembly)` or `<file> (module)`.
- **Object creation in more places:** `new X()` in a constructor initializer (`: base(...)`,
  `: this(...)`), a finalizer, an operator, an indexer or event accessor, a primary constructor's
  base argument list or a C# 14 `extension` block is a use of `X`; a function pointer `&M` is
  credited to the overload it binds.
- **A checkout below a folder named `bin`, `obj` or `.vs`** (for example `~/bin/repo`) is analyzed
  normally; before, it showed no types.

### Same names in several projects

- `find_usages` and `impact_of_change` list **one item per declaration** behind a shared name, so
  `totalFound` counts users; such items add `project`, and a type also its
  `fullName`. `impact_of_change` follows
  its chain per declaration, `directCount` equals `find_usages`' `totalFound`, and `review_context`
  uses the same numbers. A referencing type's `files` no longer lists namesakes of other projects.
- `find_symbol` and `symbol_signature` keep two same-named types of two projects as two results,
  each with `project`.
- A method's interface and base contracts now come only from its own declaration, so a same-named
  type in another project no longer adds or removes them. `impact_of_change` (implementers and
  risk), `coverage_gaps` and usages credited through a contract can change where that happened.
- `get_type_hierarchy` lists **each derived type once**; where two would read alike, the line
  names the full name, and where even that is shared, the project in brackets.
- `find_production_dead` (Full Select profile) judges each declaration on its own and no longer
  reports a `partial class Program` of top-level statements.

### Loading at the right platform

- **A solution without an `Any CPU` platform** (only `x64` and `ARM64`, for example) is loaded at
  the platform a build of the solution uses by default, where one platform fits every project;
  before, some of its projects could lose their references. Solutions with `Any CPU` are unchanged.
- **The new sidecar key `designTimeBuildPlatform`** in `<Solution>.aicb.json` sets the platform
  yourself (`"designTimeBuildPlatform": "x64"`), for the MCP server, the CLI and the desktop app. A
  value the solution does not name, or one under which its projects build at several platforms, is
  refused, and the automatic rule decides. After editing it, call
  `refresh_session(force: true)`; `aicb analyze` prints the platform it takes from the key. Versions
  before 0.5.503.1 ignore the key.
- `get_diagnostics` reports the decision in `designTimeBuildPlatform` (`platform`,
  `solutionConfiguration`, `solutionPlatforms`, `projectsAtOtherPlatform`, `blockers`, `note`,
  `source: "sidecar"`, `refusedSidecarPlatform`).

### Answers that say what they could not see

- **`get_diagnostics` names projects whose restore wrote nothing** (`unrestoredProjects`), counts
  their unresolved-name errors and names the repair: `dotnet restore`, or `dotnet workload restore`
  where a workload is missing.
- **A source generator that did not run** is named on answers about the affected projects:
  `generatedCodeNote` on `find_usages`, `impact_of_change`, `instantiation_sites`,
  `find_tests_for`, `find_implementations`, `get_type_hierarchy` and `find_dead_code`, which also
  marks such candidates `missingGeneratedCode: true`; a zero-hit `find_symbol` or `symbol_signature` says so in
  `generatedSourcesNote`.

### Other changes

- **`architecture_overview` stays small on very large solutions:** the type-to-layer map lists
  every type up to 2,000 and per-layer counts above, and the truncation block names it;
  `export_markdown` keeps the full map. It is also much faster on very large solutions, and
  `solution_metrics`, `coverage_gaps` and `list_insights` are much faster on very large
  solutions.
- The README's GitHub Action example pins this release (`@v0.5.503.1` with `version: 0.5.503.1`).

## 0.5.502.1 (2026-10-13) - Usage answers name the file and line of every user, operators count as uses, and impact_of_change weighs what implements a contract

**Who is affected.** Everyone on the MCP server: reconnect your client once - 16 tools of the
default profile have a new description; no tool or parameter was added, removed or made
required. **Scripts that read `find_usages` or `impact_of_change` items as strings: read
`name`** - every item of `usedBy` and of `directImpact` is now an object `{name, file, line}`.
Exported documents change in their dependency lists and call lists (below). A snapshot, saved
session or remembered codebase from an earlier version is analyzed afresh the first time it is
used. The configuration database is not changed. Codex users: the first call on a large solution
no longer runs into Codex's 60-second tool limit once the entry carries the new timeout - run
`aicb init --force`, or add `tool_timeout_sec = 300` to the `aicb` entry by hand.

### Codex: a tool timeout for the first analysis

- **`aicb init` gives the Codex entry in `.codex/config.toml` a tool timeout of 300 seconds**
  (`tool_timeout_sec = 300`). Codex gives up on a tool call after 60 seconds by default, and the
  first call on a solution analyzes it, which takes longer than that on a large solution. An
  `aicb` entry that is already there is left as it is, so an earlier run's entry keeps the
  default: `aicb init --force` rewrites it with the line, or add the line by hand.

### Where every user is: file and line

- **`find_usages` names the file and line of every user.** Each `usedBy` item is now an object
  `{name, file, line}` instead of a bare string: `name` is the entry as before, `file` the file
  the user is declared in, relative to the solution and with forward slashes, and `line` the line
  its declaration starts on (the first attribute line when attributes precede it) - not the line
  of the reference. A type declared in several files lists them in `files` as `[{file, line}]`;
  an entry whose file is not known carries neither. **Breaking for a script that reads the items
  as strings: read `name`.**
- **`impact_of_change`'s `directImpact` items have the same shape** `{name, file, line}`, built
  by the same rule.
- Fields, properties and events carry the line their declaration starts on too, so a user that
  is a field or property initializer is placed by its member's declaration. Markup entries and
  top-level statements carry no line.
- **`symbol_signature` reports `line` for properties, fields and events**; it is null for an
  enum member and a source-generated property.

### Operators and conversions count as uses

- **A user-defined operator or conversion is now fan-in:** `a == b`, `a + b`, a cast and an
  implicit conversion are uses of the operator they call. `find_usages`, `impact_of_change` and
  `find_tests_for` resolve an operator by its metadata name, bare or qualified (`op_Equality`,
  `Money.op_Implicit`), with `resolvedKind` `operator`; `impact_of_change` follows its users like
  a method's callers. Before, operators had no fan-in.
- A record's compiler-generated `==` has no declaration and still answers `not_found`; the note
  names the operators the type does declare. When an operator has no recorded use, the note names
  the forms that leave none.
- `find_symbol`'s description no longer says operators have no fan-in.

### `impact_of_change` and contracts

- **On an interface or abstract method, `impact_of_change` lists what implements or overrides
  it** in `implementers` (per contract member: `count`, `testCount`, `typeCount`, `testTypeCount`,
  `members`) - what a signature change breaks - and **`risk` counts them**: it reads
  `riskBasis.total`, the production caller closure plus the production types that implement the
  member. The bands (0 none, 1-4 low, 5-20 medium, above 20 high) are unchanged, and
  `productionImpactCount` keeps its meaning.
- **On an interface or abstract class, `implementers` lists the implementing or deriving types**,
  one entry per declaration. The risk counts only the types that name the contract in their own
  base list; types that inherit it through a base class are listed under `indirect`.
- When two same-named interfaces or abstract classes in different namespaces declare the member,
  one entry carries their combined count and `namesakes` names each contract with its own
  implementing types. When no production code calls the contract, `riskBasis.note` says the risk
  comes only from its implementing types, and **`review_context`** puts the same sentence into
  the row's `note`.
- Where a dependency cycle makes the risk read the direct users, the `saturation` note names the
  implementing types added to that count.
- A generic outer type, or another type nested in it, is no longer listed as an implementer when
  only a nested type implements the interface (also in `find_implementations`).

### Constructors

- **Building an object reaches its constructor:** `new X(...)` is a call to the constructor it
  binds. `find_tests_for` lists a test that reaches a method through a constructor as
  `invokes-via`, `coverage_gaps` follows constructors (and the objects a field or property
  initializer creates), and `impact_of_change` follows a constructor to the code that constructs
  the type, so its transitive count and risk can rise.
- **Side effects travel through constructors:** a method that builds an object whose constructor
  writes a file, calls the network or logs carries that effect too, transitively, also through
  `: this(...)` and `: base(...)`. `find_by_side_effects` lists such methods; a field initializer
  counts toward the constructor that runs it.
- A test class's constructor, field initializers and event initializers count as test code, not
  as a production consumer, in `impact_of_change`, `coverage_gaps` and `find_production_dead`.
- A constructor and a method whose names differ only in letter case no longer share their side
  effects.

### Exported documents

- **A method's constructor calls are listed with its other calls:** `new OrderService(repo)`
  appears as `OrderService.OrderService(IRepository)` in the method graph, the used-by graph and
  the method's Calls list. External and non-public constructors are not listed.
- **Field and event types join the dependency lists** where a property's type of the same shape
  already did - fields of any accessibility, static, readonly or const (an enum constant names
  the enum), events of either form, including the element of an array, a nullable, a generic
  argument or a tuple; the referenced type's used-by list names the declaring type in turn.
- **A tuple element counts as used** inside a generic type (`Box<(Order, int)>`) and in an array
  of tuples, so such a type is no longer reported as unused.
- **Keyword types are no dependency entries:** `char`, `sbyte`, `ushort`, `uint`, `ulong`,
  `nint` and `nuint` join `int` and `string`, and so do keyword arrays (`string[]`), nullable
  keywords (`int?`) and `dynamic` - in the type-level lists and in a method's
  `<DEPENDENCIES> Types:` list. An array is judged by its element, so your own `Foo[]` stays, and
  a type you declare with a keyword-like name (`Char`, `Dynamic`) is listed instead of being
  hidden behind the keyword.

### Same-named types

- `get_type_hierarchy` keeps the inheritance between two types of the same simple name in
  different namespaces and writes that link with full names; a base type outside the solution
  that only shares a name with one inside ends the chain as external. With a bare name of
  several arities it says whose chain it shows (`mergedArities`).
- `find_overrides` finds the overridden member when the overriding type has the same simple name
  as its base, and names a row that stands for same-named types (`mergedNamesakes`).
- `explain_symbol`, `get_context`, `pack_for_task` and `prepare_task` render every type that
  shares the asked-for name, not just one of them; `pack_for_task` and `prepare_task` no longer
  add a same-named type their ranking left out. `explain_symbol`'s callers render a caller that
  references the symbol only through a field type or base list as its own declaration.
- `check_pattern_drift` takes `Type.Member` and `Ns.Type` and notes repeated and shared names;
  `symbol_metrics` and `calls_external` name the project of a row two projects compile alike;
  `assert_absence` names a namespace-qualified type in a `no_tests` claim.

### Empty answers say why

- When a name resolves to nothing, `nearest` also finds a declared name that begins like the
  query, and names the one type that declares a member asked for on the wrong type.
  `find_usages` and `impact_of_change` explain a `not_found` where they can (a member on a type
  that does not declare it, a namespace-qualified type name).
- `coverage_gaps`, `describe_api_surface` and a ranked `symbol_metrics` say when the scope
  matched no namespace, with the closest one.
- `find_unresolved_bindings` says how many binding sites it judged (`sitesJudged`) and skipped
  (`sitesSkipped`, by reason in `sitesSkippedBy`), so a zero has a denominator; on a session
  recalled from the database it again says its zero is not a measurement.

### Other changes

- **`describe_api_surface` lists public events**, by the same visibility rule as properties, and
  `diff_public_contract` reports a removed event as breaking and an added one as additive.
- The descriptions of `solution_metrics` and `check_solution_config_drift` say that an older
  database passed as `dbPath` is upgraded on open; neither tool writes anything of its own. The
  `save_session` description no longer says a snapshot loses its line numbers.
- `SECURITY.md` names the current update command, and the README's GitHub Action example pins a
  release (`@v0.5.502.1` with `version: 0.5.502.1`).

## 0.5.501.1 (2026-10-09) - `aicb init` sets up Codex and OpenCode, namespace exclusions keep what you name, and every answer about a session uses one layer profile

**Who is affected.** Everyone on the MCP server: reconnect your client once - 12 tools of the
default profile have a new description or a new parameter description; no tool or parameter was
added, removed or made required. Codex and OpenCode users: run `aicb init` again - it now
registers the server for these clients and writes the agent skill where they read it. Anyone
with a `.aicb.json`: it can now hold keep rules (`keepNamespaces`) and an explicit opt-out
(`exclusionsDisabled`); an earlier version ignores both. Anyone who analyzes without a
configuration database (`aicb analyze` without a session database, `aicb call` without
`--db-path`): the built-in namespace exclusion list now applies there too, so dependency lists
get shorter. Exported documents change in many places (below); the built-in MCP profiles'
template no longer embeds the source code of the whole solution. A snapshot, saved session or
remembered codebase from an earlier version is analyzed afresh the first time it is used. The
configuration database is updated the first time this version opens it (built-in tag schemas,
below). Desktop app users: automatic backup no longer delays the start, and the right-click
node-override editor is gone.

### Setting up Codex and OpenCode

- **`aicb init` registers the server for Codex and OpenCode**, which do not read `.mcp.json`:
  for each of them that the project uses, or that `--hooks` names, it writes the `aicb` entry
  into `.codex/config.toml` or `opencode.json` and writes the agent skill to `.agents/skills/`,
  where both read skills. Before, the server entry and the skill reached Claude Code only, and the
  run said so.
- `--hooks none` skips only the symbol guard; the server is still registered. To wire a client
  whose folder does not exist yet, name it: `aicb init --hooks codex` or `--hooks opencode`.
- Codex reads a project's `.codex/config.toml` only in a project you have trusted in Codex. The
  run ends with that sentence when it wrote the file.
- Your own `.codex/config.toml` is never rewritten: the entry is appended as a table of its own,
  and an `aicb` entry already there, in any TOML spelling, is kept.

### Namespace exclusions: keep rules, your own types, and the same list on every path

- **Keep rules.** A keep rule names a namespace the exclusion never drops - in `.aicb.json` under
  `"keepNamespaces"`, in the desktop app's exclusion list editor as the `Keep` column, and through
  `apply_solution_config` as `"keep": true` on an exclusion. Keep rules alone leave the built-in
  list in force beneath them, so a library whose subject is a framework area (for example Dapper
  and `System.Data`) needs one rule. Your own exclusion rules still replace the built-in list. A
  keep-only list for a solution applies over the app-wide list when one is set. An earlier
  version ignores `keepNamespaces` and drops it when it rewrites the file.
- **A type your solution declares is never dropped** because its namespace matches an exclusion
  rule: extension classes you declare in `Microsoft.Extensions.DependencyInjection` and your own
  nullable value types (`CallOptions?`) reappear in dependency lists. This also holds when only a
  type argument of a base type or interface names your type (`Basket : OwnBase<OrderLine>`).
- **Without a configuration database the built-in list applies**: `aicb analyze` without a
  session database, `aicb call` without `--db-path` and a server without a configuration
  database now exclude `System`, `Microsoft`, `Windows`, `Syncfusion` and `CommunityToolkit`
  like every path with a database. Before, they excluded nothing, so one solution's dependency
  lists depended on whether a database existed.
- **The document names its list:** the header carries `Exclusions:` with the list, its source
  and its rule count (keep rules counted apart), and `export_markdown` with `outputPath` names it
  in its confirmation. With keep rules over the built-in list, the line names the built-in list
  that does the excluding.
- A type whose dependencies were all excluded no longer reads "without external dependencies";
  it reads "no dependency outside the excluded namespaces".
- **A nullable value type is judged by the type it wraps:** a kept or third-party `Kind?` is
  listed as `Kind?` in every dependency list, `int?` and other nullable built-in types no longer
  appear under a rule for `System`, and nullable framework types are excluded by their own
  namespace. The same holds for pointers.
- **`"exclusions": []` keeps its old meaning** - no list of your own, the built-in list applies -
  as in every `.aicb.json` an earlier version wrote. To exclude nothing, write
  `"exclusionsDisabled": true`; a file exported for a solution set to exclude nothing now carries
  it, and so does a list whose rules are all empty. A rule list with entries but no usable rule is
  reported as a broken file instead of being read as no list.
- **`check_solution_config_drift`** calls a custom test profile stale when it misses more than a
  quarter of the projects named like tests (before: 3 or more, whatever the solution's size),
  counts a multi-targeted project once, and an `ok` answer no longer says "may be stale". It
  judges a keep-only list by the list beneath it that does the excluding: over a list that
  excludes nothing it answers `not-configured`, over a keep-only app-wide list it judges the
  built-in list.

### `.aicb.json` is never rewritten from a file aicb could not read

- **`apply_solution_config` and the desktop app's `Export Config` leave a `.aicb.json` they cannot
  read exactly as it is** - malformed, locked, or holding a keep rule inside `exclusions` - and
  refuse before anything is written. Before, every setting the call did not name was deleted,
  `analyzePreferredTfmOnly` included. A file that becomes unreadable while the database is
  written is left alone too; the configuration is saved to the database and a warning says the
  file was not written.
- `apply_solution_config` keeps the layer, exclusion and test settings of the existing file for
  every setting the call does not change; before, a layer-only or test-only call dropped them.
- Keys a version does not know are written back unchanged, a keep rule written inside
  `exclusions` is moved to `keepNamespaces`, the test attribute names keep the file's spelling,
  and a `keep` flag that is not a JSON boolean is rejected.
- A written file contains no rule with an empty pattern or layer. Writing no longer fails when
  another writer writes the same file at that moment, leaves no `.tmp` file beside the solution,
  and removes such files an interrupted earlier write left.
- `aicb analyze` warns when the `.aicb.json` exists but could not be read.

### One layer profile for every answer about a session

- **Every render and every judgement about a session uses the same layer profile** - from
  `analyze_solution`'s `layerProfile`, the `.aicb.json`, or the configuration database the session
  was analyzed against: `architecture_overview` and the `living_architecture` resource (its layer
  map), `export_markdown` and the `session_markdown` resource, `get_context`, `explain_symbol`,
  `pack_for_task`, `prepare_task`, and without a `dbPath` also `list_insights`, `get_insight`,
  `solution_metrics`, `diff_review` and `evaluate_change_set`. Before, the renders used the
  built-in heuristic while `list_insights` judged layer violations under the configured profile,
  and the judging tools read the server's default database. The quality profile still comes from
  the server's default database.
- In `export_markdown`'s full document, the layer-violation entries of QUALITY_FINDINGS are
  judged under the document's own layer profile instead of the built-in Clean Architecture
  convention.
- A layer profile the session took from the configuration database is read again on every call,
  so editing or deleting it applies without a new analysis; a profile passed explicitly or taken
  from the `.aicb.json` stays as analyzed. The `layerProfile` a session answer names
  (`analyze_solution`, `refresh_session`, `list_sessions` and the other session answers) is the
  one the other answers apply.
- **The configuration database is read, never written, for this:** a locked, damaged or missing
  database no longer fails a render, and none is created. An app-wide default of "No mapping"
  counts as nothing configured, as it does for the analysis.
- **An answer says when that database could not be used** - locked, damaged, not an aicb
  database, or renamed or deleted since the analysis: a `configDbNote` member on a JSON answer, a
  `<!-- config-db: ... -->` comment on a Markdown answer (after a tag answer's frontmatter), and an
  extra content block on `list_insights` and the session resources. `list_sessions` names every
  session whose database cannot be read. When the layers fall back to the built-in convention
  because the `.aicb.json` cannot be used, the answer says why. A resource read no longer fails
  its size limit only because such a note was added.

### Exported documents

These apply to every Markdown output - `export_markdown`, `get_context`, `explain_symbol`,
`pack_for_task`, `prepare_task`, `aicb analyze` and the desktop app's export - unless a line names
fewer.

- **The built-in `AI Optimized` template, used by the built-in MCP profiles, no longer embeds the
  source code of the whole solution.** The new built-in template `AI Optimized + Source` keeps it.
  An existing configuration database picks this up unless you edited or hid the template.
- **Each line of code is printed once.** A `TYPE_CODE` or `METHOD_CODE` block is left out when its
  file's `FILE_CODE` block, or a type code block printed earlier in that file, already holds the
  code. Under the default profile a whole-solution export no longer prints code three times. A
  class picked with source while its file is not still gets its `TYPE_CODE`.
- **A template that embeds source** follows its MD profile's Source rule per kind, as the desktop
  app's tree already did: classes, records and plain structs keep their structure and lose only
  their own code block where the profile does not allow Source for classes.
- **Types carry `<SUMMARY>` and `<USED_BY>` blocks.** A class, interface, record, struct or enum
  with an XML `<summary>` now prints it, as methods always did, and a type lists the types that
  reference it by namespace-qualified name (in a slice, those the slice contains). Both were in
  the legend and never printed. Doc text whose elements stand on separate lines keeps a space
  between them.
- **Entry points:** `ENTRY_POINTS` and `ENTRY_POINT_FLOW` list a `private` or `internal`
  `static Main` of a valid entry-point shape, and a program written as top-level statements under
  its file label (`ConsoleApp/Program.cs (top-level) -> DR.RunAll()`).
- **Roles:** a class that derives from an ASP.NET controller through its own base classes gets
  the role `Controller` (and the layer `Presentation`), every class deriving from
  `System.Attribute` the role `Attribute`, and an attribute that implements an ASP.NET request
  filter interface the role `Middleware`; a filter-factory attribute stays `Attribute`. Methods of
  `Middleware` types appear as sources in `METHOD_GRAPH` and `METHOD_USED_BY_GRAPH`, and those that
  call into the project with a dependency, side effect or infrastructure use are listed as entry
  points. `find_by_semantics` follows the same roles.
- **Explicit interface implementations and accessors:** `USED_BY` names such a caller by its type
  and interface (`Order.IComparable.CompareTo(object)`, `Order.Total.get`) and lists every caller
  once; `METHOD_GRAPH` and `METHOD_USED_BY_GRAPH` include explicit implementations as callers. Two
  callers whose short labels would coincide print their qualified names. An expanded selection
  that follows callers keeps a property, indexer, event or constructor caller's type.
- **Parameter lists read the same on both sides of an edge:** in METHOD_GRAPH, METHOD_USED_BY,
  ENTRY_POINT_FLOW and the dependency lists a called method's parameter types are simple names
  (`Helper.Work(Payload)`), as on the calling side. Documents get shorter.
- **Dependency lists** name the types carried as type arguments of a type's member and base types
  at any depth (`List<OrderItem>` names `OrderItem`), keep a same-named type from another
  namespace and a non-generic type of the same name, and no longer list a tuple as a type or a
  generic type as its own dependency. A method's `Types:` list shows a tuple's element types
  instead of the tuple; a body using an array of tuples counts their element types.
- **Afferent coupling:** Ca counts references written inside a generic argument, an array or a
  nullable, and generic types are counted at all (they showed `n/a` or 0). Where several types
  share a simple name and a reference cannot be attributed, it is shown beside Ca, never in it: a
  type tag may carry `ca-ambiguous="N"`, QUALITY_HOTSPOTS prints `(+N ambiguous)`, and
  `solution_metrics` adds `caMaxNote` when the maximum could be higher.
- **Context sentences:** a method's `Context:` no longer claims purity: "Delegates work to other
  project methods." and "Self-contained: calls no other method." replace the two sentences that
  said "without side effects".
- **YAML:** exports that embed source keep their structure when a source file itself contains
  Markdown code fences (for example in a C# raw string) - before, the rest of the document could
  end up inside one text value. Embedded text reads back exactly, characters YAML cannot carry
  literally are escaped, and values and keys a YAML 1.1 reader would take for another type
  (`TRUE`, `ON`, `.inf`, a date, `<<`) are quoted. The `llm-natural-md` field format fences a value
  holding backticks with a longer fence.
- **The 8000-token floor is named:** a budget below it is raised as before, and the document's
  budget header, or the answer of `get_context`, `explain_symbol`, `pack_for_task` and
  `prepare_task`, now says `(requested 300, raised to the 8000 floor)`; on a YAML render as a
  `# budget: ...` comment.
- `export_markdown` treats a `format` that is neither `tag` nor `yaml` as omitted - the profile's
  format applies - and starts its answer with a note naming the ignored value. Before, any value
  rendered tag.

### MCP tool answers

- **`resolve_injection` names the registration a resolve receives:** a new field
  `effectiveRegistration` appears when two or more registrations match: the one a
  single-service resolve receives, read only where the order is certain within one
  straight-line registration method, else `winner: null` with the reason. Keyed registrations carry their `key`; two keys are two
  services, not `ambiguous`, and the three-argument `AddKeyed*(Type, key, Type)` and
  `AddSingleton(typeof(X))` forms are read.
- **References and callers:** a method with a `ref`, `in`, `out` or `ref readonly` parameter is
  listed with the modifier (`App.Parser.Read(ref int)`) by `find_usages`, `impact_of_change`,
  `call_graph` and `explain_symbol`, and an overload pair that differs only there is now two
  methods with their own callers, side effects and dead-code verdicts. A `calls_external` pattern
  with a parameter list spells an external by-ref parameter with its modifier
  (`TryParse(string, out int)`); a bare member name matches as before.
- `find_usages`, `impact_of_change`, `find_tests_for` and `coverage_gaps` credit the callers of an
  explicit interface implementation whose interface has a tuple type argument or is nested in a
  generic type. `find_usages` counts a caller in an explicit implementation or an accessor for
  the type that declares it (`selfReferences`, `textuallyInvisibleUsers`), and `explain_symbol`
  with `include: callers` lists such callers instead of answering `(none)`.
- **`impact_of_change`** says when a high-risk closure runs through a dependency cycle every
  symbol reaching it shares: a new `saturation` block names the cycle, and `risk` is then graded
  by the direct production users. `review_context` and `diff_review` carry the same risk.
- `get_type_hierarchy` and `find_implementations` count a tuple type argument as one argument
  (`Base<(int, int)>` is a reference to `Base<T>`).
- A type's accessibility comes from the compiler's view of the whole type: a `partial` type whose
  modifier is written on one part only, and a type without a modifier, are no longer reported as
  `private`, and `find_symbol` lists such a partial type once. A markup extension used in element
  form (`<local:Foo .../>`) counts as a reference to `FooExtension`, so `find_dead_code` no longer
  reports it dead.
- `solution_metrics` adds `debtApprox` beside `debtMinutes` (`"~29.7 d"`, 1 d = 8 h); both
  descriptions now say the minutes are a coarse estimate from fixed rules, not measured effort.
- `pack_for_task` and `prepare_task` no longer add same-named methods of other types (a second
  `Program.Main`) when the goal matched only one of them.
- `aicb import` and `import_constellation` refuse a file whose preview found a problem - a tag
  schema source outside the allowed list, an item without an id, an application-settings key that
  is not allowed or does not convert - with nothing written; before, the other items were written.
  An item that still fails at save time is named, and the warning says the rest stays written.

### Command line

- `aicb analyze` writes its document - directly, with `--emit-session-db` / `--session-db`, and
  with `--run-template` - under the layer profile its analysis and quality gate use, so the layer
  map matches the gate.
- `aicb call` records each call in the usage telemetry when it is given `--db-path`, under the
  client name `aicb-call`; `usage_report` counts it. It also prints the note about an unreadable
  configuration database, as the server's answers carry it.
- On Windows, when `APPDATA` is unset, empty or blank (some MCP clients start servers with a
  reduced environment), settings, the database, `aicb.mcp.json` and the logs resolve to your
  application-data folder instead of a relative `%APPDATA%` folder under the working directory.

### Desktop app

- **Automatic backup no longer delays the start.** It runs in the background once the main window
  is open and takes a consistent copy of the database while the app, and any `aicb mcp` server on
  the same database, keep working - a database another program had open was left out before
  (`-partial`). Other database files under the data folder are no longer packed into every
  backup, an interrupted backup no longer leaves a file that looks finished, and `Backup now` can
  run during an analysis. Automatic backup is on for new installations; existing ones keep their
  setting (Settings > Storage). A backup no longer shows as an active run in the Run Templates
  tab, and a database switch made during a backup waits for it instead of being undone.
- **The right-click node-override editor is removed** - the `Set Node Override...` menu entry, its
  dialog and the tree's red override dot. A right-click on a tree row opens nothing. The detail
  pill is unchanged.
- **Tag schemas you create reach the export:** picked in an MD profile's Class, Interface, Enum or
  Method row, or in the Sections panel, a schema becomes the first lines of every such block, and
  a copy of a built-in block replaces just that block. The SOLUTION, PROJECT and FILE header
  lines can be changed through their schemas. Settings > Tag Schemata says under each schema
  where it shows up, offers only source paths that produce output, flags a field whose path is
  no longer offered, and prints the declarations of class, interface and method fields readably.
  Twenty built-in schemas that never showed up in an export are gone; a profile or saved run that
  picked one shows the header schema that renders in its place.
- **The solution tree tells same-named members apart:** rows show type parameters, `ref` / `in` /
  `out`, the interface of an explicit implementation and a nested type's containing type, and a
  saved session reopens its selection and detail levels on the row they were made on. An entry of
  an earlier session that could belong to two such rows is listed as not found. Selecting one of
  two methods that differ only there exports that method alone.
- The selection strategies "Deep" and "Test-Coverage-Reachable" follow the types that reference
  a selected type.
- Changing a node's detail level changes the generated context at once; before, a level stored in
  the opened session could win until the app restarted.
- An exclusion list restored from the `.aicb.json`, its opt-out and a generated list take effect
  at once, and the Solutions tab's picker shows it. A GUI analysis filters with the list in force
  when it starts.
- `Export Config` writes back the suppressions only the file holds, but not one you lifted in the
  Insights panel, and keeps the file's settings for every axis the solution has no choice of its
  own for; the confirmation names what it kept and counts what it wrote. `Import Config` takes keep
  rules, the test axis and `exclusionsDisabled` from the file and keeps a `Strict` layering policy.
  A GUI export with a layer profile judges its QUALITY_FINDINGS under it and writes no insight run
  into the history.
- A settings panel that refuses a save keeps your input in the editor and shows the stored entry
  in the list, and a built-in entry is no longer left marked "Overridden"; an entry an earlier
  version marked that way is put right with Restore.
- Imports: Settings > Constellations lists the problems a preview found and disables Apply; a
  panel import refuses the whole file and names the first problem.
- The pipeline-profile editor names the 8000-token floor of Max Token Budget, refuses a new value
  below it, marks a stored one, and raises an imported value with a notice.
- A dialog that appears during startup (database newer than the build, migration failed,
  unfinished runs, MSBuild not found, a startup error) is shown in front with the keyboard focus
  instead of behind the splash.
- The debt label rounds before it picks its unit (477 to 479 minutes read `~1 d`). The built-in
  LLM prompts that ask for severity words show the marker where the findings parser reads it. The
  MCP usage panel's Batch column counts sub-queries that answered.

### In the repository

- **A GitHub Action** at the repository root runs the quality gate in one step: it sets up the
  .NET 10 SDK, installs the tool, restores the solution and runs `aicb analyze`
  (`uses: gregordadera/aicb-roslyn-mcp@main`); see the README.
- **The container runs as a non-root user.** Run it as the owner of the mounted folder and
  restore the solution inside it first; the README shows the commands.

### Data

- A snapshot, saved session or remembered codebase from an earlier version is analyzed afresh the
  first time it is used.
- The configuration database is updated the first time this version opens it: the built-in tag
  schemas that never reached an export are removed, and an MD profile rung or a saved session
  that named one now names the schema that renders in its place.

## 0.5.500.1 (2026-10-04) - Runs on .NET 10, loads classic .NET Framework projects, and every tool description fits in 2048 characters

**Who is affected.** Users of the .NET tool: it now needs **.NET 10**. A machine that has only
.NET 8 or .NET 9 cannot start this version - install the .NET 10 SDK first, then update. The
Windows installer and the portable ZIP bring their own runtime and need nothing beyond the usual
update. Anyone with classic (non-SDK-style) .NET Framework projects: such a solution now loads.
Everyone on the MCP server: reconnect your client once - 32 of the 54 tools of the default profile
have a new description, and every tool now lists a title and the MCP annotation hints. Several
answers are sharper: `find_dead_code` lists unused private methods, `find_tests_for` finds the
tests that read a property or field. Callers that pass a `dbPath` to a tool that only reads a
database: a path that does not exist is now an error. The configuration database does not
change. A snapshot or remembered codebase saved by an earlier version is analyzed afresh the
first time it is used, and the first open of each solution after the update runs its full
design-time build once.

### The .NET tool needs .NET 10

- **The .NET tool `aicb-roslyn-mcp` runs on .NET 10** and needs the .NET 10 SDK; up to 0.5.465.11
  it was .NET 8. Without .NET 10 it runs on the next newer .NET on the machine and needs that
  version's SDK. A machine that has only .NET 8 or .NET 9 cannot start it.
- **Updating:** install the .NET 10 SDK, then `dotnet tool update -g aicb-roslyn-mcp`. The
  requirement concerns the machine `aicb` runs on, not the solutions it analyzes: their target
  frameworks are supported as before.
- Beside a .NET 10 runtime the .NET 8 and .NET 9 SDKs are found as well. An SDK newer than the
  .NET the tool runs on is not (for example a .NET 10 runtime next to only the .NET 11 SDK). The
  environment variable `DOTNET_ROLL_FORWARD=LatestMajor` makes the tool run on the newest .NET; a
  preview .NET additionally needs `DOTNET_ROLL_FORWARD_TO_PRERELEASE=1`.
- **The message for an MSBuild that could not be registered says what to install:** it names the
  .NET the tool runs on, asks for that version's SDK and names the two switches above. Before, it
  asked for the .NET 8 SDK whatever the tool ran on.
- **The Windows installer and the portable ZIP bring the .NET 10 runtime** instead of .NET 8.
  Analyzing a solution still needs MSBuild on the machine - a .NET SDK or Visual Studio.
- **In a container:** the repository's `Dockerfile` builds on the .NET 10 SDK image. The earlier
  file installed the newest tool onto the .NET 8 SDK image, which cannot start this version; build
  from the current file.
- **The analysis runs on Roslyn 5.9.0** instead of 5.3.0. A source generator built for a newer
  compiler than the host's cannot be loaded and is listed under `generatedCodeGaps`; with 5.3.0
  that included the Razor compiler of a current .NET 10 SDK. Such projects are compiled with their
  generated code again.
- `THIRD-PARTY-NOTICES.txt` follows the new components, among them Roslyn 5.9.0 and SQLite 3.53.4.

### Classic .NET Framework projects load

- **A solution that contains a project in the classic, non-SDK format loads.** Up to 0.5.465.11
  one such project could fail the whole solution, its SDK-style projects included. Classic projects
  are built with the .NET Framework MSBuild, so they need Windows with Visual Studio or the Build
  Tools for Visual Studio, and the .NET Framework targeting pack the project names.
- **Without Visual Studio the load does not fail:** the loader uses the .NET SDK's MSBuild instead.
  When a classic project fails then, `get_diagnostics` marks its entry under
  `designTimeBuildFailures.projects` with the new field `missingMSBuild` (`visual-studio`, or
  `mono` on Linux and macOS), and the `note` says what to install - neither `dotnet restore`
  nor another .NET SDK brings the missing MSBuild.
- **The COM references of a classic project resolve on x64 Windows.** The interop assemblies the
  analysis generates for them go into a folder of its own,
  `%LOCALAPPDATA%\AIContextBuilder\design-time-build`, not into the project's `obj` folder, so
  your own build and the analysis leave each other's interop assemblies alone. The new
  environment variable `AICB_DESIGN_TIME_BUILD_DIR` names another folder, or switches this off
  with `0`. The first load of a project with COM references generates them and can take a
  minute; later loads reuse them. After a COM library is updated or registered again on the
  machine, the next load in a new process imports it again; a running server needs
  `refresh_session(force: true)`.
- **Two aicb processes that load the same classic project with COM references for the first time
  wait for each other** instead of colliding in that folder. The lock sits beside the interop
  folder; a process that waited five minutes builds anyway.
- **A COM reference that still does not resolve** - its library is not registered on the
  machine, the project is SDK-style, or the host is not an x64 Windows - is in most cases listed
  in the new field `comReferences` of the same entry, and the `note` names the way out: reference
  an interop assembly, or install what registers the library. The errors that name types of such
  a library are fallout of the missing reference, not findings about the source.
- **`analyze_solution`** says so when a load fails because the MSBuild of the chosen Visual Studio
  installation could not be loaded and the solution names classic projects: repair that
  installation, or analyze a subset solution without the classic projects.
- The `docs` tool's overview page describes the case.

### Tool descriptions, titles and annotation hints

- **Every tool description is at most 2048 characters.** Claude Code passes only the first 2048
  characters of a tool description to the model, and in 0.5.465.11 the descriptions of 21 of the
  54 tools of the default profile ran past that. The rewritten texts say what the tool does, when
  to use it, what comes back and what it writes.
- **Tools with a new description** (37 of all 82, 32 of them in the default profile):
  `analyze_solution`, `batch`, `calls_external`, `check_solution_config_drift`, `coverage_gaps`,
  `detect_circular_dependencies`, `export_markdown`, `find_binding_usages`, `find_by_code_traits`,
  `find_by_concurrency_risk`, `find_by_event_subscription`, `find_by_resource_leak`,
  `find_by_semantics`, `find_by_side_effects`, `find_dead_code`, `find_implementations`,
  `find_overrides`, `find_production_dead`, `find_resource_usages`, `find_structural_twins`,
  `find_tests_for`, `find_unresolved_bindings`, `find_usages`, `get_diagnostics`,
  `get_type_hierarchy`, `impact_of_change`, `init_solution_config`, `instantiation_sites`,
  `prepare_task`, `resolve_injection`, `review_context`, `save_session`, `server_info`,
  `solution_metrics`, `symbol_metrics`, `symbol_signature`, `usage_report`.
- **The `sessionId` parameter says that it also takes a solution path:** in every tool but one
  that has the parameter, its text now names the absolute `.sln`, `.slnx` or `.slnf` path,
  analyzed on first use. No tool, parameter or response field was added, removed or renamed by
  the rewrite.
- **Every tool lists a `title` and the four MCP annotation hints** - `readOnlyHint`,
  `destructiveHint`, `idempotentHint` and `openWorldHint` - in `tools/list`; none did before.
  Eleven tools are not read-only: `analyze_solution`, `refresh_session`, `recall_codebase`,
  `save_session`, `diff_review`, `export_markdown`, `install_agent_hooks`,
  `apply_solution_config`, `remember_codebase`, `refresh_remembered` and
  `import_constellation`; the last six are marked destructive, because they can overwrite a file
  or a stored entry. Six of the eleven are in the default profile. A client that decides by these
  hints whether to ask before a call can now tell the writers from the 71 readers.
- The help text of `aicb mcp` and of its `--db-path` option is reworded; no option changed.

### Sharper answers

- **`find_dead_code` lists private methods that nothing calls.** With `kinds='method'` (the
  default) it effectively listed none before. Methods a framework calls are declined, not judged,
  and counted in the new field `methodsIneligibleFrameworkInvoked`: those carrying `[RelayCommand]`
  or another framework attribute, partial methods, event handlers of markup code-behind and
  designer types, a static `Main`, a record's `PrintMembers`, and a `ShouldSerialize<P>` or
  `Reset<P>` method beside a property `P`. `methodsIneligibleUnanalyzedCallers` now counts only
  methods whose callers were not measured. The insight `quality-dead-code-private`
  (`list_insights` and the desktop app) uses the same rule and reports findings for the first
  time; a comparison against a snapshot saved by an earlier version shows them as new.
- **More callers are recorded** in `find_usages`, `impact_of_change` and `call_graph`: a
  `nameof(M)` inside a method's own attribute (`[RelayCommand(CanExecute = nameof(CanSave))]`,
  `[MemberData(nameof(Cases))]`) counts that method as a caller of `M`; so do the bodies of
  operators, conversions and finalizers, the arguments a primary constructor passes to its base,
  and a type's `[DebuggerDisplay]` format.
- **`find_tests_for` finds the tests that read or write a property or field.** A property or field
  query matched test names only before; it now matches tests that access it, under the new
  `matchReason` values `accesses` and `accesses-via` (strong, ranked after the calls). A type query
  also counts tests that read the type's static members, and `invokesTotal` includes these rows. A
  `Type.Member` query matches a test by name only when both names appear. `assert_absence` with
  `no_tests` counts the reading and writing tests in its reason.
- **Qualified names:** `symbol_signature` takes `Type.Member` and qualified type names (`Ns.Type`,
  `Outer.Inner`); `symbol_metrics` takes `Type..ctor` for one type's constructors. A qualified query
  that resolves to nothing, but whose last part is a declared name, answers `not_found` with that
  name as `nearest`. `find_overrides` (on an empty answer) and `get_type_hierarchy` (on `not_found`) now
  carry `nearest` too.
- **Same-named symbols of another kind:** `impact_of_change` has a new field `collision` that names
  them, ahead of the counts, which still describe the resolved symbol; `find_usages` names them in
  more cases, also when the answer is a type.
- **`find_resource_usages`** reads the `ResourceKey=` forms - `{StaticResource ResourceKey=X}`,
  `{DynamicResource ResourceKey=X}` and the element `<StaticResource ResourceKey="X" />`. With a
  `scope` it says what the solution holds outside that scope; before, a scoped call could answer
  that a key existed nowhere in the markup when it existed outside the scope.
- **`instantiation_sites`** steers only to interfaces something in the solution is injected
  under, and on an empty answer names the markup views that use the type.
- **`detect_circular_dependencies`** marks a cycle whose witness list was cut at 50 edges with the
  new field `edgesTruncated`.
- **`get_diagnostics`:** under `generatedCodeGaps` a generator that loads and then fails is named
  with the new kinds `cannot-run` (it needs a newer version of an assembly than the .NET the tool
  runs on; the note names `DOTNET_ROLL_FORWARD=LatestMajor` or an SDK pinned in `global.json` as
  the repair) and `run-failed`. `designTimeBuildFailures` no longer lists a restore warning that
  every build repeats (a NuGet audit warning) or a solution entry in a language aicb does not load
  (`.shproj`, `.dcproj`), and its note says that MSBuild reports a warning the way it reports an
  error.
- The note on generated sources that `find_symbol` and `symbol_signature` add to an empty answer
  no longer counts generated files that declare no type.

### Faster repeat opens

- **A solution with a NuGet audit warning or a `.shproj` or `.dcproj` entry is now cached** like
  any other, so opening it again no longer repeats the full design-time build.
- Editing a shared project's `.projitems` file invalidates the cached build of the solutions that
  include it.

### A reading tool does not create a database

- **A tool that only reads a database refuses a `dbPath` that does not exist.** The error starts
  with `dbPath not found: <path>. This tool only reads the database and does not create one` and
  names the tools that do create it. Before, such a call created the folder and an empty database
  at the path and answered from it.
  This applies to `analyze_solution`, `diff_review`, `solution_config_status`,
  `check_solution_config_drift`, `list_insights`, `get_insight`, `solution_metrics`,
  `evaluate_change_set`, `compare_with_previous`, `diff_public_contract`, `list_remembered` and
  `recall_codebase`, and to the resource `acb://snapshots/{hash}`.
- The tools that write keep creating the database: `apply_solution_config`, `save_session`,
  `remember_codebase` and `refresh_remembered`. A call without `dbPath` is not affected.
- **`aicb call --db-path <path>` follows the same rule:** for a tool that writes, a database that
  does not exist is created; for a read-only tool the call is refused with
  `--db-path not found: <path>`.
- A configuration database deleted while the server runs is no longer re-created as an empty file
  when the server records a call.

### Solutions the desktop app has not registered

- **`save_session`, `remember_codebase`, `apply_solution_config` and `aicb analyze
  --emit-session-db` no longer switch on automatic configuration for a solution the desktop app
  has not registered.** The desktop app still switches it on when it registers the solution.
  `apply_solution_config` keeps the `autoInit` block a committed `.aicb.json` already has instead
  of writing one of its own, and so does the desktop app's configuration export.
- The `configInit.directive` of `analyze_solution` says where the setting is stored and that it
  is a stored setting, not a request made in the conversation.
- `save_session` called with a solution path returns the session id as `sessionId`, not the path.

### Memory, and files saved during an analysis

- **The MCP server and the desktop app give memory back after a load.** About two seconds after
  an analysis, a recall, an evicted session or a larger refresh (the server), or after a solution
  has finished loading (the desktop app), the process returns the memory the load no longer needs.
  The environment variable `AICB_MEMORY_TRIM=0` (also `off` or `false`) switches this off.
- **Reloading a solution no longer keeps the previous load in memory.** In a long-running
  process every full reload added to the memory in use.
- **A file saved while an analysis runs is picked up by the next refresh.** `analyze_solution`,
  `remember_codebase`, `refresh_remembered` and the desktop app take the file baseline of a
  session before they read the solution. Before, it was taken after the analysis, so such a file
  could count as current although the analysis held its old content.

### Package

- The description of the package on nuget.org names what the server does in the words people
  search for: semantic code analysis, navigation, the impact of a change, dependency injection
  and refactoring.

## 0.5.465.11 (2026-09-30) - The .NET tool is now `aicb-roslyn-mcp`, and every tool applies a solution's configuration in the same order

**Who is affected.** Users of the .NET tool: the NuGet package has a new name, and an existing
installation is switched once by hand (below). Anyone who commits a `.aicb.json` next to a solution
or configures solutions in the desktop app: `analyze_solution`, the memory tools,
`solution_config_status`, `check_solution_config_drift` and `aicb analyze` now apply and report one
and the same configuration. The Windows installer and the portable ZIP need nothing beyond the
usual update. No database change; saved snapshots stay valid. If your client caches tool
descriptions, reconnect it once - the descriptions of `analyze_solution`, `solution_config_status`,
`check_solution_config_drift`, `remember_codebase` and `recall_codebase` changed.

### The .NET tool is now the NuGet package `aicb-roslyn-mcp`

- **The MCP server and CLI are published on nuget.org as
  [`aicb-roslyn-mcp`](https://www.nuget.org/packages/aicb-roslyn-mcp)** - up to 0.5.465.1 the package
  was called `AIContextBuilder`. The command stays `aicb`, and the MCP Registry entry
  `io.github.gregordadera/aicb-roslyn-mcp` names the new package.
- **Switching an existing installation:** `dotnet tool update` does not cross the rename. Run
  `dotnet tool uninstall -g AIContextBuilder`, then `dotnet tool install -g aicb-roslyn-mcp`. An MCP
  client configuration that starts the `aicb` command needs no change; one that starts the package
  itself with `dnx AIContextBuilder` needs the new name.
- The package `AIContextBuilder` stays on nuget.org with its versions, is marked deprecated with a
  pointer to the new name, and receives no further versions.
- The Windows installer removes an existing .NET tool under either name when you let it. Winget keeps
  the identifier `GregorDadera.AIContextBuilder`.
- The package carries the tag `aicb`, so a nuget.org search for the command name finds it.

### One order for a solution's configuration

- **`analyze_solution`, `solution_config_status`, `check_solution_config_drift` and `aicb analyze`
  resolve a solution's namespace exclusions, layer profile, test profile and analysis scope in one
  order:** an explicit parameter, then the configuration database (a choice made for this solution,
  then the app-wide default), then the `.aicb.json` committed next to the solution, then a built-in
  default.
- **A built-in default no longer overrides a committed `.aicb.json`.** Where the configuration
  database only falls back to the built-in exclusion list, or its app-wide default is the `Empty`
  layer preset or the default test profile, the `.aicb.json` now applies. Before, `analyze_solution`
  then analyzed with the built-in exclusion list while `solution_config_status` named the
  `.aicb.json` as the source. A choice made for one solution still wins over the `.aicb.json`, even
  when it names a built-in - that is how a single solution opts out of the committed profile.
- **`solution_config_status` and `check_solution_config_drift` report the configuration in force**,
  the one an analysis of the solution runs on, each with its `source`: `explicit`, `db`, `sidecar`,
  `none`, or the new `built-in` for the built-in exclusion list. `check_solution_config_drift`
  evaluates that configuration instead of whichever `.aicb.json` it found.
- **`aicb analyze` uses the test profile of a `.aicb.json`** for test-project detection in the
  quality gate and the snapshot's debt, and prints on stderr which layer or test profile it takes
  from the `.aicb.json`, as it already did for a configured one.

### The memory tools analyze like `analyze_solution`

- **`remember_codebase`, `recall_codebase` and `refresh_remembered` apply the same configuration as
  `analyze_solution`** - the configuration database first, then the `.aicb.json`, then a built-in
  default; an explicit `layerProfile` on `remember_codebase` still wins. Before, they read only the
  `.aicb.json`, and from it only the exclusions and the analysis scope: no layer profile unless one
  was passed, no test profile, never the configuration database. On the default `aicb mcp` server a
  remembered session could therefore show other dependencies than `analyze_solution` on the same
  solution, and a recalled session classified test projects by the built-in default whatever the
  repository pinned. A configuration database that cannot be opened now fails the recall, as it
  fails an analysis.

### Fixed

- **Asking `solution_config_status` or `check_solution_config_drift` about a solution no longer
  registers it in the configuration database.** The first such question created an entry for the
  solution whose defaults made the next `analyze_solution` state in `configInit.directive` that the
  user had opted the solution into automatic initialization, which nobody had.
  `apply_solution_config` still creates the entry, since it has a configuration to store.

## 0.5.465.1 (2026-09-29) - New repository name, starts without .NET 8, calls through interfaces are credited to their implementations

**Who is affected.** Everyone: the repository has a new address (every old link keeps working), and
the MCP Registry lists the server under a new name. Users of the .NET tool can now start it on a
machine without .NET 8. Everything else concerns the MCP server and the `aicb` CLI: `find_usages`,
`impact_of_change`, `find_tests_for`, `coverage_gaps` and the tools that repeat their numbers,
`analyze_solution` and the session tools, `export_markdown`, `refresh_session` and
`evaluate_change_set`. No database change; saved snapshots stay valid. If your client caches tool
descriptions, reconnect it once - several descriptions changed.

### New repository address and MCP Registry name

- **The repository moved to `github.com/gregordadera/aicb-roslyn-mcp`** (it was
  `github.com/gregordadera/AICB`). GitHub forwards every old link, clone URL and release download,
  so nothing you set up breaks; update bookmarks and git remotes when convenient. The nuget.org
  package `AIContextBuilder` and the `aicb` command keep their names.
- **The MCP Registry lists the server as `io.github.gregordadera/aicb-roslyn-mcp`.** The previous
  entry `io.github.gregordadera/aicb` keeps its published versions and is marked deprecated with a
  pointer to the new name. Clients that already run the server need no change: they start the
  `aicb` command, not the registry name.
- The desktop app's About page and the `docs` tool link to the new address.

### Listed as an MCP server on nuget.org

- **The NuGet package carries the MCP server package type** next to the .NET tool type, and it
  packs its `server.json` as `.mcp/server.json`. nuget.org lists packages of that type in its MCP
  server filter and builds a client configuration from that file. An existing installation needs
  no change.

### Starts where only a newer .NET is installed

- **The .NET tool now also starts on a machine that has no .NET 8 runtime but a newer one.** It then
  runs on the next newer .NET on the machine and needs that version's SDK, so just the .NET 10 SDK
  works. That is what the configuration nuget.org offers needs: it starts the tool with `dnx` from
  the .NET 10 SDK, and neither `dnx` nor a global install switches to a newer runtime on its own.
  Tested in an environment that holds only the .NET 10 runtime and SDK: the tool starts through
  `dnx` and as a global install, analyzes a `net8.0` and a `net10.0` solution, and answers as an MCP
  server. Where .NET 8 is installed, the tool keeps using it and nothing changes.
- **If the .NET it runs on has no SDK of its own** (for example a .NET 9 runtime next to the .NET 10
  SDK), the tool reports that MSBuild could not be registered. Install the .NET 8 SDK, or set the
  environment variable `DOTNET_ROLL_FORWARD=LatestMajor` so that it uses the newest .NET.
- The installer and the portable ZIP bring their own runtime and are not affected.

### A call through an interface is credited to the implementing method

- **`find_usages` and `impact_of_change` credit a call through an interface or abstract member to
  the method that implements it.** Such a call binds to the interface member, so a qualified method
  query (`Type.Method`) used to miss it, and a method called only through its interface looked
  unused. Those callers are now listed and counted, and `viaContract` says how many were credited,
  through which members and how many types implement each; `viaContractNote` says whether the credit
  is exact (one production implementation) or a union over several. A method in a test project is
  never credited.
- **`find_tests_for` adds the tiers `dispatch` and `dispatch-via`** for a test that calls an
  interface or abstract member the symbol implements, directly or through one method it calls. They
  rank behind the strong tiers and are counted in `dispatchTotal`, because the test may have run a
  sibling implementation or a test double instead.
- **`coverage_gaps` marks with `viaDispatch` a method that only such a test reaches.** Every other
  entry keeps the depth it had.
- **The tools that repeat these numbers carry the qualifier with them.** `review_context` and
  `diff_review` include `viaContract`, `viaContractNote` and `dispatchTotal`; `explain_symbol` says how
  many of the callers call the contract; `verify_claim` with `symbol_removed_unused` answers
  `indeterminate` for a removed method whose only callers called its interface; and
  `find_by_complexity_and_coverage` still counts a method that only a dispatch test reaches as
  untested (`reachedOnlyThroughDispatch`), so the complex-and-untested insight and its debt estimate
  do not shrink without a test being added.

### An answer too large to deliver is refused with its size

- **An answer over 16,000,000 bytes as JSON is refused on `tools/call` and on resource reads**, and the
  refusal names the size and the remedy: `outputPath` for `export_markdown`, a narrower query
  otherwise. Before, `export_markdown` on a large solution failed only after the work, with a bare
  `-32603: An error occurred.`, and a client that closes the connection on a message above 16 MiB lost
  every session the server held.
- **The limit is set with `AICB_MCP_MAX_RESPONSE_BYTES`** (thousands separators are accepted; the
  value is capped at what the JSON serializer can write). A refused tool call is counted as a failure
  in `usage_report`; a refused resource read is not recorded. `aicb call` prints the text directly
  and is not affected.

### `analyze_solution` says when a load was incomplete

- **The session answer carries `incompleteRun` when scanned projects could not bind their core
  framework types** (for example a missing targeting pack): how many, out of how many, the first ten
  names, and a note naming the repair - `refresh_session` with `force=true`, or `refresh_remembered`
  for a session restored with `recall_codebase`. It appears on `analyze_solution`, `refresh_session`,
  `inspect_session`, `list_sessions`, `recall_codebase` and `remember_codebase`, and only for an
  incomplete run, so a healthy answer is unchanged. Before, the first answer said nothing, and only a
  later refresh or `get_diagnostics` showed it. Its absence is no all-clear: `get_diagnostics` names
  the errors of a project that binds its framework but is still not restored.

### Fixed

- **A refresh keeps the namespace exclusions of the first analysis.** With a configuration database -
  the default `aicb mcp` server always has one - `analyze_solution` applied the active
  `Exclude Namespaces` list to the first analysis but not to later refreshes, whether an explicit
  `refresh_session` or the automatic one after an edit. Dependencies, metrics and insights of an
  unchanged solution could therefore change after a refresh. Sessions from `remember_codebase` and
  `refresh_remembered` had the same gap.
- **`evaluate_change_set` analyzes the proposed change with the session's namespace exclusions**, so a
  dependency the exclusions hide is no longer reported as introduced by the change.

## 0.5.464.66 (2026-09-28) - SQLite closes CVE-2025-6965, `get_diagnostics` names what it could not compile, `prepare_task` stays within a budget

**Who is affected.** Everyone gets the SQLite security update and the editorial license version 0.6.
Everything else concerns the MCP server and the `aicb` CLI: `get_diagnostics`, `prepare_task`,
`find_tests_for`, `review_context`, `instantiation_sites`, `symbol_metrics`, `resolve_injection`,
`impact_of_change`, `find_dead_code` and `list_insights`. No database change; saved snapshots stay
valid. The local-function fix below takes effect when a solution is analyzed again. If your client
caches tool descriptions, reconnect it once - several descriptions changed.

### Security

- **The bundled SQLite library moves from 3.41.2 to 3.53.3**, which fixes CVE-2025-6965
  (GHSA-2m69-gcr7-jv3q, severity high). aicb uses SQLite only for its own local database and runs
  only its own SQL, so the practical exposure was low - but the vulnerable native library shipped in
  the NuGet tool package, the installer and the portable ZIP, where a vulnerability scanner reports
  it. Existing databases open unchanged; no re-analysis is needed. `THIRD-PARTY-NOTICES.txt` lists
  the updated `SQLitePCLRaw` 2.1.13 packages.

### Licensing

- **EULA version 0.6 is an editorial version with unchanged terms.** The German part now uses real
  umlauts instead of transliterations, and dashes became plain hyphens. Prices, thresholds and every
  right and obligation are the same as in version 0.5. The immutable reference is the tag `eula-v0.6`.

### `get_diagnostics` says what it could not compile

- **A failed design-time build is disclosed in `designTimeBuildFailures`.** When MSBuild fails while
  loading a project - a version task on a shallow clone is the typical case - the project is still
  compiled with what could be read, so its compiler options can be incomplete, and that moves the
  counts in both directions. The answer now lists each affected project file with the loader's own
  message and a note naming the remedy, whenever the scope reaches such a project or one of its
  dependents. A shared failure is quoted once, not once per project.
- **Generated code the analysis could not produce is disclosed in `generatedCodeGaps`.** A project can
  compile without code a source generator or the WPF markup compiler would have written: a generator
  from a project in the solution that was never built (`not-built`), an analyzer file nobody produces
  (`not-found`), a generator built for a newer compiler than the analysis host (`cannot-load` -
  building does not fix that one), a generator that failed to load for another reason (`load-failed`),
  or WPF code-behind whose markup half is missing. Each entry carries its evidence and affected
  dependents; `diagnosticsInAffectedProjects` gives the magnitude and `diagnosticsMarked` counts the
  items marked `missingGeneratedCode: true` because they sit exactly where the code is missing.
- **A file-scoped call names the incomplete project its marked items inherit from.** Under a file-path
  scope, an incomplete project is listed whenever a counted diagnostic in the scope sits downstream of
  it, so a `cascadeFromIncomplete` item always has its cause named. `suppressedDiagnosticsTotal` now
  appears whenever `incompleteRatio` does, and a scoped call reaches `inconclusive` only where the
  solution-wide call would too.

### `prepare_task` stays within a budget

- **The template render has a default ceiling.** When neither the MCP profile nor the template sets a
  budget - true for every built-in - the answer could run to hundreds of thousands of characters, and
  to millions for a plain-language goal. The default is now a hard ceiling sized to what an MCP client
  shows inline, and the manifest in front of the context counts toward it. On a goal naming one type,
  about 304 000 characters became about 15 000. A budget you configure keeps its tolerance.
- **A goal that names a declared symbol exactly seeds on the symbols it names.** Its other words still
  steer the trimming but no longer pull in unrelated members - an ordinary word such as "works" or
  "where", or a capitalized first word of the sentence, used to anchor on a like-named method.
- **The type the goal names stays in the answer** even when the budget is tight; if its source does
  not fit, it is shown as structure rather than dropped.
- **The frontmatter stays parseable.** The pruning and budget notes are now placed after the YAML
  frontmatter instead of in front of it.

### Tests and construction sites

- **`find_tests_for` counts a test that builds the queried type.** Two new `matchReason` values,
  `constructs` (the test creates the type: `new X(...)`, target-typed `new()`, a record `with`) and
  `constructs-via` (through one method it calls), apply to type and constructor queries (`Type.Type`)
  and rank after the `invokes` tiers. Building a type does not show that a particular member ran, so
  member queries are unchanged.
- **`review_context` caps its covering tests like `find_tests_for` does** - 50 per symbol, with
  `coveringTestsTotal` and `coveringTestsTruncated`. One symbol could previously return well over a
  hundred rows, and a large solution several thousand in one answer.
- **`instantiation_sites` separates test from production.** Every site carries `isTestProject`, and
  `createdByTests` and `injectedIntoTests` stand beside the totals they split, counted over all sites
  and not just the returned page. "Does anything but a test construct this type?" is now one call.
  The classification follows the session's configured test projects.

### Corrected answers

- **Calls from constructors and property accessors in test projects count as test calls.**
  `impact_of_change` no longer counts them as production impact, and `find_dead_code` reports a
  method that only such test code reaches as unused in production.
- **Local functions of the same name in different methods are no longer merged** in call graphs, so a
  caller of one no longer appears as a caller of the other.
- **`list_insights` drops two false alarms:** `nameof(Task<T>.Result)` is not a blocking wait on a task,
  and `Enumerable.Empty<T>()` inside a loop is not a per-iteration LINQ cost.
- **`resolve_injection` no longer matches a factory registration that returns an anonymous object**
  against an unrelated service. It reports no match, and its note points at the factory site.
- **`symbol_metrics` carries `metricMeaning`** on every answer: cyclomatic and cognitive complexity
  describe code shape, not runtime cost.

### Documentation

- The nuget.org package page now matches this repository's README, names the MCP server and lists its
  search terms. The `aicb-csharp-context` skill explains the new `constructs` reasons of
  `find_tests_for`; `aicb init --force` refreshes an installed copy.
- The general manual's licensing chapter names EULA version 0.6. The printable PDFs still describe
  product state 0.5.464.43.

## 0.5.464.56 (2026-09-26) - the license that ships is the license that is published, and six answers stop hiding what they left out

**Who is affected.** Everyone: the shipped license text moves from EULA v0.3 to v0.5. Beyond that, this
release is mostly about MCP answers and exported Markdown telling you what they omitted - `find_usages`,
`find_symbol`, `symbol_signature`, `architecture_overview`, `solution_config_status`,
`check_solution_config_drift` and `pack_for_task`. No database change, no re-analysis; saved snapshots stay
valid. If your client caches tool descriptions, reconnect it once.

### Licensing

- **The binding agreement shipped with the product is now EULA v0.5**, the same version published here.
  Installer, portable ZIP and the NuGet package carry it, with `LICENSE.txt` as its plain-language summary
  beside it. What v0.4 and v0.5 added over v0.3: commercial licenses **start at EUR 25 per licensed
  developer per month**, a commercial agreement can include defined response and security-fix targets,
  version maintenance, prioritized general product improvements and source-code review under NDA. The
  free thresholds are unchanged - 100 employees, EUR 10 million annual turnover, 21 developers - and so is
  everything about enforcement: no license server, no activation, no timer, no threshold data leaving the
  machine. The 90-day transition period remains contractual text only.
- The nuget.org package page now states the same terms as this repository.

### Answers that now disclose what they omitted

- **`architecture_overview` leads with a `<TRUNCATION>` block** when the document was cut: how many sections
  were capped, how many entries are shown out of how many, and one `SECTION: shown of total` row per cut
  section. Until now the per-section `+N more` lines each named one section and added up for nobody - on a
  large solution that meant 640 of 8706 entries were shown with no statement anywhere that the rest existed.
  The frontmatter of a truncated document stays where it belongs, so `type`, `title` and `description` are
  still parseable.
- **`find_usages` reports `selfReferences`** - how many of the listed users are declared on the queried
  symbol's own type - and adds a note when *all* of them are. That is the answer that reads as outside
  dependence while nothing outside actually depends on the symbol. Self-references are disclosed, never
  filtered out: a self-reference is a real reference.
- **`find_symbol` and `symbol_signature` say when generated C# was skipped.** Generated sources under `obj/`
  stay out of the analysis on purpose - the same file often exists once per target framework, so admitting
  them would multiply every generated type - but a zero-hit answer used to read as "no such type". A
  zero-hit answer on a solution that has such files now says so in `generatedSourcesNote`.
- **A broken `.aicb.json` no longer reads as "nothing configured".** `solution_config_status` and
  `check_solution_config_drift` carry `sidecarProblem` when the sidecar next to the `.sln` exists but cannot
  be used, and they keep an invalid file apart from a locked or unreadable one - a typo is yours to fix, a
  lock is transient. Until now a broken sidecar produced an answer byte-identical to having none, three axes
  reporting `source: "none"`, which is a positive claim that nothing is configured. A healthy answer is
  unchanged.

### Corrected and smaller answers

- **`returnKind` names the return type's family, not its arity.** A plain `Task` was reported as `object`
  while `Task<T>` was `task`, and non-generic `IEnumerable`, `IList`, `ICollection`, plus
  `IReadOnlyCollection` and `IAsyncEnumerable`, fell out of `collection`.
- **`find_usages` on a bare member name no longer mixes namesakes into the self-reference count.** Where a
  short name matches members on several types, the count is omitted rather than reported wrongly; a
  type-qualified query answers as before.
- **Exported Markdown carries a smaller `<COMPRESSION_LEGEND>`.** The legend now explains only the notations
  the finished document actually contains. On a single-symbol export it had grown to about a third of the
  whole document while explaining blocks that were not in it.
- **`pack_for_task` fills the budget it was given, also on slices that had to degrade.** A request whose
  content had to be reduced below the full-code form could settle well under target - measured at about 85 %
  of a 25 000-token budget, below the 92 % the tool aims for; the same request now lands at about 96 %.

### Documentation

- The public documentation gained a measured cold/warm scale benchmark on three public solutions (Serilog,
  MahApps.Metro and RavenDB, cold and warm load, peak memory), a clearer statement of what the static
  analysis does and does not cover, a safe agent workflow, and the licensing pages for the new EULA version.
- The three reference manuals still describe product state 0.5.464.43; their licensing chapter is current
  with EULA v0.5. The changes listed above are described here in the changelog.

## 0.5.464.44 (2026-09-25) - usage check skill and complete browser-readable manuals

**Who is affected.** Users who run `aicb init --skills=all`, and anyone reading the public
documentation. The analysis engine, MCP tool answers, desktop app and saved snapshots are unchanged.

- **A fourth optional Agent Skill ships:** `aicb-usage-check` calls `usage_report` at the end of a
  task and summarizes which AICB tools were actually used, which offered tools went untouched, and
  what the calls cost. It is deliberately opt-in alongside the review pair; the default
  `aicb init` still writes only `aicb-csharp-context`. Run `aicb init --skills=all` again in an
  existing project to install it there.
- **The three reference manuals are now readable as Markdown in the browser and by coding agents,**
  one chapter per file, with the printable PDFs beside them under stable names. The manuals describe
  product state 0.5.464.43; build .44 changes only the guard described next.
- **The package page can no longer silently omit a shipped skill.** Every release now checks the
  install page, the CLI help and the package README against the list of skills that actually ship.
  This closes the gap that briefly left the nuget.org page describing only three skills.

## 0.5.464.41 (2026-09-24) - `resolve_injection` says how visible a service is in constructors

**Who is affected.** The MCP server and the `aicb` CLI. **The desktop app is unchanged.** Saved
snapshots stay valid; no database change, no re-analysis.

- **New field `constructorConsumerCount`**: how many distinct types take the queried service as a
  plain constructor parameter. It is on every answer, and a zero is a result rather than a missing
  field - until now a service half the solution injects and one nobody injects produced the same
  answer, because only *optional* constructor parameters were ever reported.
- **Read it as a description, not a verdict.** It counts constructor parameters and nothing else, so
  a service obtained through `GetService<T>`, built inside a factory lambda, or reached by reflection
  or XAML counts 0 while being thoroughly alive. The first live reading makes the point better than
  any warning: a service that almost everything takes as a factory delegate reports **2**. For "is
  this used at all", `find_usages` remains the tool.
- An optional parameter counts here too, and such a consumer still appears on `optionalDependencies`;
  collection consumption keeps its own field and is not counted twice. Consumers declared in test
  projects follow the existing `includeTests` filter.

If your client caches tool descriptions, reconnect it once - the text of `resolve_injection` changed
along with its answer.

## 0.5.464.40 (2026-09-24) - `resolve_injection` stops giving confident wrong answers

Four builds (`.37` to `.40`) that all repair the same tool. Every one of them replaces an answer
that looked definite with one that is either correct or openly says it does not know - which is
the point: a `false` that means "nobody does this" is far more expensive than a "cannot tell".

**Who is affected.** The MCP server and the `aicb` CLI. **The desktop app is unchanged** - it does
not use this analyzer. Saved snapshots stay valid; there is no database change and no re-analysis.

- **`consumedAsCollection` is answered for every query, not only for a conflicting one.** The field
  says whether anything consumes a service as a set (`IEnumerable<T>` in a constructor,
  `GetServices<T>()`). It used to be computed only where it could also downgrade a registration
  conflict, and read `false` everywhere else - so a service registered once, or registered several
  times through factories, always answered `false` no matter how many consumers took the whole set.
  Measured on a real solution, two services answered `false` while a constructor took each of them
  as `IEnumerable<T>`.
- **A factory registration that *returns* its object is now resolved.** `AddSingleton(sp => Foo.Build())`
  and the block form `AddSingleton(sp => { ...; return Foo.Build(); })` used to leave the registration
  with no type name at all - and in this single-argument form the produced type *is* the service, so
  the whole registration answered to no name. `AddSingleton(sp => new Foo())` always worked; the
  difference was only that one returns instead of constructing. A block body is read only when all of
  its `return` statements agree, and a `return` inside a nested lambda or local function is correctly
  ignored.
- **A registration the scanner can see but cannot parse is now disclosed as such.** Before, such a
  site was invisible, and the answer explained the resulting zero with *"Autofac, Castle Windsor and
  Scrutor are out of scope"* - pointing away from the file that actually held the binding. The note
  now separates *"a Microsoft-DI registration was seen here but its type could not be read"* from
  *"no Microsoft-DI registration was found"*, and names the site.
- **Optional and nullable collection parameters count.** `IEnumerable<IFoo>? foos = null` - a consumer
  that tolerates an empty set - was not counted as consuming the collection, and neither was
  `IEnumerable<IFoo?>`.
- **Consumers declared in test projects no longer count by default.** This one changes an answer you
  may have relied on: collection consumption now obeys the same `includeTests` filter the registration
  list has always obeyed. Before, a test fixture taking `IEnumerable<T>` could mark a genuine
  production conflict between two registrations as deliberate, hiding it. Pass `includeTests=true` to
  get the old, solution-wide reading.

If your client caches tool descriptions, reconnect it once - the text of `resolve_injection` changed
along with its behavior.

## 0.5.464.36 (2026-09-23) - internal wiring, nothing you can see

A plumbing release. No tool changes its answer, the CLI and the desktop app behave
exactly as in 0.5.464.35, and there is no reason to update in a hurry.

- **The MCP server's insights now see the queue of work items**, as the desktop app's
  already did. No MCP tool reads that queue yet, so no answer changes; the connection
  keeps a future tool from reporting "nothing is queued" when the queue was simply not
  connected. The desktop app was never affected.
- **One consequence worth stating:** in a setup where the MCP server is pointed at a
  database, an insights run now performs one additional indexed read against it - the same
  read the desktop app already does - and currently discards the result. Analysis still
  runs entirely on your machine, and the MCP server still writes nothing.

## 0.5.464.35 (2026-09-23) - two answers about C# code that were quietly wrong

Analysis-engine changes, so they reach the MCP server, the CLI and the desktop app alike.

- **`resolve_injection` discloses optional constructor dependencies.** A constructor
  parameter with a default (`IFoo? foo = null`) that nothing in the registration set fills
  used to fall between two answers - the tool listed what was registered, never whether it
  arrived. The answer now carries an `optionalDependencies` axis naming every such consumer,
  with a verdict of `yes`, `no` or `unknown` per construction. The verdict follows **who
  selects the constructor**: the container when the consumer is registered by type, the
  argument list when a factory lambda or a hand-built instance constructs it. Where the
  analyzer cannot see how the consumer is built - construction inside a helper method,
  `ActivatorUtilities`, several constructors to choose between, two types of the same short
  name - it answers `unknown` with a reason rather than a plausible guess. Answers for
  services with no optional consumer are byte-identical to before.
- **A static constructor no longer shares its caller entry with the parameterless one.**
  `static C()` and `C()` were registered under one key, so `find_usages` merged the callers
  of the two bodies and could not tell which one called what. The static constructor now
  keys as `C.static C()`, in `find_usages`, `call_graph`, `impact_of_change` and the
  exported Markdown.
- **Saved snapshots:** the payload format moves to 56, so a snapshot written by an older
  version is re-analyzed instead of loaded. Nothing is lost; the first analysis after the
  update takes its usual time.
- The desktop app is otherwise unchanged since 0.5.464.32.

## 0.5.464.33 (2026-09-21) - manuals linked from the package page

- Full manuals as PDF (General, MCP server, Desktop app) in
  [`docs/manual/`](https://github.com/gregordadera/AICB/tree/main/docs/manual), linked from the
  README and therefore from the nuget.org package page.
- No code change: the MCP server and CLI behave exactly like 0.5.464.32. Published on
  nuget.org only; the desktop app stays at 0.5.464.32.

## 0.5.464.32 (2026-09-21) - one installation per machine

- **The installer removes an existing .NET tool** (option, preselected). The installer
  contains the same MCP server and CLI; with both installed, Windows starts the
  installer's `aicb` first, so `dotnet tool update` updated a copy no MCP client ran.
  Now one `aicb` per machine, and a desktop-app update brings the MCP server along. If
  the tool is still running as an agent's MCP server, the installer asks you to close
  the agent and retry.
- **`aicb init` warns when `aicb` is installed more than once** and names the copy that
  actually runs.
- The installer's last page says that consoles, editors and agents that were already
  open see the new `PATH` only after a restart.
- Published builds report a plain version number (`0.5.464.32`) without a build commit
  suffix.
- Install guidance in README, Getting started and the `aicb-csharp-context` skill:
  Windows with the desktop app → installer only; everywhere else → the .NET tool.

## 0.5.464.31 (2026-09-20) - first public release

The first release published outside the author's own machine.

**MCP server and CLI** (`dotnet tool install -g AIContextBuilder` from nuget.org, Windows / Linux / macOS)

- A Roslyn-backed MCP server (`aicb mcp`, stdio) that answers the questions a coding
  agent has before it edits C#: callers and blast radius, implementations and
  overrides, covering tests, injected dependencies, side effects, dead code, dependency
  cycles, live compiler diagnostics - and packs task-sized context for a model.
- Serves both current MCP protocol revisions (`2026-07-28` and `2025-11-25`) from one
  binary.
- Self-init: every tool accepts the absolute `.sln` / `.slnx` / `.slnf` path as its
  session; no separate analyze step.
- A lean default tool pool across nine task facets; the full surface is one profile
  switch away (`--mcp-profile mcp-profile/full`).
- `aicb init` wires a project in one step: `.mcp.json`, the `aicb-csharp-context` agent
  skill, and - for Claude Code, Codex and OpenCode - the optional symbol guard.
- CLI verbs `init`, `analyze`, `export`, `import`, `list`, `mcp` and `call` (one tool,
  once, from a plain shell).

**Desktop app** (Windows, installer or portable ZIP from the release assets)

- Curate by hand what a model sees: pick types and methods, set a detail level per
  node, watch the token estimate, render the context document, and copy, save or send
  it to a model profile you configured (local models included).
- Workspace with solution tabs, snapshots, sessions, insights and the MCP usage view;
  light and dark theme.

**Privacy.** Analysis runs entirely on your machine. The CLI and the MCP server have
no network capability at all; the desktop app talks only to a model endpoint you
configured yourself, for example when you press *Send to API*. No telemetry, no update
check, no crash reporting.

**Known limits.** Analysis needs MSBuild (a .NET SDK or Visual Studio) on the machine.
The Windows downloads are not code-signed yet, so SmartScreen asks once. C# only;
third-party analyzers are not run.
