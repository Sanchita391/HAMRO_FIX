class AccountStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const active = 'active';
  static const rejected = 'rejected';
  static const suspended = 'suspended';
  static const blacklisted = 'blacklisted';
  static const disabled = 'disabled';
}

class ReportStatus {
  static const submitted = 'submitted';
  static const officialReview = 'official_review';
  static const officialAccepted = 'official_accepted';
  static const officialDeclined = 'official_declined';
  static const workerAssigned = 'worker_assigned';
  static const workerInspection = 'worker_inspection';
  static const verifiedValid = 'verified_valid';
  static const verifiedFake = 'verified_fake';
  static const needsMoreInfo = 'needs_more_information';
  static const duplicate = 'duplicate';
  static const sentToAdmin = 'sent_to_admin_for_budget';
  static const budgetApproved = 'budget_approved';
  static const budgetRejected = 'budget_rejected';
  static const revisionRequired = 'revision_required';
  static const taskAssigned = 'task_assigned';
  static const workInProgress = 'work_in_progress';
  static const workCompleted = 'work_completed';
  static const officialFinalReview = 'official_final_review';
  static const completed = 'completed';
  static const publicFeed = 'public_feed';
}

class BudgetStatus {
  static const draft = 'draft';
  static const submittedToOfficial = 'submitted_to_official';
  static const forwardedToAdmin = 'forwarded_to_admin';
  static const adminReview = 'admin_review';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const revisionRequired = 'revision_required';
  static const finalApproved = 'final_approved';
}

class TaskStatus {
  static const assigned = 'assigned';
  static const accepted = 'accepted';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const reviewRequired = 'review_required';
  static const approved = 'approved';
  static const closed = 'closed';
}

class ReportCategories {
  static const List<String> all = [
    'Pothole / Road Damage',
    'Drainage / Flooding',
    'Street Light',
    'Waste Management',
    'Water Supply',
    'Public Infrastructure',
    'Road Sign',
    'Footpath',
    'Traffic Issue',
    'Other',
  ];
}

class AppColors {
  static const darkGreen = 0xFF1A3D1A;
  static const mediumGreen = 0xFF2E6B2E;
  static const lightGreen = 0xFFB8D8B8;
}
