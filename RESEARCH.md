# Drift accessibility research

Research date: 13 October 2026.

Drift can help people see time, start a task, and prepare for the next activity.
The first version should keep the clock clear and add a few optional tools.
People with ADHD, autism, dyslexia, and other conditions have different needs.
Choose support by the person's difficulty and preference, without requiring a diagnosis.

## What the evidence supports

NICE recommends personal environmental changes for ADHD.
Examples include fewer distractions, written instructions, shorter focus periods, and movement breaks.
These recommendations support the design direction, rather than prove a particular app works.
[NICE ADHD recommendations](https://www.nice.org.uk/guidance/ng87/chapter/recommendations).

NICE recommends attention to sensory needs and predictable routines when supporting autistic adults.
Drift's sensory controls are an application of that guidance, rather than a tested intervention.
[NICE autism recommendations](https://www.nice.org.uk/guidance/CG142/chapter/Recommendations).

A randomized study tested time aids together with time-skills training for children with ADHD.
The analysis included 38 children aged 9–15 on stable medication.
Time-processing performance and parent-rated daily time management improved.
Children's own daily time-management ratings did not show a significant change.
The study cannot isolate the timer's effect or establish Drift's benefit for adults.
[Wennberg and colleagues, 2018](https://pmc.ncbi.nlm.nih.gov/articles/PMC5852175/).

No source reviewed establishes that a percentage clock treats ADHD or improves daily function.
Pair percentages with ordinary time and a clear explanation of the measured period.
Test whether the clock supports awareness or creates pressure for each user.

## Proposed features in priority order

These are product proposals based on the sources below.
Their benefit in Drift remains untested.

| Priority | Feature | Intended support | Minimum design and limit |
|---|---|---|---|
| 1 | Visual focus timer | People who lose track of duration | Show remaining minutes and a shrinking shape. Allow pause, extend, and stop. Keep the day clock separate. |
| 2 | One current task | People who forget their task after distraction | Show a task name and its next small step beside the timer. Save them locally. Avoid a large task list. |
| 3 | Sensory controls | People sensitive to movement, color, sound, or vibration | Offer a static clock and separate sound and vibration controls. Use text with color. Respect reduced motion and text size. |
| 4 | Transition cues | People who need preparation before a change | Let the user select a warning before the timer ends. Include snooze and dismiss. Do not add unwanted reminders. |
| 5 | Adjustable focus and breaks | People who need shorter work periods or movement | Let the user choose the duration. Offer a break after a session. Do not force a fixed productivity schedule. |
| 6 | A small routine | People who benefit from predictable sequences | Save a few named steps, such as a morning routine. Show the current and next step. Allow skip without penalty. |
| 7 | A personal day window | People whose active hours differ from calendar days | Offer a selected start and end time. Name the period beside its percentage. Handle overnight windows and time changes. |
| 8 | Quick capture and duration review | People who forget ideas or underestimate tasks | Save one short note during a session. Optionally compare planned and actual time. Avoid scores, streak loss, or judgment. |

The timer and breaks follow the ADHD accommodations above.
Persistent task context follows W3C guidance on clear steps after distraction.
[W3C clear steps](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o1p04-clear-steps/).

Transition cues follow W3C guidance on user-requested, personalized reminders.
[W3C reminders](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o7p07-reminders/).

The routine proposal follows guidance on visual schedules and sequences for some autistic people.
[National Autistic Society organization guidance](https://www.autism.org.uk/advice-and-guidance/behaviour/organising-and-prioritising/all-audiences).

The day window and quick capture are design hypotheses.
Validate them with users before adding more complexity.
The interface should minimize interruptions and preserve the current task when the user returns.
[W3C focus guidance](https://www.w3.org/WAI/WCAG2/supplemental/objectives/o5-user-focus/).

## Existing tools worth studying

These official pages describe current product functions.
They do not establish clinical effectiveness.

| Tool | Relevant function | Lesson for Drift |
|---|---|---|
| [Tiimo](https://www.tiimoapp.com/) | Visual planning, a focus timer, routines, and AI checklists | Keep a visible current activity. Defer AI and a full planner. |
| [Time Timer](https://support.timetimer.com/hc/en-us/articles/29258432418203-Time-Timer-App-Free-vs-Paid-Premium-Features) | Visual timers with adjustable periods, colors, and sounds | Make duration visible and keep cue preferences separate. |
| [Structured](https://help.structured.app/en/articles/380546) | A timeline that combines tasks and events | A current and next view can help without copying a full calendar. |
| [Goblin Tools](https://goblin.tools/ToDo) | Task breakdown and duration estimation | Start with a manual next step. AI estimates need user review. |
| [Focusmate](https://www.focusmate.com/) | Scheduled video sessions with another person present | Study optional shared sessions later. Avoid building video calls now. |

Working beside another person is often called body doubling.
Focusmate provides that format, but its marketing claims do not prove benefit for every person with ADHD.

## Smallest roadmap

1. Build the Android and iOS clock with ordinary time, clear phase labels, and readable controls.
2. Add one named visual timer with pause, extend, and a saved current task.
3. Add sensory controls and optional transition notifications after native delivery tests pass.
4. Test the clock and timer with people who have different attention and sensory needs.
5. Add a short routine only if users need more support for transitions.

Keep tasks on the device unless the user requests synchronization.
Do not collect diagnoses or add clinical advice.
Defer AI planning, medication tools, social feeds, video calls, and app blocking.
These functions add separate privacy, reliability, and platform requirements.

## Verification required before release

Test the timer with the screen locked and the app in the background.
Test pause, resume, restart, overnight periods, daylight-saving changes, and device clock changes.
Test denied notification permission and the phone's quiet settings.
Test Android TalkBack, iOS VoiceOver, large text, reduced motion, and contrast.
Check that a timer completion does not delete the task or force another session.

The connected Android phone can verify Android behavior.
An Android test does not verify iOS notifications, accessibility, or background behavior.

Confidence is high for the cited accessibility and accommodation guidance.
Confidence is moderate for this feature priority.
Clinical benefit for Drift is unknown until suitable research evaluates it.

## Visibility choices requested for this build

The user requested both a widget and a floating clock for comparison.
Android has both choices. iOS has the home screen widget.
These additions support access to the clock outside the app. Their clinical benefit remains untested.

Android floating windows require display permission and remain below the system status bar.
Some protected screens can hide them.
[Android overlay documentation](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY).

Widget updates depend on each operating system.
The Android widget has an update timestamp and a manual refresh control.
The iOS widget supplies percentage timeline entries, but Apple controls delivery.
[Apple widget update documentation](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

A normal app theme cannot replace the system status bar clock with percentages on both platforms.
The build keeps that limit visible in the comparison screen.
