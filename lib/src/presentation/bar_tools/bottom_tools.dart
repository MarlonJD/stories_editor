import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/constants/item_type.dart';
import 'package:stories_editor/src/presentation/utils/constants/text_animation_type.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/tool_button.dart';

class BottomTools extends StatefulWidget {
  final GlobalKey contentKey;
  final Function(String imageUri, int hour) onDone;
  final Widget? onDoneButtonStyle;
  final Function? renderWidget;
  final String? shareButtonText;
  final Function()? onTapGalleryButton;
  final String? errorText;
  final String? emptyNoticeText;

  /// editor background color
  final Color? editorBackgroundColor;
  BottomTools({
    Key? key,
    required this.contentKey,
    required this.onDone,
    this.renderWidget,
    this.onDoneButtonStyle,
    this.editorBackgroundColor,
    this.shareButtonText,
    this.onTapGalleryButton,
    this.errorText,
    this.emptyNoticeText,
  }) : super(key: key);

  @override
  State<BottomTools> createState() => _BottomToolsState();
}

class _BottomToolsState extends State<BottomTools> {
  int hours = 24;
  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    bool _createVideo = false;
    return Consumer4<ControlNotifier, ScrollNotifier, DraggableWidgetNotifier,
        PaintingNotifier>(
      builder: (_, controlNotifier, scrollNotifier, itemNotifier,
          paintingNotifier, __) {
        return Container(
          height: 95,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// preview gallery
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: const CircleBorder(),
                    ),
                    onPressed: widget.onTapGalleryButton,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add_a_photo,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              /// center logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      ),
                      icon: Icon(Icons.hourglass_bottom,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      label: (hours == 24)
                          ? Text(
                              '24s',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary),
                            )
                          : (hours == 72)
                              ? Text(
                                  '72s',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                )
                              : (hours == 168)
                                  ? Text(
                                      '1h',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    )
                                  : const SizedBox(),
                      onPressed: () {
                        setState(() {
                          if (hours == 24) {
                            hours = 72;
                          } else if (hours == 72) {
                            hours = 168;
                          } else if (hours == 168) {
                            hours = 24;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),

              /// save final image to gallery
              Flexible(
                child: Transform.scale(
                  scale: 0.9,
                  child: StatefulBuilder(
                    builder: (_, setState) {
                      return AnimatedOnTapButton(
                        onTap: () async {
                          String pngUri;
                          if (paintingNotifier.lines.isEmpty &&
                              itemNotifier.draggableWidget.isEmpty) {
                            Get.snackbar(
                                widget.errorText ?? "Error",
                                widget.emptyNoticeText ??
                                    "Empty notice cannot be published",
                                backgroundColor: Colors.red.withOpacity(0.3));
                          } else if (paintingNotifier.lines.isNotEmpty ||
                              itemNotifier.draggableWidget.isNotEmpty) {
                            for (var element in itemNotifier.draggableWidget) {
                              // if (element.type == ItemType.gif ||
                              //     element.animationType !=
                              //         TextAnimationType.none) {
                              //   setState(() {
                              //     _createVideo = true;
                              //   });
                              // }
                            }
                            debugPrint('creating image');
                            await takePicture(
                                    contentKey: widget.contentKey,
                                    context: context,
                                    saveToGallery: false)
                                .then((bytes) {
                              if (bytes != null) {
                                pngUri = bytes;
                                widget.onDone(pngUri, hours);
                              } else {}
                            });
                          }
                          setState(() {
                            _createVideo = false;
                          });
                        },
                        child: widget.onDoneButtonStyle ??
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 5, top: 4, bottom: 4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.shareButtonText ?? "Share",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ]),
                            ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _preViewContainer({child}) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.4, color: Colors.white)),
      child: child,
    );
  }
}
