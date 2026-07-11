// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:gap/gap.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/log/logger.pb.dart' as pb;
import 'package:tm/x_controller.dart';
import 'package:tm/xapi_client.dart';
import 'package:umivpn/app/settings/setting.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/utils/path.dart';
import 'package:umivpn/utils/upload_log.dart';
import 'package:umivpn/widgets/form_dialog.dart';

class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  bool _debugLog = false;
  bool _uploading = false;
  int count = 0;

  @override
  void initState() {
    super.initState();
    _debugLog = context.read<SharedPreferences>().enableDebugLog;
  }

  Future<void> _toggleDebugLog(bool value) async {
    context.read<SharedPreferences>().setEnableDebugLog(value);
    setState(() {
      _debugLog = value;
    });
    // final apiClient = context.read<XApiClient>();
    await context.read<XController>().restart();
    if (!value) {
      // logger.logger = null;
      // apiClient.setLog(pb.LoggerConfig(logLevel: pb.Level.DISABLED));
    } else {
      // await setDebugLoggerProduction();
      // apiClient.setLog(
      //   pb.LoggerConfig(
      //     logLevel: pb.Level.DEBUG,
      //     consoleWriter: true,
      //     showCaller: true,
      //     showColor: true,
      //     filePath: await getDebugFlutterLogDir().then(
      //       (value) => path.join(value.path, 'vx-go.txt'),
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? getAdaptiveAppBar(
              context,
              Text(AppLocalizations.of(context)!.debugLog),
            )
          : null,
      body: isPkg
          ? Center(
              child: GestureDetector(
                onTap: () async {
                  count++;
                  if (count >= 10 && count < 20) {
                    snack('debug log enabled');
                    await _toggleDebugLog(true);
                  } else if (count >= 20) {
                    snack('debug log disabled');
                    await _toggleDebugLog(false);
                  }
                },
                child: Text(AppLocalizations.of(context)!.debugLogNotAvailable),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.debugLog),
                      const Spacer(),
                      Switch(value: _debugLog, onChanged: _toggleDebugLog),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    AppLocalizations.of(context)!.debugLogDesc,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final reson = await showStringForm(
                            context,
                            title: AppLocalizations.of(
                              context,
                            )!.describeTheProblem,
                            maxLines: 10,
                          );
                          setState(() {
                            _uploading = true;
                          });
                          final logUploadService = context
                              .read<LogUploadService>();
                          try {
                            await logUploadService.uploadDebugLog(
                              reson ?? 'no reason provided',
                            );
                            snack('日志上传成功。谢谢您的反馈！');
                            // remove all debug log files
                            // final debugLogDir = await getDebugTunnelLogDir();
                            // await debugLogDir.delete(recursive: true);
                            // final flutterLogDir =
                            //     await getDebugFlutterLogDir();
                            // await flutterLogDir.delete(recursive: true);
                          } catch (e) {
                            snack('无法上传日志：$e');
                          } finally {
                            setState(() {
                              _uploading = false;
                            });
                          }
                        },
                        child: _uploading
                            ? smallCircularProgressIndicator()
                            : Text(AppLocalizations.of(context)!.upload),
                      ),
                      // if (!Platform.isIOS && !Platform.isMacOS)
                      //   OutlinedButton(
                      //     onPressed: () async {
                      //       try {
                      //         late Directory? downloadsDir;
                      //         if (Platform.isAndroid) {
                      //           downloadsDir = Directory(
                      //             '/storage/emulated/0/Download/',
                      //           );
                      //         } else {
                      //           downloadsDir = await getDownloadsDirectory();
                      //         }
                      //         final debugTunnelLogDir =
                      //             await getDebugTunnelLogDir();
                      //         final dstDir = path.join(
                      //           downloadsDir!.path,
                      //           "vx_debug_logs_${DateTime.now().millisecondsSinceEpoch}",
                      //         );
                      //         Directory(dstDir).createSync(recursive: true);
                      //         for (final file
                      //             in await debugTunnelLogDir.list().toList()) {
                      //           if (file is File) {
                      //             final fileName = path.basename(file.path);
                      //             if (fileName.startsWith(".")) {
                      //               continue;
                      //             }
                      //             await file.copy(path.join(dstDir, fileName));
                      //           }
                      //         }
                      //         final debugFlutterLogDir =
                      //             await getDebugFlutterLogDir();
                      //         for (final file
                      //             in await debugFlutterLogDir.list().toList()) {
                      //           if (file is File) {
                      //             final fileName = path.basename(file.path);
                      //             if (fileName.startsWith(".")) {
                      //               continue;
                      //             }
                      //             await file.copy(path.join(dstDir, fileName));
                      //           }
                      //         }
                      //         rootScaffoldMessengerKey.currentState
                      //             ?.showSnackBar(
                      //               SnackBar(
                      //                 content: Text("开发者日志已保存至: $dstDir"),
                      //                 duration: const Duration(seconds: 10),
                      //               ),
                      //             );
                      //       } catch (e) {
                      //         logger.e('无法保存日志：$e');
                      //         snack('无法保存日志：$e');
                      //       }
                      //     },
                      //     child: Text(
                      //       AppLocalizations.of(context)!.saveToDownloadFolder,
                      //     ),
                      //   ),
                      OutlinedButton(
                        onPressed: () async {
                          await _toggleDebugLog(false);
                          // remove all debug log files
                          final dir = await getDebugTunnelLogDir();
                          await dir.delete(recursive: true);
                          final flutterLogDir = await getDebugFlutterLogDir();
                          await flutterLogDir.delete(recursive: true);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.deleteDebugLogs,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
