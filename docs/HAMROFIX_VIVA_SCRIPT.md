# HamroFix — Viva / Presentation Script

Speak slowly. Look at the teacher, not only at the slides. If you forget a word, say the idea in a shorter sentence. Do **not** read the long report out loud.

**Total time if they give you ~10 minutes:** use the **Short talk**.  
**If they give ~15 minutes:** add the **Demo order**.  
**If they ask questions:** use **Likely questions**.

---

## 1. Opening (20 seconds)

“Good morning. My project is **HamroFix**. It is a mobile app for a ward office. A person can report a road or drain problem with a photo and a map pin. Then an official, a worker, and an admin each do their own job until the work is finished. The public can later see before and after photos on a feed.”

Stop. Smile. Next slide.

---

## 2. Why this problem (40 seconds)

“In many wards, people still complain by phone or Facebook. There is no tracking number. Staff mix jobs. Money for materials is not clear. Some people are afraid to put their name. At the same time, fake reports can waste money.

So I asked: can one cheap phone app connect four roles, keep a trail, hide a name from the ward desk when the user asks, but still let admin check fraud?”

---

## 3. Aim (15 seconds)

“My aim was to build a working Flutter app with Firebase, not a paper design only. Four real logins: public, official, worker, and admin.”

---

## 4. What already exists (45 seconds)

“I compared three kinds of systems.

**FixMyStreet** in the UK lets people pin a street problem. That taught me the map and photo idea.

**Nagarik App** in Nepal already puts government services on a phone. That taught me Nepali users will open a civic app. But Nagarik is national services, not a full ward work order.

**311 apps** like SeeClickFix taught me people want to see status.

HamroFix is smaller than a national app, but deeper on one pothole: inspect, budget, 15 percent worker salary, and a public feed.”

---

## 5. How I built it (50 seconds)

“I used **Flutter** so one UI runs on Android. I used **Firebase Auth** and **Firestore**. No fake login. One email is one role. Public users verify email. Workers and officials wait until they are approved.

I did not use paid SMS codes. I did not use Firebase Storage, because this was a free Spark plan. Photos are compressed and saved as small images in Firestore. That is a limit. I will say it again in weaknesses.”

---

## 6. The story of one report (90 seconds) — most important

Speak this while you point at Figure 2 (workflow) or while you demo.

“A public user opens Report. They add a photo, choose category, write what happened, pin the map. They can turn on **Submit anonymously**.

If they do that, the official still sees the problem, but **not** the name. Named reports appear **first** in the official list. Anonymous ones come after, in grey.

The official can accept the report and assign one or more workers.

The worker inspects and lists materials. The **task budget** is that material money. **Worker salary is 15 percent** of the budget the admin approves. Example: 500 rupees budget, 75 rupees salary. The **public never sees the salary**.

Admin checks the budget. Official sends funded work. Worker uploads finished photos. Official can send that to the public. The public posts on the feed. People can **like**. **Comment count** shows next to likes, like Facebook.”

If you only remember one block, remember this block.

---

## 7. Two features that show thinking (40 seconds)

“**Anonymous plus admin.** Officials cannot read the private identity document. Admin can, for fraud. I will show the same tracking ID on two screens.

**Language.** English and Nepali. Changing language should not make the whole page blink. I kept the app shell stable and cached photos.”

---

## 8. Testing (20 seconds)

“I tested by walking one issue through all four accounts on a phone. I did not rely only on unit tests, because Firebase needs a live project. My test table is in the report. Main paths passed: submit, anonymous hide, admin identity, salary rule, like and comment count, logout confirm.”

---

## 9. Weaknesses — say this before they attack you (30 seconds)

“Photos cannot be very large, because Firestore documents have a size limit. There is no real bank payment. Officials could still see a user id in raw data; the app hides the name on the screen and in rules for the identity pack. The survey numbers in the report are only valid if I actually collected them.”

Honesty here gets marks.

---

## 10. Close (20 seconds)

“HamroFix is a student system, but it behaves like a small office: report, review, inspect, pay rule, and proof on a feed. Thank you. I am happy to take questions.”

---

# Short talk (cut this if they say “5 minutes only”)

1. Opening  
2. Why this problem (cut FixMyStreet names if time is gone)  
6. The story of one report  
7. Anonymous + 15 percent  
9. One weakness (photo size)  
10. Close  

---

# Demo order (phone already logged in — practise twice)

Prepare **four** test users before the viva. Write the emails on a paper. **Never** put real passwords on a slide.

1. **Public, English:** submit a **named** report. Show My IDs and `HF-` code.  
2. **Public:** submit an **anonymous** report. Remember that code.  
3. **Official:** show list — named first, anonymous grey. Open anonymous. **No name.**  
4. **Admin:** open the **same** anonymous code. Show yellow identity card.  
5. **Worker:** show Task and Pay. Point: salary is 15 percent.  
6. **Public feed:** like and add a comment. Point: number next to likes.  
7. Tap **ने**. Show two labels in Nepali.  
8. Logout → confirm dialog.

If the internet fails: open the report PDF figures 8, 12, 13, 18, 10. Say “this is the same flow from screenshots.”

---

# Slide titles (8 slides is enough)

1. Title + your name  
2. Problem in four bullets  
3. Four roles (simple boxes)  
4. Workflow (one report)  
5. Screenshot pair: official hidden / admin shown  
6. Money rule: budget vs 15% salary  
7. Tools: Flutter + Firebase  
8. Limitations + thank you  

Do not put long paragraphs on slides. You talk. Slides only show pictures and five words.

---

# Likely questions — answers in simple English

**Why Flutter?**  
“One UI for Android. Fast for a student project. I can still run it on a phone for the demo.”

**Why Firebase not your own server?**  
“Time and cost. Auth and database are ready. Security rules control who can read what.”

**Why no Firebase Storage?**  
“Free Spark plan. I compress photos and store them in Firestore. That is why photos must stay small.”

**Is anonymous really secret?**  
“The name is not on the official screen. Identity is in a private document. Rules allow admin, not official. A person with extra database access could still see a user id. I wrote that as a limit.”

**Why 15 percent?**  
“A clear rule the teacher and the worker can check. 500 becomes 75. Not a full payroll system.”

**Why can the public not see salary?**  
“Salary is staff money. The public should see the civic budget only.”

**How do you stop two roles on one email?**  
“The account stores one role. We removed linking public and worker on the same email.”

**What is new compared to FixMyStreet?**  
“Four roles in one app, inspection items, admin budget, 15 percent pay, anonymous for official plus admin fraud view, Nepali, and a before-after feed with comment counts.”

**Did you write the code?**  
“Yes. Git has many local commits. I must push to GitHub to show them online. I can open Android Studio and a file if you want.”

**What would you do next?**  
“Proper image storage, offline mode, and a real payment later. Maybe iOS.”

**Where are survey results?**  
If you ran the form: “In Chapter 4.3. Most people said …” (use **your** numbers).  
If you did not: “The form is ready. I have not finished collecting answers. I will not invent numbers.”

**Explain Firestore rules in one sentence.**  
“Each collection says who can read and write: the owner, official, worker on that job, or admin.”

**What is a tracking code?**  
“HF- and six letters from the document id. The public uses it like a receipt.”

---

# Words to avoid in the viva

Do not say: “the AI made it”, “I just prompted”, “I don’t know this file”.  
If you used help for English, say: “I wrote the design and the code. I asked for help to tidy the report language.” That is honest.

Do not attack your senior’s furniture project. If asked why your report is different: “Their product was furniture. Mine is civic reporting for a ward.”

---

# Timing rehearsal

Read sections 1–10 out loud once with a phone timer.  
Target: **8 to 10 minutes**.  
If you are over 12 minutes, cut section 4.

Good luck. Breathe before you start.
