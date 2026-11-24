// LOCK 39. Preview source for future email delivery; this file sends nothing.
import 'dart:convert';

part 'zyra_email_templates_data.dart';

enum ZyraEmailChipTone { muted, gold, green, red }

class ZyraEmailTemplate {
  const ZyraEmailTemplate({
    required this.id,
    required this.recipientFirstName,
    required this.sampleDate,
    required this.subject,
    required this.chipLabel,
    required this.chipTone,
    required this.paragraphs,
    required this.footers,
    required this.journeyEmail,
    this.buttonLabel,
    this.signOff = 'The ZYRA team',
  });

  final String id;
  final String recipientFirstName;
  final String sampleDate;
  final String subject;
  final String chipLabel;
  final ZyraEmailChipTone chipTone;
  final List<String> paragraphs;
  final String? buttonLabel;
  final List<String> footers;
  final String signOff;
  final bool journeyEmail;

  /// The future service can read the approved words without gaining profile
  /// fields that are forbidden in email. Values here remain sample copy.
  Map<String, Object?> toPreviewSourceRecord() => {
    'id': id,
    'recipient_first_name': recipientFirstName,
    'sample_date': sampleDate,
    'subject': subject,
    'chip_label': chipLabel,
    'chip_tone': chipTone.name,
    'paragraphs': paragraphs,
    'button_label': buttonLabel,
    'footers': footers,
    'sign_off': signOff,
    'journey_email': journeyEmail,
  };

  static const settingsFooter =
      'Email settings in the app: Settings → Notifications & emails';

  String? _checkedActionUrl(String? actionUrl) {
    if (actionUrl == null) return null;
    final uri = Uri.tryParse(actionUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(actionUrl, 'actionUrl', 'HTTPS URL required');
    }
    return uri.toString();
  }

  /// The service must supply a real approved action URL before sending.
  /// With no URL, the preview button is a non-link visual sample.
  String renderHtml({String? actionUrl}) {
    final checkedUrl = _checkedActionUrl(actionUrl);
    String escape(String value) => const HtmlEscape().convert(value);
    final chipColor = switch (chipTone) {
      ZyraEmailChipTone.muted => '#6E6257',
      ZyraEmailChipTone.gold => '#845F24',
      ZyraEmailChipTone.green => '#326B4C',
      ZyraEmailChipTone.red => '#AC453E',
    };
    final chipBackground = switch (chipTone) {
      ZyraEmailChipTone.muted => 'rgba(62,46,30,.07)',
      ZyraEmailChipTone.gold => 'rgba(168,121,46,.13)',
      ZyraEmailChipTone.green => 'rgba(50,107,76,.10)',
      ZyraEmailChipTone.red => 'rgba(172,69,62,.10)',
    };
    final body = paragraphs
        .map(
          (line) =>
              '<p style="margin:0 0 14px;line-height:1.55">'
              '${escape(line)}</p>',
        )
        .join();
    final footer = footers
        .map(
          (line) =>
              '<p style="color:#6E6257;line-height:1.55">'
              '${escape(line)}</p>',
        )
        .join();
    final label = buttonLabel;
    final button = label == null
        ? ''
        : checkedUrl == null
        ? '<span style="display:block;border:1px solid #A9792E;'
              'border-radius:24px;padding:14px;text-align:center">'
              '${escape(label)}</span>'
        : '<a href="${const HtmlEscape(HtmlEscapeMode.attribute).convert(checkedUrl)}" style="display:block;'
              'border:1px solid #A9792E;border-radius:24px;padding:14px;'
              'text-align:center;color:#2B2420;text-decoration:none">'
              '${escape(label)}</a>';
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>${escape(subject)}</title></head>'
        '<body style="background:#FBF7F0;color:#2B2420;'
        'font:16px Arial,sans-serif">'
        '<main style="max-width:600px;margin:auto;padding:20px">'
        '<section style="background:#FAF5EC;border-radius:20px;padding:24px">'
        '<div style="text-align:center;letter-spacing:0.35em;'
        'color:#845F24">ZYRA</div>'
        '<div style="text-align:center;margin:18px 0">'
        '<span style="display:inline-block;border-radius:999px;'
        'border:1px solid $chipBackground;background:$chipBackground;'
        'color:$chipColor;padding:6px 12px">'
        '${escape(chipLabel)}</span></div>'
        '<p>Assalaamu alaikum ${escape(recipientFirstName)},</p>'
        '$body$button$footer<p>${escape(signOff)}</p></section>'
        '<p style="color:#6E6257;font-size:12px">'
        '${escape(settingsFooter)}</p></main></body></html>';
  }

  String renderPlainText({String? actionUrl}) => [
    'ZYRA · $chipLabel',
    '',
    'Assalaamu alaikum $recipientFirstName,',
    '',
    for (final paragraph in paragraphs) ...[paragraph, ''],
    if (buttonLabel != null) ...[
      buttonLabel!,
      ?_checkedActionUrl(actionUrl),
      '',
    ],
    for (final footer in footers) ...[footer, ''],
    signOff,
    '',
    settingsFooter,
  ].join('\n');
}

enum ZyraEmailSetting {
  journeyRequests,
  journeyStages,
  messages,
  guardianActivity,
  journeyEmails,
}

/// Caller-owned, preview-only values. No device permission or server preference.
class ZyraPreviewEmailSettings {
  const ZyraPreviewEmailSettings({
    this.journeyRequests = true,
    this.journeyStages = true,
    this.messages = true,
    this.guardianActivity = true,
    this.journeyEmails = true,
  });

  final bool journeyRequests;
  final bool journeyStages;
  final bool messages;
  final bool guardianActivity;
  final bool journeyEmails;

  bool value(ZyraEmailSetting setting) => switch (setting) {
    ZyraEmailSetting.journeyRequests => journeyRequests,
    ZyraEmailSetting.journeyStages => journeyStages,
    ZyraEmailSetting.messages => messages,
    ZyraEmailSetting.guardianActivity => guardianActivity,
    ZyraEmailSetting.journeyEmails => journeyEmails,
  };

  ZyraPreviewEmailSettings withValue(ZyraEmailSetting setting, bool enabled) =>
      ZyraPreviewEmailSettings(
        journeyRequests: setting == ZyraEmailSetting.journeyRequests
            ? enabled
            : journeyRequests,
        journeyStages: setting == ZyraEmailSetting.journeyStages
            ? enabled
            : journeyStages,
        messages: setting == ZyraEmailSetting.messages ? enabled : messages,
        guardianActivity: setting == ZyraEmailSetting.guardianActivity
            ? enabled
            : guardianActivity,
        journeyEmails: setting == ZyraEmailSetting.journeyEmails
            ? enabled
            : journeyEmails,
      );
}

/// A pure send decision for a future service to call with the recipient's own
/// preference. It cannot send mail or read another member's setting.
bool zyraPreviewShouldSendEmail(
  ZyraEmailTemplate template,
  ZyraPreviewEmailSettings recipientSettings,
) => !template.journeyEmail || recipientSettings.journeyEmails;

const zyraPreviewEmailTemplates = <ZyraEmailTemplate>[
  ..._zyraEmailTemplateData,
];

ZyraEmailTemplate? zyraPreviewEmailTemplate(String id) {
  for (final template in zyraPreviewEmailTemplates) {
    if (template.id == id) return template;
  }
  return null;
}
