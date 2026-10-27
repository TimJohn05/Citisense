import 'complaint.dart';
import 'enums.dart';

class CitizenNotification {
  final String id;
  final String complaintId;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final String heading;
  final String remarks;
  final String? officerName;
  final DateTime timestamp;
  final bool isRead;

  const CitizenNotification({
    required this.id,
    required this.complaintId,
    required this.category,
    required this.status,
    required this.heading,
    required this.remarks,
    this.officerName,
    required this.timestamp,
    this.isRead = false,
  });

  CitizenNotification copyWith({
    bool? isRead,
  }) {
    return CitizenNotification(
      id: id,
      complaintId: complaintId,
      category: category,
      status: status,
      heading: heading,
      remarks: remarks,
      officerName: officerName,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  static CitizenNotification? fromComplaint(Complaint complaint, {bool isRead = false}) {
    if (complaint.status == ComplaintStatus.pending) {
      return null;
    }

    final heading = switch (complaint.status) {
      ComplaintStatus.inReview => 'Report Placed Under Review',
      ComplaintStatus.resolved => 'Report Accepted & Resolved',
      ComplaintStatus.rejected => 'Report Rejected',
      _ => 'Report Status Updated',
    };

    final remarks = switch (complaint.status) {
      ComplaintStatus.rejected =>
        (complaint.rejectReason != null && complaint.rejectReason!.trim().isNotEmpty)
            ? complaint.rejectReason!.trim()
            : 'No rejection reason specified.',
      ComplaintStatus.resolved =>
        (complaint.officerNotes != null && complaint.officerNotes!.trim().isNotEmpty)
            ? complaint.officerNotes!.trim()
            : 'Issue marked as resolved by barangay official.',
      ComplaintStatus.inReview =>
        (complaint.officerNotes != null && complaint.officerNotes!.trim().isNotEmpty)
            ? complaint.officerNotes!.trim()
            : 'Report acknowledged and currently under investigation.',
      _ => 'Status changed to ${complaint.status.label}.',
    };

    final timestamp = complaint.resolvedAt ?? complaint.createdAt;

    return CitizenNotification(
      id: '${complaint.id}_${complaint.status.name}',
      complaintId: complaint.id,
      category: complaint.category,
      status: complaint.status,
      heading: heading,
      remarks: remarks,
      officerName: complaint.resolvedBy,
      timestamp: timestamp,
      isRead: isRead,
    );
  }
}
