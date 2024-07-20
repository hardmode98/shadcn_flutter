import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PopoverRoute<T> extends PopupRoute<T> {
  final BuildContext anchorContext;
  final WidgetBuilder builder;
  final Offset position;
  final Alignment alignment;
  final CapturedThemes themes;
  final CapturedData data;
  final Key? key;
  final bool modal;
  final Size? anchorSize;
  final Alignment anchorAlignment;
  final PopoverConstraint widthConstraint;
  final PopoverConstraint heightConstraint;
  final Object? regionGroupId;
  final Offset? offset;
  final Alignment? transitionAlignment;
  final EdgeInsets margin;
  final bool follow;
  final bool consumeOutsideTaps;
  final ValueChanged<PopoverAnchorState>? onTickFollow;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;

  PopoverRoute({
    required this.anchorContext,
    required this.builder,
    required this.position,
    required this.alignment,
    required this.themes,
    required this.anchorAlignment,
    required this.data,
    this.modal = false,
    this.key,
    this.anchorSize,
    this.widthConstraint = PopoverConstraint.flexible,
    this.heightConstraint = PopoverConstraint.flexible,
    super.settings,
    this.regionGroupId,
    this.offset,
    this.transitionAlignment,
    this.margin = const EdgeInsets.all(8),
    this.follow = true,
    this.consumeOutsideTaps = true,
    this.onTickFollow,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  @override
  Widget buildModalBarrier() {
    if (modal) return super.buildModalBarrier();
    if (!consumeOutsideTaps) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (isCurrent) {
            Navigator.of(anchorContext).pop();
          } else {
            Navigator.of(anchorContext).removeRoute(this);
          }
        },
      );
    }
    return const SizedBox();
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return PopoverAnchor(
      key: key,
      anchorContext: anchorContext,
      position: position,
      alignment: alignment,
      themes: themes,
      builder: builder,
      animation: animation,
      anchorSize: anchorSize,
      anchorAlignment: anchorAlignment,
      widthConstraint: widthConstraint,
      heightConstraint: heightConstraint,
      onTapOutside: () {
        if (!modal) {
          if (isCurrent) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).removeRoute(this);
          }
        }
      },
      route: this,
      regionGroupId: regionGroupId,
      offset: offset,
      transitionAlignment: transitionAlignment,
      margin: margin,
      follow: follow,
      consumeOutsideTaps: consumeOutsideTaps,
      onTickFollow: onTickFollow,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      data: data,
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  Duration get reverseTransitionDuration => kDefaultDuration;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
        parent: super.createAnimation(),
        curve: Curves.linear,
        reverseCurve: const Interval(0, 2 / 3));
  }
}

class PopoverAnchor extends StatefulWidget {
  const PopoverAnchor({
    super.key,
    required this.anchorContext,
    required this.position,
    required this.alignment,
    this.themes,
    required this.builder,
    required this.animation,
    required this.anchorAlignment,
    this.widthConstraint = PopoverConstraint.flexible,
    this.heightConstraint = PopoverConstraint.flexible,
    this.anchorSize,
    this.route,
    this.onTapOutside,
    this.regionGroupId,
    this.offset,
    this.transitionAlignment,
    this.margin = const EdgeInsets.all(8),
    this.follow = true,
    this.consumeOutsideTaps = true,
    this.onTickFollow,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
    this.data,
  });

  final Offset position;
  final Alignment alignment;
  final Alignment anchorAlignment;
  final CapturedThemes? themes;
  final CapturedData? data;
  final WidgetBuilder builder;
  final Size? anchorSize;
  final Animation<double> animation;
  final PopoverConstraint widthConstraint;
  final PopoverConstraint heightConstraint;
  final PopoverRoute? route;
  final VoidCallback? onTapOutside;
  final Object? regionGroupId;
  final Offset? offset;
  final Alignment? transitionAlignment;
  final EdgeInsets margin;
  final bool follow;
  final BuildContext anchorContext;
  final bool consumeOutsideTaps;
  final ValueChanged<PopoverAnchorState>? onTickFollow;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;

  @override
  State<PopoverAnchor> createState() => PopoverAnchorState();
}

enum PopoverConstraint {
  flexible,
  anchorFixedSize,
  anchorMinSize,
  anchorMaxSize,
}

class PopoverAnchorState extends State<PopoverAnchor>
    with SingleTickerProviderStateMixin {
  late BuildContext _anchorContext;
  late Offset _position;
  late Offset? _offset;
  late Alignment _alignment;
  late Alignment _anchorAlignment;
  late PopoverConstraint _widthConstraint;
  late PopoverConstraint _heightConstraint;
  late EdgeInsets _margin;
  Size? _anchorSize;
  late bool _follow;
  late bool _allowInvertHorizontal;
  late bool _allowInvertVertical;
  late Ticker _ticker;

  set offset(Offset? offset) {
    if (offset != null) {
      setState(() {
        _offset = offset;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _offset = widget.offset;
    _position = widget.position;
    _alignment = widget.alignment;
    _anchorSize = widget.anchorSize;
    _anchorAlignment = widget.anchorAlignment;
    _widthConstraint = widget.widthConstraint;
    _heightConstraint = widget.heightConstraint;
    _margin = widget.margin;
    _follow = widget.follow;
    _anchorContext = widget.anchorContext;
    _allowInvertHorizontal = widget.allowInvertHorizontal;
    _allowInvertVertical = widget.allowInvertVertical;
    _ticker = createTicker(_tick);
    if (_follow) {
      _ticker.start();
    }
  }

  void close([bool immediate = false]) {
    var route = widget.route;
    if (route != null) {
      if (route.isCurrent && !immediate) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).removeRoute(route);
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void closeLater() {
    if (mounted && widget.route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).removeRoute(widget.route!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PopoverAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alignment != widget.alignment) {
      _alignment = widget.alignment;
    }
    if (oldWidget.anchorSize != widget.anchorSize) {
      _anchorSize = widget.anchorSize;
    }
    if (oldWidget.anchorAlignment != widget.anchorAlignment) {
      _anchorAlignment = widget.anchorAlignment;
    }
    if (oldWidget.widthConstraint != widget.widthConstraint) {
      _widthConstraint = widget.widthConstraint;
    }
    if (oldWidget.heightConstraint != widget.heightConstraint) {
      _heightConstraint = widget.heightConstraint;
    }
    if (oldWidget.offset != widget.offset) {
      _offset = widget.offset;
    }
    if (oldWidget.margin != widget.margin) {
      _margin = widget.margin;
    }
    if (oldWidget.follow != widget.follow) {
      _follow = widget.follow;
      if (_follow) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
    if (oldWidget.anchorContext != widget.anchorContext) {
      _anchorContext = widget.anchorContext;
    }
    if (oldWidget.allowInvertHorizontal != widget.allowInvertHorizontal) {
      _allowInvertHorizontal = widget.allowInvertHorizontal;
    }
    if (oldWidget.allowInvertVertical != widget.allowInvertVertical) {
      _allowInvertVertical = widget.allowInvertVertical;
    }
  }

  Size? get anchorSize => _anchorSize;
  Alignment get anchorAlignment => _anchorAlignment;
  Offset get position => _position;
  Alignment get alignment => _alignment;
  PopoverConstraint get widthConstraint => _widthConstraint;
  PopoverConstraint get heightConstraint => _heightConstraint;
  Offset? get offset => _offset;
  EdgeInsets get margin => _margin;
  bool get follow => _follow;
  BuildContext get anchorContext => _anchorContext;
  bool get allowInvertHorizontal => _allowInvertHorizontal;
  bool get allowInvertVertical => _allowInvertVertical;

  set alignment(Alignment value) {
    if (_alignment != value) {
      setState(() {
        _alignment = value;
      });
    }
  }

  set anchorAlignment(Alignment value) {
    if (_anchorAlignment != value) {
      setState(() {
        _anchorAlignment = value;
      });
    }
  }

  set widthConstraint(PopoverConstraint value) {
    if (_widthConstraint != value) {
      setState(() {
        _widthConstraint = value;
      });
    }
  }

  set heightConstraint(PopoverConstraint value) {
    if (_heightConstraint != value) {
      setState(() {
        _heightConstraint = value;
      });
    }
  }

  set margin(EdgeInsets value) {
    if (_margin != value) {
      setState(() {
        _margin = value;
      });
    }
  }

  set follow(bool value) {
    if (_follow != value) {
      setState(() {
        _follow = value;
        if (_follow) {
          _ticker.start();
        } else {
          _ticker.stop();
        }
      });
    }
  }

  set anchorContext(BuildContext value) {
    if (_anchorContext != value) {
      setState(() {
        _anchorContext = value;
      });
    }
  }

  set allowInvertHorizontal(bool value) {
    if (_allowInvertHorizontal != value) {
      setState(() {
        _allowInvertHorizontal = value;
      });
    }
  }

  set allowInvertVertical(bool value) {
    if (_allowInvertVertical != value) {
      setState(() {
        _allowInvertVertical = value;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (!mounted || !anchorContext.mounted) return;
    // update position based on anchorContext
    RenderBox? renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      Offset pos = renderBox.localToGlobal(Offset.zero);
      Size size = renderBox.size;
      Offset newPos = Offset(
        pos.dx + size.width / 2 + size.width / 2 * _anchorAlignment.x,
        pos.dy + size.height / 2 + size.height / 2 * _anchorAlignment.y,
      );
      if (_position != newPos) {
        setState(() {
          widget.onTickFollow?.call(this);
          _anchorSize = size;
          _position = newPos;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget builtChild = widget.builder(context);
    if (widget.themes != null) {
      builtChild = widget.themes!.wrap(builtChild);
    }
    if (widget.data != null) {
      builtChild = widget.data!.wrap(builtChild);
    }
    return TapRegion(
      enabled: widget.consumeOutsideTaps,
      onTapOutside: widget.onTapOutside != null
          ? (event) {
              widget.onTapOutside?.call();
            }
          : null,
      groupId: widget.regionGroupId,
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        removeTop: true,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            return PopoverLayout(
              alignment: _alignment,
              position: _position,
              anchorSize: _anchorSize,
              anchorAlignment: _anchorAlignment,
              widthConstraint: _widthConstraint,
              heightConstraint: _heightConstraint,
              offset: _offset,
              margin: _margin,
              scale: tweenValue(0.9, 1.0, widget.animation.value),
              scaleAlignment: widget.transitionAlignment ?? _alignment,
              allowInvertVertical: _allowInvertVertical,
              allowInvertHorizontal: _allowInvertHorizontal,
              child: child!,
            );
          },
          child: FadeTransition(
            opacity: widget.animation,
            child: builtChild,
          ),
        ),
      ),
    );
  }
}

Future<T?> showPopover<T>({
  required BuildContext context,
  required Alignment alignment,
  required WidgetBuilder builder,
  Offset? position,
  Alignment? anchorAlignment,
  PopoverConstraint widthConstraint = PopoverConstraint.flexible,
  PopoverConstraint heightConstraint = PopoverConstraint.flexible,
  Key? key,
  bool useRootNavigator = true,
  bool modal = true,
  Clip clipBehavior = Clip.none,
  RouteSettings? routeSettings,
  Object? regionGroupId,
  Offset? offset,
  Alignment? transitionAlignment,
  EdgeInsets margin = const EdgeInsets.all(8),
  bool follow = true,
  bool consumeOutsideTaps = true,
  ValueChanged<PopoverAnchorState>? onTickFollow,
  bool allowInvertHorizontal = true,
  bool allowInvertVertical = true,
}) {
  anchorAlignment ??= alignment * -1;
  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  final CapturedThemes themes =
      InheritedTheme.capture(from: context, to: navigator.context);
  final CapturedData datas = Data.capture(from: context, to: navigator.context);
  Size? anchorSize;
  if (position == null) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset pos = renderBox.localToGlobal(Offset.zero);
    anchorSize ??= renderBox.size;
    position = Offset(
      pos.dx + anchorSize.width / 2 + anchorSize.width / 2 * anchorAlignment.x,
      pos.dy +
          anchorSize.height / 2 +
          anchorSize.height / 2 * anchorAlignment.y,
    );
  }
  return navigator.push(PopoverRoute(
    anchorContext: context,
    key: key,
    builder: builder,
    position: position,
    alignment: alignment,
    themes: themes,
    modal: modal,
    settings: routeSettings,
    anchorSize: anchorSize,
    anchorAlignment: anchorAlignment,
    widthConstraint: widthConstraint,
    heightConstraint: heightConstraint,
    regionGroupId: regionGroupId,
    data: datas,
    offset: offset,
    transitionAlignment: transitionAlignment,
    margin: margin,
    follow: follow,
    consumeOutsideTaps: consumeOutsideTaps,
    onTickFollow: onTickFollow,
    allowInvertHorizontal: allowInvertHorizontal,
    allowInvertVertical: allowInvertVertical,
  ));
}

class PopoverController extends ChangeNotifier {
  final List<GlobalKey<PopoverAnchorState>> _openPopovers = [];

  bool get hasOpenPopover => _openPopovers.isNotEmpty;

  Iterable<PopoverAnchorState> get openPopovers => _openPopovers
      .map((key) => key.currentState)
      .whereType<PopoverAnchorState>();

  Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required Alignment alignment,
    Alignment? anchorAlignment,
    PopoverConstraint widthConstraint = PopoverConstraint.flexible,
    PopoverConstraint heightConstraint = PopoverConstraint.flexible,
    bool modal = false,
    bool closeOthers = true,
    Offset? offset,
    GlobalKey<PopoverAnchorState>? key,
    Object? regionGroupId,
    Alignment? transitionAlignment,
    bool consumeOutsideTaps = true,
    EdgeInsets margin = const EdgeInsets.all(8),
    ValueChanged<PopoverAnchorState>? onTickFollow,
    bool follow = true,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
  }) async {
    if (closeOthers) {
      close();
    }
    key ??= GlobalKey<PopoverAnchorState>();
    _openPopovers.add(key);
    notifyListeners();
    T? res = await showPopover(
      context: context,
      alignment: alignment,
      anchorAlignment: anchorAlignment,
      builder: builder,
      modal: modal,
      widthConstraint: widthConstraint,
      heightConstraint: heightConstraint,
      key: key,
      regionGroupId: regionGroupId,
      offset: offset,
      transitionAlignment: transitionAlignment,
      consumeOutsideTaps: consumeOutsideTaps,
      margin: margin,
      onTickFollow: onTickFollow,
      follow: follow,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
    );
    _openPopovers.remove(key);
    notifyListeners();
    return res;
  }

  void close([bool immediate = false]) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.close(immediate);
    }
    _openPopovers.clear();
    notifyListeners();
  }

  void closeLater() {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.closeLater();
    }
    _openPopovers.clear();
    notifyListeners();
  }

  set anchorContext(BuildContext value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.anchorContext = value;
    }
  }

  set alignment(Alignment value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.alignment = value;
    }
  }

  set anchorAlignment(Alignment value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.anchorAlignment = value;
    }
  }

  set widthConstraint(PopoverConstraint value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.widthConstraint = value;
    }
  }

  set heightConstraint(PopoverConstraint value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.heightConstraint = value;
    }
  }

  set margin(EdgeInsets value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.margin = value;
    }
  }

  set follow(bool value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.follow = value;
    }
  }

  set offset(Offset? value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.offset = value;
    }
  }

  set allowInvertHorizontal(bool value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.allowInvertHorizontal = value;
    }
  }

  set allowInvertVertical(bool value) {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.allowInvertVertical = value;
    }
  }

  void disposePopovers() {
    for (GlobalKey<PopoverAnchorState> key in _openPopovers) {
      key.currentState?.closeLater();
    }
  }

  @override
  void dispose() {
    disposePopovers();
    super.dispose();
  }
}

class PopoverLayout extends SingleChildRenderObjectWidget {
  final Alignment alignment;
  final Alignment anchorAlignment;
  final Offset position;
  final Size? anchorSize;
  final PopoverConstraint widthConstraint;
  final PopoverConstraint heightConstraint;
  final Offset? offset;
  final EdgeInsets margin;
  final double scale;
  final Alignment scaleAlignment;
  final FilterQuality? filterQuality;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;
  const PopoverLayout({
    Key? key,
    required this.alignment,
    required this.position,
    required this.anchorAlignment,
    required this.widthConstraint,
    required this.heightConstraint,
    this.anchorSize,
    this.offset,
    this.margin = const EdgeInsets.all(8),
    required Widget child,
    required this.scale,
    required this.scaleAlignment,
    this.filterQuality,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PopoverLayoutRender(
      alignment: alignment,
      position: position,
      anchorAlignment: anchorAlignment,
      widthConstraint: widthConstraint,
      heightConstraint: heightConstraint,
      anchorSize: anchorSize,
      offset: offset,
      margin: margin,
      scale: scale,
      scaleAlignment: scaleAlignment,
      filterQuality: filterQuality,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant PopoverLayoutRender renderObject) {
    bool hasChanged = false;
    if (renderObject._alignment != alignment) {
      renderObject._alignment = alignment;
      hasChanged = true;
    }
    if (renderObject._position != position) {
      renderObject._position = position;
      hasChanged = true;
    }
    if (renderObject._anchorAlignment != anchorAlignment) {
      renderObject._anchorAlignment = anchorAlignment;
      hasChanged = true;
    }
    if (renderObject._widthConstraint != widthConstraint) {
      renderObject._widthConstraint = widthConstraint;
      hasChanged = true;
    }
    if (renderObject._heightConstraint != heightConstraint) {
      renderObject._heightConstraint = heightConstraint;
      hasChanged = true;
    }
    if (renderObject._anchorSize != anchorSize) {
      renderObject._anchorSize = anchorSize;
      hasChanged = true;
    }
    if (renderObject._offset != offset) {
      renderObject._offset = offset;
      hasChanged = true;
    }
    if (renderObject._margin != margin) {
      renderObject._margin = margin;
      hasChanged = true;
    }
    if (renderObject._scale != scale) {
      renderObject._scale = scale;
      hasChanged = true;
    }
    if (renderObject._scaleAlignment != scaleAlignment) {
      renderObject._scaleAlignment = scaleAlignment;
      hasChanged = true;
    }
    if (renderObject._filterQuality != filterQuality) {
      renderObject._filterQuality = filterQuality;
      hasChanged = true;
    }
    if (renderObject._allowInvertHorizontal != allowInvertHorizontal) {
      renderObject._allowInvertHorizontal = allowInvertHorizontal;
      hasChanged = true;
    }
    if (renderObject._allowInvertVertical != allowInvertVertical) {
      renderObject._allowInvertVertical = allowInvertVertical;
      hasChanged = true;
    }
    if (hasChanged) {
      renderObject.markNeedsLayout();
    }
  }
}

class PopoverLayoutRender extends RenderShiftedBox {
  Alignment _alignment;
  Alignment _anchorAlignment;
  Offset _position;
  Size? _anchorSize;
  PopoverConstraint _widthConstraint;
  PopoverConstraint _heightConstraint;
  Offset? _offset;
  EdgeInsets _margin;
  double _scale;
  Alignment _scaleAlignment;
  FilterQuality? _filterQuality;
  bool _allowInvertHorizontal;
  bool _allowInvertVertical;

  bool _invertX = false;
  bool _invertY = false;

  PopoverLayoutRender({
    RenderBox? child,
    required Alignment alignment,
    required Offset position,
    required Alignment anchorAlignment,
    required PopoverConstraint widthConstraint,
    required PopoverConstraint heightConstraint,
    Size? anchorSize,
    Offset? offset,
    EdgeInsets margin = const EdgeInsets.all(8),
    required double scale,
    required Alignment scaleAlignment,
    FilterQuality? filterQuality,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
  })  : _alignment = alignment,
        _position = position,
        _anchorAlignment = anchorAlignment,
        _widthConstraint = widthConstraint,
        _heightConstraint = heightConstraint,
        _anchorSize = anchorSize,
        _offset = offset,
        _margin = margin,
        _scale = scale,
        _scaleAlignment = scaleAlignment,
        _filterQuality = filterQuality,
        _allowInvertHorizontal = allowInvertHorizontal,
        _allowInvertVertical = allowInvertVertical,
        super(child);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  Matrix4 get _effectiveTransform {
    Size childSize = child!.size;
    Offset childOffset = (child!.parentData as BoxParentData).offset;
    var scaleAlignment = _scaleAlignment;
    if (_invertX || _invertY) {
      scaleAlignment = Alignment(
        _invertX ? -scaleAlignment.x : scaleAlignment.x,
        _invertY ? -scaleAlignment.y : scaleAlignment.y,
      );
    }
    Matrix4 transform = Matrix4.identity();
    Offset alignmentTranslation = scaleAlignment.alongSize(childSize);
    transform.translate(childOffset.dx, childOffset.dy);
    transform.translate(alignmentTranslation.dx, alignmentTranslation.dy);
    transform.scale(_scale, _scale);
    transform.translate(-alignmentTranslation.dx, -alignmentTranslation.dy);
    transform.translate(-childOffset.dx, -childOffset.dy);
    return transform;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _effectiveTransform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    Matrix4 effectiveTransform = _effectiveTransform;
    transform.multiply(effectiveTransform);
    super.applyPaintTransform(child, transform);
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _filterQuality != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Matrix4 transform = _effectiveTransform;
      if (_filterQuality == null) {
        final Offset? childOffset = MatrixUtils.getAsTranslation(transform);
        if (childOffset == null) {
          final double det = transform.determinant();
          if (det == 0 || !det.isFinite) {
            layer = null;
            return;
          }
          layer = context.pushTransform(
            needsCompositing,
            offset,
            transform,
            super.paint,
            oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
          );
        } else {
          super.paint(context, offset + childOffset);
          layer = null;
        }
      } else {
        final Matrix4 effectiveTransform =
            Matrix4.translationValues(offset.dx, offset.dy, 0.0)
              ..multiply(transform)
              ..translate(-offset.dx, -offset.dy);
        final ui.ImageFilter filter = ui.ImageFilter.matrix(
          effectiveTransform.storage,
          filterQuality: _filterQuality!,
        );
        if (layer is ImageFilterLayer) {
          final ImageFilterLayer filterLayer = layer! as ImageFilterLayer;
          filterLayer.imageFilter = filter;
        } else {
          layer = ImageFilterLayer(imageFilter: filter);
        }
        context.pushLayer(layer!, super.paint, offset);
        assert(() {
          layer!.debugCreator = debugCreator;
          return true;
        }());
      }
    }
  }

  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.biggest;
    Size childSize = child!.size;
    double offsetX = _offset?.dx ?? 0;
    double offsetY = _offset?.dy ?? 0;
    double x = _position.dx -
        childSize.width / 2 -
        (childSize.width / 2 * _alignment.x);
    double y = _position.dy -
        childSize.height / 2 -
        (childSize.height / 2 * _alignment.y);
    double left = x - _margin.left;
    double top = y - _margin.top;
    double right = x + childSize.width + _margin.right;
    double bottom = y + childSize.height + _margin.bottom;
    if ((left < 0 || right > size.width) && _allowInvertHorizontal) {
      x = _position.dx -
          childSize.width / 2 -
          (childSize.width / 2 * -_alignment.x);
      if (_anchorSize != null) {
        x -= _anchorSize!.width * _anchorAlignment.x;
      }
      left = x - _margin.left;
      right = x + childSize.width + _margin.right;
      offsetX *= -1;
      _invertX = true;
    } else {
      _invertX = false;
    }
    if ((top < 0 || bottom > size.height) && _allowInvertVertical) {
      y = _position.dy -
          childSize.height / 2 -
          (childSize.height / 2 * -_alignment.y);
      if (_anchorSize != null) {
        y -= _anchorSize!.height * _anchorAlignment.y;
      }
      top = y - _margin.top;
      bottom = y + childSize.height + _margin.bottom;
      offsetY *= -1;
      _invertY = true;
    } else {
      _invertY = false;
    }
    final double dx = left < 0
        ? -left
        : right > size.width
            ? size.width - right
            : 0;
    final double dy = top < 0
        ? -top
        : bottom > size.height
            ? size.height - bottom
            : 0;
    Offset result = Offset(x + dx + offsetX, y + dy + offsetY);
    BoxParentData childParentData = child!.parentData as BoxParentData;
    childParentData.offset = result;
  }
}