import 'dart:async';
import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter/src/animation.dart';

typedef DrawerBuilder = Widget Function(
    BuildContext context, Size extraSize, Size size);

Future<T?> openDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required OverlayPosition position,
  bool expands = false,
  bool draggable = true,
}) {
  return openRawDrawer<T>(
    context: context,
    builder: (context, extraSize, size) {
      return DrawerWrapper(
        position: position,
        expands: expands,
        draggable: draggable,
        extraSize: extraSize,
        size: size,
        child: builder(context),
      );
    },
    position: position,
  );
}

Future<T?> openSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required OverlayPosition position,
}) {
  return openRawDrawer<T>(
    context: context,
    transformBackdrop: false,
    builder: (context, extraSize, size) {
      return SheetWrapper(
        position: position,
        expands: true,
        extraSize: extraSize,
        size: size,
        child: builder(context),
      );
    },
    position: position,
  );
}

class DrawerWrapper extends StatefulWidget {
  final OverlayPosition position;
  final Widget child;
  final bool expands;
  final bool draggable;
  final Size extraSize;
  final Size size;

  const DrawerWrapper({
    required this.position,
    required this.child,
    this.expands = false,
    this.draggable = true,
    this.extraSize = Size.zero,
    required this.size,
  });

  @override
  State<DrawerWrapper> createState() => _DrawerWrapperState();
}

class _DrawerWrapperState extends State<DrawerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ControlledAnimation _extraOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _extraOffset = ControlledAnimation(_controller);
  }

  double? get expandingHeight {
    switch (widget.position) {
      case OverlayPosition.left:
      case OverlayPosition.right:
        return double.infinity;
      default:
        return null;
    }
  }

  double? get expandingWidth {
    switch (widget.position) {
      case OverlayPosition.top:
      case OverlayPosition.bottom:
        return double.infinity;
      default:
        return null;
    }
  }

  Widget buildDraggableBar(ThemeData theme) {
    switch (widget.position) {
      case OverlayPosition.left:
      case OverlayPosition.right:
        return Container(
          width: 8,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(1000),
          ),
        );
      case OverlayPosition.top:
      case OverlayPosition.bottom:
        return Container(
          width: 100,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(1000),
          ),
        );
    }
  }

  Size getSize(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.hasSize ?? false
        ? renderBox?.size ?? widget.size
        : widget.size;
  }

  Widget buildDraggable(BuildContext context, ControlledAnimation? controlled,
      Widget child, ThemeData theme) {
    switch (widget.position) {
      case OverlayPosition.left:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.width;
            double newValue = controlled.value + increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          onHorizontalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return gap(
                        widget.extraSize.width + _extraOffset.value.max(0));
                  }),
              widget.child,
              gap(16),
              buildDraggableBar(theme),
              gap(16),
            ],
          ),
        );
      case OverlayPosition.right:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.width;
            double newValue = controlled.value - increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  -details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          onHorizontalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              gap(16),
              buildDraggableBar(theme),
              gap(16),
              widget.child,
              AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return gap(
                        widget.extraSize.width + _extraOffset.value.max(0));
                  }),
            ],
          ),
        );
      case OverlayPosition.top:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.height;
            double newValue = controlled.value + increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          onVerticalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return gap(
                        widget.extraSize.height + _extraOffset.value.max(0));
                  }),
              widget.child,
              gap(16),
              buildDraggableBar(theme),
              gap(16),
            ],
          ),
        );
      case OverlayPosition.bottom:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.height;
            double newValue = controlled.value - increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  -details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          onVerticalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              gap(16),
              buildDraggableBar(theme),
              gap(16),
              widget.child,
              AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return gap(
                        widget.extraSize.height + _extraOffset.value.max(0));
                  }),
            ],
          ),
        );
    }
  }

  Border getBorder(ThemeData theme) {
    switch (widget.position) {
      case OverlayPosition.left:
        // top, right, bottom
        return Border(
          right: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
          bottom: BorderSide(color: theme.colorScheme.border),
        );
      case OverlayPosition.right:
        // top, left, bottom
        return Border(
          left: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
          bottom: BorderSide(color: theme.colorScheme.border),
        );
      case OverlayPosition.top:
        // left, right, bottom
        return Border(
          left: BorderSide(color: theme.colorScheme.border),
          right: BorderSide(color: theme.colorScheme.border),
          bottom: BorderSide(color: theme.colorScheme.border),
        );
      case OverlayPosition.bottom:
        // left, right, top
        return Border(
          left: BorderSide(color: theme.colorScheme.border),
          right: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
        );
    }
  }

  BoxDecoration getDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10), // seems to be fixed radius?
      color: theme.colorScheme.background,
      border: getBorder(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<_OverlaidEntryData>(context);
    final animation = data?.state._controlledAnimation;
    final theme = Theme.of(context);
    return Container(
      width: widget.expands ? expandingWidth : null,
      height: widget.expands ? expandingHeight : null,
      decoration: getDecoration(theme),
      child: widget.draggable
          ? buildDraggable(context, animation, widget.child, theme)
          : widget.child,
    );
  }
}

Future<void> closeSheet(BuildContext context) {
  // sheet is just a drawer with no backdrop transformation
  return closeDrawer(context);
}

class SheetWrapper extends DrawerWrapper {
  const SheetWrapper(
      {required super.position,
      required super.child,
      required super.size,
      super.draggable = false,
      super.expands = false,
      super.extraSize = Size.zero});

  @override
  State<DrawerWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends _DrawerWrapperState {
  @override
  Border getBorder(ThemeData theme) {
    switch (widget.position) {
      case OverlayPosition.left:
        return Border(right: BorderSide(color: theme.colorScheme.border));
      case OverlayPosition.right:
        return Border(left: BorderSide(color: theme.colorScheme.border));
      case OverlayPosition.top:
        return Border(bottom: BorderSide(color: theme.colorScheme.border));
      case OverlayPosition.bottom:
        return Border(top: BorderSide(color: theme.colorScheme.border));
    }
  }

  @override
  BoxDecoration getDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.background,
      border: getBorder(theme),
    );
  }
}

enum OverlayPosition {
  left,
  right,
  top,
  bottom,
}

const kBackdropScaleDown = 0.95;

class BackdropTransformData {
  final Size sizeDifference;

  BackdropTransformData(this.sizeDifference);
}

Future<T?> openRawDrawer<T>({
  Key? key,
  required BuildContext context,
  required DrawerBuilder builder,
  required OverlayPosition position,
  bool transformBackdrop = true,
  bool useRootDrawerOverlay = true,
  bool modal = true,
  Color? barrierColor,
  bool barrierDismissible = true,
}) {
  final DrawerLayerData? parentLayer =
      DrawerOverlay.maybeOf(context, useRootDrawerOverlay);
  assert(parentLayer != null, 'No DrawerOverlay found in the widget tree');
  final CapturedThemes themes =
      InheritedTheme.capture(from: context, to: parentLayer!.overlay.context);
  final completer = Completer<T?>();
  final entry = DrawerOverlayEntry(
    builder: builder,
    modal: modal,
    backdropBuilder: transformBackdrop
        ? (context, child, animation, stackIndex) {
            final theme = Theme.of(context);
            final existingData = Data.maybeOf<BackdropTransformData>(context);
            return LayoutBuilder(builder: (context, constraints) {
              return stackIndex == 0
                  ? AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        Size size = constraints.biggest;
                        double scale =
                            1 - (1 - kBackdropScaleDown) * animation.value;
                        Size sizeAfterScale = Size(
                          size.width * scale,
                          size.height * scale,
                        );
                        var extraSize = Size(
                          size.width -
                              sizeAfterScale.width / kBackdropScaleDown,
                          size.height -
                              sizeAfterScale.height / kBackdropScaleDown,
                        );
                        if (existingData != null) {
                          extraSize = Size(
                            extraSize.width +
                                existingData.sizeDifference.width /
                                    kBackdropScaleDown,
                            extraSize.height +
                                existingData.sizeDifference.height /
                                    kBackdropScaleDown,
                          );
                        }
                        return Data(
                          data: BackdropTransformData(extraSize),
                          child: Transform.scale(
                            scale: scale,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  theme.radiusXxl * animation.value),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: child,
                    )
                  : AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        Size size = constraints.biggest;
                        double scale =
                            1 - (1 - kBackdropScaleDown) * animation.value;
                        Size sizeAfterScale = Size(
                          size.width * scale,
                          size.height * scale,
                        );
                        var extraSize = Size(
                          size.width - sizeAfterScale.width,
                          size.height - sizeAfterScale.height,
                        );
                        if (existingData != null) {
                          extraSize = Size(
                            extraSize.width +
                                existingData.sizeDifference.width /
                                    kBackdropScaleDown,
                            extraSize.height +
                                existingData.sizeDifference.height /
                                    kBackdropScaleDown,
                          );
                        }
                        return Data(
                          data: BackdropTransformData(extraSize),
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
            });
          }
        : (context, child, animation, stackIndex) => child,
    barrierBuilder: (context, child, animation, stackIndex) {
      if (stackIndex > 0) {
        if (!transformBackdrop) {
          return null;
        }
      }
      return Positioned(
        top: -9999,
        left: -9999,
        right: -9999,
        bottom: -9999,
        child: FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: animation.status != AnimationStatus.completed,
                child: child!,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: barrierDismissible ? () => closeDrawer(context) : null,
              child: Container(
                color: barrierColor ??
                    (stackIndex == 0
                        ? Colors.black.withOpacity(0.8)
                        : Colors.black.withOpacity(0.4)),
              ),
            ),
          ),
        ),
      );
    },
    themes: themes,
    completer: completer,
    position: position,
  );
  final overlay = parentLayer.overlay;
  overlay.addEntry(entry);
  completer.future.whenComplete(() {
    overlay.removeEntry(entry);
  });
  return completer.future;
}

class _OverlaidEntryData {
  final _OverlaidEntryState state;

  _OverlaidEntryData(this.state);
}

Future<void> closeDrawer<T>(BuildContext context, [T? result]) {
  final data = Data.maybeOf<_OverlaidEntryData>(context);
  assert(data != null, 'No OverlaidEntryData found in the widget tree');
  return data!.state.close();
}

class DrawerLayerData {
  final _DrawerOverlayState overlay;
  final DrawerLayerData? parent;

  const DrawerLayerData(this.overlay, this.parent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawerLayerData &&
        other.overlay == overlay &&
        other.parent == parent;
  }

  @override
  int get hashCode {
    return overlay.hashCode ^ parent.hashCode;
  }
}

class DrawerOverlay extends StatefulWidget {
  final Widget child;

  const DrawerOverlay({required this.child});

  @override
  State<DrawerOverlay> createState() => _DrawerOverlayState();

  static DrawerLayerData? maybeOf(BuildContext context, [bool root = false]) {
    var data = Data.maybeOf<DrawerLayerData>(context);
    if (root) {
      while (data?.parent != null) {
        data = data!.parent;
      }
    }
    return data;
  }
}

class _DrawerOverlayState extends State<DrawerOverlay> {
  final List<DrawerOverlayEntry> _entries = [];
  final GlobalKey backdropKey = GlobalKey();

  void addEntry(DrawerOverlayEntry entry) {
    setState(() {
      _entries.add(entry);
    });
  }

  void removeEntry(DrawerOverlayEntry entry) {
    setState(() {
      _entries.remove(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentLayer = Data.maybeOf<DrawerLayerData>(context);
    Widget child = KeyedSubtree(
      key: backdropKey,
      child: widget.child,
    );
    int index = 0;
    for (final entry in _entries) {
      child = OverlaidEntry(
        key: entry.key, // to make the overlay state persistent
        builder: entry.builder,
        backdrop: child,
        barrierBuilder: entry.barrierBuilder,
        modal: entry.modal,
        themes: entry.themes,
        completer: entry.completer,
        position: entry.position,
        backdropBuilder: entry.backdropBuilder,
        stackIndex: index++,
        totalStack: _entries.length,
      );
    }
    return Data(
      data: DrawerLayerData(this, parentLayer),
      child: child,
    );
  }
}

class OverlaidEntry<T> extends StatefulWidget {
  final DrawerBuilder builder;
  final Widget backdrop;
  final BackdropBuilder backdropBuilder;
  final BarrierBuilder barrierBuilder;
  final bool modal;
  final CapturedThemes themes;
  final Completer<T> completer;
  final OverlayPosition position;
  final int stackIndex;
  final int totalStack;

  const OverlaidEntry({
    super.key,
    required this.builder,
    required this.backdrop,
    required this.backdropBuilder,
    required this.barrierBuilder,
    required this.modal,
    required this.themes,
    required this.completer,
    required this.position,
    required this.stackIndex,
    required this.totalStack,
  });

  @override
  State<OverlaidEntry<T>> createState() => _OverlaidEntryState<T>();
}

class _OverlaidEntryState<T> extends State<OverlaidEntry<T>>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<double> additionalOffset = ValueNotifier(0);
  late AnimationController _controller;
  late ControlledAnimation _controlledAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _controlledAnimation = ControlledAnimation(_controller);
    _controlledAnimation.forward(1, Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> close() {
    return _controlledAnimation.forward(0, Curves.easeOutCubic).then((value) {
      widget.completer.complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    Offset startFractionalOffset;
    switch (widget.position) {
      case OverlayPosition.left:
        alignment = Alignment.centerLeft;
        startFractionalOffset = const Offset(-1, 0);
        break;
      case OverlayPosition.right:
        alignment = Alignment.centerRight;
        startFractionalOffset = const Offset(1, 0);
        break;
      case OverlayPosition.top:
        alignment = Alignment.topCenter;
        startFractionalOffset = const Offset(0, -1);
        break;
      case OverlayPosition.bottom:
        alignment = Alignment.bottomCenter;
        startFractionalOffset = const Offset(0, 1);
        break;
    }
    return Data(
      data: _OverlaidEntryData(this),
      child: LayoutBuilder(builder: (context, constraints) {
        Widget barrier = (widget.modal
                ? widget.barrierBuilder(context, widget.backdrop,
                    _controlledAnimation, widget.stackIndex)
                : null) ??
            Positioned(
              top: -9999,
              left: -9999,
              right: -9999,
              bottom: -9999,
              child: GestureDetector(
                onTap: () {
                  close();
                },
              ),
            );
        final extraSize =
            Data.maybeOf<BackdropTransformData>(context)?.sizeDifference;
        Size additionalSize;
        Offset additionalOffset;
        if (extraSize == null) {
          additionalSize = Size.zero;
          additionalOffset = Offset.zero;
        } else {
          switch (widget.position) {
            case OverlayPosition.left:
              additionalSize = Size(extraSize.width / 2, 0);
              additionalOffset = Offset(-additionalSize.width, 0);
              break;
            case OverlayPosition.right:
              additionalSize = Size(extraSize.width / 2, 0);
              additionalOffset = Offset(additionalSize.width, 0);
              break;
            case OverlayPosition.top:
              additionalSize = Size(0, extraSize.height / 2);
              additionalOffset = Offset(0, -additionalSize.height);
              break;
            case OverlayPosition.bottom:
              additionalSize = Size(0, extraSize.height / 2);
              additionalOffset = Offset(0, additionalSize.height);
              break;
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.backdropBuilder(context, widget.backdrop,
                _controlledAnimation, widget.stackIndex),
            barrier,
            Positioned.fill(
              child: widget.themes.wrap(
                Align(
                  alignment: alignment,
                  child: AnimatedBuilder(
                    animation: _controlledAnimation,
                    builder: (context, child) {
                      return FractionalTranslation(
                        translation: startFractionalOffset *
                            (1 - _controlledAnimation.value),
                        child: child,
                      );
                    },
                    child: Transform.translate(
                      offset: additionalOffset / kBackdropScaleDown,
                      child: widget.builder(
                          context, additionalSize, constraints.biggest),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

typedef BackdropBuilder = Widget Function(BuildContext context, Widget child,
    Animation<double> animation, int stackIndex);

typedef BarrierBuilder = Widget? Function(BuildContext context, Widget child,
    Animation<double> animation, int stackIndex);

class DrawerOverlayEntry<T> {
  final GlobalKey key = GlobalKey();
  final BackdropBuilder backdropBuilder;
  final DrawerBuilder builder;
  final bool modal;
  final BarrierBuilder barrierBuilder;
  final CapturedThemes themes;
  final Completer<T> completer;
  final OverlayPosition position;

  DrawerOverlayEntry({
    required this.builder,
    required this.backdropBuilder,
    required this.modal,
    required this.barrierBuilder,
    required this.themes,
    required this.completer,
    required this.position,
  });
}