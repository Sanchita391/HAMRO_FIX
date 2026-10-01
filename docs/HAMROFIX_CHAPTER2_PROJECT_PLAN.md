# Chapter 2 – Project Plan

This chapter shows **how** the work was organised: time (Gantt chart), problems that could stop the project (risks), and the path of one civic report (workflow).

---

## 2.1 Gantt chart

A Gantt chart is a calendar of tasks. Dark cells mean “work in this week.”

**How to make Figure 1 in Excel (do this exactly)**

1. Open Excel.  
2. Copy the table below.  
3. Select the grid of `X` cells → Home → Fill colour (green).  
4. Screenshot the sheet.  
5. In Word: Insert picture. Caption: **Figure 1: Gantt chart of the HamroFix project.**  
6. Above the picture write: “Figure 1 shows the weekly plan from research to report writing.”

**Duration: Week 1 to Week 12.**  
This chart includes **everything already done this semester**: proposal and research from the early weeks, the Figma design, then the working app (all roles and features), then testing and this report.

Print **landscape**. In Excel use font size 8. Colour every `X` green. Caption: **Figure 1: Gantt chart of the HamroFix project (Week 1–12).**

| Work item | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-----------|---|---|---|---|---|---|---|---|---|----|----|----|
| **A. Planning and research (already done)** | | | | | | | | | | | | |
| Choose topic: civic reporting for Nepal | X | | | | | | | | | | | |
| Problem, aim, and objectives | X | X | | | | | | | | | | |
| Project proposal | X | X | | | | | | | | | | |
| Ethics / consent form | X | X | | | | | | | | | | |
| Literature: Shasaan, Mero Sadak, ECWORKS 311 | | X | X | X | | | | | | | | |
| Market gaps (transparency, Nepal, follow-up) | | | X | X | | | | | | | | |
| Survey questions and user needs | | | X | X | | | | | | | | |
| Personas, scenarios, and use cases | | | | X | X | | | | | | | |
| Figma prototype (four roles) | | | | X | X | X | | | | | | |
| Nepali-friendly UI in Figma | | | | | X | X | | | | | | |
| DECIDE evaluation plan | | | | | | X | | | | | | |
| Functional and non-functional needs | | | | X | X | | | | | | | |
| Weekly progress reports (research) | X | X | X | X | X | X | | | | | | |
| **B. App setup** | | | | | | | | | | | | |
| Flutter / Android project | | | | | X | X | | | | | | |
| Firebase Auth and Firestore | | | | | X | X | | | | | | |
| Firestore security rules | | | | | | X | X | | | | | |
| Green HamroFix theme and logo | | | | | X | X | | | | | | |
| Landing page and role choice | X | | | | X | X | | | | | | |
| Public login and signup | X | | | | | X | | | | | | |
| Worker login and signup | X | | | | | X | X | | | | | |
| Official login and access request | X | | | | | | X | | | | | |
| Admin login | X | | | | | | | X | | | | |
| One email = one role | | | | | | X | X | | | | | |
| Email verify (public) | | | | | | X | | | | | | |
| Pending approval (worker / official) | | | | | | | X | X | | | | |
| **C. Public features** | | | | | | | | | | | | |
| Report form: photo / video | | | | | | X | X | | | | | |
| Category, description, municipality | | | | | | X | X | | | | | |
| GPS / OpenStreetMap pin | | | | | | | X | | | | | |
| Tracking ID (HF-code) and My IDs | | | | | | X | X | | | | | |
| Alerts / notifications | | | | | | | | X | X | | | |
| Public profile | | | | | | | X | | | | | |
| Anonymous submit | | | | | | | | | | X | | |
| **D. Official features** | | | | | | | | | | | | |
| Official home and report queue | | | | | | | | X | | | | |
| Accept / decline / mark fake | | | | | | | | X | | | | |
| Assign more than one worker | | | | | | | | X | | | | |
| Worker application review | | | | | | | | X | | | | |
| Send funded work and completion | | | | | | | | | X | | | |
| Named reports first, then anonymous | | | | | | | | | | X | | |
| **E. Worker features** | | | | | | | | | | | | |
| Worker home, Task tab, badges | | | | | | | X | | | | | |
| Site inspect and material items | | | | | | | | X | | | | |
| Budget request to official | | | | | | | | X | | | | |
| Completion photos | | | | | | | | | X | | | |
| Pay tab: salary = 15% of budget | | | | | | | X | X | | | | |
| Public cannot see worker salary | | | | | | | | X | | | | |
| **F. Admin features** | | | | | | | | | | | | |
| Admin home, people, approvals | | | | | | | | X | | | | |
| Decide budget | | | | | | | | X | | | | |
| See anonymous identity (fraud) | | | | | | | | | | X | | |
| Audit / staff invite | | | | | | | | X | | | | |
| **G. Shared product features** | | | | | | | | | | | | |
| Public feed and My Feed | | | | | | X | | | X | | | |
| Likes | | | | | | | | | X | | | |
| Comments and comment count | | | | | | | | | | X | X | |
| English / Nepali toggle | | | | | | | | | X | X | | |
| Logout confirm for all roles | | | | | | | | | | X | | |
| Compress and cache photos | | | | | | X | | | | X | | |
| **H. Test, git, and report** | | | | | | | | | | | | |
| Test four roles end to end | | | | | | | | | | X | X | X |
| Screenshots for figure list | | | | | | | | | | | X | X |
| Git commits (local history) | | | | | X | X | X | X | X | X | X | X |
| Weekly progress reports (development) | | | | | | | X | X | X | X | | |
| Write final university report | | | | | | | | | | X | X | X |
| Viva slides and practice | | | | | | | | | | | | X |

Rows in **bold** are section titles only. Do **not** colour those rows. Colour only the `X` cells.

**Week-by-week (what this semester already covered)**

| Week | What was done |
|------|----------------|
| Week 1 | Topic. Proposal start. Ethics. First login/landing screens. |
| Week 2 | Proposal finish. Start literature (Shasaan, Mero Sadak, 311). |
| Week 3 | Literature and survey. User needs. |
| Week 4 | Personas and use cases. Figma for four roles. |
| Week 5 | Figma + DECIDE plan. Firebase, theme, project setup. |
| Week 6 | Public report, tracking IDs, feed start, photo compress. |
| Week 7 | Worker dashboard, GPS, inspection path, one-email-one-role. |
| Week 8 | Official/admin dashboards, budget, 15% salary, applications. |
| Week 9 | Feed likes, language, funded work, completion to public. |
| Week 10 | Anonymous reports, logout confirm, comment counts, list order. |
| Week 11 | Full role testing. Report writing. Figure screenshots. |
| Week 12 | Finish report. Viva script and slides. Submit. |

If a teacher asks “why is Git only in September?” say: **design and Figma were earlier in the semester; coding and Git were the later build. The Gantt shows both.** Do not pretend Git existed in Week 1 if it did not. The **planning rows** are the early work; the **app rows** are the build.

If your college week 1 date is not the first week of July, write the real dates on the Excel header (W1 = your first week, W12 = submission week).

---

## 2.2 Risk analysis

A risk is something that can delay or damage the project. Each risk needs a response.

**Table 2: Project risks and responses**

| ID | Risk | Chance | Impact | What we did / will do |
|----|------|--------|--------|------------------------|
| R1 | Firebase “permission denied” | High | High | Test each role. Fix Firestore rules. |
| R2 | Photo too large to save | High | High | Compress the image before upload. |
| R3 | Slow internet on the phone | Medium | High | Show a clear error. Allow retry. |
| R4 | Fake civic reports | Medium | High | Admin can see identity on anonymous reports. Official can mark fake. |
| R5 | User has two roles on one email | Medium | High | One email, one role only. |
| R6 | Language change breaks the screen | Medium | Medium | Keep one app shell. Cache photos. |
| R7 | Demo login fails on viva day | Medium | High | Prepare four test accounts on paper. Take screenshots as backup. |
| R8 | Git commits not on GitHub | High | Medium | After commit, **push** to `origin main`. |
| R9 | Not enough time for all features | Medium | Medium | Must-have first: report, review, assign, track. Extra later: feed, Nepali, anonymous. |
| R10 | Ethics / personal photos | Low | High | Use test accounts. Do not put real citizenship photos in the report. |

**Figure (optional):** You may add **Figure 1b** — a simple 2×2 box: chance (low/high) vs impact (low/high), and place R1–R10 as dots. Not required if Table 2 is complete.

---

## 2.3 Workflow diagram

The workflow is the **path of one problem** from the street to a finished update.

**How to make Figure 2**

Use PowerPoint or [https://app.diagrams.net](https://app.diagrams.net) (draw.io). Use **rectangles** for steps and **arrows** for next step. One page, landscape. Font size large enough to read when printed.

**Boxes to draw (copy these labels)**

1. Public logs in  
2. Send photo + GPS + description  
3. Optional: submit as anonymous  
4. Official sees the report *(named reports first)*  
5. Official accepts / declines / marks fake  
6. Official assigns worker(s)  
7. Worker inspects and lists materials  
8. Budget goes to official, then admin  
9. Admin sets task budget *(worker salary = 15% of budget)*  
10. Official sends funded work  
11. Worker uploads finished photos  
12. Official shares with the public  
13. Public posts on feed (likes + comments)

**Side note on the drawing:** from box 3, draw a dashed arrow: “Official does not see name → Admin can see name if needed.”

**Caption in Word:** **Figure 2: Workflow of a HamroFix civic report.**  
**Sentence above it:** “Figure 2 shows how a report moves from the public user to workers and admin, then back to the public feed.”

### Simple text workflow (if the teacher also wants it in words)

Public report → Official review → Worker inspection → Admin budget → Funded task → Completion photos → Public feed.

Anonymous reports follow the **same** path. Only the **name** is hidden from the official screen.

---

## 2.4 Chapter summary

The Gantt chart sets the weeks. The risk table shows what can go wrong and how to handle it. The workflow shows that HamroFix is not only a form: it is a full office path from a photo to a public update.
