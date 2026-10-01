import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/logger.dart';

const appStoreId = '6744701950';
const microsoftStoreId = isWinStore ? '9N9HJP6DB31L' : 'XP8K2L3DJ2716V';

/// Prompts for an App Store / Play Store / Microsoft Store review after the
/// user has had the app installed for a while.
///
/// On Android / iOS / macOS: platform-native in-app review UI.
/// On Windows: a custom dialog that can open the Microsoft Store listing,
/// since [InAppReview.requestReview] is not supported there.
class ReviewPrompt {
  ReviewPrompt(this._pref, {InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final SharedPreferences _pref;
  final InAppReview _inAppReview;

  static const minDaysSinceFirstOpen = 3;

  static bool _requestInFlight = false;

  /// Call once at app start so install age can be measured, then maybe prompt.
  void onAppOpen(BuildContext context) {
    ensureFirstOpenRecorded();
    unawaited(maybeRequestReview(context));
  }

  /// Call once at app start so install age can be measured.
  void ensureFirstOpenRecorded() {
    if (_pref.firstOpenAt != null) return;

    // Existing installs already past onboarding: skip the waiting period so a
    // review can appear on the next eligible open after update.
    if (_pref.hasShownWelcome) {
      _pref.setFirstOpenAt(
        DateTime.now().subtract(const Duration(days: minDaysSinceFirstOpen)),
      );
    } else {
      _pref.setFirstOpenAt(DateTime.now());
    }
  }

  bool _isEligible() {
    if (_pref.lastReviewPromptAt != null) return false;

    final firstOpen = _pref.firstOpenAt;
    if (firstOpen == null) return false;
    if (DateTime.now().difference(firstOpen).inDays < minDaysSinceFirstOpen) {
      return false;
    }

    return true;
  }

  Future<void> maybeRequestReview(BuildContext context) async {
    if (_requestInFlight) return;
    if (!_isEligible()) return;

    _requestInFlight = true;
    try {
      // Record the attempt even if the user dismisses / OS suppresses, so we
      // never auto-ask again from our side.
      _pref.setLastReviewPromptAt(DateTime.now());

      if (Platform.isWindows) {
        if (!context.mounted) return;
        await _showWindowsReviewDialog(context);
        return;
      }

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        logger.d('Requested in-app review');
      } else {
        logger.d('In-app review unavailable');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to request in-app review',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _showWindowsReviewDialog(BuildContext context) async {
    final shouldRate = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.rateApp)),
            ],
          ),
          content: Text(
            l10n.rateAppPromptDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.notNow),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.rateApp),
            ),
          ],
        );
      },
    );

    if (shouldRate == true) {
      await openStoreListing();
    }
  }

  Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(
      appStoreId: appStoreId,
      microsoftStoreId: microsoftStoreId,
    );
  }

  /// Settings "Rate UmiVPN" button: native review dialog, or store listing.
  Future<void> openReviewOrStoreListing() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await openStoreListing();
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to open review / store listing',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
