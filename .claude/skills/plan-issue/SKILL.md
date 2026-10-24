---
name: plan-issue
description: Read a Dmus GitHub issue by number, design a plan to fix it in plan mode, post the plan as a comment on the issue, and ask the user what to do next. Use when asked to plan, design, or scope a fix for an issue.
argument-hint: [issue-number]
disable-model-invocation: true
allowed-tools: EnterPlanMode, ExitPlanMode, AskUserQuestion, Read, Grep, Glob, Bash(gh issue view:*), Bash(gh issue comment:*), Bash(gh api:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git diff:*), Bash(git grep:*), Bash(ls:*)
---

Plan a fix for GitHub issue #$ARGUMENTS in `donmccaughey/dmus`, post the plan as a
comment on the issue, and then ask the user what to do with it. The whole skill
runs in plan mode: do not edit source files, do not commit, and do not close,
label, or retitle the issue. The only things written are the plan file that plan
mode provides and the issue comment.

## 1. Enter plan mode

Call `EnterPlanMode` before anything else. If the user declines, stop and say the
skill needs plan mode.

## 2. Fetch the issue

```bash
gh issue view $ARGUMENTS --json number,title,body,state,labels,comments
```

Stop and say so if the argument is missing, is not a number, or the issue does not
exist. Read every comment before doing anything else:

- An investigation comment (from `/investigate-issue`) usually already names the
  responsible code as `path:line`. Start from it rather than rediscovering it.
- If a plan comment already exists, do not write a second one blind. Tell the user
  it exists and ask whether to revise it or start over.

Record the commit the plan is written against:

```bash
git rev-parse --short HEAD
git status --porcelain
```

## 3. Research

Read the files the issue and its comments point at, and anything they call. Look
for existing helpers before proposing new ones. Check these in particular:

- `docs/requirements.md`: find the requirement the issue bears on. If the desired
  behavior is not captured there, the plan must include the requirements edit,
  written in EARS form to match the document, alongside the code change. Ignore
  `docs/draft_requirements.md`.
- `dmus.xcodeproj/project.pbxproj` when the fix might touch build settings or add
  files. The target uses file-system synchronized groups, so new files under
  `dmus/` need no project edit.
- `CLAUDE.md` for code style, especially the rule against comments that restate
  the code.

Prefer reading files directly; use an Explore agent only when the scope is
unclear. Use `AskUserQuestion` during research only for a choice that changes
the plan materially, not for anything a careful colleague would decide alone.

## 4. Write the plan

Write it to the plan file named in the plan-mode system message, in this shape.
Keep it short enough to scan and concrete enough to execute without re-research.

1. **Context**: what the issue reports, the root cause with `path:line`
   references, and the requirement it satisfies or the requirement change it
   needs.
2. **Changes**: one subsection per file, in the order they should be made. Name
   the functions and types involved and show a code snippet only where the exact
   form matters (a new scene type, a delegate method, a signature). Say why each
   change is needed, not just what it is. Call out comments that become stale.
3. **Verification**: how to prove the fix end to end, as runnable commands and
   observable checks that mirror the issue's "desired behavior" list. Reuse the
   build and launch recipes in `.claude/skills/investigate-issue/SKILL.md`. Include
   an iOS Simulator build whenever the change touches shared or platform-branched
   code, choosing a device whose runtime meets the iOS deployment target.
4. **Out of scope**: what the plan deliberately leaves alone, including that no
   commit is made and the issue is not closed unless the user asks.

Recommend one approach. Do not list alternatives you are not proposing.

## 5. Post the plan on the issue

Copy the plan into a file in the scratchpad directory from the system prompt,
adjusted for an issue reader (see [plan-comment-example.md](plan-comment-example.md)):

- Open with one line saying it is a plan, and the commit it was written against.
- Drop references to the plan file and to plan mode.
- Keep the Context, Changes, Verification, and Out of scope sections.

Then post it and keep the URL that `gh` returns:

```bash
gh issue comment $ARGUMENTS --body-file "$SCRATCHPAD/issue-$ARGUMENTS-plan.md"
```

## 6. Ask for the next action

Give the user the comment URL and a two or three line summary of the plan, then
call `AskUserQuestion` with these options:

- **Implement the plan**: call `ExitPlanMode`, make the changes, run the
  verification section, and report the results. Do not commit or close the issue
  unless asked.
- **Revise the plan**: take the user's notes, update the plan file, and edit the
  existing comment in place rather than posting a second one, using the comment
  id from the URL:

  ```bash
  gh api --method PATCH /repos/donmccaughey/dmus/issues/comments/<id> -F body=@"$SCRATCHPAD/issue-$ARGUMENTS-plan.md"
  ```

  Then ask again.
- **Stop here**: leave the plan on the issue and the tree untouched, and end the
  turn without exiting plan mode.

Do not ask for approval of the plan in any other way; this question is the
approval step.
