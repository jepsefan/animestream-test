import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/update.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:animestream/core/network/network.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateSheet extends StatefulWidget {
  final UpdateCheckResult data;
  const UpdateSheet({
    required this.data,
    super.key,
  });

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  StreamSubscription<List<int>>? _sub;
  Completer<void>? _downloadCompleter;

  final ValueNotifier<double> progress = ValueNotifier(0);

  DownloadState downloadState = DownloadState.idle;

  String downloadPath = "";

  Future<bool> verifyFileHash(File file, String expectedDigest) async {
    final parts = expectedDigest.trim().toLowerCase().split(':');

    if (parts.length != 2 || parts[0] != 'sha256' || !RegExp(r'^[0-9a-f]{64}$').hasMatch(parts[1])) {
      throw FormatException('Missing or invalid SHA-256 digest');
    }

    final actualDigest = await sha256.bind(file.openRead()).first;
    return actualDigest.toString() == parts[1];
  }

  void downloadAndInstallUpdate() async {
    final filename = "animestream_${widget.data.latestVersion}.part";
    final finalFilename = "animestream_${widget.data.latestVersion}.${Platform.isWindows ? "exe" : "apk"}";
    final tempPath = await getTemporaryDirectory();
    final partFilePath = "${tempPath.path}/$filename";
    final finalFilePath = "${tempPath.path}/$finalFilename";

    bool isAlreadyDownloaded = false;
    final finalFile = File(finalFilePath);

    if (finalFile.existsSync()) {
      try {
        if (await verifyFileHash(finalFile, widget.data.hash)) {
          isAlreadyDownloaded = true;
        }
      } catch (e) {
        Logs.app.log("Hash verification failed for existing file: $e");
      }
    }

    if (isAlreadyDownloaded) {
      Logs.app.log("Installable asset already downloaded. Opening the file...");
      downloadPath = finalFilePath;
    } else {
      Logs.app.log("Downloading patch ${widget.data.latestVersion}...");
      downloadPath = partFilePath;

      if (mounted) {
        setState(() {
          downloadState = DownloadState.downloading;
        });
      }

      final uri = Uri.parse(widget.data.downloadLink);
      final buffer = await File(downloadPath).openWrite();
      _downloadCompleter = Completer<void>();

      double downloadedBytes = 0;

      Future<void> cleanup() async {
        await buffer.flush();
        await buffer.close();
      }

      try {
        final req = Request("GET", uri);
        final res = await req.send();
        int totalBytes = res.contentLength ?? 0;

        _sub = res.stream.listen((chunk) {
          downloadedBytes += chunk.length;
          progress.value = totalBytes == 0 ? 0 : downloadedBytes / totalBytes;
          buffer.add(chunk);
        }, onError: (err) {
          if (!_downloadCompleter!.isCompleted) _downloadCompleter!.completeError(err);
        }, onDone: () {
          if (!_downloadCompleter!.isCompleted) _downloadCompleter!.complete();
        }, cancelOnError: true);
        
        await _downloadCompleter!.future;
        await cleanup();
      } catch (err) {
        await cleanup();
        if (err == "cancelled") {
          Logs.app.log("Download cancelled by user.");
          return;
        }
        floatingSnackBar("There was an issue downloading the update.");
        Logs.app.log("Error downloading the update: ${err.toString()}");
        File(downloadPath).deleteSync();
        if (mounted) {
          setState(() {
            downloadState = DownloadState.idle;
          });
        }
        return;
      }

      try {
        if (!(await verifyFileHash(File(downloadPath), widget.data.hash))) {
          throw Exception("Hash mismatch");
        }
      } catch (e) {
        floatingSnackBar("File verification failed. Please try again.");
        Logs.app.log("Update file hash mismatch or error: $e");
        File(downloadPath).deleteSync();
        if (mounted) {
          setState(() {
            downloadState = DownloadState.idle;
          });
        }
        return;
      }

      // rename from temp name to proper extension 
      File(downloadPath).renameSync(finalFilePath);
      downloadPath = finalFilePath;

      // check and clean the old file (can pile up if not cleaned)
      // this is also cleanable with the "clear cache" option
      final oldVersion = File(
          "${tempPath.path}/animestream_${(await PackageInfo.fromPlatform()).version}.${Platform.isWindows ? "exe" : "apk"}");
      if (oldVersion.existsSync()) {
        oldVersion.deleteSync();
      }

      // set completed state after saving to disk
      if (mounted) {
        setState(() {
          downloadState = DownloadState.completed;
        });
      }

      Logs.app.log("nice... Download complete!");
    }

    var openRes = await OpenFile.open(downloadPath);
    if (openRes.type == ResultType.permissionDenied) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isGranted) {
        openRes = await OpenFile.open(downloadPath);
      }
    }
    if (openRes.type == ResultType.done) {
      Logs.app.log("Update dialog invoked succesfully.");
    }
  }

  void _cancelDownload() {
    _sub?.cancel();
    _sub = null;
    if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
      _downloadCompleter!.completeError("cancelled");
    }
    if (mounted) setState(() => downloadState = DownloadState.idle);
    progress.value = 0;
  }

  @override
  void dispose() {
    _sub?.cancel();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 15, right: 15, top: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Update Available",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),

                      // Padding(
                      // padding: const EdgeInsets.only(left: 14, bottom: 12),
                      // child:
                      Row(
                        // mainAxisAlignment: ,
                        children: [
                          Text(
                            widget.data.latestVersion,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          Container(
                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              margin: EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: appTheme.accentColor,
                              ),
                              child: Text(
                                widget.data.preRelease ? "beta" : "stable",
                                style: TextStyle(
                                  color: appTheme.onAccent,
                                  fontSize: 15,
                                  fontFamily: "NunitoSans",
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse("https://github.com/frostnova721/animestream/releases/latest"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: Icon(
                      Icons.launch_rounded,
                      size: 28,
                    ),
                    tooltip: "Open In Browser",
                  ),
                ],
              ),
            ),
            Container(
              height: 400,
              decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(25)),
              padding: EdgeInsets.all(14),
              child: ListView(
                shrinkWrap: true,
                children: [
                  MarkdownBody(
                    data: widget.data.description,
                    styleSheet: MarkdownStyleSheet(
                      h1: style(bold: true),
                      h2: style(bold: true),
                      listBullet: style(),
                      h3: style(),
                      h4: style(),
                      h5: style(),
                      h6: style(),
                      p: style(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ValueListenableBuilder(
                        valueListenable: progress,
                        builder: (ctx, val, child) {
                          return LiquidDownloadButton(
                            state: downloadState,
                            progress: val,
                            onPressed: () {
                              // if the update is downloaded and state is install, it automatically opens
                              // the available update file
                              if (downloadState != DownloadState.downloading) return downloadAndInstallUpdate();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      onPressed: () async {
                        _cancelDownload();
                        if (downloadPath.isNotEmpty && downloadState != DownloadState.completed)
                          await File(downloadPath).delete();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      color: appTheme.accentColor,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: appTheme.accentColor),
                        fixedSize: Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      icon: Icon(Icons.close),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle style({bool bold = false}) {
    return TextStyle(
      color: appTheme.textMainColor,
      fontFamily: "NotoSans",
      fontWeight: bold ? FontWeight.bold : null,
    );
  }
}

enum DownloadState { idle, downloading, completed }

class LiquidDownloadButton extends StatelessWidget {
  final DownloadState state;
  final double progress; // 0.0 to 1.0
  final VoidCallback onPressed;

  const LiquidDownloadButton({
    super.key,
    required this.state,
    required this.progress,
    required this.onPressed,
  }) : assert(progress >= 0 && progress <= 1, "Progress value must be between 0.0 and 1.0!");

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 50,
          width: double.infinity,
          color: state == DownloadState.idle ? appTheme.accentColor : appTheme.backgroundSubColor,
          child: Stack(
            children: [
              if (state != DownloadState.idle)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * progress,
                      height: constraints.maxHeight,
                      color: appTheme.accentColor,
                    );
                  },
                ),
              Center(
                child: Text(
                  _getButtonText(),
                  style: TextStyle(
                    color: appTheme.onAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (state) {
      case DownloadState.idle:
        return "Download";
      case DownloadState.downloading:
        return "Downloading... ${progress == 0 ? "" : "${(progress * 100).toInt()}%"}";
      case DownloadState.completed:
        return "Install";
    }
  }
}
