# Workflows that wait for people — voice-over script

Video title: **Workflows that wait for people**
Subtitle: *Start, wait for an event, ask a person: durable workflows in WSO2 Integrator*

Everything referenced here is in this folder. Slides are 4K PNGs in `slides/`; hold each for the length given.
Narration is paced at about 150 words a minute; the timings in the clip sections are positions in that clip.

## Running order

| # | Asset | Length | Part |
|---|---|---|---|
| 1 | `slides/01-title.png` | 0:12 | Hook |
| 2 | `user-journey.mp4` | 1:41 | The use case |
| 3 | `slides/03-blocks.png` | 0:30 | The concept |
| 4 | `slides/04-architecture.png` | 0:45 | The solution |
| 5 | `slides/05-wiring.png` | 0:45 | How the apps plug in |
| 6 | `slides/08-endtoend.png` | 0:25 | One claim, end to end |
| 7 | `slides/07-integration.png` | 0:20 | What we build |
| 8 | `part3-build-segments/01-b1.mp4` … `12-b15.mp4` | 8:24 | Build it |
| 9 | `part3-management.mp4` | 0:13 | Management API |
| 10 | `part3-configurations.mp4` | 0:21 | Configure per environment |
| 11 | `slides/09-next.png` | 0:12 | Close |

About 14 minutes. For a shorter cut, drop 7 and the clips marked *optional*; the slides `02-cover.png` and
`06-contract.png` are spares (a section card, and the full API table).

---

## 1. Hook — `slides/01-title.png` (0:12)

> Approvals look simple, until they have to wait. For a document. For a person. For days.
> This is how a durable workflow does that waiting for you, so your apps don't have to.

## 2. The use case — `user-journey.mp4` (1:41)

**0:00 – intro slide**
> Meet Ann and Jane. Ann files expense claims in the Expenses portal. Jane, her manager, approves them in her own
> Approvals console. Two people, two apps, and one process in between.

**0:14 – sign in**
> Ann signs in to Expenses: her earlier claims, one approved, one rejected. Jane signs in to Approvals. Nothing is
> waiting for her yet.

**0:37 – Ann submits a claim**
> Ann files a team dinner with a customer: four hundred and twenty dollars fifty. The moment she submits, a workflow
> starts for this claim. And the first thing it asks for is the bill. That's the Submit bill button: the portal
> isn't deciding that, it's showing the step the process is waiting at.
> Notice Jane still has nothing. The manager only gets involved once the bill is in.

**0:51 – Ann uploads the bill**
> Ann uploads the receipt. That upload is the event the workflow was waiting for, and it moves on.

**1:01 – Jane gets the task**
> And there it is in Jane's console: an approval task, with the claim and the bill attached. She checks the bill,
> adds a comment, and approves.

**1:17 – Ann sees the result**
> Back in Ann's portal, the claim is approved, with Jane's comment. Nobody passed it on.

**1:24 – closing slide**
> Neither app knows the steps of this process. Both just show what the workflow is doing.

## 3. The concept — `slides/03-blocks.png` (0:30)

> Under the hood, it's three building blocks. Start: a business event starts a process, under a business id, here
> the claim id. Wait: the process parks until an event arrives, for seconds or for weeks, and it survives restarts.
> Ask: the process creates a task for a role, and any app can list it and complete it.
> Most approval processes are a combination of these three.

## 4. The solution — `slides/04-architecture.png` (0:45)

> Here's the whole solution. On the left, the two apps: ordinary front-ends with no process logic. On the right,
> the platform: the claims database, Temporal as the durable runtime, and the Integration Control Plane for
> operations.
> In the middle is what we build in WSO2 Integrator. A Claims API, the front door. The processClaim workflow, which
> records every step in the claims database. And the Workflow Management API, which ships with the runtime. We don't
> write it; we switch it on.

## 5. How the apps plug in — `slides/05-wiring.png` (0:45)

> So how are the apps wired to this? Expenses talks to the Claims API we built. It submits a claim with an id it
> picks, and that id becomes the workflow id. The bill is sent to that same id, so it lands in the right waiting
> workflow. And the claim list reads the status the workflow records at each step.
> Approvals talks to the Management API. Each call says who is asking, with a user id and a role. It only ever sees
> the tasks that person may act on, and completing one hands the decision straight back to the workflow.
> Because neither app knows the steps, you can change the process without touching them.

## 6. One claim, end to end — `slides/08-endtoend.png` (0:25)

> Follow one claim through. Ann submits: bill required. She uploads: in review, and the workflow asks a manager.
> Jane approves: recorded, and visible to Ann. Between those steps the workflow simply waits. Nothing polls, and
> nothing is lost if the integration restarts.

## 7. What we build — `slides/07-integration.png` (0:20) *optional*

> Let's build it in WSO2 Integrator: a Claims API with three resources, the five-step workflow, and the Management
> API, switched on with a checkbox.

## 8. Build it — `part3-build-segments/` (8:24)

**`01-b1.mp4` (0:18) — create the integration**
> We start from an empty project and create the ClaimApproval integration.

**`02-b3.mp4` (0:23) — the workflow**
> First, the process itself: a durable workflow called processClaim. Its input is a claim: id, employee,
> description and amount.

**`03-b4.mp4` (0:25) — first activity**
> The first step records the claim. Anything that touches the outside world is an activity: its result is recorded,
> and it's retried by policy. We create createClaim, and pass it the workflow's input.

**`04-b5.mp4` (1:03) — connect the database, insert the claim**
> Inside the activity we need the claims database, so we connect to it right here. MySQL, with the user, password
> and database name as configurables, so no credentials live in the code.
> Saving brings us straight back to the activity. Now an Execute on that connection, with the insert. It records the
> claim as bill required. Long statements like this go in the expanded editor.

**`05-b6.mp4` (0:26) — wait for the bill**
> Now the first wait. Await Data, for the bill: a new Bill type with a file name and a link. The workflow parks here
> until the bill arrives, however long that takes.

**`06-b7.mp4` (0:53) — attach the bill**
> When it does, a second activity, attachBill, stores the bill's link on the claim and moves it to in review. It
> takes the claim id from the input and the bill we just received.

**`07-b9.mp4` (0:46) — ask a manager**
> Now we ask a person. A Human Task, approveClaim, for the MANAGER role. The task carries the claim and the bill
> link, which is what Jane saw. Its result is a decision: approved, and a comment.

**`08-b10.mp4` (0:13) — branch on the decision**
> Then an If on the decision.

**`09-b11.mp4` (1:10) — record an approval**
> On the approved path, a third activity, recordDecision, takes the claim id, the status, and the manager's comment.
> We call it with approved.

**`10-b13.mp4` (0:36) — record a rejection**
> And on the else path, the same activity with rejected. That's the whole process.

**`11-b14.mp4` (1:10) — start it from the API**
> Now the front door. An HTTP service at slash claims, with a POST that takes a claim. To start the workflow we use
> runWithId, found with the node search, so the claim id becomes the workflow id. That's the detail that lets the
> bill find its workflow later.

**`12-b15.mp4` (1:03) — send the bill to the waiting workflow**
> The bill route. POST claims, claim id, bill, with a Send Data Event: the processClaim workflow, this claim's id,
> the bill data. This is the event the workflow is waiting for.

## 9. Management API — `part3-management.mp4` (0:13)

> And the API the Approvals app uses? One checkbox on the overview: Enable Workflow Management REST API. Every task
> the workflow creates is now listable and completable, for the right people.

## 10. Configure per environment — `part3-configurations.mp4` (0:21)

> The database user, password and name were configurables, so each environment sets its own values, here in
> Config dot toml, without touching the integration. Run it, point the two apps at it, and you have what Ann and Jane
> used at the start.

## 11. Close — `slides/09-next.png` (0:12)

> Start a process, wait for an event, ask a person. Three building blocks, and the waiting is the runtime's job,
> not yours.
