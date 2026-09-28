# AEGIS

Milestone escrow for student freelancers. A client locks the budget up front, the freelancer works against milestones, and money only moves when the client approves — or automatically, if they go quiet for 14 days.

## The problem

Student freelancers taking small gigs (design work, tutoring, code, etc.) often deal with clients who ghost after the work is delivered — no approval, no payment, no response. Aegis solves this two ways:

Money is locked before work starts. The client funds the full project budget into escrow when the project begins, not after.
Silence isn't free for the client. If a client doesn't approve or dispute a submitted milestone within 14 days, it releases automatically.

## Features

- Auth

Login / signup / forgot password with inline validation
Role selection (Client or Freelancer), switchable anytime from the app bar

- Client

Post a project with a 3-step wizard (details → skills → milestones)
Lock the full budget via GCashor Maya
Approve a milestone (releases funds) or request a revision with notes
Open a dispute case if something's wrong

- Freelancer

Browse and apply to open jobs
Submit work per milestone, resubmit after a revision request
Wallet balance with withdraw to GCash or Maya

- Shared

Per-project chat
Notifications with unread badge (payments, submissions, disputes)
14-day "days left to review" countdown shown on every active milestone
Admin view for resolving open dispute cases

## Running it

```bash
flutter pub get
flutter run -d chrome      
```

## Where things are 

```bash
lib/
  main.dart                       app entry point — sets up ProviderScope, DevicePreview,
                                   and every go_router route

  theme.dart                      AppColors, AppText, Gap spacing scale, buildTheme(),
                                   and the peso()/timeAgo() formatters used everywhere

  data/
    models.dart                   the shapes: AppUser, Milestone, Project, Message,
                                   Notice, DisputeCase, and the Role/MilestoneStatus/
                                   ProjectStatus/NoticeKind enums — all immutable with
                                   copyWith()
    store.dart                    the app's brain — a Riverpod Notifier<AppData> called
                                   Store. Every mutation is a method here: fundProject,
                                   submitWork, releaseMilestone, requestRevision,
                                   withdraw, createProject, applyToProject, sendMessage,
                                   markAllNoticesRead, openCase, resolveCase.
                                   _seed() at the bottom is the fake starting data.

  widgets/
    common.dart                   shared pieces every screen imports: Pressable,
                                   AppButton, AppField, AppCard, StatusPill, Avatar,
                                   and the toast() snackbar helper

  screens/
    auth_screens.dart             LoginScreen, SignupScreen, ForgotPasswordScreen,
                                   RoleScreen (picks Client/Freelancer, sets roleProvider)
    shell.dart                    Shell — the bottom-nav scaffold wrapping Home/Browse/
                                   Chats/Profile, role toggle, notice badge, end drawer
    home_screen.dart              role-aware dashboard (client's posted projects vs.
                                   freelancer's active gigs + wallet snapshot)
    browse_screen.dart            two tabs: open jobs to apply to, freelancers to browse
    project_card.dart             the reusable project/job card used in Home and Browse
    project_screen.dart           project detail — milestone timeline, submit-work
                                   dialog, release/revision actions, open-a-case flow
    create_project_screen.dart    3-step "post a project" wizard (details → skills →
                                   milestones), calls Store.createProject
    chat_screens.dart             ChatListScreen (tab inside Shell) + ChatScreen
                                   (per-project thread), calls Store.sendMessage
    money_screens.dart            DepositScreen (locks the budget, calls
                                   Store.fundProject) + WalletScreen (balance,
                                   calls Store.withdraw)
    notifications_screen.dart     reads storeProvider.notices, groups by NoticeKind,
                                   calls markAllNoticesRead
    profile_screen.dart           also defines VerificationScreen and SettingsScreen
    admin_screen.dart             lists open DisputeCases, resolves them via
                                   Store.resolveCase, unfreezing the project    
```
