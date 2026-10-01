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
  static const sentToWorker = 'sent_to_worker';
}

class AlertType {
  static const reportAccepted = 'report_accepted';
  static const report = 'report';
  static const budget = 'budget';
  static const task = 'task';
  static const message = 'message';

  static const publicVisible = {reportAccepted, budget};
  static const reportBadge = {report, reportAccepted, 'report_status'};
  static const budgetBadge = {budget};
  static const taskBadge = {task};
  static const messageBadge = {message};
  static const workerVisible = {
    task,
    budget,
    'worker_approval',
    'worker_rejection',
  };
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

// Canonical worker skills stored on users + workerApplications.
class WorkerSpecialties {
  static const plumber = 'Plumber';
  static const electrician = 'Electrician';
  static const roadRepair = 'Road Repair';
  static const garbageCollection = 'Garbage Collection';
  static const waterSupply = 'Water Supply';
  static const sewage = 'Sewage';
  static const construction = 'Construction';
  static const carpenter = 'Carpenter';
  static const painter = 'Painter';
  static const other = 'Other';

  static const List<String> all = [
    plumber,
    electrician,
    roadRepair,
    garbageCollection,
    waterSupply,
    sewage,
    construction,
    carpenter,
    painter,
    other,
  ];

  static const Map<String, String> nepali = {
    plumber: 'प्लम्बर',
    electrician: 'इलेक्ट्रिसियन',
    roadRepair: 'सडक मर्मत',
    garbageCollection: 'फोहोर संकलन',
    waterSupply: 'पानी आपूर्ति',
    sewage: 'ढल व्यवस्थापन',
    construction: 'निर्माण',
    carpenter: 'सिकर्मी',
    painter: 'रंगकर्मी',
    other: 'अन्य',
  };

  static String chipLabel(String id, {required bool english}) {
    final np = nepali[id];
    if (english || np == null || np.isEmpty) return id;
    return '$id / $np';
  }

  static String canonicalize(String raw) {
    final english = raw.split('/').first.trim();
    if (english.isEmpty) return '';
    final key = english.toLowerCase();
    for (final item in all) {
      if (item.toLowerCase() == key) return item;
    }
    if (key.contains('plumb')) return plumber;
    if (key.contains('electric')) return electrician;
    if (key.contains('pothole') ||
        key.contains('road') ||
        key.contains('footpath')) {
      return roadRepair;
    }
    if (key.contains('garbage') || key.contains('waste')) {
      return garbageCollection;
    }
    if (key.contains('water')) return waterSupply;
    if (key.contains('sewage') ||
        key.contains('drain') ||
        key.contains('flood')) {
      return sewage;
    }
    if (key.contains('construct')) return construction;
    if (key.contains('carpent')) return carpenter;
    if (key.contains('paint')) return painter;
    return other;
  }

  static List<String> fromFirestore(dynamic listField, [String? legacy]) {
    final out = <String>{};
    void add(String raw) {
      final value = canonicalize(raw);
      if (value.isNotEmpty) out.add(value);
    }

    if (listField is List) {
      for (final item in listField) {
        add(item.toString());
      }
    }
    final text = (legacy ?? '').trim();
    if (text.isNotEmpty) {
      for (final part in text.split(RegExp(r'[,;]'))) {
        add(part);
      }
    }
    return List<String>.unmodifiable(out);
  }

  static Set<String> forReportCategory(String category) {
    switch (category.trim()) {
      case 'Pothole / Road Damage':
        return {roadRepair, construction};
      case 'Drainage / Flooding':
        return {sewage, plumber, construction};
      case 'Street Light':
        return {electrician};
      case 'Waste Management':
        return {garbageCollection};
      case 'Water Supply':
        return {plumber, waterSupply};
      case 'Public Infrastructure':
        return {construction, carpenter, painter, electrician, plumber};
      case 'Road Sign':
        return {roadRepair, painter, construction};
      case 'Footpath':
        return {roadRepair, construction, carpenter};
      case 'Traffic Issue':
        return {roadRepair, electrician};
      default:
        return {};
    }
  }

  static bool matchesCategory(List<String> workerSpecs, String category) {
    final needed = forReportCategory(category);
    if (needed.isEmpty) return true;
    final have = workerSpecs.map(canonicalize).toSet();
    if (have.contains(other)) return true;
    return have.any(needed.contains);
  }
}

class AppColors {
  static const darkGreen = 0xFF1A3D1A;
  static const mediumGreen = 0xFF2E6B2E;
  static const lightGreen = 0xFFB8D8B8;
}
