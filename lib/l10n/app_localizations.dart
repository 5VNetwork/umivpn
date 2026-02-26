import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @node.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get node;

  /// No description provided for @inbound.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get inbound;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get logLevel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get routing;

  /// No description provided for @whileList.
  ///
  /// In en, this message translates to:
  /// **'CN'**
  String get whileList;

  /// No description provided for @gfw.
  ///
  /// In en, this message translates to:
  /// **'GFW'**
  String get gfw;

  /// No description provided for @proxyAll.
  ///
  /// In en, this message translates to:
  /// **'Proxy All'**
  String get proxyAll;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @systemProxy.
  ///
  /// In en, this message translates to:
  /// **'System Proxy'**
  String get systemProxy;

  /// No description provided for @inputManually.
  ///
  /// In en, this message translates to:
  /// **'Input Manually'**
  String get inputManually;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @addNode.
  ///
  /// In en, this message translates to:
  /// **'Add Node'**
  String get addNode;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @domainStrategy.
  ///
  /// In en, this message translates to:
  /// **'Domain Strategy'**
  String get domainStrategy;

  /// No description provided for @enableMux.
  ///
  /// In en, this message translates to:
  /// **'Enable Mux'**
  String get enableMux;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @ipOrDomain.
  ///
  /// In en, this message translates to:
  /// **'IP / Domain'**
  String get ipOrDomain;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @nodeSelection.
  ///
  /// In en, this message translates to:
  /// **'Node Selection'**
  String get nodeSelection;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get disconnecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @speedTest.
  ///
  /// In en, this message translates to:
  /// **'Speed Test'**
  String get speedTest;

  /// No description provided for @statusTest.
  ///
  /// In en, this message translates to:
  /// **'Usable Test'**
  String get statusTest;

  /// No description provided for @selfhost.
  ///
  /// In en, this message translates to:
  /// **'Selfhost'**
  String get selfhost;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get reconnecting;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @emptyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Empty clipboard'**
  String get emptyClipboard;

  /// No description provided for @decodeQrCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode QR code'**
  String get decodeQrCode;

  /// No description provided for @proxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get proxy;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promote;

  /// No description provided for @domainsOrIps.
  ///
  /// In en, this message translates to:
  /// **'Domains/IPs'**
  String get domainsOrIps;

  /// No description provided for @addProxyDomainIp.
  ///
  /// In en, this message translates to:
  /// **'Add Proxy Domain/IP'**
  String get addProxyDomainIp;

  /// No description provided for @addDirectDomainIp.
  ///
  /// In en, this message translates to:
  /// **'Add Direct Domain/IP'**
  String get addDirectDomainIp;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @invalidIp.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP'**
  String get invalidIp;

  /// No description provided for @invalidCidr.
  ///
  /// In en, this message translates to:
  /// **'Invalid CIDR'**
  String get invalidCidr;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @regularExpression.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regularExpression;

  /// No description provided for @keyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get keyword;

  /// No description provided for @rootDomain.
  ///
  /// In en, this message translates to:
  /// **'Root Domain'**
  String get rootDomain;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// No description provided for @editServer.
  ///
  /// In en, this message translates to:
  /// **'Edit Server'**
  String get editServer;

  /// No description provided for @sshKey.
  ///
  /// In en, this message translates to:
  /// **'SSH Key'**
  String get sshKey;

  /// No description provided for @selectFromFile.
  ///
  /// In en, this message translates to:
  /// **'Select From File'**
  String get selectFromFile;

  /// No description provided for @sudoPassword.
  ///
  /// In en, this message translates to:
  /// **'Sudo Password'**
  String get sudoPassword;

  /// No description provided for @statusMonitor.
  ///
  /// In en, this message translates to:
  /// **'Status Monitor'**
  String get statusMonitor;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field Required'**
  String get fieldRequired;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid Port'**
  String get invalidPort;

  /// No description provided for @invalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get invalidAddress;

  /// No description provided for @failedToAddServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to add server'**
  String get failedToAddServer;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @serverPubKey.
  ///
  /// In en, this message translates to:
  /// **'Server Public Key'**
  String get serverPubKey;

  /// No description provided for @serverPubKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'If not filled, any public key sent by the server on the first connection will be accepted, then the public key will be used on the future connections.'**
  String get serverPubKeyHelper;

  /// No description provided for @failedConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get failedConnectServer;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @keyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Key Passphrase'**
  String get keyPassphrase;

  /// No description provided for @showRealtimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Show Realtime Status'**
  String get showRealtimeStatus;

  /// No description provided for @hideRealtimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Hide Realtime Status'**
  String get hideRealtimeStatus;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// No description provided for @prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get prefix;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addToProxy.
  ///
  /// In en, this message translates to:
  /// **'Add to Proxy?'**
  String get addToProxy;

  /// No description provided for @addToDirect.
  ///
  /// In en, this message translates to:
  /// **'Add to Direct?'**
  String get addToDirect;

  /// No description provided for @default0.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default0;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @remainingData.
  ///
  /// In en, this message translates to:
  /// **'Remaining Data'**
  String get remainingData;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @updateInterval.
  ///
  /// In en, this message translates to:
  /// **'Update Interval'**
  String get updateInterval;

  /// No description provided for @testArea.
  ///
  /// In en, this message translates to:
  /// **'Test Area'**
  String get testArea;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto Update'**
  String get autoUpdate;

  /// No description provided for @unableToGetNodes.
  ///
  /// In en, this message translates to:
  /// **'Failed to get nodes, your pasteboard does not contain a subscription url that UmiVPN can parse'**
  String get unableToGetNodes;

  /// No description provided for @unableToGetNodesEmptyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to get nodes, clipboard is empty'**
  String get unableToGetNodesEmptyClipboard;

  /// No description provided for @subscriptionAddress.
  ///
  /// In en, this message translates to:
  /// **'Subscription Address'**
  String get subscriptionAddress;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @invalidHttp.
  ///
  /// In en, this message translates to:
  /// **'Invalid HTTPS URL'**
  String get invalidHttp;

  /// No description provided for @noNode.
  ///
  /// In en, this message translates to:
  /// **'No Node'**
  String get noNode;

  /// No description provided for @failedToChangeOutboundMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change outbound mode'**
  String get failedToChangeOutboundMode;

  /// No description provided for @failedToChangeFakeDns.
  ///
  /// In en, this message translates to:
  /// **'Failed to change fake dns'**
  String get failedToChangeFakeDns;

  /// No description provided for @failedToChangeRoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change routing mode'**
  String get failedToChangeRoutingMode;

  /// No description provided for @disableInAuto.
  ///
  /// In en, this message translates to:
  /// **'Disable in auto mode'**
  String get disableInAuto;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @remarkAddress.
  ///
  /// In en, this message translates to:
  /// **'Remark & Address'**
  String get remarkAddress;

  /// No description provided for @usable.
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get usable;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @latency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latency;

  /// No description provided for @selectOneOutbound.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOneOutbound;

  /// No description provided for @addFailedUniqueConstraint.
  ///
  /// In en, this message translates to:
  /// **'Addition failed because the rule confilcts with an existing rule.'**
  String get addFailedUniqueConstraint;

  /// No description provided for @enableInAuto.
  ///
  /// In en, this message translates to:
  /// **'Enable in auto mode'**
  String get enableInAuto;

  /// No description provided for @showClient.
  ///
  /// In en, this message translates to:
  /// **'Show Client'**
  String get showClient;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnectedUnexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Disconnected unexpectedly. Reason: {reason}'**
  String disconnectedUnexpectedly(String reason);

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @iosAppRoutingNoSupport.
  ///
  /// In en, this message translates to:
  /// **'App-based routing is currently not supported on iOS'**
  String get iosAppRoutingNoSupport;

  /// No description provided for @failedToChangeInboundMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change inbound'**
  String get failedToChangeInboundMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @mannual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get mannual;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{value} {value, plural, =0{Minutes} =1{Minute} other{Minutes}}'**
  String min(num value);

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'{value} {value, plural, =0{Hours} =1{Hour} other{Hours}}'**
  String hour(num value);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @openSourceSoftwareNotice.
  ///
  /// In en, this message translates to:
  /// **'Open Source Software Notice'**
  String get openSourceSoftwareNotice;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @privacyPolicySummary.
  ///
  /// In en, this message translates to:
  /// **'UmiVPN only collects diagnostic logs if the switch button below is on. These logs do not contain personal data. Please click the button below to view the detailed privacy policy.'**
  String get privacyPolicySummary;

  /// No description provided for @diagnosticLogDoesNotContainPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic logs does not link to you, and does not contain personal data'**
  String get diagnosticLogDoesNotContainPersonalData;

  /// No description provided for @shareDiagnosticLogWithDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Share diagnostic logs with developers'**
  String get shareDiagnosticLogWithDeveloper;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @contactUsSummary.
  ///
  /// In en, this message translates to:
  /// **'You can contact us by the following ways. Thank you!'**
  String get contactUsSummary;

  /// No description provided for @contactUsFreely.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions, please contact us.'**
  String get contactUsFreely;

  /// No description provided for @bugAreWelcome.
  ///
  /// In en, this message translates to:
  /// **'Bug reports and suggestions are welcome, thanks very much!'**
  String get bugAreWelcome;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @openSourceSoftwareNoticeText.
  ///
  /// In en, this message translates to:
  /// **'UmiVPN uses the following open-source projects:'**
  String get openSourceSoftwareNoticeText;

  /// No description provided for @sourceCodeUrl.
  ///
  /// In en, this message translates to:
  /// **'URL to source code'**
  String get sourceCodeUrl;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Login'**
  String get loginWithEmail;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get loginWithApple;

  /// No description provided for @loginWithMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get loginWithMicrosoft;

  /// No description provided for @newUserTrialText.
  ///
  /// In en, this message translates to:
  /// **'New users can try Pro for 7 days for free'**
  String get newUserTrialText;

  /// No description provided for @proExpiredAt.
  ///
  /// In en, this message translates to:
  /// **'Pro Expiry'**
  String get proExpiredAt;

  /// No description provided for @lifetimeProAccount.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Pro Account'**
  String get lifetimeProAccount;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to Group'**
  String get addToGroup;

  /// No description provided for @addApp.
  ///
  /// In en, this message translates to:
  /// **'Add App'**
  String get addApp;

  /// No description provided for @noSelectedNode.
  ///
  /// In en, this message translates to:
  /// **'No selected node'**
  String get noSelectedNode;

  /// No description provided for @pleaseSelectNode.
  ///
  /// In en, this message translates to:
  /// **'Please select a node'**
  String get pleaseSelectNode;

  /// No description provided for @pleaseSelectSelector.
  ///
  /// In en, this message translates to:
  /// **'Please select a selector'**
  String get pleaseSelectSelector;

  /// No description provided for @pleaseEnterRuleName.
  ///
  /// In en, this message translates to:
  /// **'Please enter rule name'**
  String get pleaseEnterRuleName;

  /// No description provided for @ruleName.
  ///
  /// In en, this message translates to:
  /// **'Matched Rule Name'**
  String get ruleName;

  /// No description provided for @matchAll.
  ///
  /// In en, this message translates to:
  /// **'Match All'**
  String get matchAll;

  /// No description provided for @ruleMatchCondition.
  ///
  /// In en, this message translates to:
  /// **'When all conditions are met, the rule matches. If there are zero conditions, the rule will never match.'**
  String get ruleMatchCondition;

  /// No description provided for @inboundLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get inboundLabel;

  /// No description provided for @domainSet.
  ///
  /// In en, this message translates to:
  /// **'Domain Set'**
  String get domainSet;

  /// No description provided for @appSet.
  ///
  /// In en, this message translates to:
  /// **'App Set'**
  String get appSet;

  /// No description provided for @ipSet.
  ///
  /// In en, this message translates to:
  /// **'IP Set'**
  String get ipSet;

  /// No description provided for @addRouterRule.
  ///
  /// In en, this message translates to:
  /// **'Add Router Rule'**
  String get addRouterRule;

  /// No description provided for @addDnsRule.
  ///
  /// In en, this message translates to:
  /// **'Add DNS Rule'**
  String get addDnsRule;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get editRule;

  /// No description provided for @addRouter.
  ///
  /// In en, this message translates to:
  /// **'Add Route Mode'**
  String get addRouter;

  /// No description provided for @copyDefault.
  ///
  /// In en, this message translates to:
  /// **'Copy Default'**
  String get copyDefault;

  /// No description provided for @ruleOrder.
  ///
  /// In en, this message translates to:
  /// **'Rules are matched from top to bottom'**
  String get ruleOrder;

  /// No description provided for @nodeChain.
  ///
  /// In en, this message translates to:
  /// **'Node Chain'**
  String get nodeChain;

  /// No description provided for @nodeChainDesc.
  ///
  /// In en, this message translates to:
  /// **'Nodes selected will use the following nodes in a node chain. The last node in the chain is the landing node.'**
  String get nodeChainDesc;

  /// No description provided for @addSelector.
  ///
  /// In en, this message translates to:
  /// **'Add Selector'**
  String get addSelector;

  /// No description provided for @selectorNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Selector name cannot be duplicated'**
  String get selectorNameDuplicate;

  /// No description provided for @renameSelector.
  ///
  /// In en, this message translates to:
  /// **'Rename Selector'**
  String get renameSelector;

  /// No description provided for @allNodes.
  ///
  /// In en, this message translates to:
  /// **'All Nodes'**
  String get allNodes;

  /// No description provided for @partialNodes.
  ///
  /// In en, this message translates to:
  /// **'Partial Nodes'**
  String get partialNodes;

  /// No description provided for @nodeGroup.
  ///
  /// In en, this message translates to:
  /// **'Node Group'**
  String get nodeGroup;

  /// No description provided for @lowestLatency.
  ///
  /// In en, this message translates to:
  /// **'Lowest Latency'**
  String get lowestLatency;

  /// No description provided for @lowLatency.
  ///
  /// In en, this message translates to:
  /// **'Low Latency'**
  String get lowLatency;

  /// No description provided for @highThroughput.
  ///
  /// In en, this message translates to:
  /// **'High Speed'**
  String get highThroughput;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @setNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Set name cannot be duplicated'**
  String get setNameDuplicate;

  /// No description provided for @mutuallyExclusiveSetName.
  ///
  /// In en, this message translates to:
  /// **'Mutually Exclusive Set Name'**
  String get mutuallyExclusiveSetName;

  /// No description provided for @include.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get include;

  /// No description provided for @exclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get exclude;

  /// No description provided for @simple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simple;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @customDirect.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct'**
  String get customDirect;

  /// No description provided for @customProxy.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy'**
  String get customProxy;

  /// No description provided for @cnGames.
  ///
  /// In en, this message translates to:
  /// **'CN Games'**
  String get cnGames;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @gfwWithoutCustomDirect.
  ///
  /// In en, this message translates to:
  /// **'GFW (without custom direct)'**
  String get gfwWithoutCustomDirect;

  /// No description provided for @gfwModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get gfwModeProxyDomains;

  /// No description provided for @gfwModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy IPs'**
  String get gfwModeProxyIps;

  /// No description provided for @cnModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains'**
  String get cnModeProxyDomains;

  /// No description provided for @cnModeDirectDomains.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct Domains'**
  String get cnModeDirectDomains;

  /// No description provided for @cnModeDirectIps.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct IPs'**
  String get cnModeDirectIps;

  /// No description provided for @proxyAllModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains'**
  String get proxyAllModeProxyDomains;

  /// No description provided for @proxyAllModeDirectDomains.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct Domains'**
  String get proxyAllModeDirectDomains;

  /// No description provided for @proxyAllModeDirectIps.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct IPs'**
  String get proxyAllModeDirectIps;

  /// No description provided for @ruBlockModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get ruBlockModeProxyDomains;

  /// No description provided for @ruBlockModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy IPs'**
  String get ruBlockModeProxyIps;

  /// No description provided for @ruBlockAllModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get ruBlockAllModeProxyDomains;

  /// No description provided for @ruBlockAllModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy IPs'**
  String get ruBlockAllModeProxyIps;

  /// No description provided for @ipToDomain.
  ///
  /// In en, this message translates to:
  /// **'IP -> Domain'**
  String get ipToDomain;

  /// No description provided for @proFeatureDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a Pro feature. Upgrade to Pro to unlock all features'**
  String get proFeatureDescription;

  /// No description provided for @becomePermanentPro.
  ///
  /// In en, this message translates to:
  /// **'Become Permanent Pro User'**
  String get becomePermanentPro;

  /// No description provided for @becomePermanentProDescription.
  ///
  /// In en, this message translates to:
  /// **'Become permanent Pro user'**
  String get becomePermanentProDescription;

  /// No description provided for @tryPro.
  ///
  /// In en, this message translates to:
  /// **'Try Pro'**
  String get tryPro;

  /// No description provided for @newUserProTrial.
  ///
  /// In en, this message translates to:
  /// **'New users can try Pro for 7 days'**
  String get newUserProTrial;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cancelled'**
  String get purchaseCancelled;

  /// No description provided for @verifyingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Verifying Purchase...'**
  String get verifyingPurchase;

  /// No description provided for @purchaseVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify purchase: {reason}'**
  String purchaseVerificationFailed(String reason);

  /// No description provided for @ifYouHavePaid.
  ///
  /// In en, this message translates to:
  /// **'If you have paid, don\'t worry, your payment will be automatically refunded by the store. If you have any questions, please contact us. Order ID: {orderId}'**
  String ifYouHavePaid(String orderId);

  /// No description provided for @invalidPurchase.
  ///
  /// In en, this message translates to:
  /// **'Invalid Purchase'**
  String get invalidPurchase;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful'**
  String get purchaseSuccessful;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {status}'**
  String purchaseFailed(String status);

  /// No description provided for @unableToConnectToStore.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to store'**
  String get unableToConnectToStore;

  /// No description provided for @loginBeforePurchase.
  ///
  /// In en, this message translates to:
  /// **'Please login before purchasing. New users can try Pro for 7 days'**
  String get loginBeforePurchase;

  /// No description provided for @loginBeforeRestore.
  ///
  /// In en, this message translates to:
  /// **'Please login before restoring purchase.'**
  String get loginBeforeRestore;

  /// No description provided for @alternativePurchase.
  ///
  /// In en, this message translates to:
  /// **'If purchase fails, please try other platforms or official website.'**
  String get alternativePurchase;

  /// No description provided for @upgradeToPermanentPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPermanentPro;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @changePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change Period'**
  String get changePeriod;

  /// No description provided for @downgrade.
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get downgrade;

  /// No description provided for @caseInsensitive.
  ///
  /// In en, this message translates to:
  /// **'Case Insensitive'**
  String get caseInsensitive;

  /// No description provided for @startFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start'**
  String get startFailed;

  /// No description provided for @startFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {reason}'**
  String startFailedWithReason(String reason);

  /// No description provided for @startFailedReasonTunNeedAdmin.
  ///
  /// In en, this message translates to:
  /// **'Tun inbound is only available when running as administrator. Rerun UmiVPN as administrator or change inbound mode.'**
  String get startFailedReasonTunNeedAdmin;

  /// No description provided for @startFailedReasonNoNode.
  ///
  /// In en, this message translates to:
  /// **'No node'**
  String get startFailedReasonNoNode;

  /// No description provided for @startFailedReasonNoEnabledNode.
  ///
  /// In en, this message translates to:
  /// **'No enabled nodes, enable at least one node'**
  String get startFailedReasonNoEnabledNode;

  /// No description provided for @startFailedReasonNoSelected.
  ///
  /// In en, this message translates to:
  /// **'No selected node'**
  String get startFailedReasonNoSelected;

  /// No description provided for @failedToUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Failed to update subscription: {value}'**
  String failedToUpdateSub(String value);

  /// No description provided for @failedToAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to add subscription, there is an existing subscription with the same link'**
  String get failedToAddSubscription;

  /// No description provided for @tunNeedAdmin.
  ///
  /// In en, this message translates to:
  /// **'To use tun, rerun UmiVPN as administrator'**
  String get tunNeedAdmin;

  /// No description provided for @decodeResult.
  ///
  /// In en, this message translates to:
  /// **'Successfully got {value1} {value1, plural, =1{node} other{nodes}}, {value2} {value2, plural, =1{node failed} other{nodes failed}}'**
  String decodeResult(num value1, num value2);

  /// No description provided for @updateSubResult.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated {value1} {value1, plural, =1{subscription} other{subscriptions}}, {value2} {value2, plural, =1{subscription} other{subscriptions}} failed. {value3} {value3, plural, =1{node} other{nodes}} added, {value4} {value4, plural, =1{node} other{nodes}} failed to parse'**
  String updateSubResult(num value1, num value2, num value3, num value4);

  /// No description provided for @failedToUpdateCountry.
  ///
  /// In en, this message translates to:
  /// **'Failed to update areas'**
  String get failedToUpdateCountry;

  /// No description provided for @keepAlivePeriodMustBeBetween2And60.
  ///
  /// In en, this message translates to:
  /// **'Need to be between 2 and 60'**
  String get keepAlivePeriodMustBeBetween2And60;

  /// No description provided for @showApp.
  ///
  /// In en, this message translates to:
  /// **'Show App'**
  String get showApp;

  /// No description provided for @hideApp.
  ///
  /// In en, this message translates to:
  /// **'Hide App'**
  String get hideApp;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Show System Apps'**
  String get showSystemApps;

  /// No description provided for @hideSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Hide System Apps'**
  String get hideSystemApps;

  /// No description provided for @doubleTapToDelete.
  ///
  /// In en, this message translates to:
  /// **'Double tap to delete'**
  String get doubleTapToDelete;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @sshKeyPath.
  ///
  /// In en, this message translates to:
  /// **'SSH Key File Path'**
  String get sshKeyPath;

  /// No description provided for @useCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Use Added SSH Key'**
  String get useCommonSshKey;

  /// No description provided for @addCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Add SSH Key'**
  String get addCommonSshKey;

  /// No description provided for @sshKeyContentOrPathRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one of SSH Key Content or SSH Key File Path is required'**
  String get sshKeyContentOrPathRequired;

  /// No description provided for @failedToAddCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to add SSH key'**
  String get failedToAddCommonSshKey;

  /// No description provided for @failedToAddCommonSshKeyDueToDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'Failed to add SSH key because there is a key with the same name'**
  String get failedToAddCommonSshKeyDueToDuplicateName;

  /// No description provided for @quickDeploy.
  ///
  /// In en, this message translates to:
  /// **'Quick Deploy'**
  String get quickDeploy;

  /// No description provided for @deploy.
  ///
  /// In en, this message translates to:
  /// **'Deploy'**
  String get deploy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deploySuccess.
  ///
  /// In en, this message translates to:
  /// **'{deploy} on Server-{server} succeeded'**
  String deploySuccess(String deploy, String server);

  /// No description provided for @failedToDeploy.
  ///
  /// In en, this message translates to:
  /// **'Failed to deploy: {value}'**
  String failedToDeploy(String value);

  /// No description provided for @peerCertChainSHA256Hash.
  ///
  /// In en, this message translates to:
  /// **'SHA256'**
  String get peerCertChainSHA256Hash;

  /// No description provided for @serverCA.
  ///
  /// In en, this message translates to:
  /// **'Root CA'**
  String get serverCA;

  /// No description provided for @failedToInitGrpcClient.
  ///
  /// In en, this message translates to:
  /// **'Failed to init grpc client: {value}'**
  String failedToInitGrpcClient(String value);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @appKeyword.
  ///
  /// In en, this message translates to:
  /// **'App Keyword'**
  String get appKeyword;

  /// No description provided for @sniffDomain.
  ///
  /// In en, this message translates to:
  /// **'Sniff Domain'**
  String get sniffDomain;

  /// No description provided for @trafficStats.
  ///
  /// In en, this message translates to:
  /// **'Traffic Stats'**
  String get trafficStats;

  /// No description provided for @useSshKey.
  ///
  /// In en, this message translates to:
  /// **'Use SSH Key'**
  String get useSshKey;

  /// No description provided for @errorOnly.
  ///
  /// In en, this message translates to:
  /// **'Error Only'**
  String get errorOnly;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @failedToUndoBlockDns.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove the WFP filter for blocking dns traffic of primary NIC, please close this app which can remove the filter'**
  String get failedToUndoBlockDns;

  /// No description provided for @failedToRemoveSystemProxy.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove system proxy, please remove it mannually at Settings > System Proxy.'**
  String get failedToRemoveSystemProxy;

  /// No description provided for @failedToChangeNode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change node: {value}'**
  String failedToChangeNode(String value);

  /// No description provided for @failureDetail.
  ///
  /// In en, this message translates to:
  /// **'Failure detail'**
  String get failureDetail;

  /// No description provided for @failedNodes.
  ///
  /// In en, this message translates to:
  /// **'Failed nodes'**
  String get failedNodes;

  /// No description provided for @failedSub.
  ///
  /// In en, this message translates to:
  /// **'Failed subscriptions'**
  String get failedSub;

  /// No description provided for @addRemark.
  ///
  /// In en, this message translates to:
  /// **'Add a remark?'**
  String get addRemark;

  /// No description provided for @multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi Select'**
  String get multiSelect;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @quickAction.
  ///
  /// In en, this message translates to:
  /// **'Quick Action'**
  String get quickAction;

  /// No description provided for @deleteUnusable.
  ///
  /// In en, this message translates to:
  /// **'Delete Unusable Nodes'**
  String get deleteUnusable;

  /// No description provided for @smallScreenPreference.
  ///
  /// In en, this message translates to:
  /// **'Small Screen Preference'**
  String get smallScreenPreference;

  /// No description provided for @chainProxy.
  ///
  /// In en, this message translates to:
  /// **'Chain Proxy'**
  String get chainProxy;

  /// No description provided for @singleNode.
  ///
  /// In en, this message translates to:
  /// **'Single Node'**
  String get singleNode;

  /// No description provided for @multipleNodes.
  ///
  /// In en, this message translates to:
  /// **'Multiple Nodes'**
  String get multipleNodes;

  /// No description provided for @balanceStrategy.
  ///
  /// In en, this message translates to:
  /// **'Balance Strategy'**
  String get balanceStrategy;

  /// No description provided for @manualNodeMode.
  ///
  /// In en, this message translates to:
  /// **'Manual Mode'**
  String get manualNodeMode;

  /// No description provided for @outboundMode.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get outboundMode;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @balanceStrategyMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get balanceStrategyMemory;

  /// No description provided for @selectingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Select Strategy'**
  String get selectingStrategy;

  /// No description provided for @mostThroughput.
  ///
  /// In en, this message translates to:
  /// **'Speed Highest'**
  String get mostThroughput;

  /// No description provided for @allOk.
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get allOk;

  /// No description provided for @yourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your Devices'**
  String get yourDevices;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @addNewNode.
  ///
  /// In en, this message translates to:
  /// **'Add New Node'**
  String get addNewNode;

  /// No description provided for @useExistingNode.
  ///
  /// In en, this message translates to:
  /// **'Use Existing Node'**
  String get useExistingNode;

  /// No description provided for @atLeastTwoNodes.
  ///
  /// In en, this message translates to:
  /// **'At least two nodes are required'**
  String get atLeastTwoNodes;

  /// No description provided for @advancedMode.
  ///
  /// In en, this message translates to:
  /// **'Pro Mode'**
  String get advancedMode;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple Mode'**
  String get simpleMode;

  /// No description provided for @rule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get rule;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @selector.
  ///
  /// In en, this message translates to:
  /// **'Selector'**
  String get selector;

  /// No description provided for @atmoicDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Small Domain Set'**
  String get atmoicDomainSet;

  /// No description provided for @greatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Large Domain Set'**
  String get greatDomainSet;

  /// No description provided for @atmoicIpSet.
  ///
  /// In en, this message translates to:
  /// **'Small IP Set'**
  String get atmoicIpSet;

  /// No description provided for @greatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Large IP Set'**
  String get greatIpSet;

  /// No description provided for @createGreatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Create Great Domain Set'**
  String get createGreatDomainSet;

  /// No description provided for @editGreatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Great Domain Set'**
  String get editGreatDomainSet;

  /// No description provided for @createSmallDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Create Small Domain Set'**
  String get createSmallDomainSet;

  /// No description provided for @editSmallDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Small Domain Set'**
  String get editSmallDomainSet;

  /// No description provided for @editGreatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Great IP Set'**
  String get editGreatIpSet;

  /// No description provided for @createGreatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Create Great IP Set'**
  String get createGreatIpSet;

  /// No description provided for @editAppSet.
  ///
  /// In en, this message translates to:
  /// **'Edit App Set'**
  String get editAppSet;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @geoSiteOrGeoIPFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Downloading needed geo files...'**
  String get geoSiteOrGeoIPFileNotFound;

  /// No description provided for @createIpSmallSet.
  ///
  /// In en, this message translates to:
  /// **'Create IP Small Set'**
  String get createIpSmallSet;

  /// No description provided for @editIpSmallSet.
  ///
  /// In en, this message translates to:
  /// **'Edit IP Small Set'**
  String get editIpSmallSet;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @domainSetDescription.
  ///
  /// In en, this message translates to:
  /// **'The following domain set uses proxy DNS server (default 8.8.8.8 and 1.1.1.1) to resolve, other domains use direct DNS server (default is dns servers of your primary physical nic, or 223.5.5.5 and 114.114.114.114 if the former cannot be known) to resolve'**
  String get domainSetDescription;

  /// No description provided for @routerRuleDescription.
  ///
  /// In en, this message translates to:
  /// **'For each connection, rules are matched one by one from top to bottom, if a rule matches, the following rules will not be considered. If no rule matches, the connection will abort.'**
  String get routerRuleDescription;

  /// No description provided for @dstIpSet.
  ///
  /// In en, this message translates to:
  /// **'Destination IP Set'**
  String get dstIpSet;

  /// No description provided for @ruleNameUmiVPNTestNodes.
  ///
  /// In en, this message translates to:
  /// **'UmiVPN Node Testing'**
  String get ruleNameUmiVPNTestNodes;

  /// No description provided for @ruleNameInternalDnsProxyGoProxy.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS (CF)'**
  String get ruleNameInternalDnsProxyGoProxy;

  /// No description provided for @ruleNameInternalDnsDirectGoDirect.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS (Aliyun & CF)'**
  String get ruleNameInternalDnsDirectGoDirect;

  /// No description provided for @ruleNameProxyDnsServerGoProxy.
  ///
  /// In en, this message translates to:
  /// **'Default Proxy DNS Server'**
  String get ruleNameProxyDnsServerGoProxy;

  /// No description provided for @ruleNameDirectDnsServerGoDirect.
  ///
  /// In en, this message translates to:
  /// **'Default Direct DNS Server'**
  String get ruleNameDirectDnsServerGoDirect;

  /// No description provided for @ruleNameDnsHijack.
  ///
  /// In en, this message translates to:
  /// **'DNS Hijack: Non-Direct Domain'**
  String get ruleNameDnsHijack;

  /// No description provided for @ruleNameCustomDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct Domain'**
  String get ruleNameCustomDirectDomain;

  /// No description provided for @ruleNameCustomDirectIp.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct IP'**
  String get ruleNameCustomDirectIp;

  /// No description provided for @ruleNameCustomProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy Domain'**
  String get ruleNameCustomProxyDomain;

  /// No description provided for @ruleNameCustomProxyIp.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy IP'**
  String get ruleNameCustomProxyIp;

  /// No description provided for @ruleNameProxyApp.
  ///
  /// In en, this message translates to:
  /// **'Proxy App'**
  String get ruleNameProxyApp;

  /// No description provided for @ruleNameDirectApp.
  ///
  /// In en, this message translates to:
  /// **'Direct App'**
  String get ruleNameDirectApp;

  /// No description provided for @ruleNameCnDirectIp.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct IPs'**
  String get ruleNameCnDirectIp;

  /// No description provided for @ruleNameDefaultProxy.
  ///
  /// In en, this message translates to:
  /// **'Default Proxy'**
  String get ruleNameDefaultProxy;

  /// No description provided for @ruleNameCnDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct Domains'**
  String get ruleNameCnDirectDomain;

  /// No description provided for @ruleNameGfwProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get ruleNameGfwProxyDomain;

  /// No description provided for @ruleNameGfwProxyIp.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy IPs'**
  String get ruleNameGfwProxyIp;

  /// No description provided for @ruleNameRuBlockProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get ruleNameRuBlockProxyDomain;

  /// No description provided for @ruleNameRuBlockProxyIp.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy IPs'**
  String get ruleNameRuBlockProxyIp;

  /// No description provided for @ruleNameRuBlockAllProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get ruleNameRuBlockAllProxyDomain;

  /// No description provided for @ruleNameRuBlockAllProxyIp.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy IPs'**
  String get ruleNameRuBlockAllProxyIp;

  /// No description provided for @ruleNameDefaultDirect.
  ///
  /// In en, this message translates to:
  /// **'Default Direct'**
  String get ruleNameDefaultDirect;

  /// No description provided for @ruleNameGlobalDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct Domains'**
  String get ruleNameGlobalDirectDomain;

  /// No description provided for @ruleNameGlobalDirectIp.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct IPs'**
  String get ruleNameGlobalDirectIp;

  /// No description provided for @addAppSet.
  ///
  /// In en, this message translates to:
  /// **'Add App Set'**
  String get addAppSet;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Pro Account'**
  String get pro;

  /// No description provided for @proxyShare.
  ///
  /// In en, this message translates to:
  /// **'Proxy Share'**
  String get proxyShare;

  /// No description provided for @sniff.
  ///
  /// In en, this message translates to:
  /// **'Sniff'**
  String get sniff;

  /// No description provided for @proxyShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTP and SOCKS inbound after VPN starts, so that other devices in the local network can access the internet through this machine. The inbound name is \"proxyShare\", which you can use in rules.'**
  String get proxyShareDesc;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login Success'**
  String get loginSuccess;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Login by Email'**
  String get emailLogin;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @microsoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get microsoft;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate UmiVPN'**
  String get rateApp;

  /// No description provided for @userConsend.
  ///
  /// In en, this message translates to:
  /// **'Once you login, your email will be stored in our server until you delete your account. This is neccessary for providing account login. We do not share your email with any third party. Do you allow us to store your email?'**
  String get userConsend;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @disagree.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get disagree;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @greatSetDescription1.
  ///
  /// In en, this message translates to:
  /// **'A large set is composed of small sets or other large sets. When telling whether a domain/IP is in the set, the exluded sets will be considered first, if the domain is in any of the excluded set, then the domain is not in the set. '**
  String get greatSetDescription1;

  /// No description provided for @greatSetDescription2.
  ///
  /// In en, this message translates to:
  /// **'A large set can have a mutually exclusive set. If a domain/IP is in set A, then the domain/IP is not in it\'s mutually exclusive set.'**
  String get greatSetDescription2;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @failedToDownloadGeoData.
  ///
  /// In en, this message translates to:
  /// **'Failed to download GeoData: {value}'**
  String failedToDownloadGeoData(String value);

  /// No description provided for @doNotUse1080IOS.
  ///
  /// In en, this message translates to:
  /// **'Do not use 1080 on iOS'**
  String get doNotUse1080IOS;

  /// No description provided for @deletedNode.
  ///
  /// In en, this message translates to:
  /// **'Deleted Node'**
  String get deletedNode;

  /// No description provided for @selectorContainsDeletedLandHandler.
  ///
  /// In en, this message translates to:
  /// **'Selector {value} uses a deleted node as landing node, please remove it and retry'**
  String selectorContainsDeletedLandHandler(String value);

  /// No description provided for @tunIpv6Settings.
  ///
  /// In en, this message translates to:
  /// **'TUN IP Settings'**
  String get tunIpv6Settings;

  /// No description provided for @alwaysEnableIpv6.
  ///
  /// In en, this message translates to:
  /// **'Always Enable IPv6'**
  String get alwaysEnableIpv6;

  /// No description provided for @dependsOnDefaultNic.
  ///
  /// In en, this message translates to:
  /// **'Depends on Default Physical NIC'**
  String get dependsOnDefaultNic;

  /// No description provided for @dependsOnDefaultNicDesc.
  ///
  /// In en, this message translates to:
  /// **'If the default physical NIC supports IPv6, then the TUN NIC will also support IPv6, otherwise IPv6 is not supported'**
  String get dependsOnDefaultNicDesc;

  /// No description provided for @failedToCreateAllFirstLaunch.
  ///
  /// In en, this message translates to:
  /// **'Failed to create database tables: {value}'**
  String failedToCreateAllFirstLaunch(String value);

  /// No description provided for @failedToInsertDefaultData.
  ///
  /// In en, this message translates to:
  /// **'Failed to insert default data into database: {value}'**
  String failedToInsertDefaultData(String value);

  /// No description provided for @newVersionDownloadedDialog.
  ///
  /// In en, this message translates to:
  /// **'New version {version} downloaded, install it?'**
  String newVersionDownloadedDialog(String version);

  /// No description provided for @skipThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get skipThisVersion;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get later;

  /// No description provided for @autoUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically downloading new version and notify you when it\'s ready'**
  String get autoUpdateDescription;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}...'**
  String downloading(String version);

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update, reason: {reason}'**
  String installFailed(String reason);

  /// No description provided for @tun46SettingIpv4Only.
  ///
  /// In en, this message translates to:
  /// **'IPv4 Only'**
  String get tun46SettingIpv4Only;

  /// No description provided for @tun46SettingIpv4AndIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv4 and IPv6'**
  String get tun46SettingIpv4AndIpv6;

  /// No description provided for @ad.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ad;

  /// No description provided for @advancedSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'VPN related settings'**
  String get advancedSettingDesc;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @gfwDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs of GFW go proxy, others go direct'**
  String get gfwDesc;

  /// No description provided for @cnDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs of China mainland go direct, others go proxy'**
  String get cnDesc;

  /// No description provided for @proxyAllDesc.
  ///
  /// In en, this message translates to:
  /// **'All non-private domains/IPs go proxy'**
  String get proxyAllDesc;

  /// No description provided for @dnsRule.
  ///
  /// In en, this message translates to:
  /// **'DNS Rules'**
  String get dnsRule;

  /// No description provided for @dnsRuleNameGfwProxyFake.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameGfwProxyFake;

  /// No description provided for @dnsRuleNameGfwProxy.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get dnsRuleNameGfwProxy;

  /// No description provided for @dnsRuleNameRuBlockProxyFake.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameRuBlockProxyFake;

  /// No description provided for @dnsRuleNameRuBlockProxy.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get dnsRuleNameRuBlockProxy;

  /// No description provided for @dnsRuleNameRuBlockAllProxyFake.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameRuBlockAllProxyFake;

  /// No description provided for @dnsRuleNameRuBlockAllProxy.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get dnsRuleNameRuBlockAllProxy;

  /// No description provided for @dnsRuleNameCnProxyFake.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameCnProxyFake;

  /// No description provided for @dnsRuleNameCnProxy.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains'**
  String get dnsRuleNameCnProxy;

  /// No description provided for @dnsRuleNameProxyAllProxyFake.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameProxyAllProxyFake;

  /// No description provided for @dnsRuleNameProxyAllProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains'**
  String get dnsRuleNameProxyAllProxy;

  /// No description provided for @dnsRuleNameDefaultDirect.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get dnsRuleNameDefaultDirect;

  /// No description provided for @routerRules.
  ///
  /// In en, this message translates to:
  /// **'Router Rules'**
  String get routerRules;

  /// No description provided for @dnsRuleDesc.
  ///
  /// In en, this message translates to:
  /// **'For each DNS request, rules are matched one by one starting from the top. If a rule matches, the following rule will not be considered. The dns server specified by the rule will be used to handle the dns query'**
  String get dnsRuleDesc;

  /// No description provided for @dnsServer.
  ///
  /// In en, this message translates to:
  /// **'DNS Server'**
  String get dnsServer;

  /// No description provided for @howDnsRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'When all conditions match or there is no condition enabled, a dns rule matches.'**
  String get howDnsRuleMatch;

  /// No description provided for @selectAtleastOneDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Select at least one dns server'**
  String get selectAtleastOneDnsServer;

  /// No description provided for @dnsType.
  ///
  /// In en, this message translates to:
  /// **'DNS Type'**
  String get dnsType;

  /// No description provided for @directDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Direct DNS Server'**
  String get directDnsServer;

  /// No description provided for @proxyDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Proxy DNS Server'**
  String get proxyDnsServer;

  /// No description provided for @addDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Add DNS Server'**
  String get addDnsServer;

  /// No description provided for @useDefaultDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Use DNS servers of default NIC. If unable to get the servers, fallback to use the above servers.'**
  String get useDefaultDnsServer;

  /// No description provided for @useDefaultNicDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Use DNS servers of default NIC. If unable to get the servers, use the following:'**
  String get useDefaultNicDnsServer;

  /// No description provided for @addDnsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple addresses supported. Use comma to seperate. Each dns query will be sent to all addresses simultaneouly, the first reply will be used.'**
  String get addDnsAddressHint;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @duplicateDnsServerName.
  ///
  /// In en, this message translates to:
  /// **'Duplicate DNS server name'**
  String get duplicateDnsServerName;

  /// No description provided for @dnsTypeConditionDesc.
  ///
  /// In en, this message translates to:
  /// **'If checked, then this condition is enabled. The condition is true only when the type of a dns query is in the selected type.'**
  String get dnsTypeConditionDesc;

  /// No description provided for @enabledConditions.
  ///
  /// In en, this message translates to:
  /// **'Enabled conditions: {number}'**
  String enabledConditions(num number);

  /// No description provided for @showSelector.
  ///
  /// In en, this message translates to:
  /// **'Show Selector'**
  String get showSelector;

  /// No description provided for @hideSelector.
  ///
  /// In en, this message translates to:
  /// **'Hide Selector'**
  String get hideSelector;

  /// No description provided for @showHandler.
  ///
  /// In en, this message translates to:
  /// **'Show Handler'**
  String get showHandler;

  /// No description provided for @hideHandler.
  ///
  /// In en, this message translates to:
  /// **'Hide Selector'**
  String get hideHandler;

  /// No description provided for @restoreIAP.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restoreIAP;

  /// No description provided for @debugLog.
  ///
  /// In en, this message translates to:
  /// **'Debug Log'**
  String get debugLog;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @saveToDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to Download'**
  String get saveToDownloadFolder;

  /// No description provided for @saveToDownloadFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Move the logs to your Download folder'**
  String get saveToDownloadFolderDesc;

  /// No description provided for @debugLogDesc.
  ///
  /// In en, this message translates to:
  /// **'If you encountered any problem during using UmiVPN, you can enable the button, and wait until the problem occur again, then click upload to upload the logs to us, rememeber to close it and delete the logsafter uploading.  Developer logs are not uploaded automatically since they contain your network activities, including the websites and apps you use. We delete the logs immediately once we process them.'**
  String get debugLogDesc;

  /// No description provided for @clashFormatSupported.
  ///
  /// In en, this message translates to:
  /// **'Only Clash Rule files are supported'**
  String get clashFormatSupported;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @fallbackToProxy.
  ///
  /// In en, this message translates to:
  /// **'Fallback To Proxy'**
  String get fallbackToProxy;

  /// No description provided for @fallbackToProxySetting.
  ///
  /// In en, this message translates to:
  /// **'When a direct connection failed, fallback to use proxy. The node selected by the \"Proxy\" selector will be used, if the selector does not exist, a random nodes will be selected'**
  String get fallbackToProxySetting;

  /// No description provided for @installAsWinService.
  ///
  /// In en, this message translates to:
  /// **'Add UmiVPN to Windows Service'**
  String get installAsWinService;

  /// No description provided for @installAsWinServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Before use TUN, UmiVPN needs to be added into Windows Service. Click Yes to install UmiVPN as a service, which would require you to give permission in the following UAC prompt window.'**
  String get installAsWinServiceDesc;

  /// No description provided for @placeOnTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get placeOnTop;

  /// No description provided for @stopPlaceOnTop.
  ///
  /// In en, this message translates to:
  /// **'Untop'**
  String get stopPlaceOnTop;

  /// No description provided for @fallbackTo.
  ///
  /// In en, this message translates to:
  /// **'Fallback to {node}'**
  String fallbackTo(String node);

  /// No description provided for @pingTestMethod.
  ///
  /// In en, this message translates to:
  /// **'Latency Test Method'**
  String get pingTestMethod;

  /// No description provided for @pingReal.
  ///
  /// In en, this message translates to:
  /// **'Real Latency'**
  String get pingReal;

  /// No description provided for @pingRealDesc.
  ///
  /// In en, this message translates to:
  /// **'Time used to retrieve a result'**
  String get pingRealDesc;

  /// No description provided for @startOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start on Boot'**
  String get startOnBoot;

  /// No description provided for @startOnBootDesc.
  ///
  /// In en, this message translates to:
  /// **'Start UmiVPN automatically at startup'**
  String get startOnBootDesc;

  /// No description provided for @alwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always ON'**
  String get alwaysOn;

  /// No description provided for @alwaysOnDesc.
  ///
  /// In en, this message translates to:
  /// **'As long as you did not click disconnect, always try to be connected when the app is running'**
  String get alwaysOnDesc;

  /// No description provided for @checkAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check and Update'**
  String get checkAndUpdate;

  /// No description provided for @noNewVersion.
  ///
  /// In en, this message translates to:
  /// **'No new versions'**
  String get noNewVersion;

  /// No description provided for @enableSystemExtension.
  ///
  /// In en, this message translates to:
  /// **'Please enable UmiVPN SystemExtension by going to System Settings -> General -> Login Items & Extensions -> Network Extensions'**
  String get enableSystemExtension;

  /// No description provided for @systemProxyPortSetting.
  ///
  /// In en, this message translates to:
  /// **'System Proxy Port Setting'**
  String get systemProxyPortSetting;

  /// No description provided for @randomPorts.
  ///
  /// In en, this message translates to:
  /// **'Random Ports'**
  String get randomPorts;

  /// No description provided for @staticPorts.
  ///
  /// In en, this message translates to:
  /// **'Static Ports'**
  String get staticPorts;

  /// No description provided for @whenNoDomain.
  ///
  /// In en, this message translates to:
  /// **'Sniff When No Domain Info'**
  String get whenNoDomain;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check Update'**
  String get checkUpdate;

  /// No description provided for @handlerCopiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Copy succeeded. The node has been added to the Default group'**
  String get handlerCopiedSuccess;

  /// No description provided for @hysteriaRejectQuic.
  ///
  /// In en, this message translates to:
  /// **'Hysteria Reject QUIC'**
  String get hysteriaRejectQuic;

  /// No description provided for @syncBackup.
  ///
  /// In en, this message translates to:
  /// **'Sync & Backup'**
  String get syncBackup;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncDesc1.
  ///
  /// In en, this message translates to:
  /// **'Sync your database between multiple devices. '**
  String get cloudSyncDesc1;

  /// No description provided for @cloudSyncDesc2.
  ///
  /// In en, this message translates to:
  /// **'For Android devices with Google Services installed and Apple devices that can communicate with Google FCM servers, sync are real-time. Otherwise, sync will happen every 5 minutes.'**
  String get cloudSyncDesc2;

  /// No description provided for @cloudSyncDesc3.
  ///
  /// In en, this message translates to:
  /// **'The sync data will be automatically cleared from the cloud after your device have fetched them. If your device has not fetched them for 7 days, the data will deleted from the cloud.'**
  String get cloudSyncDesc3;

  /// No description provided for @nodeSub.
  ///
  /// In en, this message translates to:
  /// **'Node/Subscription'**
  String get nodeSub;

  /// No description provided for @routeSetDNSSelector.
  ///
  /// In en, this message translates to:
  /// **'Rule/Set/Selector/DNS'**
  String get routeSetDNSSelector;

  /// No description provided for @selectorSetting.
  ///
  /// In en, this message translates to:
  /// **'Selector Settings'**
  String get selectorSetting;

  /// No description provided for @serverKey.
  ///
  /// In en, this message translates to:
  /// **'Server/Key'**
  String get serverKey;

  /// No description provided for @lanSync.
  ///
  /// In en, this message translates to:
  /// **'LAN Sync'**
  String get lanSync;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @conditaionWarn1.
  ///
  /// In en, this message translates to:
  /// **'In most cases, domain conditions and IP conditions should not exist at the same time. When they both exist, the rule will only match when the request has both domain and IP information, which is not always the case.'**
  String get conditaionWarn1;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set Name'**
  String get setName;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @domainIpAppConditionDesc.
  ///
  /// In en, this message translates to:
  /// **'When a request\'s domain/IP/App is in any of the sets, the rule matches.'**
  String get domainIpAppConditionDesc;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Database Backup'**
  String get backup;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup database to cloud once a day.'**
  String get autoBackupDesc;

  /// No description provided for @currentBackup.
  ///
  /// In en, this message translates to:
  /// **'Current Backup'**
  String get currentBackup;

  /// No description provided for @uploadDb.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadDb;

  /// No description provided for @restoreDb.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreDb;

  /// No description provided for @deleteCloudDb.
  ///
  /// In en, this message translates to:
  /// **'Delete database in cloud'**
  String get deleteCloudDb;

  /// No description provided for @uploadDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload database successfully'**
  String get uploadDbSuccess;

  /// No description provided for @restoreDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore database successfully'**
  String get restoreDbSuccess;

  /// No description provided for @deleteDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete successfully'**
  String get deleteDbSuccess;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @fallbackRetryDomain.
  ///
  /// In en, this message translates to:
  /// **'Retry Domain'**
  String get fallbackRetryDomain;

  /// No description provided for @fallbackRetryDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'If a proxy connection uses ip targets and failed due to i/o timeout(this might due to DNS pollution), use domain as target and retry. The sniffed domain of the connection will be used first, if it is unavailable, the ip-to-domain domain will be used.'**
  String get fallbackRetryDomainDesc;

  /// No description provided for @backupPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to encrypt database. Only devices with this password can restore backups. The password is encrypted and stored locally.'**
  String get backupPasswordDesc;

  /// No description provided for @syncPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to encrypt sync data. Only devices with this password can sync data successfully. The password is encrypted and stored locally.'**
  String get syncPasswordDesc;

  /// No description provided for @addDomainIpAppSet.
  ///
  /// In en, this message translates to:
  /// **'Add Domain/App/IP Set'**
  String get addDomainIpAppSet;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsaved;

  /// No description provided for @rememberPasswordInMemory.
  ///
  /// In en, this message translates to:
  /// **'Remember sudo password in memory for later use'**
  String get rememberPasswordInMemory;

  /// No description provided for @doNotShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show again'**
  String get doNotShowAgain;

  /// No description provided for @rpmTunNotice.
  ///
  /// In en, this message translates to:
  /// **'When TUN is on, Reverse Path Forwarding mode will be set to Loose(2) and reset to what it was when disconnect. You can go to the following website to learn about Reverse Path Forwarding'**
  String get rpmTunNotice;

  /// No description provided for @internalDnsDesc.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS servers are used to resolve domains when outbounds are dialing. There are two of them, one is internal-dns-proxy, which uses the Proxy selector to connect to 1.1.1.1; the other is internal-dns-direct, which uses directly connect to 223.5.5.5 and 1.1.1.1. The internal-dns-direct is used first, if it failed, the internal-dns-proxy will be used.'**
  String get internalDnsDesc;

  /// No description provided for @nodeSetDesc.
  ///
  /// In en, this message translates to:
  /// **'There is a small domain set named \"__node__\" which contains domains and SNIs of all nodes. There is also a small IP set named \"__node__\" which contains IPs of all nodes.'**
  String get nodeSetDesc;

  /// No description provided for @dnsNameDesc.
  ///
  /// In en, this message translates to:
  /// **'A DNS server\'s name can be referenced in the inbound condition to specify which node it uses.'**
  String get dnsNameDesc;

  /// No description provided for @directAppSetDesc.
  ///
  /// In en, this message translates to:
  /// **'On Android, applications in the direct app set will not go through UmiVPN (Split Tunnel)'**
  String get directAppSetDesc;

  /// No description provided for @deleteDebugLogs.
  ///
  /// In en, this message translates to:
  /// **'Delete Debug Logs'**
  String get deleteDebugLogs;

  /// No description provided for @conditionDesc.
  ///
  /// In en, this message translates to:
  /// **'When a connection does not have IP info, IP condition will be false and the rule will not match. Similarly, when a connection does not have domain info, domain condition will be false and the rule will not match.'**
  String get conditionDesc;

  /// No description provided for @lookupEch.
  ///
  /// In en, this message translates to:
  /// **'Lookup ECH'**
  String get lookupEch;

  /// No description provided for @lookupEchDesc.
  ///
  /// In en, this message translates to:
  /// **'If enabled and above ECH Config is empty, ECH config will be looked up from DNS server. If lookup success, use ECH, otherwise do not use ECH.'**
  String get lookupEchDesc;

  /// No description provided for @adWanted.
  ///
  /// In en, this message translates to:
  /// **'Publish Ads'**
  String get adWanted;

  /// No description provided for @basicQuickDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Two cores, four protocols'**
  String get basicQuickDeployTitle;

  /// No description provided for @basicQuickDeploySummary.
  ///
  /// In en, this message translates to:
  /// **'Deploy Xray, Hysteria cores and set nodes with four common protocols'**
  String get basicQuickDeploySummary;

  /// No description provided for @basicQuickDeployDetails.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core and Hysteria, and deploy the following four inbound. If the server has already installed Xray or Hysteria, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get basicQuickDeployDetails;

  /// No description provided for @basicQuickDeployContent1.
  ///
  /// In en, this message translates to:
  /// **'Vmess five random ports'**
  String get basicQuickDeployContent1;

  /// No description provided for @basicQuickDeployContent2.
  ///
  /// In en, this message translates to:
  /// **'Shadowsocks five random ports'**
  String get basicQuickDeployContent2;

  /// No description provided for @basicQuickDeployContent3.
  ///
  /// In en, this message translates to:
  /// **'Hysteria 443 port'**
  String get basicQuickDeployContent3;

  /// No description provided for @basicQuickDeployContent4.
  ///
  /// In en, this message translates to:
  /// **'Vless-XTLS-Vision 443 port'**
  String get basicQuickDeployContent4;

  /// No description provided for @masqueradeQuickDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Reality/XHTTP'**
  String get masqueradeQuickDeployTitle;

  /// No description provided for @masqueradeQuickDeploySummary.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core and deploy Reality/XHTTP inbound. If the server has already installed Xray, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get masqueradeQuickDeploySummary;

  /// No description provided for @masqueradeQuickDeployDetails.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core, and deploy Reality/XHTTP inbound. If the server has already installed Xray, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get masqueradeQuickDeployDetails;

  /// No description provided for @fatalError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please restart UmiVPN. Error: {error}'**
  String fatalError(String error);

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @selectAtleastOneSelector.
  ///
  /// In en, this message translates to:
  /// **'Select at least one selector'**
  String get selectAtleastOneSelector;

  /// No description provided for @addRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Add Route Mode'**
  String get addRouteMode;

  /// No description provided for @setNameProxyApp.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get setNameProxyApp;

  /// No description provided for @setNameDirectApp.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get setNameDirectApp;

  /// No description provided for @defaultSelectorTag.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get defaultSelectorTag;

  /// No description provided for @selectAtleastOneNode.
  ///
  /// In en, this message translates to:
  /// **'Select at least one node'**
  String get selectAtleastOneNode;

  /// No description provided for @insertDefaultError.
  ///
  /// In en, this message translates to:
  /// **'Failed to insert default data, please restart UmiVPN and add them in the routing page. Reason: {error}'**
  String insertDefaultError(String error);

  /// No description provided for @pleaseSelectARoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Please select a routing mode'**
  String get pleaseSelectARoutingMode;

  /// No description provided for @addRouteModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Clicking the + button to add a routing mode.'**
  String get addRouteModeNotice;

  /// No description provided for @freeUserCannotUseCustomRoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Free users cannot use custom routing modes. Please select a default routing mode. You can add default routing modes in the routing page.'**
  String get freeUserCannotUseCustomRoutingMode;

  /// No description provided for @defaultRouteModes.
  ///
  /// In en, this message translates to:
  /// **'Default modes'**
  String get defaultRouteModes;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @geositeUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'If empty, the geosite.dat provided by LoyalSoldier will be used'**
  String get geositeUrlDesc;

  /// No description provided for @geoUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'If empty, the geoip.dat provided by LoyalSoldier will be used'**
  String get geoUrlDesc;

  /// No description provided for @ruBlocked.
  ///
  /// In en, this message translates to:
  /// **'Russia Blocked'**
  String get ruBlocked;

  /// No description provided for @ruBlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Domains/IPs blocked in Russia go proxy, others go direct'**
  String get ruBlockedDesc;

  /// No description provided for @ruBlockedAll.
  ///
  /// In en, this message translates to:
  /// **'Russia Blocked(All)'**
  String get ruBlockedAll;

  /// No description provided for @ruBlockedAllDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs known to be blocked in Russia go proxy, others go direct'**
  String get ruBlockedAllDesc;

  /// No description provided for @dnsServerProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy DNS Server'**
  String get dnsServerProxy;

  /// No description provided for @dnsServerDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct DNS Server'**
  String get dnsServerDirect;

  /// No description provided for @sniffDomainForIpConnection.
  ///
  /// In en, this message translates to:
  /// **'If a connection use IP target, sniff domain'**
  String get sniffDomainForIpConnection;

  /// No description provided for @resolveDomain.
  ///
  /// In en, this message translates to:
  /// **'For connections using domain targets, use DNS to resolve IPs. When each resolved IP make the IP condition true, the condition is true'**
  String get resolveDomain;

  /// No description provided for @skipSniff.
  ///
  /// In en, this message translates to:
  /// **'No Sniff'**
  String get skipSniff;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resovle'**
  String get resolve;

  /// No description provided for @skipResolve.
  ///
  /// In en, this message translates to:
  /// **'No Resolve'**
  String get skipResolve;

  /// No description provided for @describeTheProblem.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem you encountered, if you have already contacted customer service, you can leave it blank'**
  String get describeTheProblem;

  /// No description provided for @debugLogNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Developer log function is not available in non-store version'**
  String get debugLogNotAvailable;

  /// No description provided for @useBloomFilter.
  ///
  /// In en, this message translates to:
  /// **'Use Bloom Filter in iOS'**
  String get useBloomFilter;

  /// No description provided for @useBloomFilterDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloom Filter can reduce memory usage, however, there is a small chance (1%) of false positives: domains not in the set might be misclassified as in the set.'**
  String get useBloomFilterDesc;

  /// No description provided for @addFromClashRuleFiles.
  ///
  /// In en, this message translates to:
  /// **'Add from Clash Rule Files'**
  String get addFromClashRuleFiles;

  /// No description provided for @selectFromInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Select from Installed Apps'**
  String get selectFromInstalledApps;

  /// No description provided for @ipToDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'IP -> Domain is got from the recent DNS history. Because many domains can be resolved to the same IP, it might not be the actual domain. Therefore, the connection is likely to have the domain, but not guaranteed.'**
  String get ipToDomainDesc;

  /// No description provided for @followingAiTranslated.
  ///
  /// In en, this message translates to:
  /// **'The following languages are translated by AI, which may not be accurate.'**
  String get followingAiTranslated;

  /// No description provided for @addToDefault.
  ///
  /// In en, this message translates to:
  /// **'Add to Default'**
  String get addToDefault;

  /// No description provided for @managePlan.
  ///
  /// In en, this message translates to:
  /// **'Manage Plan'**
  String get managePlan;

  /// No description provided for @managePlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Upgrade, downgrade or cancel subscription'**
  String get managePlanDesc;

  /// No description provided for @availablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get availablePlans;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @dontCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Cancel Subscription'**
  String get dontCancelSubscription;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @noTokenFound.
  ///
  /// In en, this message translates to:
  /// **'No token found'**
  String get noTokenFound;

  /// No description provided for @subscriptionReactivated.
  ///
  /// In en, this message translates to:
  /// **'Subscription reactivated'**
  String get subscriptionReactivated;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @couldNotOpenCustomerPortal.
  ///
  /// In en, this message translates to:
  /// **'Could not open customer portal'**
  String get couldNotOpenCustomerPortal;

  /// No description provided for @noPortalUrlReceived.
  ///
  /// In en, this message translates to:
  /// **'No portal URL received'**
  String get noPortalUrlReceived;

  /// No description provided for @failedToOpenCustomerPortal.
  ///
  /// In en, this message translates to:
  /// **'Failed to open customer portal: {errorMessage}'**
  String failedToOpenCustomerPortal(String errorMessage);

  /// No description provided for @couldNotOpenPlayStoreSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Could not open Play Store subscriptions'**
  String get couldNotOpenPlayStoreSubscriptions;

  /// No description provided for @couldNotOpenAppStoreSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Could not open subscription management. Please go to Settings > [Your Name] > Subscriptions to manage your subscription.'**
  String get couldNotOpenAppStoreSubscriptions;

  /// No description provided for @cannotDeleteAccountWithActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your account while you have an active subscription. Please cancel your subscription first.'**
  String get cannotDeleteAccountWithActiveSubscription;

  /// No description provided for @visitOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit Official Website'**
  String get visitOfficialWebsite;

  /// No description provided for @noPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlansAvailable;

  /// No description provided for @noPricingOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No pricing options available for this plan'**
  String get noPricingOptionsAvailable;

  /// No description provided for @priceIdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Price ID not available for this plan'**
  String get priceIdNotAvailable;

  /// No description provided for @noAuthenticationTokenFound.
  ///
  /// In en, this message translates to:
  /// **'No authentication token found'**
  String get noAuthenticationTokenFound;

  /// No description provided for @couldNotOpenCheckoutUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open checkout URL'**
  String get couldNotOpenCheckoutUrl;

  /// No description provided for @noCheckoutUrlReceived.
  ///
  /// In en, this message translates to:
  /// **'No checkout URL received'**
  String get noCheckoutUrlReceived;

  /// No description provided for @failedToCreateCheckoutSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to create checkout session: {errorMessage}'**
  String failedToCreateCheckoutSession(String errorMessage);

  /// No description provided for @monthlyTraffic.
  ///
  /// In en, this message translates to:
  /// **'Monthly Traffic'**
  String get monthlyTraffic;

  /// No description provided for @unlimitedData.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Data'**
  String get unlimitedData;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get currentLocation;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(num count);

  /// No description provided for @areYouSureReactivate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reactivate?'**
  String get areYouSureReactivate;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @dataRefresh.
  ///
  /// In en, this message translates to:
  /// **'Data Refresh'**
  String get dataRefresh;

  /// No description provided for @renewalDate.
  ///
  /// In en, this message translates to:
  /// **'Renewal Date'**
  String get renewalDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @selectBillingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Billing Period'**
  String get selectBillingPeriod;

  /// No description provided for @activeSubscriptionFound.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription Found'**
  String get activeSubscriptionFound;

  /// No description provided for @activeSubscriptionFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'You already have an active subscription from other source. Please cancel that subscription before subscribing to this plan. If you cancel that subscription and subscribe to this plan, benefits of the old subscription will be lost.'**
  String get activeSubscriptionFoundMessage;

  /// No description provided for @warningExistingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Warning: Existing Subscription'**
  String get warningExistingSubscription;

  /// No description provided for @warningExistingSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'You currently have a canceled subscription that has not ended yet. Subscribing to a new plan now will cause you to lose the benefits of your existing subscription, even though it has not ended.'**
  String get warningExistingSubscriptionMessage;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in before purchasing a subscription.'**
  String get loginRequiredMessage;

  /// No description provided for @failedToLoadPlans.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plans'**
  String get failedToLoadPlans;

  /// No description provided for @failedToLoadPlansMessage.
  ///
  /// In en, this message translates to:
  /// **'Please visit our website to view available plans.'**
  String get failedToLoadPlansMessage;

  /// No description provided for @copyDatabase.
  ///
  /// In en, this message translates to:
  /// **'Copy Database'**
  String get copyDatabase;

  /// No description provided for @fromClipboard.
  ///
  /// In en, this message translates to:
  /// **'From Clipboard'**
  String get fromClipboard;

  /// No description provided for @selectQrCode.
  ///
  /// In en, this message translates to:
  /// **'Select QR Code'**
  String get selectQrCode;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'Youtube'**
  String get youtube;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @perQuarter.
  ///
  /// In en, this message translates to:
  /// **'per quarter'**
  String get perQuarter;

  /// No description provided for @perHalfYear.
  ///
  /// In en, this message translates to:
  /// **'per half year'**
  String get perHalfYear;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYear;

  /// No description provided for @willRenewTo.
  ///
  /// In en, this message translates to:
  /// **'When renew, plan will change to {plan} ({period})'**
  String willRenewTo(String plan, String period);

  /// No description provided for @securelyConnected.
  ///
  /// In en, this message translates to:
  /// **'SECURELY CONNECTED'**
  String get securelyConnected;

  /// No description provided for @versionTooOld.
  ///
  /// In en, this message translates to:
  /// **'Version Too Old'**
  String get versionTooOld;

  /// No description provided for @versionTooOldMessage.
  ///
  /// In en, this message translates to:
  /// **'Your app version is too old. Please upgrade to the latest version to continue.'**
  String get versionTooOldMessage;

  /// No description provided for @noServers.
  ///
  /// In en, this message translates to:
  /// **'No Servers'**
  String get noServers;

  /// No description provided for @noServersMessage.
  ///
  /// In en, this message translates to:
  /// **'Sorry, no server matching your choice is available now. Please try again later.'**
  String get noServersMessage;

  /// No description provided for @selectRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Select Route Mode'**
  String get selectRouteMode;

  /// No description provided for @welcomeToUmiVPN.
  ///
  /// In en, this message translates to:
  /// **'Welcome to UmiVPN!'**
  String get welcomeToUmiVPN;

  /// No description provided for @umivpnIsFreeToUse.
  ///
  /// In en, this message translates to:
  /// **'UmiVPN is free to use'**
  String get umivpnIsFreeToUse;

  /// No description provided for @welcomeConnectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Each connection lasts 30 minutes, after that, please come back and connect again.'**
  String get welcomeConnectionInfo;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;

  /// No description provided for @enableAppOpenAds.
  ///
  /// In en, this message translates to:
  /// **'App Open Ads'**
  String get enableAppOpenAds;

  /// No description provided for @enableAppOpenAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'Once enabled, the connection duration will be 30 minutes instead of 15 minutes. An ad will appear when you open UmiVPN.'**
  String get enableAppOpenAdsDesc;

  /// No description provided for @noTorrect.
  ///
  /// In en, this message translates to:
  /// **'No Torrenting'**
  String get noTorrect;

  /// No description provided for @noTorrectDesc.
  ///
  /// In en, this message translates to:
  /// **'UmiVPN cannot be used for torrenting, torrenting traffic will not go through VPN tunnels. They will be go directly to the public Internet'**
  String get noTorrectDesc;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
