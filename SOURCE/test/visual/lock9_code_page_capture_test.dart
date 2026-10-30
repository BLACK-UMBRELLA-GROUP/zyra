import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_local_code_aliases.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/wali_invite_seeker_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK9_CODE_PAGE_2026-10-30';
const _capture = bool.fromEnvironment('ZYRA_LOCK9_CAPTURE');
Finder _key(String id) => find.byKey(ValueKey(id));
void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final mode in ['scan', 'add_guardian', 'guardian_signup_add_seeker']) {
    testWidgets(
      'LOCK9 actual $mode states and local effect boundary',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
        ZyraInternalPreviewClient.beginPreview();
        final h = BaselineHarness(
          t,
          group: 'lock9_$mode',
          outputRoot: '$_root/PRODUCT/APPROVED/CODE_PAGE/BUILT',
          evidenceRoot: _evidence,
          flatOutput: true,
        );
        if (mode == 'guardian_signup_add_seeker') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
          ZyraInternalPreviewClient.beginPreview();
          await h.mountPresentation(
            child: const WaliInviteSeekerScreen(signupPreview: true),
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: true,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: const [],
            ),
          );
        } else {
          await h.mount(tab: mode == 'scan' ? 0 : 3, pages: const []);
        }
        if (mode == 'scan') {
          await h.tap('concept_browse_menu');
          final target = find.descendant(
            of: _key('concept_browse_options_navigation'),
            matching: _key('floating-nav-item-1'),
          );
          await t.tapAt(t.getCenter(target));
          await h.flush();
        } else if (mode == 'add_guardian') {
          await h.tap('guardian-add-top');
        }
        Future<void> cap(String state) async {
          if (_capture) {
            await h.capture(
              'code_page',
              '${mode}__$state',
              state,
              'Actual local caller; no camera/request/link service invoked.',
              fileName: '${mode}__$state.png',
            );
          }
        }

        await cap(mode == 'scan' ? 'empty' : 'normal');
        if (mode == 'scan') {
          await t.enterText(_key('local-code-field'), '7k2mq9td4h');
          FocusManager.instance.primaryFocus?.unfocus();
          await h.flush();
          await cap('typing');
        }
        await t.enterText(
          _key('local-code-field'),
          ZyraLocalCodeAliases.master,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await h.flush();
        await h.tap('local-code-check');
        expect(find.textContaining('first name and role only'), findsOneWidget);
        await cap('found');
        if (mode != 'scan') {
          await h.tap('local-code-send');
          expect(find.text('Request sent'), findsOneWidget);
          expect(find.byType(BottomSheet), findsNothing);
          await cap('sent');
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
