// LOCK 51: fixed sample text from the V365 LEGAL table.
enum ZyraLegalPreviewDocument { privacy, terms, photos }

class ZyraLegalPreviewPage {
  const ZyraLegalPreviewPage({
    required this.title,
    required this.date,
    required this.webAddress,
    required this.sections,
    this.summary,
    this.lead,
  });

  final String title;
  final String date;
  final String webAddress;
  final List<ZyraLegalPreviewSection> sections;
  final List<String>? summary;
  final String? lead;
}

class ZyraLegalPreviewSection {
  const ZyraLegalPreviewSection(this.chip, this.heading, this.body);

  final String chip;
  final String heading;
  final String body;
}

const zyraLegalPreviewPages = {
  ZyraLegalPreviewDocument.privacy: ZyraLegalPreviewPage(
    title: 'Privacy policy',
    date: '24 Nov 2026',
    webAddress: 'zyraconnect.app/privacy',
    summary: [
      'We never sell your information or show your exact location.',
      'Faith and background answers are saved only if you agree, and never appear on your profile.',
      'Only verified members, and their Guardians, see your photos clearly.',
      'You can download your data, pause, or delete your account at any time.',
    ],
    sections: [
      ZyraLegalPreviewSection(
        'Who we are',
        'Who we are',
        'ZYRA is a marriage app where your family Guardians can take part in each Journey. This page explains what we keep about you, and why.',
      ),
      ZyraLegalPreviewSection(
        'What this covers',
        'What this policy covers',
        'The ZYRA app, the emails we send and our website. It does not cover other apps or websites you open from ZYRA.',
      ),
      ZyraLegalPreviewSection(
        'What we collect',
        'What we collect',
        'Your profile, photos and video, your Partner preferences answers, your Journeys and messages, and basic details about your phone.',
      ),
      ZyraLegalPreviewSection(
        'Why we use it',
        'Why we use it, and our legal reasons',
        'To run your account, keep members safe and show you compatible profiles. Each use has a legal reason under UK data protection law.',
      ),
      ZyraLegalPreviewSection(
        'Sensitive answers',
        'Faith, background and other sensitive answers',
        'These are saved only if you agree. They are never shown on your profile and are used only to order the profiles you see.',
      ),
      ZyraLegalPreviewSection(
        'Identity check',
        'Your identity check',
        'A short selfie video and your ID show us you are a real person. We keep the result of the check, not your document.',
      ),
      ZyraLegalPreviewSection(
        'Photos and video',
        'Your photos and video',
        'Verified members who can see your profile, and their Guardians, see your photos. Anyone not yet verified sees them blurred.',
      ),
      ZyraLegalPreviewSection(
        'What Guardians see',
        'What Guardians see',
        'Your Guardians see what you choose to share with them, Journey by Journey. You can change this at any time.',
      ),
      ZyraLegalPreviewSection(
        'Who else handles it',
        'Who else handles your information',
        'A small number of services help us run ZYRA, such as payments, email and crash reports. Each may use your information only for that job.',
      ),
      ZyraLegalPreviewSection(
        'Compatibility',
        'Compatibility ordering',
        'Your answers decide which profiles you see first. No person at ZYRA orders them by hand.',
      ),
      ZyraLegalPreviewSection(
        'Your area',
        'Your approximate area',
        'Other members see your town, never your exact location.',
      ),
      ZyraLegalPreviewSection(
        'Emails',
        'Emails and notifications',
        'We send the account emails you need. You choose which other emails and notifications you get.',
      ),
      ZyraLegalPreviewSection(
        'On your phone',
        'Things that stay on your phone',
        'Face ID and your App lock code stay on your phone. We never see them.',
      ),
      ZyraLegalPreviewSection(
        'How long we keep it',
        'How long we keep it',
        'Until you delete your account, then 30 days in case you change your mind. Safety reports are kept longer.',
      ),
      ZyraLegalPreviewSection(
        'Your rights',
        'Your rights',
        'You can see, correct, download or delete your information. Contact support to ask.',
      ),
      ZyraLegalPreviewSection(
        'Safety and reports',
        'Safety and reports',
        'When you report someone, we keep what we need to look into it, even after an account closes.',
      ),
      ZyraLegalPreviewSection(
        'Age',
        'Age',
        'ZYRA is only for people aged 18 and over.',
      ),
      ZyraLegalPreviewSection(
        'Changes',
        'Changes to this policy',
        'We will tell you in the app before any change to how your information is used.',
      ),
    ],
  ),
  ZyraLegalPreviewDocument.terms: ZyraLegalPreviewPage(
    title: 'Terms of use',
    date: '24 Nov 2026',
    webAddress: 'zyraconnect.app/terms',
    summary: [
      'ZYRA is for adults aged 18 and over who are serious about marriage.',
      'Every member checks their identity before they can begin a Journey.',
      'Memberships renew each month until you cancel in your Apple settings.',
      'Treat everyone with respect. We may close accounts that don’t.',
    ],
    sections: [
      ZyraLegalPreviewSection(
        'About these terms',
        'About these terms',
        'These terms are the agreement between you and ZYRA when you use the app.',
      ),
      ZyraLegalPreviewSection(
        'Who can join',
        'Who can join',
        'You must be 18 or over, single, and joining to look for marriage.',
      ),
      ZyraLegalPreviewSection(
        'Your account',
        'Your account and the identity check',
        'You sign in with Apple or Google and check your identity once. Keep your account to yourself.',
      ),
      ZyraLegalPreviewSection(
        'Seekers and Guardians',
        'Seekers and Guardians',
        'Seekers look for a spouse. Guardians are family members a Seeker invites to take part.',
      ),
      ZyraLegalPreviewSection(
        'Memberships',
        'Memberships and purchases',
        'Payments go through Apple. Memberships renew each month until you cancel.',
      ),
      ZyraLegalPreviewSection(
        'Guardian access',
        'Guardian access is the Seeker’s choice',
        'A Seeker decides which Guardians take part, and what each one can see.',
      ),
      ZyraLegalPreviewSection(
        'Refunds',
        'Cooling-off and refunds',
        'Refunds are handled by Apple, under its own rules.',
      ),
      ZyraLegalPreviewSection(
        'How to behave',
        'How to behave, reports and blocks',
        'Be honest and respectful. You can block or report anyone at any time.',
      ),
      ZyraLegalPreviewSection(
        'Journeys',
        'Journeys',
        'A Journey is a set time to get to know one person, with your Guardians beside you.',
      ),
      ZyraLegalPreviewSection(
        'Pausing and closing',
        'Pausing, private mode and closing your account',
        'Pause, go private or delete your account in Settings. You have 30 days to change your mind.',
      ),
      ZyraLegalPreviewSection(
        'Suspending accounts',
        'Our right to suspend or close accounts',
        'We may suspend or close an account that breaks these terms or puts others at risk.',
      ),
      ZyraLegalPreviewSection(
        'Liability',
        'Liability',
        'We work hard to keep ZYRA safe, but we can’t promise how any introduction will turn out.',
      ),
      ZyraLegalPreviewSection(
        'Changes',
        'Changes to these terms',
        'We will tell you in the app before these terms change.',
      ),
      ZyraLegalPreviewSection(
        'Complaints',
        'Complaints and law',
        'Contact support first and we will try to put it right.',
      ),
      ZyraLegalPreviewSection(
        'Apple and Google',
        'Apple and Google',
        'Apple and Google are not part of this agreement and are not responsible for ZYRA.',
      ),
    ],
  ),
  ZyraLegalPreviewDocument.photos: ZyraLegalPreviewPage(
    title: 'How photos are kept safe',
    date: '24 Nov 2026',
    webAddress: 'zyraconnect.app/photo-safety',
    lead:
        'Your photos are for people serious about marriage — and their families.',
    sections: [
      ZyraLegalPreviewSection(
        'Who can see them',
        'Who can see your photos',
        'Verified members who can see your profile, and their Guardians. Anyone not yet verified sees them blurred. Guardian Network shows members by initial only.',
      ),
      ZyraLegalPreviewSection(
        'Where they’re kept',
        'Where your photos are kept',
        'In private storage, never at a public web address.',
      ),
      ZyraLegalPreviewSection(
        'What we check',
        'What we check',
        'Every photo is checked before it shows: just you, with your face clear. No group photos, children or other people’s pictures.',
      ),
      ZyraLegalPreviewSection(
        'Your video',
        'Your video (Seeker One)',
        'Your profile video follows the same rules as your photos.',
      ),
      ZyraLegalPreviewSection(
        'What others may not do',
        'What other members may not do',
        'Copy or share your photos outside ZYRA. Anyone who does can be reported and removed.',
      ),
      ZyraLegalPreviewSection(
        'You stay in control',
        'You stay in control',
        'Change or remove photos at any time. Download my data includes your own photos. Delete your account and your photos go with it.',
      ),
    ],
  ),
};
