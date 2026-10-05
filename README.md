<!--
  This is your project's front page. Replace every placeholder below.
  It is the first thing your instructor and any future employer will read, and
  the live link in it is how your project gets opened for grading.

  New here? Read START-HERE.md first. Delete this comment when you are done.
-->

# Aegis

> A milestone-based escrow app that protects student and junior freelancers from client ghosting and non-payment by locking project funds until work is approved.

**Live demo:** https://YOURUSERNAME.github.io/YOUR-REPO/ <!-- GitHub Pages is set up already; replace if you host elsewhere -->
**Demo video:** `https://drive.google.com/drive/quota`)
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
**Author:** Berceles, John Benedcit B.

This repository lives in the author's own GitHub account and is public on
purpose. There is no `student.json` here and there should not be one: see
`docs/06-security-and-privacy.md` for what a public repo means for secrets and
personal data.

---

## Screenshots

Put two or three real screenshots at phone size in `docs/assets/`, then replace
this paragraph with them:

```markdown
| Log In | Post a project | Milestone Tracker |
| <img width="468" height="956" alt="image" src="https://github.com/user-attachments/assets/9634f184-49d5-478b-b695-67f842a70e32" />
 | <img width="479" height="953" alt="image" src="https://github.com/user-attachments/assets/d2ac1973-1823-4d83-a834-bc32b1b6859d" />
 | <img width="512" height="959" alt="image" src="https://github.com/user-attachments/assets/2fccf7c4-01e2-4f5d-ae4a-38b63daf9f9a" />
 |
```

A repo without screenshots reads as abandoned, whatever the code says.

## What it does

Three to five bullets. What can a user actually do?

- Lets a client post a project with milestones and fund it upfront, so the freelancer knows the money is real before starting work
- Holds each milestone's payment in escrow until the client approves the submitted work, or releases automatically if the client goes silent past the review window
- Lets a freelancer submit work per milestone and request a revision cycle if the client isn't satisfied
- Flags a project for admin/human review when a dispute can't be resolved by the app's own rules
- Verifies student freelancers, and shows ratings/reviews from past projects
- Sends in-app notifications for funding, submissions, approvals, and disputes

## Built with

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | Riverpod (flutter_riverpod) — a single Store extends Notifier<AppData> holding all app state |
| Router | go_router |
| Storage | Static no SUPABASE yet. |
| Other packages | google_fonts (Manrope/Inter type system), device_preview (phone-frame preview when testing on web) |

## Running it yourself

```bash
flutter pub get
flutter run -d chrome
```

Then open http://localhost:8080. Requires Flutter (run `flutter --version` and
put yours here).

### Environment variables

This project does not use a .env file. Flutter/Dart has no built-in .env reader, so configuration instead lives in a gitignored Dart file: copy lib/data/supabase_config.dart.example to lib/data/supabase_config.dart and fill in your own values. Never commit the real file.


## Privacy and secrets

Required section. Two or three honest sentences:

- The app stores account info (email, full name, role, verification status) and project/escrow data (milestones, amounts, messages) in Supabase Postgres tables.
- Row Level Security (RLS) policies on the profiles table restrict reads/writes to the authenticated owner.
- All sample data, screenshots, and the demo are all an example, no real personal information.

## Project documentation

| Document | |
| --- | --- |
| https://github.com/HAU-6ADET/student-6ADET-2125-Jberceles/blob/main/project/PROPOSAL.md | the problem, the users, the scope |
| https://github.com/HAU-6ADET/student-6ADET-2125-Jberceles/blob/main/project/Wireframe-ADET-PRELIMS.pdf | what it looks like, and the screen flow |
| [Design system](docs/03-design-system.md) | colors, type, spacing, components |
| [Weekly reports](docs/04-weekly-reports.md) | what happened each week |
| https://drive.google.com/file/d/1zDjKjeppALMwZGIxpDLFpaN8oQErFzMz/view?usp=sharing | the recording and what it shows |
| https://github.com/Svintjohn/final-project-template/edit/main/README.md | the checklist, filled in |

## Status and what is next

Core flows work: signup/login via Supabase Auth, posting a project with milestones, funding, submitting work, approving/releasing a milestone, and requesting revisions. Admin escalation and chat exist in the UI. Known gaps: payment is simulated rather than wired to a real payment gateway, and the 14-day anti-ghosting auto-release timer is not yet backed by a scheduled server job. Next: wire real payments, move the auto-release timer server-side, and add push notifications. Also the final Integration of a DATABASE 

## Credits

- Packages: see pubspec.yaml
- Assets, icons, 3D models, sounds: name the author and the licence for each
- People who helped, and how

## AI use

If you used AI while building this, say so here. Honest disclosure is the
standard in this course and increasingly outside it, and reporting heavy use
accurately costs you nothing.

This section is the last 10 points of the finals badge, and it wants three
things:

![Built with AI assistance](https://img.shields.io/badge/built%20with-AI%20assistance-0b5fff)

- the badge above, or one you like better
- a line naming which assistant you used and how much of the work it touched
- a link to https://github.com/Svintjohn/final-project-template/blob/main/AI-USAGE.md, where the full account lives

Keep the detail in `AI-USAGE.md` rather than here. This section is the summary a
visitor reads; that file is the record the badge is graded from.

## Licence

MIT, see [LICENSE](LICENSE). Change it if you want different terms.
