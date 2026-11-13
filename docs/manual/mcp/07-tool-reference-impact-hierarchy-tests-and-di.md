[AICB - MCP Server](README.md) &middot; chapter 7 of 12

# 7 Tool reference: impact, hierarchy, tests and DI

The tools in this chapter answer four groups of questions:

- **Impact and fan-in** - who uses a symbol, how far a change propagates, which call or dependency path connects two symbols, and who constructs a type.
- **Hierarchy and lifecycle** - who implements an interface, who overrides a method, how a type's inheritance tree looks, and how a type is created, injected, returned, referenced and persisted across the solution.
- **Tests and coverage** - which tests cover a symbol, which methods no test calls directly, which complex methods are untested, and whether a negative claim about a symbol holds.
- **Dependency injection** - which concrete type is registered for an interface (by Microsoft DI or as a MEF export), with which lifetime, and where.

## 7.1 Conventions used in this chapter

- **Session.** Every tool takes a `sessionId`. Most tools also accept the absolute path to a `.sln` file directly and analyze it on first use. A tool answer is computed from the analyzed session, so after you edit source files call `refresh_session` before asking again - otherwise the symbol graph keeps answering from the pre-edit state. See "Sessions and staleness".
- **Read-only.** All tools in this chapter only read the analyzed model. None of them changes source files, the session, or any database.
- **Recalled sessions.** All tools in this chapter work on a session restored from a saved snapshot, except `resolve_injection`, which needs a live analyzed session.
- **`note`.** Where a response carries a `note`, read it before the numbers. It leads the answer when the answer needs a qualification - an empty result that is not proof of absence, a run whose project references did not all resolve, or a zero that is not a measurement. Notes are omitted when there is nothing to say.
- **Caps.** Capped lists report the true total in `totalFound` and set `truncated` to `true`. Narrow the query or the `scope` to see the rest.
- **Availability.** Each tool below carries an availability line. "Core" tools are part of every tool set. "Default" tools are part of the default tool set. A tool marked "not in the default tool set" is still shipped, but you reach it only when the server runs with an MCP profile whose facet menu includes it (for example the Exploration, Debugging or Architecture facet), or when you add its name through the `AICB_MCP_TOOLS` environment variable.
- **Parameter aliases.** Some tools accept a familiar alternative spelling for their main argument, listed in the parameter tables as an alias. The canonical name is always advertised; the alias is only tolerated so a call that used the other name still binds.

## 7.2 Fan-in, impact and paths

### `find_usages`

**Purpose.** List who uses a symbol - the fan-in. This is the central "who calls X?" tool and the first call for almost every impact question.

**When to use it.** Before renaming, moving or deleting a symbol; when you need the concrete list of callers, readers, writers or subscribers; when you want to know whether a type is referenced at all.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id returned by `analyze_solution`, or an absolute `.sln` path for self-init. |
| `symbol` | string | yes | - | Exact (case-sensitive) name of a type, method, property, field, event, enum member or user-defined operator (by its metadata name, such as `op_Equality`) - or the qualified `Type.Member` form to disambiguate a member. `Type.Type` asks for a type's constructor. |
| `includeTests` | bool | no | `true` | Include users declared in test projects. `false` lists production users only, before the 100-item cap, and `testUsersFiltered` says how many were left out. A user no fact places in a project stays listed. `viaContract` keeps counting every caller. |

**What a name resolves to**

| Query | `resolvedKind` | Answer |
|---|---|---|
| Type name | `type` | The types that reference it - a type of the same simple name that derives from it, or holds or creates it under another arity or a namespace-qualified name, included (`Identity<T1, T2> : Identity`, `Ef.User : Core.User`), while a type that names only itself is not its own user - plus markup views, `.razor` files, `.cshtml` views and files of top-level statements. A doc `cref` counts (unmarked), and so does an attribute application at any position; an assembly- or module-level attribute is credited to the file that applies it, as `<file> (assembly)` or `<file> (module)`. A generic type parameter that shares the type's name (a `T` beside a solution type `T`, a Razor `@typeparam`) is not a use of it. |
| Method name | `method` | The methods that call it (the union across overloads). An override is also credited with the callers of the virtual member it overrides. |
| Property or field name | `property` / `field` | The methods that read or write it. A CommunityToolkit `[ObservableProperty]` backing field additionally lists the consumers of its generated property - the two are one symbol pair to a caller. |
| Event name | `event` | The methods that raise, subscribe to or unsubscribe from it. The subscriber types are also available through `find_by_event_subscription`. |
| Enum member (bare `Partial` or qualified `BackupStatus.Partial`) | `enum_member` | The methods that reference it - a switch label, a comparison, an assignment. |
| User-defined operator or conversion by its metadata name (bare `op_Equality` or qualified `Money.op_Implicit`) | `operator` | The code that uses it - `a == b`, `a + b`, `++`, `+=`, a cast and an implicit conversion of a value - in method, accessor, constructor, initializer and operator bodies. A use through a generic constraint lands on the interface's static abstract operator, not on the implementing type's. A record's compiler-synthesized `==` has no declaration and answers `not_found`. |
| `Type.Type` | `constructor` | The type's construction and injection sites, a `new` in top-level statements included (named by its file label). This analyzer records no per-constructor fan-in, so overloads are unioned and a listed site may have called a different overload than you meant; `instantiation_sites` reports the same facts with the two edge kinds kept apart. `impact_of_change` does not resolve this form. |

**Qualified members.** A qualified member form respects every segment: `Outer.Inner.Member` or `Ns.Type.Member` answers for the member of the type whose full name ends in that chain - also through a generic outer type (`Outer<T>.Inner.Save`) - not for every type that carries the last type segment's name. The simple form `Type.Member` still answers for every type of that name, and says so in `namesakes` when there are several.

**Where the users come from.** Besides C# code, the fan-in includes:

- **`.cshtml` views** (MVC, Razor Pages) that the Razor source generator compiled in the analysis: what a view calls, reads or names is credited to the view file, labelled `<path>.cshtml (razor)`. A type injected in a `_ViewImports.cshtml` is credited to that file once, not to every view below it, and an `@attribute [X]` in a view is a use of the attribute type. Views the generator did not compile are named on a zero answer (see "Empty answers").
- **Top-level statements.** Every type a `Program.cs` without a class names counts as used by that file, labelled `<path>/Program.cs (top-level)`: `typeof`, type arguments (`AddTransient<I, Impl>()`), casts, `is`/`as` and patterns, `default(T)`, `nameof(T)`, declared locals, `out`, `foreach` and `catch` types, tuple elements, attributes on local functions, a record `with`, collection expressions, a creation, and the types in a called method's signature.
- **Source-generated code.** What a source generator's output calls, reads or names is credited to the generated document, labelled `<path> (generated)` (see "Source-generated code" under "Recurring conventions across the catalog"). A handwritten `partial void OnXChanged` hook that a generated setter calls lists that setter as its caller. An element with `x:Name` whose code a XAML generator writes counts as one user of its type: its view.
- **WinUI `{x:Bind}`.** Each member an `{x:Bind}` path names - looked up on the page's `x:Class` or a template's `x:DataType` - has the view as a user.
- **ASP.NET Web Forms.** A page, master page, user control or `Global.asax` credits the class its `Inherits=` directive names, and `.ashx` handlers and `.asmx` services the class their `Class=` directive names; the user is the markup file, labelled for example `About.aspx (webforms)`.
- **Markup** in the forms listed under "Empty answers" below.

**Counting rules worth knowing.**

- **Multi-targeted projects.** A type's users include the references made in every target framework, and a type or member only an older target framework declares is found instead of answering `not_found`.
- **Extension members.** On a static class that declares C# 14 `extension` blocks, the users include the types that call those extension members.
- **Indexers.** Reading or writing an indexer of a solution type counts as calling its getter or setter. On a `Count` or `Length` property, the users include code that reads it implicitly through `x[^1]`, a range or a list pattern.
- **Names that are not type references.** A tuple element name that matches a type name (`(Foo Key, int Count)`) and the member name of an anonymous type are not uses of a type of that name. A type named only in the signature of a lambda with a `ref`, `out` or default-value parameter counts as used.
- **Reflection by `nameof`.** A method fetched by reflection with `nameof` (for example `GetMethod(nameof(M))`) lists the fetching method as its user. A method named by `nameof` in an attribute - on a method, property, field, event, indexer or type - counts as used too.

**Example**

```json
{ "sessionId": "<session>", "symbol": "OrderService.Cancel" }
```

**Response.** `symbol`, `resolvedKind`, an optional `note`, and `usedBy` - a capped envelope (`items`, `count`, `totalFound`, `truncated`, maximum 100) - and, on a production-only answer (`includeTests: false`), `testUsersFiltered`. Each item is an object `{name, file, line}`, one per user, so `totalFound` counts users:

- `name` - the user: a calling member under its full key with parameter types, a referencing type, or a markup view.
- `file` - the file the user is declared in, relative to the solution and with forward slashes.
- `line` - the line the user's declaration starts on in that file (its first attribute line when attributes precede it), not the line of the reference. A field, property or event whose initializer uses the symbol is placed by that member's declaration.

A partial type declared in several files lists them in `files` as `[{file, line}]` objects instead of `file` and `line`. Where one name stands for several users - two types of one simple name in different namespaces, the same type or caller compiled in two projects - each declaration is its own item under the shared `name`, and the items add `fullName` (for a type), plus `project` where the full name or the caller is shared too. A lone item carries neither - except a user whose name is the queried name itself (a generic `Foo<T>` listed as a user of `Foo`), which names its `fullName`. Markup and top-level entries carry a `file` but no `line`, and an item that no recorded fact places carries neither: absent means unknown, never a guess. A script written for earlier releases, whose items were bare strings, reads `name`.

```json
{
  "symbol": "OrderService.Cancel",
  "resolvedKind": "method",
  "usedBy": {
    "items": [
      {
        "name": "MyApp.Web.OrdersController.Cancel(int)",
        "file": "src/MyApp.Web/OrdersController.cs",
        "line": 41
      }
    ],
    "count": 1,
    "totalFound": 1,
    "truncated": false
  }
}
```

Depending on the answer, additional steering fields appear:

- `nearest` - the closest declared name, set when the query matched nothing (`resolvedKind: "not_found"`). A likely typo or case mismatch; it can also be a declared name the query only begins, or - for a member asked on a type that does not declare it - the one type that does.
- `collision` - set when a bare name also names a symbol that is not counted: for a member answer a same-named type, or - where no C# type has the name - a Razor component written only in markup (that component has no symbol here and its users are not counted); for a member or type answer, another member kind of the name that has users (named with its qualified forms and direct user count).
- `namesakes` - set when the name resolved to a type that the solution declares several times (a generic and a non-generic type of one name, such as `Foo` and `Foo<T>`, count as two and are named in their declaration form), or a qualified member whose type part still names several types (`'<query>' is declared on N DIFFERENT types named '<Type>' ...`, with a further-qualified example). `usedBy` is then the union over all of them, and no entry says which one it uses. A bare member name keeps its union without this note.
- `viaContract` and `viaContractNote` - set when a qualified method was credited the callers of the interface or abstract members it implements.
- `selfReferences` - how many of the listed users of a member sit on its own type. Counted only when the matched members sit on one type by full name; two same-named types are not taken for one owner.
- `textuallyInvisibleUsers`, `textualBindingKinds`, `textualBindingNote` - see below.
- `overloads` - set on a method answer that unions several overloads: it names which ones, and each item's `calls` names the overloads that item calls.
- `viaImplementation` and `viaImplementationNote` - set on an interface event answer: the implementing events and where they are raised, which the `usedBy` list does not hold.
- `resourceKeyNote` - set on a type answer when a markup view declares the type as a keyed resource: the views that use it by key are not in the list.
- `docCrefOnly: true` - on an item whose only reference to the type is a documentation `cref`: it is counted, because a rename breaks it, but it is not code that uses the type.
- `testUsersFiltered` - on `includeTests: false` only: how many users the filter left out because they are declared in test projects. For the constructor form (`Type.Type`) test sites are dropped too, and the note says how many construction edges sat in tests. `selfReferences` and the textual-binding fields are counted over the users that remain.

**`not_found` is not "undeclared".** A delegate type and a qualified or nested type name (`Outer.Inner`) answer `not_found` too. Where the declarations can explain the miss, a `note` says why: a member asked on a type that does not declare it (the note names the types that do), a qualified member whose qualifier names none of the same-named types that declare it (the note names their full names and suggests a tail of one of them, or `Type.member` for all of them), a declared type named by a qualified form, namespace-qualified or nested (the note names the simple name to ask for), or a Blazor component written only in a `.razor` file (the note names its file; it does not list the component's users).

**Empty answers.** A real kind with an empty `usedBy` means the symbol exists but no intra-solution reference was recorded. That is not proof of dead code, and the `note` that leads the answer names the ways a real use can escape the index and a cross-check you can run. On `includeTests: false`, an answer whose users were all in test projects says so instead (`No PRODUCTION user was recorded: all N recorded users are declared in test projects ...`) and keeps the same list of escapes:

- **Markup, beyond the recorded forms.** Recorded in XAML are `{Binding}` root paths in both markup-extension and element syntax (low-confidence, tagged `(xaml)`, attributed to the resolved view-model); event wires in `.xaml` and Avalonia `.axaml` alike - an attribute that names an event the element's type or one of its bases declares, or an attached `Owner.Event`, credited to its handler, a `void` method with two parameters (where the element's type cannot be resolved, only `Click` counts; an `.axaml` wire is labelled `<file>.axaml (axaml)`); property sites in `.xaml` and `.axaml` - an attribute or property element that sets a property, an attached `Owner.Member` (also under a URI-mapped prefix), and the `Property` of a `Setter`, `Trigger` or `Condition`, credited to the property, or to `SetX` where an attached property is set and `GetX` where it is read. A bare `Setter` name is read against the enclosing `Style` or `ControlTemplate` `TargetType`, or against the type the last segment of an Avalonia `Style Selector` names (`Button` in `Button.accent` or `Button:pointerover`, a `ns|Type` through its prefix), a nested `^` style inheriting its parent's; a selector naming several types or none (a comma, only a class, a name or `:is()`), the `[Property=]` conditions inside a selector, and a type the run could not resolve record nothing, and an Avalonia `Classes.accent="True"` toggle is not a use of a `Classes` member. Also recorded: `{x:Static}` members, attached-property read accessors, `{TemplateBinding}` members and markup type references, a nested type written `prefix:Outer+Inner` included (in `{x:Type}`, `x:Static`, `DataType`, `TargetType`, `d:DesignInstance`, attached-property owners and markup extensions). Recorded in `.razor` files are members named in `@code` blocks, in code-block statements and in component-parameter values (a value without `@` only where the parameter's type is known and is not `string`), and a call through an injected member (`@inject`, `[Inject]`) or through the component's own field or property, credited to the member on that member's type. A WPF view with neither a design hint nor a matching name takes the one view-model type that production code assigns to its `DataContext` (for example `new MainWindow { DataContext = shell }`); assignments in test projects do not count, and a view assigned two different types gets none. A view-model reached only through a `d:DesignInstance` design hint or the `FooView` -> `FooViewModel` naming convention records its member edges but not its type edge, so a view-model rename can still read as low-risk.
- **C# `nameof`** of a method anywhere but in an attribute of a method, property, indexer, field, event or type, or as a reflection lookup's name argument (a `nameof` in such an attribute, such as `[RelayCommand(CanExecute = nameof(CanSave))]`, counts as a use; a `nameof` of a type is recorded).
- **Activation by name at runtime:** reflection with a string literal, a container resolving by convention.
- **Source-generated code a generator did not write in this run** - one that failed to load or run; `get_diagnostics` names it under `generatedCodeGaps`. A caller in the output of a generator that did run is recorded, credited to the generated document as `<path> (generated)` (a `.cshtml` view's to the view's file). Committed `*.Designer.cs` and `*.g.cs` files outside build output are read like any other source file.
- **Visual Basic and F# projects:** a use there records no edge. Where the symbol is reachable from such a project, the note says `NOT ANALYSED` and names the projects, also on a populated answer.
- **`.cshtml` views the Razor generator did not compile** - a runtime-compiled view in a plain `Microsoft.NET.Sdk` project, a generator that did not run, or views the design-time build did not hand to it. A zero answer names them: `VIEWS NOT READ: <n> .cshtml view(s) in <projects> were not compiled by the Razor generator in this run (<m> other view(s) were read) - ...`, with the advice to search the name in those projects' `.cshtml` files before reading the zero as unused. A non-zero answer does not carry it.
- **Enum members only:** values that arrive as strings or numbers (`Enum.Parse`/`TryParse`, JSON or database deserialization, a XAML attribute literal, a command-line argument) and attribute arguments on a type, property or field.
- **Events only:** a subscription made through an interface lands on the interface's event, not the class's (the bare name unions both); a handler added by name (`WeakEventManager.AddHandler(src, nameof(E), ...)`, reflection `AddEventHandler`) or wired in markup leaves no edge.
- **Operators only:** a `dynamic` operand, bound at run time; a call by name through reflection; the operator `true` or `false` behind a user-defined `&&` or `||`; the element operators of a tuple comparison `(a, b) == (c, d)`; and a conversion that a `foreach` applies to its elements, a compound assignment to its operand or result, or `??` to its right side.

The cross-checks the note suggests: for a member, run the fan-in query on its declaring type (a type's fan-in is recorded where its member's is not); for a type, ask `instantiation_sites`, which reads different facts (construction and injection edges); for either, search the name in `.xaml`, `.csproj` or `.json`, or read the source.

**Textually invisible users.** When the answer has entries that bind to the symbol without naming it anywhere in their own source - a value consumed from a member that returns the type, a call that omits an optional parameter of the type, a call to a member inherited from a generic base class closed over the type, or a call to or an override of a member inherited from the type through another base class - the response reports the count in `textuallyInvisibleUsers` and splits it in `textualBindingKinds`:

| Kind | Meaning | Breaks when |
|---|---|---|
| Via return type | Consumes a value of the type from a member that returns it. | The type's contract changes (a member is renamed or removed); survives a type rename. |
| Via optional parameter | Calls a method that takes the type as an optional parameter and omits the argument. | Only when that method's signature changes; survives a rename and a contract change. |
| Via closed generic base | Calls a member inherited from a generic base class that its own type closes over this type (`OrderRepository : RepositoryBase<Order>`), and holds no value of it. | Only when that base list changes; survives a rename and a contract change of the type. |
| Via inherited member | Derives from the type through another base class and calls a member the type declares (bare, `this.` or `base.`) or overrides one. | When those members change; survives a rename of the type. |
| Via implementation | Holds a value of a type that implements or derives from the type and hands it on where the type is expected. | When that implementing type breaks; survives a rename of the type and a member added to it. |
| Via using disposal | Disposes it through a `using` statement or declaration, which calls it without naming it. | Only when the type stops being disposable. |
| Via extension member | Calls an extension method or a C# 14 extension member the type declares through a receiver (`items.Shuffle()`). | When that member is renamed, removed or re-signed, or the type moves to a namespace the caller does not import; survives a rename of the type. |
| Unclassified | Binds by a mechanism this check does not recognize. | Inspect by hand. |

The JSON names of the kinds are `viaReturnType`, `viaOptionalParameter`, `viaClosedGenericBase`, `viaInheritedMember`, `viaImplementation`, `viaUsingDisposal`, `viaExtensionMember` and `unclassified`. Every kind is present in `textualBindingKinds`, at 0 where it does not apply, and the kinds add up to `textuallyInvisibleUsers`. A call to an inherited member on another object (`other.Save()`) is left unclassified: the check cannot tell it from a namesake. `textualBindingNote` states the same in one sentence. Only a count is reported, not a per-entry flag.

**Limits.** Matching is case-sensitive. The list is capped at 100; on a heavily tested symbol test users can take most of those slots, so ask with `includeTests: false` for the production fan-in. A member name resolves by simple name across all types unless you use the qualified `Type.Member` form.

**Run-wide qualification.** If the analysis run could not resolve every project's references, a `note` leads every answer of this family - including a populated one - because such a run is short by ordinary references, not only exotic ones. Rebuild and call `refresh_session`, then repeat the query.

**A generator that did not run.** When the symbol is declared in a project where a source generator or the WPF markup compiler did not run, or in a project that depends on one, the answer carries `generatedCodeNote` - on a populated answer too, because the list is then short by ordinary references. See "Recurring conventions across the catalog".

### `impact_of_change`

**Purpose.** Estimate the blast radius of changing a symbol: the direct and the transitive fan-in (who depends on it, directly or through chains) plus a risk level. This is the call to make before you refactor or rename shared code.

**When to use it.** Before an edit that changes a symbol other code names - a rename included. The trigger is the symbol's reach, not the kind of edit.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `symbol` | string | yes | - | The same strings `find_usages` accepts - a user-defined operator by its metadata name included - except the constructor form `Type.Type`, which is not resolved here (use `find_usages`). A type takes its simple name only. |

**Response.** `symbol`, `resolvedKind`, an optional `note`, `directCount`, `transitiveCount`, `risk`, `productionImpactCount`, `directImpact` (capped envelope, maximum 20 entries), the textual-binding fields described under `find_usages`, and `nearest` on an unresolved name. Where they apply: `saturation`, `viaContract` and `viaContractNote`, `implementers`, `riskBasis`, `collision`, `namesakes`, `generatedSubject`, `generatedStops` and `generatedCodeNote` (ahead of `risk`; see "Recurring conventions across the catalog").

| Field | Meaning |
|---|---|
| `directCount` | Number of direct users, counted one per declaration exactly as `find_usages` lists them (its `totalFound`). Includes test-project callers. |
| `transitiveCount` | Number of dependents in the full transitive closure, one per declaration: where several types or callers share a name, each declaration is its own node, and a dependent is followed to the declaration it refers to where that can be told. Includes test-project callers. |
| `productionImpactCount` | The non-test part of the transitive closure. |
| `risk` | `none`, `low`, `medium` or `high`. |
| `directImpact` | The direct users, as items `{name, file, line}` exactly as in `find_usages` (a type declared in several files lists `files` as `[{file, line}]`). |
| `saturation` | Set where one dependency cycle dominates a high closure: it leads the counts, names the cycle, and risk is then graded by the direct production fan-in. `saturation.cycleMembers` lists the members of that cycle as a capped envelope (`items`, `count`, `totalFound`, `truncated`; at most 200, with the true count); `cycleSample` keeps the first three. |
| `generatedSubject` | Set when a source generator writes every declaration of the symbol: the risk then grades an edit of the generator's input, not of a file you edit by hand. |
| `generatedStops` | `{count, note}`: how many generated documents (`<path> (generated)`) the walk reached and stopped at - it does not continue to the users of the members they declare, so the counts can be short of what reaches the symbol through generated code. |
| `viaContract`, `viaContractNote` | A qualified method also counts the callers of the interface or abstract members it implements, as in `find_usages`. |
| `implementers` | On an interface or abstract method or type: one entry per contract with `contract`, `count`, `testCount`, `typeCount`, `testTypeCount` and `members` - what a signature change breaks. See below. |
| `riskBasis` | Set together with `implementers`: `closure`, `implementers`, `total` and an optional `note` - the number the risk was graded on. |
| `collision` | A same-named symbol of another kind, not counted. |
| `attachedProperty` | For a queried field that registers a dependency property: the accessors through which markup sets and reads the attached property, and the instance wrapper property (an entry of `kind: "wrapper"`) through which markup sets and binds it, each with its markup files. It moves no count, and the risk does not change because of these files. |

```json
{
  "symbol": "OrderService",
  "resolvedKind": "type",
  "directCount": 1,
  "transitiveCount": 2,
  "risk": "low",
  "productionImpactCount": 2,
  "directImpact": {
    "items": [
      {
        "name": "CompositionRoot",
        "file": "src/MyApp.Console/CompositionRoot.cs",
        "line": 9
      }
    ],
    "count": 1,
    "totalFound": 1,
    "truncated": false
  }
}
```

A script written for earlier releases, whose `directImpact` items were bare strings, reads `name`.

**What is counted, per kind.** A type: the closure of the types that reference it. A method or an operator: its caller closure, following interface and abstract dispatch at every hop. A creation counts as a call to the constructor it binds, so for a method called from a constructor the closure reaches the code that builds the object, and its risk can rise. A property, field, event or enum member: the code that touches it - there is no transitive member chain, so `transitiveCount` equals `directCount`. A field or event initializer in a test class counts as test code, not as a production consumer.

**How the risk level is calibrated.** The thresholds are `none` for 0, `low` from 1 to 4, `medium` from 5 to 20, and `high` above 20. They read `productionImpactCount`: test-project callers are excluded, because exercising a symbol from tests is its designed fan-in and updating those tests after the change is mechanical, not risk. Two cases read a different number:

- With `saturation`, the bands read the direct production fan-in the block names, because a count that every symbol reaching the cycle shares measures the cycle, not the symbol.
- With `implementers`, the bands read `riskBasis.total` = `riskBasis.closure` (the caller count above) + `riskBasis.implementers` (the production implementing types), because a signature change breaks both. On a method every production implementing type counts. On an interface or abstract class only the types that name it in their own base list count, and only those the closure does not already hold.

The risk counts dependents, not what the change means.

**Implementers.** An `implementers` entry for an interface or abstract **method** lists the implementing and overriding members; `typeCount` counts the types they sit on, one per declaration (two same-named types in different projects count twice), which is what a change to one overload breaks. When the member name is declared by two same-named interfaces or abstract classes in different namespaces, the entry keeps their combined count and `namesakes` names each contract with its own implementing types. An entry for an interface or abstract **type** has one entry per declaration (namesakes in different namespaces and generic interfaces of different arity stay apart) and lists the implementing or deriving types, including those that implement the interface through a base class or another interface - for a generic interface whatever type arguments they close it with, at any depth - as `find_implementations` lists them; the ones that reach it only through a base class, and the interfaces that extend it below the first level (their own base list names a derived interface, not this one), are listed again under `indirect` and do not raise the risk - for a generic interface as for a non-generic one. A class that gets the interface through a derived interface is not indirect: it implements the members, so a signature change breaks it. A type in the global namespace and a namespaced type of the same simple name are not taken for each other in these counts. When no production code calls the interface or abstract member - or, for a type, no production type references it - `riskBasis.note` says that the risk comes only from its implementing types; the risk level itself is unchanged by the note. Where `saturation` grades the closure by its direct users, its note names the implementing types added to that count.

**Notes.**

- `risk: "none"` on a solution that has production projects does not by itself carry a note for a symbol used only by tests: `directCount` is then greater than 0 while the risk is `none`. That class is reported by `find_production_dead`, which is outside the default tool set.
- On an unresolved name the answer leads with a note stating that the numbers measure nothing and that `risk: "none"` is the absence of a measurement, not a safe verdict. A mistyped name and a genuinely dependency-free symbol produce the identical answer. Where the declarations explain the miss, the note says why, as in `find_usages` - including a Blazor component written only in a `.razor` file.
- A resolved symbol with `directCount` 0 carries the escapes note described under `find_usages`, including the `VIEWS NOT READ` sentence when `.cshtml` views were not compiled. The users `find_usages` lists from `.cshtml` views and top-level statements count here as well, and a qualified member resolves as described there.
- `generatedSubject` and `generatedStops` move no count and no risk level; they say what the numbers do not cover. A name-collision note lists the handwritten namesakes first and counts the generated ones (`..., and N more, all generated`).
- Where the symbol is reachable from a Visual Basic or F# project, the note says `NOT ANALYSED` and names the projects: the counts cover the C# code alone, and a risk read off them says nothing about that code.
- In multi-targeted projects the counts include the references of every target framework, and a member only an older target framework declares resolves (see "Multi-targeted projects" under "Recurring conventions across the catalog").
- If every project in the solution classifies as a test project **and** `productionImpactCount` is 0, a note says so; read `directCount`/`transitiveCount` instead. The count is not structurally forced to zero: unresolved keys and markup fan-in labels can still be classified as production impact.

**Example**

```json
{ "sessionId": "<session>", "symbol": "OrderService" }
```

### `call_graph`

**Purpose.** Build a depth-limited call graph rooted at a method name.

**When to use it.** To see the shape of a call neighborhood - what a method calls, or who calls it - without reading bodies. For a single path between two methods use `trace_flow`.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `method` | string | yes | - | The root method's name. Alias: `symbol`. |
| `depth` | int | no | `2` | Maximum traversal depth. Values are clamped to 1-10. |
| `direction` | string | no | `"callees"` | `"callees"` follows project-internal calls outward; `"callers"` follows the inverse (who calls this). |

**Response.** `root`, `direction`, `maxDepth`, `edges` (pairs of caller and callee keys), `truncated`, and `rootedAt`. The edge list is cycle-safe and capped at 500 edges; `truncated` says whether the cap was hit. The key of a local function carries its character offsets, and `localFunctionKeyNote` says so when such a key appears. In the `callers` direction, `generatedStops` (`{count, note}`) counts the generated documents (`<path> (generated)`) among the callers: the walk does not continue past them to the callers of the members they declare. A method a source generator declares can be the root.

**Notes.**

- The graph is rooted at the name, not at one symbol: every same-named declaration in the solution is a root and the graph is their union. A common name such as `ExecuteAsync` can pull in unrelated members. Check `rootedAt` - the declarations actually walked - when the result looks too large, and re-query a rarer name.
- An empty `rootedAt` means the name resolved to nothing; an empty edge list alone does not tell you that.
- Note: `direction` is not validated. Any value other than `callees` selects the `callers` direction.

**Example**

```json
{ "sessionId": "<session>", "method": "RunAsync", "depth": 3, "direction": "callers" }
```

### `instantiation_sites`

**Purpose.** Find who instantiates a type - its construction and dependency-injection sites. This is the narrow "who creates or obtains an instance of X?" answer that `find_usages` (every reference: field, parameter, generic argument and so on) cannot give.

**When to use it.** When a type's constructor changes and you need the call sites that must be updated; when you want to know whether a type is obtained through the container rather than constructed; when a fan-in query on the concrete type returned a surprisingly small list.

**Availability.** Default tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `typeName` | string | yes | - | The type's simple name. Namespace and generic arguments are normalized away. Alias: `symbol`. |
| `scope` | string | no | `"solution"` | A namespace prefix that narrows which sites are scanned. |

**Response.** `typeName`, an optional `note`, `createdByCount`, `createdByTests`, `injectedIntoCount`, `injectedIntoTests`, `sites` (a capped envelope, maximum 200 entries; created sites first, then injected), and `nearest` when the name matched no declaration. Each site carries `name`, `declaringType`, `namespace`, `kind` and `isTestProject`, and `generated` - the label of the generated document - on a site in a source generator's output. A type a source generator declares is found as well.

| Edge kind | Meaning |
|---|---|
| `created` | A method, constructor, accessor or top-level code that runs `new X(...)`. This includes target-typed `new`, `record with`, and collection or `stackalloc` allocation. A field or property initializer `= new X()` is attributed to the constructor the compiler runs it in - the implicit one when none is declared - so such a site is named `.ctor`; with several non-chaining constructors, one initializer line yields one site per constructor. A creation in top-level statements is named by its file label (`<path>/Program.cs (top-level)`) with no declaring type and no namespace, so a namespace `scope` leaves it out; a multi-targeted project's file is one site. |
| `injected` | A type that receives X as a constructor-injected dependency; the container constructs X and hands it over. For these sites `declaringType` is null, because the consuming type is the site. |

**Notes.**

- Test-project sites are included, because a test that constructs X breaks when X's constructor changes.
- A concrete type registered in a dependency injection container reports `injectedIntoCount: 0` correctly: its consumers take the interface, so the injection edges sit on the interface's name. When the injected count is zero and the type implements interfaces, the note names them and points you to the query that carries the answer (`resolve_injection` confirms the registration).
- When both counts are zero, a note names the construction paths this fact cannot see: a container registration whose consumers take an interface, a generic service-locator call such as `GetRequiredService<T>()` or `GetService<T>()` (the type appears as a type argument, which is neither edge kind; a fan-in query on the type names the calling type, and `resolve_injection` counts such calls per service under `otherConsumers`), and `Activator.CreateInstance` or other reflection.
- On a session recalled from a snapshot stored before top-level creations were recorded, the answer carries `TOP-LEVEL CREATIONS NOT KNOWN` (see "Recall safety" under "Recurring conventions across the catalog").
- The tool matches the name against facts without resolving it, so a misspelled type or one outside a narrowed scope yields the same 0/0. When `typeName` matches no declaration, the construction-boundary note remains and a `nearest` suggestion appears alongside it.

**Example**

```json
{ "sessionId": "<session>", "typeName": "OrderRepository", "scope": "MyApp.Infrastructure" }
```

### `trace_flow`

**Purpose.** Trace the shortest static call path between two methods.

**When to use it.** To understand how a flow connects two methods, or which chain of callers triggers a method, before editing.

**Availability.** Not in the default tool set; reachable through a profile whose facet menu includes it (for example Exploration, Debugging, Documentation, Architecture or Performance), or via `AICB_MCP_TOOLS`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `from` | string | yes | - | The anchor method's name (the start of the trace). |
| `to` | string | yes | - | The target method's name to reach. |
| `maxDepth` | int | no | `12` | Maximum traversal depth. Values are clamped to 1-50. |
| `direction` | string | no | `"callees"` | `"callees"`: how does `from` end up calling `to`? `"callers"`: through which caller chain does `to` reach `from`? Only the exact value `callers` (case-insensitive) selects the reverse direction. |

**Response.** `from`, `to`, `direction`, `found`, `length`, `path` (an ordered `Type.Method` list from `from` to `to`), and a `note`. When no path exists within `maxDepth`, `found` is `false` and the note says so. In `callers` mode each step is called by the next. `length` counts the nodes on the path, not the hops, so a direct call reports `length: 2`.

**Notes.** Resolution is name-based. The tool follows only project-internal static call edges - not interface dispatch, events, dependency injection or reflection. It reads persisted call facts and works on recalled sessions.

**Example**

```json
{ "sessionId": "<session>", "from": "Main", "to": "SaveOrder", "maxDepth": 20 }
```

### `type_dependency_path`

**Purpose.** Trace the shortest type-dependency path between two types - the type-level counterpart to `trace_flow`. It answers the *why* of a transitive dependency, where `impact_of_change` gives only the set of impacted types.

**When to use it.** To find the chain that connects two types, for example why a domain type transitively reaches an infrastructure type - a layering smell.

**Availability.** Not in the default tool set; reachable through a profile whose facet menu includes it (for example Exploration, Debugging, Documentation, Architecture or Performance), or via `AICB_MCP_TOOLS`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `from` | string | yes | - | The anchor type's simple name (the start of the trace). |
| `to` | string | yes | - | The target type's simple name to reach. |
| `maxDepth` | int | no | `12` | Maximum traversal depth. Values are clamped to 1-50. |
| `direction` | string | no | `"dependencies"` | `"dependencies"`: how does `from` end up depending on `to`? `"dependents"`: through which dependent chain does `to` reach `from`? Only the exact value `dependents` (case-insensitive) selects the reverse direction. |

**Response.** `from`, `to`, `direction`, `found`, `length`, `path` (an ordered type-name list from `from` to `to`) and a `note`. When no path exists within `maxDepth`, `found` is `false` and the note says so. In `dependents` mode each step is depended on by the next. `length` counts the nodes on the path, so a direct dependency reports `length: 2`.

**Notes.**

- A type A depends on B when A references B: as a base type or interface, field, property, parameter, return type, generic argument, or a type used in its body. These are the same forward type-dependency edges that `find_usages` inverts and `impact_of_change` closes over, so a `dependencies` path from A to B exists exactly when A appears in `impact_of_change(B)`.
- Resolution is name-based on simple type names; cross-namespace name collisions collapse. Only intra-solution types can be endpoints - external and framework types are not.

**Example**

```json
{ "sessionId": "<session>", "from": "OrderService", "to": "SqliteOrderRepository" }
```

## 7.3 Hierarchy, implementations and lifecycle

### `find_implementations`

**Purpose.** List the types that implement an interface, whether the interface is declared in the solution or external (`IDisposable`, `IEquatable`).

**When to use it.** Before changing an interface, to see every implementer that must be updated; when you want to know whether an interface has one production implementation or many.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `interfaceName` | string | yes | - | The interface's simple name. An arity suffix in metadata or declaration form - `IConsumer`1` or `IConsumer<T>`, or `IConsumer`0` for the non-generic namesake - filters to that arity; a bare name keeps the merged view over all arities. A concrete type argument (`IConsumer<OrderPlaced>`) keeps only the types that close the interface with that argument. Case-sensitive; a namespace-qualified name matches nothing, and two interfaces sharing a simple name answer as one list. Aliases: `symbol`, `interface`. |
| `includeTests` | bool | no | `false` | Include test-project implementers. |
| `typeArgumentBase` | string | no | `null` | Keep only the types that close the generic interface with a type argument that is this type, or derives from or implements it - a simple name, case-sensitive, with an arity suffix for a generic (`DeletedNotification<T>`, `ICancelableNotification`). Only solution types form the family; when none matches, `typeArgumentBaseFilter` carries a note. |

**Response.** An optional leading `note` (set when the analysis run could not resolve all project references), the item list in the shared capped envelope (`items`, `count`, `totalFound`, `truncated`, maximum 100, sorted by name), an optional `hint`, an optional `generatedCodeNote`, `testImplementationsFiltered`, `typeArgumentFilter` on a closed query, and `typeArgumentBaseFilter` when `typeArgumentBase` is set.

Each item carries `name`, `kind` (`class`, `struct`, `record` or `interface`), `isTestProject` and, where known, `namespace`, `generated` (the label of the generated document) on a type a source generator declares, and `isAbstract` where it applies: the key is left out on interface rows and on rows whose kind is not known (`via: "back-edge"`), and a missing key means it does not apply. With `isAbstract`, an abstract base or a test fake is distinguishable from a concrete production implementer. A generic implementer additionally carries `declaration`, its arity-qualified form such as `PolicyWrap<TResult>`, so a generic and a non-generic pair sharing name and namespace stay distinguishable. `via` says how an item was found when it is not by an interface the type itself declares: `via: "back-edge"` marks an item known only from the interface's own implementer list, `via: "inherited"` a type that gets the interface through a base class or interface declared in the solution - including an interface that extends the queried one through another interface, at any depth.

On a generic interface each item also carries `closes`: the type arguments it closes the interface with, directly or through its bases and generic interfaces, one entry per distinct argument list (`ContentDeletedNotification`, or `Saved, IContent` for two arguments). An open generic implementer names its own type parameter; a position that cannot be read - an outer type parameter of a nested type - is written `*`. An item that does not name the interface in its own base list carries `through`: the base class or interface it gets it through (`IContentLastChanceFinder`, or `WebhookEventBase<TNotification>` for a generic solution type). Both are omitted when empty or when the chain could not be read.

**Generic interfaces.** A bare or arity query on a generic interface the solution declares (`IHandler`, `IHandler<T>`) lists every type that implements it, whatever type arguments it closes the interface with: those that declare it directly, and those that get it through a base class (generic or not) or another interface, at any depth below (`Update : HandlerBase<Saved, string>`, `Leaf : Update`), marked `via: "inherited"`. The same holds for a non-generic interface nested in a generic type (`Outer<T>.INested`). A type in the global namespace and a namespaced type of the same simple name are not taken for each other.

**Closed queries.** A query with a concrete type argument (`IHandler<Saved>`) lists the types that close the interface with those arguments, also through base classes and generic interfaces; such a walked item carries no `via` when the solution declares the interface. The closed answer is always a subset of the open one: the subclass of an unrelated same-named base class is not listed. A position written as a type parameter (`T`, or the name the interface itself declares there) is a placeholder, so `IHandler<T>` and the metadata form keep the arity answer. `typeArgumentFilter` reports `typeArguments` and counts the arity-matching types - test projects included - that were left out because they close the interface otherwise (`otherClosings`) or only over their own type parameters (`openClosings`), and how many stayed with an unreadable closing (`unresolved`). Such an item stays in the list, marked `closing: "unresolved"`.

**Type-argument families.** `typeArgumentBase` answers "which classes handle any notification of this family": it keeps the implementers that close the interface with an argument that is the named type or derives from or implements it, at any depth, including types that get the interface through a base class. Like the closed form it filters before the test filter. An implementer whose closing cannot be read stays in the list, marked `closing: "unresolved"`. `typeArgumentBaseFilter` reports `base`, `familyTypes` (how many solution types form the family), `leftOut` (the implementers no family argument closes, test projects included) and `unresolved`, and a `note` when nothing could match - the interface is not generic, or no solution type and no implementer names the base.

**Notes.**

- Test-project implementers are excluded by default. When that filter removed something, `testImplementationsFiltered` reports how many - a short list is never silently short. Set `includeTests: true` to see them.
- An empty result carries a `hint` in two cases: when the name is a type that is not an interface (the hint points to `get_type_hierarchy` and `find_overrides`), and when no type in the index carries the name at all (the hint says so and carries a did-you-mean when one is close enough; a delegate counts as undeclared). An empty list is a statement about the name, not about implementers.
- `generatedCodeNote` flags a source generator that did not run in the interface's project, as on the other declaration tools (see "Recurring conventions across the catalog"). On an empty result it also appears when a generator that did not run may have added the interface below it - in a project that uses the interface's project, or in any project for an interface the solution does not declare.

**Example**

```json
{ "sessionId": "<session>", "interfaceName": "ICodeAnalyzer", "includeTests": false }
```

```json
{ "sessionId": "<session>", "interfaceName": "INotificationHandler", "typeArgumentBase": "DeletedNotification<T>" }
```

### `find_overrides`

**Purpose.** List the override-to-base relationships for methods of a given name - the class-inheritance counterpart to `find_implementations`. It answers both "who overrides this virtual or abstract method?" (impact) and "what does this override?" (comprehension) in one call.

**When to use it.** Before changing a virtual or abstract method's signature, and when you want to see how a base behavior is specialized across the hierarchy.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `methodName` | string | yes | - | The method's exact (case-sensitive) simple name, for example `ToString` or `Dispose`. Alias: `symbol`. |

**Response.** The shared capped envelope (`items`, `count`, `totalFound`, `truncated`, maximum 100). Each entry pairs an overriding method with the nearest ancestor that declares the virtual or abstract method it overrides, rendered as `Derived.M(params) overrides Base`. Container and base render in their declaration form, for example `Strategy<T>.M(...) overrides ResilienceStrategy<TResult>`. When the overridden base is a framework virtual outside the solution, the entry reads `... overrides (external base)`. An override a source generator wrote reads `Derived.M(params) (generated) overrides Base`. An empty list means no overrides of that name were found.

**Notes.** Two same-named types that differ only by namespace, or that declare identical type-parameter names, render identically and collapse into a single row - the list carries no namespace. Treat a row as the relationship, not as one attributed type. Where a row stands for same-named types from different namespaces, `mergedNamesakes` follows the list and names each such row and its types. When the overriding type has the same simple name as its base, the row still names the base that declares the overridden member.

**Example**

```json
{ "sessionId": "<session>", "methodName": "Dispose" }
```

### `get_type_hierarchy`

**Purpose.** Walk a type's inheritance hierarchy in both directions: the base-class chain upward and the transitively derived types downward, plus the type's implemented interfaces.

**When to use it.** To see where a type sits in the hierarchy, which types derive from a base, or which interfaces a type implements. For "who implements this interface", use `find_implementations` instead - interfaces never appear as a base class, so an interface's `derivedTypes` is empty.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `typeName` | string | yes | - | The type's exact (case-sensitive) simple name. Add an arity suffix - `Repository<T>` or `Repository`1` - to address a generic type unambiguously when a generic and a non-generic type share the name. Alias: `symbol`. |

**Response.** `type`, `resolvedKind`, an optional `note` (the run-wide qualification), an optional `hint`, an optional `generatedCodeNote`, `mergedNamesakes`, `separatedNamesakes`, `mergedArities`, `baseChain`, `interfaces`, `derivedTypes` (a capped envelope, maximum 100) and, on `not_found`, a trailing `nearest`.

- `baseChain` lists the base-class chain upward, nearest base first. When the chain leaves the solution, the last entry names the external base, for example `ObservableObject (external)`. A base type outside the solution that only shares its simple name with a type inside it ends the chain as external.
- `interfaces` lists the interfaces the type itself declares - one inherited through a base class is not repeated; for an interface query these are its base interfaces.
- `derivedTypes` lists transitively derived types, one entry per type (partial fragments and the instances of a multi-targeted project stay one entry, and `totalFound` counts types); each entry reads `Derived : DirectBase`, so the subtree structure is preserved in the flat list, and ` (generated)` marks a type a source generator declares. Test-project types are included and not marked.
- Every link is rendered arity-qualified, so a same-name generic and non-generic type are distinguishable. Types sharing a simple name are written by full name, for example `Ef.User : Core.User`, and where the full name is shared too - the same type in two projects - the project follows in brackets (`Extensions [MyApp.Web] : ExtensionsBase`). A link between two types of the same simple name is kept in both directions.
- `mergedArities` is set when a bare name matches a generic type and its non-generic namesake: the view merges them, and the field says whose base chain is shown.
- `resolvedKind: "not_found"` answers three empty lists: no type of that name is declared in the solution - also for an external base, a delegate type, a namespace-qualified name, a nested `Outer.Inner` form, or an arity suffix no declaration has. A trailing `nearest` then gives a close declared type name, for a qualified form the simple name. A Blazor component written only in a `.razor` file is named in the `not_found` note with its file, because its class has no symbol here.

**Notes.**

- The simple-name index merges namesakes - same simple name, different declared type, from a foreign namespace or a different declaring type. When the answered view merged such types, `mergedNamesakes` names them ahead of the lists they may affect. An arity suffix separates arities only; namesakes cannot be separated.
- `derivedTypes` lists a type only when its declared base really is the resolved type. A derivation from a same-named *other* type - typically a framework base shadowed by an in-solution namesake - is excluded and counted in `separatedNamesakes`, which names the resolved type and the foreign bases. Without it, an empty `derivedTypes` on a name the solution plainly uses as a base would read as "nothing derives from this".
- An interface query carries a `hint` stating that `derivedTypes` covers class inheritance only and pointing to `find_implementations`.

**Example**

```json
{ "sessionId": "<session>", "typeName": "GraphSectionRendererBase" }
```

### `lifecycle_of`

**Purpose.** Map the full lifecycle of a type T in one edge-partitioned slice - who creates, injects, returns, references and persists it - instead of calling `find_usages` and `instantiation_sites` separately and partitioning by hand.

**When to use it.** When you need the whole picture of how a type is produced and consumed; and for the recurring "persisted but dropped" bug class: if the write leg shows up in `created` or `persisted` but nothing reads T back, that asymmetry is the smell.

**Availability.** Not in the default tool set; reachable through a profile whose facet menu includes it (for example Exploration, Debugging, Documentation, Architecture or Performance), or via `AICB_MCP_TOOLS`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `typeName` | string | yes | - | The type whose lifecycle to map. Simple name; namespace and generic arguments are normalized away. Alias: `symbol`. |
| `scope` | string | no | `"solution"` | A namespace prefix that narrows which sites are reported - not the target type. |

**Response.** `typeName`, `scope`, an optional leading `note`, `targetIsDeclared`, `typesScanned`, `methodsScanned`, and the five buckets `created`, `injected`, `returned`, `referenced` and `persisted`. Each bucket is a capped envelope with its true total (maximum 100 entries), and each entry carries `name`, `declaringType` and `namespace`.

| Bucket | Meaning |
|---|---|
| `created` | Methods, and files of top-level statements, that run `new T(...)`. A top-level file is named by its label (`<path>/Program.cs (top-level)`) with no declaring type and no namespace, so a namespace `scope` leaves it out. |
| `injected` | Types that receive T as a constructor-injected dependency. |
| `returned` | Methods whose return type is or wraps T - `Task<T>`, `IReadOnlyList<T>` and other factory shapes included. |
| `referenced` | The full type fan-in, equivalent to `find_usages`. This is the read/use umbrella and deliberately overlaps the specific buckets. |
| `persisted` | Best-effort: methods with a database or serialization side effect that reference T - the persist and round-trip edge. |

**Notes.**

- The answer states what it looked at: `scope` echoes the applied filter, `typesScanned` is the population behind `injected` and `referenced` (a partial type counted once), and `methodsScanned` is the population behind `created`, `returned` and `persisted` - it also counts the top-level files whose creations were read (a file that creates nothing is not counted). Because `scope` narrows the sites of every bucket, it is a second route to five zeros that has nothing to do with the type.
- `targetIsDeclared` says whether a type of that simple name is declared in the solution at all. `false` means an external type or a misspelling, and any edges shown are then this solution's use of an outside type rather than that type's lifecycle.
- A `note` leads the buckets whenever a zero needs qualifying.
- Like `find_usages` and `instantiation_sites`, this is a discovery and impact tool, so test-project sites are included.
- It reads persisted facts and works on recalled sessions. A session recalled from a snapshot stored before top-level creations were recorded carries `TOP-LEVEL CREATIONS NOT KNOWN` on an unscoped query, also on a populated answer.

**Example**

```json
{ "sessionId": "<session>", "typeName": "OrderDto", "scope": "MyApp.Application" }
```

## 7.4 Tests and coverage

### `find_tests_for`

**Purpose.** Find the test cases that likely cover a symbol.

**When to use it.** Before changing a symbol, to see which tests pin it; when you want to know whether a method is exercised at all.

**Availability.** Core tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `symbol` | string | yes | - | A type name, or a member name either bare or in the qualified `Type.Member` form - the same strings `find_usages` and `impact_of_change` resolve, a user-defined operator by its metadata name (`op_Equality`) included - or `Type.Type` for the constructor. |

**Which methods count as tests.** Only a method that itself carries a test attribute counts - an actual runnable test, not a fixture builder or helper that merely lives in a test project. The default attribute set is `Fact`, `Theory`, `Test`, `TestMethod` and `TestCase`, matched as a case-insensitive substring so that variants such as `WindowsFact` are recognized. The set is configurable through the solution's test profile.

**Response.** The shared capped envelope (`items`, `count`, `totalFound`, `truncated`, maximum 50), plus `invokesTotal`, `dispatchTotal` (omitted at 0) and an optional `note` after the list. Each item carries `testType`, `testMethod`, `project` and `matchReason`.

**Match tiers.** `matchReason` names one of eleven tiers, in sort order:

| Tier | Meaning |
|---|---|
| `invokes` | The test calls the target itself. |
| `invokes-via` | The test reaches the target through one method or constructor it calls - still strong, but second-hand. A test that builds an object reaches what that object's constructor calls. |
| `command` | The test reads the generated command property of a `[RelayCommand]` target method, or a hand-written command property that a body of the target's type builds on it, and executes the command. This is a pairing by the generator's naming rule, not a recorded call. |
| `command-via` | The same through one method the test calls; or the test executes the generated command of a `[RelayCommand]` method that calls the target. |
| `accesses` | The test reads or writes the target property or field; for a type, a static one. |
| `accesses-via` | The same, through one method or constructor the test calls. |
| `constructs` | The test builds the target type (type and constructor queries only). |
| `constructs-via` | The same, through one method or constructor the test calls. |
| `dispatch` | The test calls an interface or abstract member the target implements; a test double may have run instead. |
| `dispatch-via` | The same, through one method or constructor the test calls - or the test reaches the target through a getter it reads only through the interface or base property that getter implements or overrides; a note names that property. |
| `name` | The weak guess: the test's own name or its test class's name mentions the symbol at an identifier-segment boundary - for `Type.Member`, both names. A mid-word substring is not a mention. |

The first eight tiers are strong; `dispatch` and `dispatch-via` are contract rows, and `name` is a guess. The evidence reaches one call deep at most: the test's body and one method or constructor it calls, or one property getter it reads, or for a command row the one `[RelayCommand]` method that calls the target. A deeper chain (helper calling helper) or a table-driven sweep is not counted, so an empty answer is not "nothing pins this". `invokesTotal` counts the strong rows and `dispatchTotal` the contract rows over the whole result, not only the returned page; `totalFound` minus both is the number of name guesses. Stronger evidence sorts first, so the cap can only drop the least load-bearing end.

**Notes.** The `note` says so on an empty answer, and names the other cases where the bare numbers mislead:

- A query that names nothing declared at all, or a qualified query whose type segment names no declared type. Matching is case-sensitive, so every hit is weak name noise - it describes the spelling, not this solution's coverage.
- An event or an enum member. Only the name tier can match it.
- A nested type in the `Outer.Inner` form.
- A constructor query (`Type.Type`).
- Contract rows (`dispatch`, `dispatch-via`), and construction rows, which are matched on the type's simple name, so a same-named type counts too.
- A non-empty answer in which no row is strong (`invokesTotal` 0) - only name guesses or contract rows. The note says that the list does not show that anything pins the symbol, and for a member it adds the declaring type's own count as a cross-check.
- A method that a body subscribes as an event handler (`+= OnX`) is not a call to it. Tests whose only edge to the method is such a subscription are counted in the note and not listed as invocations, and the note says that this tool follows no event raise, so a test that raises the event is not listed on the strength of the raise.
- `namesakes` - set when the name matches several declared types: the answer is their union, and the field says which types share the name.
- When the answer is the union of several overloads, the note leads with that.
- A symbol a source generator declares, and a member only an older target framework of a multi-targeted project declares, resolve as in `find_usages`; a row for the latter names that framework's test project instance, for example `Tests(net462)`.

**Example**

```json
{ "sessionId": "<session>", "symbol": "OrderService.Cancel" }
```

### `coverage_gaps`

**Purpose.** Surface negative knowledge for a scope: methods that no test invokes directly, and semantic axes that are explicitly declared absent.

**When to use it.** Before claiming that code is covered; when you want a list of untested methods; when you want to know which semantic annotations are deliberately blank.

**Availability.** Default tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `scope` | string | no | `"solution"` | `"solution"` or a namespace prefix to narrow which symbols are checked. |

**Response.** `scope`, an optional `note`, `symbolsScanned`, `uncovered` (a capped envelope, maximum 200), `verifiedAbsent` (a capped envelope, maximum 200), `transitivelyReached`, `judgedUnits`, `testProjectsExcluded`, `testFixtureTypesExcluded`, `reachedOnlyThroughDispatch` and, where they apply, `commandCreditRefused` and `unfollowedAccessorCallers`.

| Field | Meaning |
|---|---|
| `uncovered` | Methods that no test invokes directly. Each item carries `kind`, `name`, `declaringType`, `namespace` and, when applicable, `testReachDepth`, `viaDispatch`, `unfollowedAccessor` and `outerType` (the enclosing type of a nested type). |
| `unfollowedAccessorCallers` | How many entries carry `unfollowedAccessor` (see the notes). |
| `verifiedAbsent` | Semantic axes the developer explicitly declared as `none`. Each item carries `kind`, `name`, `declaringType`, `namespace` and `field`. |
| `symbolsScanned` | Every unit in scope, methods and types. |
| `judgedUnits` | The non-test, non-abstract methods the uncovered list is drawn from - the population behind the gap count. |
| `testProjectsExcluded` | The distinct test-classified projects whose units were excluded. |
| `testFixtureTypesExcluded` | The distinct types excluded through the attribute-inferred fixture axis: a type that declares a test-attributed method is a test fixture, so its attribute-less `SetUp`/helper scaffolding is test code even when the project's name matches no test rule. Its constructors, its getters and its field and event initializers count as test code too. |

**The one-hop definition.** The uncovered list is a one-hop index, not a coverage measurement. A method that a test reaches through another method - a CLI verb behind its command builder - is listed as uncovered although it is thoroughly exercised. Therefore read the per-entry `testReachDepth`: the hops to the nearest directly tested method, where 1 means a directly tested method calls it. Entries without that field are the ones no test reaches at all - work those first. A shallow depth is close to "already exercised" (confirm with `find_tests_for`); a deep one is more likely incidental.

The entries are marked rather than filtered out, because a deep transitive path is not the same claim as a test, and silently hiding a genuinely untested method would be the worse error for a tool whose job is negative knowledge.

**Notes.**

- A non-empty answer leads with a `note` carrying the split for that answer - how many of the listed methods are reached from a test through intermediate calls - and the same count is available as `transitivelyReached`. When no listed method is reached even indirectly, the note says so instead.
- A constructor is a hop of the walk, never an entry of the list: `new X(...)` reaches the constructor overload it binds and what that constructor calls, so a method only a constructor calls gets a `testReachDepth`. The walk also follows an object that a field or property initializer creates: the code its constructor calls counts as reached when a test creates the containing object.
- A property read is a hop too: a test that reads a property reaches what its getter calls, also when it reads the property through an interface or base property, and reading or writing an indexer of a solution type reaches that indexer's getter or setter. An entry without `testReachDepth` that only an accessor the walk does not follow calls - a setter, an indexer, an event accessor or an explicit interface getter - carries `unfollowedAccessor` (the accessor kind), and `unfollowedAccessorCallers` counts them: its missing depth is unknown, not measured. Such an entry is marked only where its member has a user, a XAML binding included, or may have one aicb cannot see.
- The walk also follows interface, abstract and virtual dispatch - a getter read through an interface or base property included; an entry reached only that way carries `viaDispatch`, and `reachedOnlyThroughDispatch` counts them.
- A `scope` that matches no namespace answers `symbolsScanned: 0` with a `note` that says where to look instead: the namespace of a type the prefix names, the namespaces that contain the prefix as whole segments, or the closest namespace.
- Abstract and interface method declarations are excluded: they have no body and are not coverable units.
- A weak test-name match does not count as coverage here; it is too weak to prove anything.
- An entry without `testReachDepth` may carry `commandCreditRefused`: the number of test or test-reached bodies that read the command running the method, execute a command and also read another command property. The facts do not show which command ran, so no reach is credited, and such an entry may still be reached - its missing depth is unknown, not measured.
- Runtime coverage from a coverage tool remains the only measurement that sees reflection, generated and framework-invoked paths.
- Absence of a detected test is not proof that zero tests exist.
- Dispatchable through `batch`/`measure`.

**Example**

```json
{ "sessionId": "<session>", "scope": "MyApp.Application" }
```

### `find_by_complexity_and_coverage`

**Purpose.** The prioritized refactor and test list: the methods that are both complex and have no direct test call - the intersection of the complexity ranking and the uncovered list, in one call, ranked by complexity descending so the riskiest float to the top.

**When to use it.** When you want to pick the next refactoring or test target by risk rather than by browsing two separate lists.

**Availability.** Not in the default tool set; reachable through a profile whose facet menu includes it (for example Refactoring, Debugging, Review, Testing or Performance), or via `AICB_MCP_TOOLS`.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `minComplexity` | int | no | `0` | Complexity floor. Only methods with cyclomatic complexity greater than or equal to this value are considered; 0 means no floor. The list is ranked by complexity descending regardless. Raise it, for example to 10, to keep only genuinely complex untested methods. |
| `scope` | string | no | `"solution"` | `"solution"` or a namespace prefix to narrow scope. |

**Response.** `scope`, an optional leading `note`, `minComplexity`, `complexMethodCount`, `uncoveredMethodCount`, `methods` (a capped envelope, maximum 200, complexity descending), `transitivelyReached` and, where they apply, `reachedOnlyThroughDispatch` and `unfollowedAccessorCallers`.

`complexMethodCount` and `uncoveredMethodCount` report the two input sizes - the complex methods at or above the floor, and the uncovered methods in scope. Each item carries `name`, `declaringType`, `namespace`, `cyclomaticComplexity`, `parameterCount` and, when applicable, `testReachDepth` and `unfollowedAccessor` (an item without a depth that a setter, an indexer, an event accessor or an explicit interface getter calls: its missing depth is not measured; `unfollowedAccessorCallers` counts them).

**Notes.**

- The tool inherits the one-hop definition from `coverage_gaps`, property reads into the getter included: a method a test reaches through another method is in this list too. Read the per-item `testReachDepth` and treat the items without it as the real candidates - the distinction matters more here than in `coverage_gaps`, because this output is a worklist people act on. A non-empty answer leads with a note carrying that split.
- There is no `includeTests` switch, deliberately: the complexity half excludes test-project methods, and a test method is by definition never untested.
- Overloads remain separate entries, each with its own complexity and parameter count; the shared `(namespace, declaring type, name)` key is only used to look up coverage.
- It composes two persisted-fact services and works on recalled sessions.

**Example**

```json
{ "sessionId": "<session>", "minComplexity": 10, "scope": "MyApp.Core" }
```

### `assert_absence`

**Purpose.** Check a negative claim against the analyzed model and return `confirmed`, `refuted` or `indeterminate` with the evidence.

**When to use it.** To validate statements such as "this service is untested" or "this axis is explicitly unset" before relying on them.

**Availability.** Default tool set.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `claim` | string | yes | - | One of the three claim forms below. |

| Claim | Meaning |
|---|---|
| `no_tests:<Symbol>` | The symbol has no detected covering test. |
| `absent:<Symbol>.<axis>` | The semantic axis is verified-absent - a developer explicitly declared `none`, not merely unknown. |
| `unknown:<Symbol>.<axis>` | The axis has no provenance entry at all. |

`<Symbol>` is a bare name or the qualified `Type.Member` form - the same strings that `find_usages`, `find_tests_for` and `impact_of_change` resolve. `axis` is one of the semantic axes, for example `role`, `layer`, `domain`, `context` or `responsibility`.

**Response.** `claim`, `claimType`, `symbol`, `axis`, `verdict`, `reason` and `evidence` (a list of strings).

**Verdicts.**

| Verdict | Meaning |
|---|---|
| `confirmed` | The model supports the claim. For `no_tests` this means no covering test was detected. For `absent` the axis really is verified-absent. For `unknown` the axis really has no provenance entry. |
| `refuted` | The model contradicts the claim. For `no_tests` this requires at least one strong covering test, as `find_tests_for` defines its tiers. For `absent` the axis has a provenance source other than verified-absent. |
| `indeterminate` | The model cannot decide. |

**Notes.**

- The tool is conservative in both directions: what the model cannot prove is `indeterminate`, never falsely confirmed - and never falsely refuted either.
- Tests that merely carry the symbol in their name yield `indeterminate` with the invokes/name-only split disclosed in the reason, not a refutation; a test named after a symbol is not proof that it exercises it.
- For a property, field, event or enum member, `no_tests` can only ever rest on name matches, because that member kind carries no invocation edge; the reason says so.
- A name that resolves to nothing is reported as such - a statement about the name, not about the code. A `no_tests` claim that names a declared type by its namespace-qualified name is not reported as undeclared: the reason names the type and asks for its simple name.
- An axis name that is not recorded anywhere in the solution returns `indeterminate` with the actually recorded axes as evidence. A typo or an invented axis is never silently `confirmed`.

**Example**

```json
{ "sessionId": "<session>", "claim": "no_tests:OrderService.Cancel" }
```

## 7.5 Dependency injection

### `resolve_injection`

**Purpose.** Resolve a `Microsoft.Extensions.DependencyInjection` or MEF registration: given a service type - an interface, or a class registered as itself - return what is registered for it, the lifetime, and where the registration happens - `location` (the registering call as file and line), `project` and `declaringMethod`.

**When to use it.** When you need to know which implementation is wired for an interface, which lifetime applies, or where a registration lives; when a fan-in or instantiation answer suggests a container registration. It does not answer usage (`find_usages`), implementers (`find_implementations`) or construction (`instantiation_sites`).

**Availability.** Default tool set. Note: this tool needs a live analyzed session; a session restored from a saved snapshot cannot answer it.

**Parameters**

| Parameter | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `sessionId` | string | yes | - | Session id, or an absolute `.sln` path for self-init. |
| `interface` | string | yes | - | The service type's simple or fully qualified name, for example `ICodeAnalyzer`. A closed generic form (`IHandler<Saved>`) lists only the registrations serving that closing, together with the open registrations (`IHandler<>`) that serve every closing; `IHandler` or `IHandler<T>` lists every closing. Aliases: `symbol`, `interfaceName`. |
| `site` | string | no | `null` | Narrow to registrations whose file path contains this substring. |
| `includeTests` | bool | no | `false` | Include registrations declared in test projects. |

**What is scanned.** `AddSingleton`, `AddScoped` and `AddTransient`, their `TryAdd*` variants and keyed forms - in generic, `typeof`, instance and factory-lambda form. Beyond these:

- **Project-local registration helpers.** A helper declared in the solution that registers its own type arguments is followed into its body, whatever its name - a wrapper such as `AddCachedSingleton` as well as an `AddHandler<TEvent, THandler>()`. Each call of the helper is read with its own type arguments, and such a row carries the note `via <helper>`. A generic the helper builds over its type parameter is closed with the call's arguments; a keyed call inside the helper takes each call's own key (a key the helper computes from what it is handed reads `(dynamic)`); a factory lambda names its product where the body shows one type. Where a call read through the helper is in view, the helper's own body line is not listed again, and two identical `TryAdd`s that one call reaches under the same key are one row.
- **Service descriptors built at the call.** `Add`, `TryAdd`, `TryAddEnumerable` and `Replace` on the service collection, handed a `ServiceDescriptor` the call shows being built: in place (`new ServiceDescriptor(...)`, `ServiceDescriptor.Singleton`/`Scoped`/`Transient`/`Describe` and the keyed factories), in a local that is not written again, or as the elements of the collection a `TryAddEnumerable` takes (one row per element). A row from `TryAdd`, `TryAddEnumerable` or `Replace` is noted with that name; a plain `Add` carries no such note.
- **`AddHostedService<T>()`** and its factory overload: `IHostedService` implemented by `T`, Singleton, note `AddHostedService`.
- **Package helpers with an `As` chain.** A package extension such as `AddSingletonAs<T>()`, whose body the analysis does not read, followed by `.As<I>()` or `.AsSelf()`, is read from its call shape alone: it registers `I` (or `T` for `AsSelf()`), implemented by `T`, with the lifetime its name says. Such a row carries the note `inferred, not read: ...` naming the helper and its assembly, and the answer says once which helpers were read this way and that what else they register - and whether they add, try to add or replace - is not known.
- **One data-driven shape:** a `foreach` over a static table of `new(typeof(Service), typeof(Impl))` rows is expanded into one registration per row, also when the table lives in another project. Such a registration carries the note `table row <file>:<line>`.
- **MEF exports.** An `[Export]` attribute of `System.ComponentModel.Composition` or `System.Composition` (or an attribute derived from their `ExportAttribute`) on a class, struct or record, or on its methods, properties and fields, is a registration row. The service is the `typeof` argument, else the part or the member's type; `key` is a contract name as written; `implementationType` is the part, or `(factory)` for a member export. The lifetime: MEF 1 `[PartCreationPolicy(CreationPolicy.Shared)]` is `Singleton` and `NonShared` is `Transient`, otherwise `(dynamic)`; MEF 2 `[Shared]` on any partial declaration is `Singleton`, else `Transient`; an export whose attribute does not bind (an unrestored project) reads `(dynamic)`. The `note` reads `MEF export`, followed for a derived attribute by ` via [Name]: the service is read from its type argument; the contract it hands MEF is set in its constructor` and for a member export by `; member Part.Member`. MEF rows never make `ambiguous` true and never win `effectiveRegistration`; beside Microsoft DI registrations the winner is judged over those alone.

**What is not read:** a `ServiceDescriptor` that is not built at the call or in a local there (a parameter, a loop variable, a method result, a conditional, a reassigned local, a collection held in a local, a spread element), framework helpers that register on the caller's behalf (`AddHttpClient`, `AddDbContext` and the like), Scrutor assembly scans, Autofac, Castle Windsor and other non-Microsoft containers, and of MEF: a derived export attribute without a `typeof`, a method export without a `typeof`, `[InheritedExport]` on an interface, a convention builder, and an `Export` attribute that does not bind in a file importing no MEF namespace (such as Xamarin's selector attribute). Umbraco collection builders are read, but as operations under `collectionBuilders`, not as registrations.

A call whose service type is a runtime value - reflection or assembly scans, a method result, a deconstructed loop variable - is not expanded, and neither is a factory lambda whose product cannot be named. Instead a `note` names those sites and which kind each one is. A site that demonstrably cannot register the queried service - for example one that registers a class as itself while the query is an interface - is left out of that list and only counted with its reason. An empty list with such a note means "not statically visible", not "not registered".

A factory that *returns* its object is resolved: both `sp => Foo.Build()` and a block body whose `return` statements all agree on one type. Where they disagree, or where there is no `return` at all, the product stays unnamed and the site is disclosed rather than guessed at. A `return` inside a nested lambda or local function belongs to that function, not to the factory.

**Response.** `query`, `matchCount`, `ambiguous`, `multiRegistration`, `registrationSites`, `consumedAsCollection`, `testRegistrationsFiltered`, and `registrations`. On a closed query the answer adds `typeArgumentFilter`; for an Umbraco collection builder it adds `collectionBuilders` (see the table), and the answer's `note` says `A collection builder collects types for this name: see collectionBuilders.` Each registration carries `serviceType`, `implementationType`, `lifetime` (`Singleton`, `Scoped` or `Transient`; `(dynamic)` for a MEF part whose creation policy is not fixed or not readable), an optional `note`, `location` (file and line of the registering call; a relative path such as `..\...` for a project outside the solution folder), `project`, `declaringMethod` (`Type.Method`; null for top-level statements), `key` for a keyed registration (omitted otherwise) and `isTestProject` when the registration comes from a test project. `serviceType` carries its type arguments - `IDisplayDriver<ISite>`, `IHandler<>` for an open registration, `IHandler<TModel>` where a type parameter of the surrounding code fills it - while `implementationType` is a simple name, the service itself for a self or instance registration. A keyed call (`AddKeyedSingleton<IFoo, Foo>("k")`, also the non-generic `AddKeyedSingleton(typeof(IFoo), "k", typeof(Foo))`) keeps its key: two keys are two services, and so are two closings (`IRepo<A>`, `IRepo<B>`).

Rows noted `inferred, not read` count as rows - in `matchCount`, `multiRegistration`, `registrationSites` and the closed-query filter - but not as evidence about how the helper adds: they take no part in `ambiguous`, never name an `effectiveRegistration` winner, and never make an optional dependency read `yes`.

| Field | Meaning |
|---|---|
| `registrationSites` | How many distinct registration sites matched. |
| `multiRegistration` | Whether more than one registration matched at all. |
| `consumedAsCollection` | True when the service is consumed as a collection somewhere - a `GetServices<T>()` or `GetServices(typeof(T))` call, or an `IEnumerable<T>`-family or `T[]` constructor parameter, optional and nullable ones included. Several registrations are then a deliberate multi-binding. Consumers declared in test projects count only under `includeTests`, exactly as the registration list does. |
| `ambiguous` | Judged within one registration site (one declaring method, or the file outside any method) and per service (per key and per closed service type): true only when that site registers more than one distinct, statically resolvable implementation and `consumedAsCollection` is false. Two rows that both add to the service's set (`TryAddEnumerable`, `AddHostedService`) are no conflict. Across sites it is deliberately not ambiguity: a solution with several hosts (GUI, CLI, MCP) registers the same service once per host, and those containers never meet. Use `registrationSites`, `multiRegistration` and the per-registration `declaringMethod` to judge the case this grain cannot see: two helper methods composed by the same host. |
| `effectiveRegistration` | Present when two or more registrations match: `winner` is the registration a single-service resolve receives - the last one kept, with `TryAdd*` keeping nothing once the service is registered - read only where the order is certain, within one straight-line registration method. Otherwise `winner` is `null` and `reason` says why (for example several sites, a call inside a branch or loop, two types of one simple name, a `TryAddEnumerable`, `Replace` or `AddHostedService` with its rule named, or a row inferred from a package helper's call shape). A descriptor `Add`/`TryAdd` takes part in the order like `AddSingleton`/`TryAddSingleton`. Keyed registrations are set aside, because a plain resolve never receives one. When a service has two or more MEF exports and no Microsoft DI registration, `reason` says that MEF composes by contract and no export wins. |
| `constructorConsumerCount` | How many types take the service as a plain constructor parameter - visibility, never a usage verdict. |
| `otherConsumers` | The consumers that take the service other than through a constructor parameter, one entry per form found: `locator` (a `GetService<T>()`, `GetRequiredService<T>()` or `GetService(typeof(T))` call or its keyed twin, whatever the receiver - `Ioc.Default`, an `IServiceProvider` - also through `?.`) and `inject-property` (a C# property with `[Inject]`, a Razor `@inject` directive, an `[Inject]` property in a `@code` block, in `.razor` and `.cshtml` files outside build output). Each entry carries `form`, `consumers` (distinct declaring types; a Razor file, and a call outside any type, count as their own consumer), `sites` (calls or properties; a Razor file is one site) and `examples` (up to three, as `File.cs:line`; a Razor example carries no line). Test projects count only with `includeTests`. `GetServices<T>` stays with `consumedAsCollection`. Omitted when there are none. |
| `optionalDependencies` | The constructors taking the service as an optional parameter, each judged `yes`, `no` or `unknown`. A closed generic service is judged against the registrations of its own closing only, so a `yes` that came from a registration of another closing reads `no`. In a multi-targeted project there is one entry per parameter under the project's own name, with a `targetFrameworks` list. On a MEF export row, an optional constructor parameter of the part is never judged `yes` (it reads `unknown`), because MEF fills an importing constructor from its imports. |
| `typeArgumentFilter` | On a closed query only: `typeArguments`, `otherClosings` (registrations of the same name closed with other arguments, left out; `matchCount + otherClosings` is the answer to the bare name under the same filters), `unresolved` (rows whose closing the call does not fix, kept in the list) and a `note` saying which fields stay at the level of the bare name - `otherConsumers` among them, which reads every closing. |
| `testRegistrationsFiltered` | How many registrations the default test filter removed. Omitted when nothing was hidden. |
| `collectionBuilders` | Umbraco collection builders whose collection, item type, builder or collected types the query names - listed apart, never as registrations: `registrations`, `matchCount` and the other fields are unchanged by them. A `note`, and per builder `builder`, `collection`, `item`, `operationCount`, `unreadCount` and up to 100 `operations` in the order they are written (by project, file and position), each with `operation` (`append`, `insert`, `insertBefore`, `insertAfter`, `add`, `remove`, `replace`, `exclude` or `clear`), `type`, `anchor` (for `insertBefore`, `insertAfter` and `replace`), `location` and `project`. `type` is null for `clear`, for a type passed as a runtime value and for a generic helper's own type parameter; the last two count in `unreadCount`. The builder registers each collected type as itself and the collection through a factory, so nothing registers the item type, and the resulting order and set depend on the order the composers run in. A builder is recognized by Umbraco's `CollectionBuilderBase` (namespace `Umbraco.Cms.Core.Composing`); a namesake in another namespace is not. The `site` and test filters apply to the operations as to the list. Omitted otherwise. |

**The three empty answers are distinguishable.**

1. A name nothing in the solution names - no declaration, no registration, no base list, parameter, type argument, `typeof`, Razor `@inject` or `[Inject]` property that writes it - carries `resolvedKind: "not_found"` and a `nearest` suggestion: a typo. A closed query whose name is registered with other closings is not `not_found`; its note names the closed form.
2. A real name with no registration always carries a `note`. Its basic form opens `No Microsoft.Extensions.DependencyInjection (Add*/TryAdd*, keyed included) registration and no MEF [Export] naming '<name>' was found` and states the reader's boundary - nothing was found, which means "not statically visible", never "not registered" - scoped to the answer's view (it says when registrations in test projects or outside the `site` filter were left out), and it names the forms that are not read together with which of them the solution actually holds:
   - registration helpers whose body is not read - a package's, or one a source generator writes - by call count, pointing first at helpers from the assembly that declares the queried type or named after it, and at calls that pass the type or an implementer as a type argument;
   - registration by convention: types marked `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` or `[ExposeServices]` are counted, with a pointer to the types that name the service in their base list or in `[ExposeServices]` (a non-empty answer gets the pointer alone);
   - MEF parts exported through `[InheritedExport]` on an interface or a convention builder (an `[Export]` attribute is read);
   - calls whose service type is a runtime value, as described above;
   - for an interface the solution does not declare, that the library declaring it may register it in code this scanner does not see;
   - when a scanned project references a foreign container assembly, that sign, because its registrations are invisible here.
3. Everything was filtered out by the test filter, reported as `testRegistrationsFiltered: N`; the note says how many were left out and that `includeTests: true` lists them.

**Notes.**

- Test-project registrations are excluded by default - a test's own container stub is not the production binding. Set `includeTests: true` to include them; each one is flagged `isTestProject`. The same filter reaches collection CONSUMPTION: a fixture taking `IEnumerable<T>` does not, on its own, mark a production conflict between two registrations as deliberate.
- A service consumed as a collection is not flagged as ambiguous even with several registrations; see `consumedAsCollection`.

**Example**

```json
{ "sessionId": "<session>", "interface": "ICodeAnalyzer", "site": "DependencyInjection" }
```

---

[&larr; 6 Tool reference: orientation, sessions and symbols](06-tool-reference-orientation-sessions-and-symbols.md) &middot; [Contents](README.md) &middot; [8 Tool reference: facts, dead code, metrics and patterns &rarr;](08-tool-reference-facts-dead-code-metrics-and-patterns.md)
