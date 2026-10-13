# Mobile port

1. `how` over the affected subsystem.
   The macOS engine derives progress from local minute and second values. Time shift changes the clock label only.
2. `architect` for parallel design exploration.
   skip: The user limits design panels to contested designs. A shared Expo app fits the existing mobile projects.
3. Write the throughput checkpoint as four todo items.
   - Blocking first steps. Read the existing engine, phases, fonts, and shift behavior.
   - Independent workstreams. One implementer owns mobile files. The lead owns native verification and handoff.
   - Shared mutable state. No shared source writes. Reviewers read the completed change.
   - Smallest safe decomposition. One mobile app shares a pure time model across Android and iOS.
4. Delegate code-writing to a subagent.
   Complete. Built the clock, local time shift, Android widget and floating clock, and iOS widget.
5. Verify on the matching surface.
   Complete. Clock tests and native model checks pass. Android runs on the user's Samsung A33.
   Four iOS interaction tests pass. The native widget renders on the iOS home screen.
6. Rebase into small, ordered commits. Stack follow-ups.
   Complete. Source and native resources are staged for a local commit. Verification artifacts are saved separately.
7. If the design is contested, `interrogate` before shipping.
   skip: No contested design.
8. Run **Opening a PR**.
   skip: The user requested a local build. No remote publication requested.

The delivery gate uses two fresh reviewers in parallel. Update HANDOFF.md after verification.
