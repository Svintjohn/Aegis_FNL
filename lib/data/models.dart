enum Role { client, freelancer }

// The status of a milestone in the project workflow. The order is important, as it
enum MilestoneStatus {
  locked,      
  submitted,   
  revision,  
  released,    
}

// The status of a project in the workflow. The order is important, as it
enum ProjectStatus { awaitingFunds, active, completed, disputed }
class AppUser {
  final String id;
  final String name;
  final String headline;
  final double rating;
  final int completedProjects;
  final bool verified;
  final List<String> skills;
  final String rate;

  const AppUser({
    required this.id,
    required this.name,
    required this.headline,
    this.rating = 0,
    this.completedProjects = 0,
    this.verified = false,
    this.skills = const [],
    this.rate = '',
  });

  String get initials => name.trim().split(' ').map((w) => w[0]).take(2).join();
}

class Milestone {
  final String id;
  final String title;
  final int percent;
  final double amount;
  final MilestoneStatus status;
  final DateTime? submittedAt;
  final String? submissionNote;
  final String? revisionNote;

  const Milestone({
    required this.id,
    required this.title,
    required this.percent,
    required this.amount,
    this.status = MilestoneStatus.locked,
    this.submittedAt,
    this.submissionNote,
    this.revisionNote,
  });

  /// The client gets 14 days to respond once work is submitted, then the
  /// funds release on their own. 
  int? get daysLeftToReview {
    if (status != MilestoneStatus.submitted || submittedAt == null) return null;
    final elapsed = DateTime.now().difference(submittedAt!).inDays;
    return (14 - elapsed).clamp(0, 14);
  }

  Milestone copyWith({
    MilestoneStatus? status,
    DateTime? submittedAt,
    String? submissionNote,
    String? revisionNote,
  }) {
    return Milestone(
      id: id,
      title: title,
      percent: percent,
      amount: amount,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionNote: submissionNote ?? this.submissionNote,
      revisionNote: revisionNote ?? this.revisionNote,
    );
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String clientName;
  final String? freelancerName;
  final double budget;
  final ProjectStatus status;
  final List<String> skills;
  final List<Milestone> milestones;
  final DateTime postedAt;
  final int proposals;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.clientName,
    required this.budget,
    this.freelancerName,
    this.status = ProjectStatus.active,
    this.skills = const [],
    this.milestones = const [],
    required this.postedAt,
    this.proposals = 0,
  });

  bool get isFunded => status != ProjectStatus.awaitingFunds;

  double get lockedAmount => milestones
      .where((m) => m.status != MilestoneStatus.released)
      .fold(0.0, (sum, m) => sum + m.amount);

  double get releasedAmount => milestones
      .where((m) => m.status == MilestoneStatus.released)
      .fold(0.0, (sum, m) => sum + m.amount);

  double get progress {
    if (milestones.isEmpty) return 0;
    final done = milestones.where((m) => m.status == MilestoneStatus.released).length;
    return done / milestones.length;
  }

// The first milestone that is not yet released. This is the one that the freelancer is currently working on, or the next one to be worked on.
  Milestone? get currentMilestone {
    for (final m in milestones) {
      if (m.status != MilestoneStatus.released) return m;
    }
    return null;
  }

  Project copyWith({
    ProjectStatus? status,
    List<Milestone>? milestones,
    String? freelancerName,
  }) {
    return Project(
      id: id,
      title: title,
      description: description,
      clientName: clientName,
      freelancerName: freelancerName ?? this.freelancerName,
      budget: budget,
      status: status ?? this.status,
      skills: skills,
      milestones: milestones ?? this.milestones,
      postedAt: postedAt,
      proposals: proposals,
    );
  }
}

class Message {
  final String id;
  final String projectId;
  final String text;
  final DateTime sentAt;
  final bool fromMe;

  const Message({
    required this.id,
    required this.projectId,
    required this.text,
    required this.sentAt,
    this.fromMe = false,
  });
}

enum NoticeKind { timer, payment, message, verification, admin }

class Notice {
  final String id;
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? projectId;

  const Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    this.projectId,
  });

  Notice markRead() => Notice(
        id: id, kind: kind, title: title, body: body,
        at: at, read: true, projectId: projectId,
      );
}

class DisputeCase {
  final String id;
  final String projectId;
  final String projectTitle;
  final String raisedBy;
  final String reason;
  final DateTime openedAt;
  final bool resolved;

  const DisputeCase({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.raisedBy,
    required this.reason,
    required this.openedAt,
    this.resolved = false,
  });

  DisputeCase resolve() => DisputeCase(
        id: id, projectId: projectId, projectTitle: projectTitle,
        raisedBy: raisedBy, reason: reason, openedAt: openedAt, resolved: true,
      );
}
