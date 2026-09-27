import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

// The current role of the user. 
final roleProvider = StateProvider<Role>((ref) => Role.client);

final storeProvider = NotifierProvider<Store, AppData>(Store.new);

// Currently no database but I will input or use a SUPABASE database to store the data and retrieve it. For now, I will use a local store to simulate the data.
class AppData {
  final List<Project> projects;
  final List<Message> messages;
  final List<Notice> notices;
  final List<DisputeCase> cases;
  final double walletBalance;

  const AppData({
    this.projects = const [],
    this.messages = const [],
    this.notices = const [],
    this.cases = const [],
    this.walletBalance = 0,
  });

  AppData copyWith({
    List<Project>? projects,
    List<Message>? messages,
    List<Notice>? notices,
    List<DisputeCase>? cases,
    double? walletBalance,
  }) {
    return AppData(
      projects: projects ?? this.projects,
      messages: messages ?? this.messages,
      notices: notices ?? this.notices,
      cases: cases ?? this.cases,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  Project? project(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get unreadNotices => notices.where((n) => !n.read).length;
}

class Store extends Notifier<AppData> {
  var _nextId = 100;
  String _id() => '${_nextId++}';

  @override
  AppData build() => _seed();

// --- user actions ---

// The client funds the project, which moves it to the active state and allows the freelancer to submit work. The money is held in escrow until released.
  void fundProject(String projectId) {
    _updateProject(projectId, (p) => p.copyWith(status: ProjectStatus.active));
    _notify(
      NoticeKind.payment,
      'Funds locked',
      '${peso_(_project(projectId)?.budget ?? 0)} is now held in escrow.',
      projectId: projectId,
    );
  }

  void submitWork(String projectId, String milestoneId, String note) {
    _updateMilestone(projectId, milestoneId, (m) => m.copyWith(
          status: MilestoneStatus.submitted,
          submittedAt: DateTime.now(),
          submissionNote: note,
        ));
    _notify(
      NoticeKind.timer,
      'Work submitted',
      'The client has 14 days to review before funds release automatically.',
      projectId: projectId,
    );
  }

// Client release or approved the project and releaase the money to the freelancer. Once all milestone are released, the project is marked as completed and the funds are added to the client's wallet balance.
  void releaseMilestone(String projectId, String milestoneId) {
    final project = _project(projectId);
    final milestone = project?.milestones.where((m) => m.id == milestoneId).firstOrNull;
    if (milestone == null) return;

    _updateMilestone(projectId, milestoneId,
        (m) => m.copyWith(status: MilestoneStatus.released));

    final updated = _project(projectId)!;
    if (updated.milestones.every((m) => m.status == MilestoneStatus.released)) {
      _updateProject(projectId, (p) => p.copyWith(status: ProjectStatus.completed));
    }

    state = state.copyWith(walletBalance: state.walletBalance + milestone.amount);
    _notify(
      NoticeKind.payment,
      'Milestone released',
      '${peso_(milestone.amount)} was released to the freelancer.',
      projectId: projectId,
    );
  }

  void requestRevision(String projectId, String milestoneId, String note) {
    _updateMilestone(projectId, milestoneId, (m) => m.copyWith(
          status: MilestoneStatus.revision,
          revisionNote: note,
        ));
    _notify(
      NoticeKind.message,
      'Revision requested',
      note,
      projectId: projectId,
    );
  }

  void withdraw(double amount) {
    if (amount <= 0 || amount > state.walletBalance) return;
    state = state.copyWith(walletBalance: state.walletBalance - amount);
    _notify(NoticeKind.payment, 'Withdrawal sent',
        '${peso_(amount)} is on its way to your e-wallet.');
  }

  // --- projects ---

// This is called when the client creates a new project. It builds the milestones and adds the project to the store.
  String createProject({
    required String title,
    required String description,
    required double budget,
    required List<String> skills,
    required List<({String title, double amount})> milestones,
  }) {
    final id = _id();
    var percentSoFar = 0;
    final built = <Milestone>[];
    for (var i = 0; i < milestones.length; i++) {
      final m = milestones[i];
      final percent = i == milestones.length - 1
          ? 100 - percentSoFar
          : ((m.amount / budget) * 100).round();
      percentSoFar += percent;
      built.add(Milestone(
        id: '$id-${i + 1}',
        title: m.title,
        percent: percent,
        amount: m.amount,
      ));
    }

    final project = Project(
      id: id,
      title: title,
      description: description,
      clientName: 'You',
      budget: budget,
      status: ProjectStatus.awaitingFunds,
      skills: skills,
      milestones: built,
      postedAt: DateTime.now(),
    );

    state = state.copyWith(projects: [project, ...state.projects]);
    return id;
  }

  /// Freelancer applies to an open job.
  void applyToProject(String projectId) {
    _updateProject(projectId, (p) => p.copyWith(freelancerName: 'You'));
    _notify(NoticeKind.message, 'Proposal sent',
        'The client has been notified of your proposal.', projectId: projectId);
  }

  // --- chat & notices ---

  // Send a message in the project chat. This is called by the freelancer or client.

  void sendMessage(String projectId, String text) {
    final msg = Message(
      id: _id(),
      projectId: projectId,
      text: text.trim(),
      sentAt: DateTime.now(),
      fromMe: true,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void markAllNoticesRead() {
    state = state.copyWith(
      notices: [for (final n in state.notices) n.markRead()],
    );
  }

  // --- disputes ---

  // The client or freelancer can open a dispute case. This freezes the project and requires admin intervention to resolve.

  void openCase(String projectId, String reason) {
    final project = _project(projectId);
    if (project == null) return;

    final newCase = DisputeCase(
      id: _id(),
      projectId: projectId,
      projectTitle: project.title,
      raisedBy: 'You',
      reason: reason,
      openedAt: DateTime.now(),
    );

    _updateProject(projectId, (p) => p.copyWith(status: ProjectStatus.disputed));
    state = state.copyWith(cases: [newCase, ...state.cases]);
    _notify(NoticeKind.admin, 'Case opened',
        'An admin will review this project. Funds are frozen until then.',
        projectId: projectId);
  }

  void resolveCase(String caseId) {
    state = state.copyWith(cases: [
      for (final c in state.cases) if (c.id == caseId) c.resolve() else c,
    ]);
    final resolved = state.cases.firstWhere((c) => c.id == caseId);
    _updateProject(resolved.projectId, (p) => p.copyWith(status: ProjectStatus.active));
  }

  // --- internals --- 

  // Helper to find a project by ID. Returns null if not found.

  Project? _project(String id) => state.project(id);

  void _updateProject(String id, Project Function(Project) change) {
    state = state.copyWith(projects: [
      for (final p in state.projects) if (p.id == id) change(p) else p,
    ]);
  }

  void _updateMilestone(
    String projectId,
    String milestoneId,
    Milestone Function(Milestone) change,
  ) {
    _updateProject(projectId, (p) => p.copyWith(milestones: [
          for (final m in p.milestones) if (m.id == milestoneId) change(m) else m,
        ]));
  }

  void _notify(NoticeKind kind, String title, String body, {String? projectId}) {
    final notice = Notice(
      id: _id(),
      kind: kind,
      title: title,
      body: body,
      at: DateTime.now(),
      projectId: projectId,
    );
    state = state.copyWith(notices: [notice, ...state.notices]);
  }
}

// small local copy so the store doesn't import the theme layer
String peso_(double amount) => '₱${amount.toStringAsFixed(2)}';

const demoFreelancers = [
  AppUser(
    id: 'f1', name: 'Paulina Manalo', headline: 'UI/UX Designer',
    rating: 4.9, completedProjects: 18, verified: true,
    skills: ['Figma', 'UI Design', 'Prototyping'], rate: '₱400–700/hr',
  ),
  AppUser(
    id: 'f2', name: 'Amadeo Mercado', headline: 'Full Stack Developer',
    rating: 4.8, completedProjects: 12, verified: true,
    skills: ['React', 'Node.js', 'Firebase'], rate: '₱500–800/hr',
  ),
  AppUser(
    id: 'f3', name: 'Bleu Sunshine', headline: 'Mobile Developer',
    rating: 4.7, completedProjects: 9, verified: false,
    skills: ['Flutter', 'Dart', 'Supabase'], rate: '₱600–900/hr',
  ),
  AppUser(
    id: 'f4', name: 'Xavier San Mateo', headline: 'Backend Engineer',
    rating: 4.6, completedProjects: 7, verified: true,
    skills: ['Python', 'FastAPI', 'PostgreSQL'], rate: '₱550–850/hr',
  ),
];

AppData _seed() {
  final now = DateTime.now();

  final cafePos = Project(
    id: '1',
    title: 'Cafe POS System',
    description:
        'A simple point-of-sale for a two-branch coffee shop. Needs an order '
        'screen, daily sales summary, and printable receipts.',
    clientName: 'Cebu Retail Co.',
    freelancerName: 'Paulina Manalo',
    budget: 5000,
    skills: ['Flutter', 'PostgreSQL'],
    postedAt: now.subtract(const Duration(days: 12)),
    milestones: [
      Milestone(id: '1-1', title: 'Wireframes & design', percent: 25, amount: 1250,
          status: MilestoneStatus.released),
      Milestone(id: '1-2', title: 'Order screen', percent: 25, amount: 1250,
          status: MilestoneStatus.submitted,
          submittedAt: now.subtract(const Duration(days: 12)),
          submissionNote: 'Order screen is done, including the receipt preview.'),
      const Milestone(id: '1-3', title: 'Sales summary', percent: 25, amount: 1250),
      const Milestone(id: '1-4', title: 'Testing & handover', percent: 25, amount: 1250),
    ],
  );

  final landing = Project(
    id: '2',
    title: 'Landing Page Redesign',
    description:
        'Refresh an existing marketing page. Same copy, new layout, must load '
        'fast on mobile data.',
    clientName: 'Studio Marikina',
    freelancerName: 'Amadeo Mercado',
    budget: 3750,
    skills: ['Figma', 'React'],
    postedAt: now.subtract(const Duration(days: 5)),
    milestones: [
      Milestone(id: '2-1', title: 'Concept & moodboard', percent: 40, amount: 1500,
          status: MilestoneStatus.released),
      Milestone(id: '2-2', title: 'Full page build', percent: 60, amount: 2250,
          status: MilestoneStatus.revision,
          revisionNote: 'Hero section feels cramped on small screens — can we '
              'give it more breathing room?'),
    ],
  );

  final openJobs = [
    Project(
      id: '3',
      title: 'Inventory Dashboard UI',
      description:
          'Design a dashboard for tracking stock across three warehouses. '
          'Charts, low-stock alerts, and a weekly export.',
      clientName: 'Berceles IT Solutions',
      budget: 4500,
      status: ProjectStatus.awaitingFunds,
      skills: ['UI Design', 'Figma'],
      postedAt: now.subtract(const Duration(hours: 2)),
      proposals: 3,
      milestones: const [
        Milestone(id: '3-1', title: 'Layout & flows', percent: 50, amount: 2250),
        Milestone(id: '3-2', title: 'Final screens', percent: 50, amount: 2250),
      ],
    ),
    Project(
      id: '4',
      title: 'Mobile App Icon Set',
      description: '24 icons in two weights, delivered as SVG and a Figma library.',
      clientName: 'Google Developer Group on Campus - HAU',
      budget: 1200,
      status: ProjectStatus.awaitingFunds,
      skills: ['Illustration', 'Figma'],
      postedAt: now.subtract(const Duration(hours: 9)),
      proposals: 6,
      milestones: const [
        Milestone(id: '4-1', title: 'First 12 icons', percent: 50, amount: 600),
        Milestone(id: '4-2', title: 'Remaining 12 icons', percent: 50, amount: 600),
      ],
    ),
  ];

  return AppData(
    projects: [cafePos, landing, ...openJobs],
    walletBalance: 2750,
    messages: [
      Message(id: 'm1', projectId: '1', text: 'Hi! Starting on the order screen today.',
          sentAt: now.subtract(const Duration(days: 13))),
      Message(id: 'm2', projectId: '1', text: 'Sounds good, take your time.',
          sentAt: now.subtract(const Duration(days: 13)), fromMe: true),
      Message(id: 'm3', projectId: '1', text: 'Submitted it for review — let me know!',
          sentAt: now.subtract(const Duration(days: 12))),
      Message(id: 'm4', projectId: '2', text: 'Sent the revised mockup, check niyo po.',
          sentAt: now.subtract(const Duration(hours: 3))),
    ],
    notices: [
      Notice(id: 'n1', kind: NoticeKind.timer, title: 'Review deadline approaching',
          body: 'Cafe POS System — 2 days left to review Milestone 2.',
          at: now.subtract(const Duration(hours: 1)), projectId: '1'),
      Notice(id: 'n2', kind: NoticeKind.payment, title: 'Milestone released',
          body: '₱1,500.00 was released for Landing Page Redesign.',
          at: now.subtract(const Duration(days: 4)), read: true, projectId: '2'),
      Notice(id: 'n3', kind: NoticeKind.verification, title: 'Verification approved',
          body: 'Your student ID has been verified.',
          at: now.subtract(const Duration(days: 8)), read: true),
    ],
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
