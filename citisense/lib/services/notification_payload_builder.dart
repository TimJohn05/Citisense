import 'package:flutter/foundation.dart';

import '../models/enums.dart';

class NotificationPayloadBuilder {
  NotificationPayloadBuilder._();

  static final Map<ComplaintStatus, Map<String, String>> _titleTemplates = {
    ComplaintStatus.pending: {
      'en': 'Your complaint #{id} is now Pending',
      'tl': 'Ang inyong reklamo #{id} ay Pending na',
    },
    ComplaintStatus.inReview: {
      'en': 'Your complaint #{id} is under review',
      'tl': 'Ang inyong reklamo #{id} ay nililinis na',
    },
    ComplaintStatus.resolved: {
      'en': 'Your complaint #{id} has been resolved',
      'tl': 'Ang inyong reklamo #{id} ay naayos na',
    },
    ComplaintStatus.rejected: {
      'en': 'Your complaint #{id} was rejected',
      'tl': 'Ang inyong reklamo #{id} ay tinanggihan',
    },
    ComplaintStatus.acknowledged: {
      'en': 'Your complaint #{id} acknowledged',
      'tl': 'Ang inyong reklamo #{id} ay nakuha na',
    },
  };

  static final Map<ComplaintStatus, Map<String, String>> _bodyTemplates = {
    ComplaintStatus.pending: {
      'en': 'Your complaint has been received and is pending review.',
      'tl': 'Ang inyong reklamo ay natanggap na at nakabinbin pa.',
    },
    ComplaintStatus.inReview: {
      'en': 'An officer is now reviewing your complaint.',
      'tl': 'May opisyal na nagreribyu sa inyong reklamo.',
    },
    ComplaintStatus.resolved: {
      'en': 'Your complaint has been resolved. Thank you for reporting!',
      'tl': 'Ang inyong reklamo ay naayos na. Salamat sa pag-uulat!',
    },
    ComplaintStatus.rejected: {
      'en': 'Your complaint was rejected. Reason: {reason}',
      'tl': 'Ang inyong reklamo ay tinanggihan. Dahilan: {reason}',
    },
    ComplaintStatus.acknowledged: {
      'en': 'Your complaint has been acknowledged and assigned to an officer.',
      'tl': 'Ang inyong reklamo ay nakuha na at na-assign sa isang opisyal.',
    },
  };

  static String _getLocale() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode == 'tl' ? 'tl' : 'en';
  }

  static String _getTemplate(
    Map<ComplaintStatus, Map<String, String>> templates,
    ComplaintStatus status,
  ) {
    final locale = _getLocale();
    return templates[status]?[locale] ?? templates[status]?['en'] ?? '';
  }

  static String _formatTemplate(String template, String complaintId, String? description) {
    String result = template.replaceAll('#{id}', complaintId);

    if (description != null && description.isNotEmpty) {
      final descPreview = description.length > 50
          ? '${description.substring(0, 50)}...'
          : description;
      result = result.replaceAll('{description}', descPreview);
    }

    return result;
  }

  static Map<String, dynamic> buildPayload({
    required String complaintId,
    required ComplaintStatus oldStatus,
    required ComplaintStatus newStatus,
    required String description,
    String? customMessage,
    String? officerName,
  }) {
    // Title
    String title = _getTemplate(_titleTemplates, newStatus)
        .replaceAll('#{id}', complaintId.substring(0, 8));

    // Body
    String body;
    if (customMessage != null && customMessage.isNotEmpty) {
      body = customMessage;
    } else {
      final template = _getTemplate(_bodyTemplates, newStatus);
      String bodyText = _formatTemplate(template, complaintId.substring(0, 8), null);

      // Add officer name if available
      if (officerName != null && officerName.isNotEmpty) {
        bodyText += '\n— $officerName';
      }

      body = bodyText;
    }

    // Data payload for FCM
    final data = {
      'complaintId': complaintId,
      'type': 'status_change',
      'oldStatus': newStatus.name,
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    return {
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data,
      'android': {
        'channelId': 'complaint_updates',
        'priority': 'high',
        'notification': {
          'sound': 'default',
          'defaultVibrateTimings': true,
        },
      },
      'apns': {
        'payload': {
          'aps': {
            'sound': 'default',
            'badge': 1,
          },
        },
      },
    };
  }

  /// Build localized title/body for local notifications
  static ({String title, String body}) buildLocalized({
    required String complaintId,
    required ComplaintStatus newStatus,
    String? customMessage,
    String? officerName,
  }) {
    String title = _getTemplate(_titleTemplates, newStatus)
        .replaceAll('#{id}', complaintId.substring(0, 8));

    String body;
    if (customMessage != null && customMessage.isNotEmpty) {
      body = customMessage;
    } else {
      final template = _getTemplate(_bodyTemplates, newStatus);
      body = _formatTemplate(template, complaintId.substring(0, 8), null);

      if (officerName != null && officerName.isNotEmpty) {
        body += '\n— $officerName';
      }
    }

    return (title: title, body: body);
  }

  /// Get localized status label
  static String getStatusLabel(ComplaintStatus status) {
    const labels = {
      'en': {
        ComplaintStatus.pending: 'Pending',
        ComplaintStatus.inReview: 'Under Review',
        ComplaintStatus.resolved: 'Resolved',
        ComplaintStatus.rejected: 'Rejected',
        ComplaintStatus.acknowledged: 'Acknowledged',
      },
      'tl': {
        ComplaintStatus.pending: 'Pending',
        ComplaintStatus.inReview: 'Nililinis na',
        ComplaintStatus.resolved: 'Naayos na',
        ComplaintStatus.rejected: 'Tinanggihan',
        ComplaintStatus.acknowledged: 'Nakuha na',
      },
    };
    final locale = _getLocale();
    return labels[locale]?[status] ?? labels['en']?[status] ?? status.name;
  }
}