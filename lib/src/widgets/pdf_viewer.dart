// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/extension.dart';
import 'package:vector_math/vector_math_64.dart' as vec;

import '../../pdfrx.dart';
import '../utils/platform.dart';
import 'interactive_viewer.dart' as iv;
import 'pdf_error_widget.dart';
import 'pdf_page_links_overlay.dart';

/// A widget to display PDF document.
///
/// To create a [PdfViewer] widget, use one of the following constructors:
/// - [PdfDocument] with [PdfViewer.documentRef]
/// - [PdfViewer.asset] with an asset name
/// - [PdfViewer.file] with a file path
/// - [PdfViewer.uri] with a URI
///
/// Or otherwise, you can pass [PdfDocumentRef] to [PdfViewer] constructor.
class PdfViewer extends StatefulWidget {
  /// Create [PdfViewer] from a [PdfDocumentRef].
  ///
  /// [documentRef] is the [PdfDocumentRef].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  const PdfViewer(
    this.documentRef, {
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
  });

  /// Create [PdfViewer] from an asset.
  ///
  /// [assetName] is the asset name.
  /// [passwordProvider] is used to provide password for encrypted PDF. See [PdfPasswordProvider] for more info.
  /// [firstAttemptByEmptyPassword] is used to determine whether the first attempt to open the PDF is by empty password
  /// or not. For more info, see [PdfPasswordProvider].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  PdfViewer.asset(
    String assetName, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
  }) : documentRef = PdfDocumentRefAsset(
         assetName,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
       );

  /// Create [PdfViewer] from a file.
  ///
  /// [path] is the file path.
  /// [passwordProvider] is used to provide password for encrypted PDF. See [PdfPasswordProvider] for more info.
  /// [firstAttemptByEmptyPassword] is used to determine whether the first attempt to open the PDF is by empty password
  /// or not. For more info, see [PdfPasswordProvider].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  PdfViewer.file(
    String path, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
  }) : documentRef = PdfDocumentRefFile(
         path,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
       );

  /// Create [PdfViewer] from a URI.
  ///
  /// [uri] is the URI.
  /// [passwordProvider] is used to provide password for encrypted PDF. See [PdfPasswordProvider] for more info.
  /// [firstAttemptByEmptyPassword] is used to determine whether the first attempt to open the PDF is by empty password
  /// or not. For more info, see [PdfPasswordProvider].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  /// [preferRangeAccess] to prefer range access to download the PDF. The default is false. (Not supported on Web).
  /// [headers] is used to specify additional HTTP headers especially for authentication/authorization.
  /// [withCredentials] is used to specify whether to include credentials in the request (Only supported on Web).
  PdfViewer.uri(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
    bool preferRangeAccess = false,
    Map<String, String>? headers,
    bool withCredentials = false,
  }) : documentRef = PdfDocumentRefUri(
         uri,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
         preferRangeAccess: preferRangeAccess,
         headers: headers,
         withCredentials: withCredentials,
       );

  /// Create [PdfViewer] from a byte data.
  ///
  /// [data] is the byte data.
  /// [sourceName] must be some ID, e.g., file name or URL, to identify the source of the PDF. If [sourceName] is not
  /// unique for each source, the viewer may not work correctly.
  /// [passwordProvider] is used to provide password for encrypted PDF. See [PdfPasswordProvider] for more info.
  /// [firstAttemptByEmptyPassword] is used to determine whether the first attempt to open the PDF is by empty password
  /// or not. For more info, see [PdfPasswordProvider].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  PdfViewer.data(
    Uint8List data, {
    required String sourceName,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
  }) : documentRef = PdfDocumentRefData(
         data,
         sourceName: sourceName,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
       );

  /// Create [PdfViewer] from a custom source.
  ///
  /// [fileSize] is the size of the PDF file.
  /// [read] is the function to read the PDF file.
  /// [sourceName] must be some ID, e.g., file name or URL, to identify the source of the PDF. If [sourceName] is not
  /// unique for each source, the viewer may not work correctly.
  /// [passwordProvider] is used to provide password for encrypted PDF. See [PdfPasswordProvider] for more info.
  /// [firstAttemptByEmptyPassword] is used to determine whether the first attempt to open the PDF is by empty password
  /// or not. For more info, see [PdfPasswordProvider].
  /// [controller] is the controller to control the viewer.
  /// [params] is the parameters to customize the viewer.
  /// [initialPageNumber] is the page number to show initially.
  PdfViewer.custom({
    required int fileSize,
    required FutureOr<int> Function(Uint8List buffer, int position, int size) read,
    required String sourceName,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    super.key,
    this.controller,
    this.params = const PdfViewerParams(),
    this.initialPageNumber = 1,
  }) : documentRef = PdfDocumentRefCustom(
         fileSize: fileSize,
         read: read,
         sourceName: sourceName,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
       );

  /// [PdfDocumentRef] that represents the PDF document.
  final PdfDocumentRef documentRef;

  /// Controller to control the viewer.
  final PdfViewerController? controller;

  /// Parameters to customize the display of the PDF document.
  final PdfViewerParams params;

  /// Page number to show initially.
  final int initialPageNumber;

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> with SingleTickerProviderStateMixin implements PdfTextSelectionDelegate {
  PdfViewerController? _controller;
  late final _txController = _PdfViewerTransformationController(this);
  late final AnimationController _animController;
  Animation<Matrix4>? _animGoTo;
  int _animationResettingGuard = 0;

  PdfDocument? _document;
  PdfPageLayout? _layout;
  Size? _viewSize;
  double? _coverScale;
  double? _alternativeFitScale;
  static const _defaultMinScale = 0.1;
  double _minScale = _defaultMinScale;
  int? _pageNumber;
  bool _initialized = false;
  StreamSubscription<PdfDocumentEvent>? _documentSubscription;

  final List<double> _zoomStops = [1.0];

  final _imageCache = _PdfPageImageCache();
  final _magnifierImageCache = _PdfPageImageCache();

  late final _canvasLinkPainter = _CanvasLinkPainter(this);

  // Changes to the stream rebuilds the viewer
  final _updateStream = BehaviorSubject<Matrix4>();

  final _textCache = <int, PdfPageText?>{};
  final _textSelection = SplayTreeMap<int, PdfPageTextRange>();
  Timer? _textSelectionChangedThrottleTimer;
  final double _hitTestMargin = 3.0;

  /// The starting/ending point of the text selection.
  _TextSelectionPoint? _selA, _selB;
  Offset? _textSelectAnchor;

  /// [_textSelA] is the rectangle of the first character in the selected paragraph and
  PdfTextSelectionAnchor? _textSelA;

  /// [_textSelB] is the rectangle of the last character in the selected paragraph.
  PdfTextSelectionAnchor? _textSelB;

  _TextSelectionPartMoving _selPartMoving = _TextSelectionPartMoving.none;

  Offset? _showTextSelectionContextMenuAt;

  Timer? _interactionEndedTimer;
  bool _isInteractionGoingOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _widgetUpdated(null);
  }

  @override
  void didUpdateWidget(covariant PdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _widgetUpdated(oldWidget);
  }

  Future<void> _widgetUpdated(PdfViewer? oldWidget) async {
    if (widget == oldWidget) {
      return;
    }

    if (oldWidget?.documentRef == widget.documentRef) {
      if (widget.params.doChangesRequireReload(oldWidget?.params)) {
        if (widget.params.annotationRenderingMode != oldWidget?.params.annotationRenderingMode) {
          _imageCache.releaseAllImages();
          _magnifierImageCache.releaseAllImages();
        }
      }
      return;
    } else {
      final oldListenable = oldWidget?.documentRef.resolveListenable();
      oldListenable?.removeListener(_onDocumentChanged);
      final listenable = widget.documentRef.resolveListenable();
      listenable.addListener(_onDocumentChanged);
      listenable.load();
    }

    _onDocumentChanged();
  }

  void _onDocumentChanged() async {
    _layout = null;
    _documentSubscription?.cancel();
    _documentSubscription = null;
    _textSelectionChangedThrottleTimer?.cancel();
    _stopInteraction();
    _imageCache.releaseAllImages();
    _magnifierImageCache.releaseAllImages();
    _canvasLinkPainter.resetAll();
    _textCache.clear();
    _clearTextSelections(invalidate: false);
    _pageNumber = null;
    _gotoTargetPageNumber = null;
    _initialized = false;
    _txController.removeListener(_onMatrixChanged);
    _controller?._attach(null);

    final document = widget.documentRef.resolveListenable().document;
    if (document == null) {
      _document = null;
      if (mounted) {
        setState(() {});
      }
      _notifyOnDocumentChanged();
      return;
    }

    _document = document;

    _controller ??= widget.controller ?? PdfViewerController();
    _controller!._attach(this);
    _txController.addListener(_onMatrixChanged);
    _documentSubscription = document.events.listen(_onDocumentEvent);

    if (mounted) {
      setState(() {});
    }

    _notifyOnDocumentChanged();
    _loadDelayed();
  }

  /// How long to wait before loading the trailing pages after the initial page load.
  ///
  /// This is to ensure that the initial page is displayed quickly, and the trailing pages are loaded in the background.
  static const _trailingPageLoadingDelay = Duration(milliseconds: kIsWeb ? 200 : 100);

  /// How long to wait before loading the page image.
  static const _pageImageCachingDelay = Duration(milliseconds: kIsWeb ? 100 : 20);
  static const _partialImageLoadingDelay = Duration(milliseconds: kIsWeb ? 200 : 50);

  Future<void> _loadDelayed() async {
    // To make the page image loading more smooth, delay the loading of pages
    await Future.delayed(_trailingPageLoadingDelay);

    final stopwatch = Stopwatch()..start();
    await _document?.loadPagesProgressively((pageNumber, totalPageCount, document) {
      if (document == _document && mounted) {
        debugPrint('PdfViewer: Loaded page $pageNumber of $totalPageCount in ${stopwatch.elapsedMilliseconds} ms');
        return true;
      }
      return false;
    }, data: _document);
  }

  void _notifyOnDocumentChanged() {
    if (widget.params.onDocumentChanged != null) {
      Future.microtask(() => widget.params.onDocumentChanged?.call(_document));
    }
  }

  @override
  void dispose() {
    _documentSubscription?.cancel();
    _textSelectionChangedThrottleTimer?.cancel();
    _interactionEndedTimer?.cancel();
    _imageCache.cancelAllPendingRenderings();
    _magnifierImageCache.cancelAllPendingRenderings();
    _animController.dispose();
    widget.documentRef.resolveListenable().removeListener(_onDocumentChanged);
    _imageCache.releaseAllImages();
    _magnifierImageCache.releaseAllImages();
    _canvasLinkPainter.resetAll();
    _txController.removeListener(_onMatrixChanged);
    _controller?._attach(null);
    _txController.dispose();
    super.dispose();
  }

  void _onMatrixChanged() => _invalidate();

  void _onDocumentEvent(PdfDocumentEvent event) {
    if (event is PdfDocumentPageStatusChangedEvent) {
      for (final page in event.pages) {
        _imageCache.removeCacheImagesForPage(page.pageNumber);
        _magnifierImageCache.removeCacheImagesForPage(page.pageNumber);
      }
      _invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.documentRef.resolveListenable();
    if (listenable.error != null) {
      return Container(
        color: widget.params.backgroundColor,
        child: (widget.params.errorBannerBuilder ?? _defaultErrorBannerBuilder)(
          context,
          listenable.error!,
          listenable.stackTrace,
          widget.documentRef,
        ),
      );
    }
    if (_document == null) {
      return Container(
        color: widget.params.backgroundColor,
        child: widget.params.loadingBannerBuilder?.call(context, listenable.bytesDownloaded, listenable.totalBytes),
      );
    }

    return Container(
      color: widget.params.backgroundColor,
      child: _PdfViewerKeyHandler(
        onKeyRepeat: _onKey,
        params: widget.params.keyHandlerParams,
        child: StreamBuilder(
          stream: _updateStream,
          builder: (context, snapshot) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCopyTextEnabled = _document!.permissions?.allowsCopying != false;
                final enableSwipeToSelectText =
                    widget.params.textSelectionParams?.textSelectionTriggeredBySwipe ??
                    shouldTextSelectionTriggeredBySwipe;
                final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
                _updateLayout(viewSize);
                return Stack(
                  children: [
                    iv.InteractiveViewer(
                      transformationController: _txController,
                      constrained: false,
                      boundaryMargin: widget.params.boundaryMargin ?? const EdgeInsets.all(double.infinity),
                      maxScale: widget.params.maxScale,
                      minScale: minScale,
                      panAxis: widget.params.panAxis,
                      panEnabled: widget.params.panEnabled,
                      scaleEnabled: widget.params.scaleEnabled,
                      onInteractionEnd: _onInteractionEnd,
                      onInteractionStart: _onInteractionStart,
                      onInteractionUpdate: widget.params.onInteractionUpdate,
                      interactionEndFrictionCoefficient: widget.params.interactionEndFrictionCoefficient,
                      onWheelDelta: widget.params.scrollByMouseWheel != null ? _onWheelDelta : null,
                      // PDF pages
                      child: MouseRegion(
                        cursor: SystemMouseCursors.move,
                        hitTestBehavior: HitTestBehavior.deferToChild,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.text,
                          hitTestBehavior: HitTestBehavior.deferToChild,
                          child: GestureDetector(
                            onTapDown: widget.params.textSelectionParams?.textTap ?? _textTap,
                            onDoubleTapDown: widget.params.textSelectionParams?.textDoubleTap ?? _textDoubleTap,
                            onLongPressStart: widget.params.textSelectionParams?.textLongPress ?? _textLongPress,
                            onSecondaryTapUp:
                                widget.params.textSelectionParams?.textSecondaryTapUp ?? _textSecondaryTapUp,
                            onPanStart: enableSwipeToSelectText ? _onTextPanStart : null,
                            onPanUpdate: enableSwipeToSelectText ? _onTextPanUpdate : null,
                            onPanEnd: enableSwipeToSelectText ? _onTextPanEnd : null,
                            child: CustomPaint(
                              foregroundPainter: _CustomPainter.fromFunctions(
                                _paintPages,
                                hitTestFunction: _hitTestForTextSelection,
                              ),
                              size: _layout!.documentSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_initialized) ..._buildPageOverlayWidgets(context),
                    if (_initialized && _canvasLinkPainter.isEnabled)
                      SelectionContainer.disabled(child: _canvasLinkPainter.linkHandlingOverlay(viewSize)),
                    if (_initialized && widget.params.viewerOverlayBuilder != null)
                      ...widget.params.viewerOverlayBuilder!(context, viewSize, _canvasLinkPainter._handleLinkTap).map(
                        (e) => SelectionContainer.disabled(child: e),
                      ),
                    if (_initialized) ..._placeTextSelectionWidgets(context, viewSize, isCopyTextEnabled),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _updateLayout(Size viewSize) {
    if (viewSize.height <= 0) return; // For fix blank pdf when restore window from minimize on Windows
    final currentPageNumber = _guessCurrentPageNumber();
    final oldSize = _viewSize;
    final isViewSizeChanged = oldSize != viewSize;
    _viewSize = viewSize;
    final isLayoutChanged = _relayoutPages();

    _calcCoverFitScale();
    _calcZoomStopTable();

    void callOnViewerSizeChanged() {
      if (isViewSizeChanged) {
        if (_controller != null && widget.params.onViewSizeChanged != null) {
          widget.params.onViewSizeChanged!(viewSize, oldSize, _controller!);
        }
      }
    }

    if (!_initialized && _layout != null && _coverScale != null && _alternativeFitScale != null) {
      _initialized = true;
      Future.microtask(() async {
        // forcibly calculate fit scale for the initial page
        _pageNumber = _gotoTargetPageNumber = _calcInitialPageNumber();
        _calcCoverFitScale();
        _calcZoomStopTable();
        final zoom =
            widget.params.calculateInitialZoom?.call(_document!, _controller!, _alternativeFitScale!, _coverScale!) ??
            _coverScale!;
        await _setZoom(Offset.zero, zoom, duration: Duration.zero);
        await _goToPage(pageNumber: _pageNumber!, duration: Duration.zero);
        if (mounted && _document != null && _controller != null) {
          widget.params.onViewerReady?.call(_document!, _controller!);
        }
        callOnViewerSizeChanged();
      });
    } else if (isLayoutChanged || isViewSizeChanged) {
      Future.microtask(() async {
        if (mounted) {
          await _goToPage(pageNumber: currentPageNumber ?? _calcInitialPageNumber());
          callOnViewerSizeChanged();
        }
      });
    } else if (currentPageNumber != null && _pageNumber != currentPageNumber) {
      _setCurrentPageNumber(currentPageNumber);
    }
  }

  int _calcInitialPageNumber() {
    return widget.params.calculateInitialPageNumber?.call(_document!, _controller!) ?? widget.initialPageNumber;
  }

  void _startInteraction() {
    _interactionEndedTimer?.cancel();
    _interactionEndedTimer = null;
    _isInteractionGoingOn = true;
  }

  void _stopInteraction() {
    _interactionEndedTimer?.cancel();
    if (!mounted) return;
    _interactionEndedTimer = Timer(const Duration(milliseconds: 300), () {
      _isInteractionGoingOn = false;
      _invalidate();
    });
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    widget.params.onInteractionEnd?.call(details);
    _stopInteraction();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _startInteraction();
    widget.params.onInteractionStart?.call(details);
  }

  /// Last page number that is explicitly requested to go to.
  int? _gotoTargetPageNumber;

  bool _onKey(PdfViewerKeyHandlerParams params, LogicalKeyboardKey key, bool isRealKeyPress) {
    final result = widget.params.onKey?.call(params, key, isRealKeyPress);
    if (result != null) {
      return result;
    }
    final duration = widget.params.keyHandlerParams.repeatInterval;
    switch (key) {
      case LogicalKeyboardKey.pageUp:
        _goToPage(pageNumber: (_gotoTargetPageNumber ?? _pageNumber!) - 1, duration: duration);
        return true;
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.space:
        _goToPage(pageNumber: (_gotoTargetPageNumber ?? _pageNumber!) + 1, duration: duration);
        return true;
      case LogicalKeyboardKey.home:
        _goToPage(pageNumber: 1, duration: duration);
        return true;
      case LogicalKeyboardKey.end:
        _goToPage(pageNumber: _document!.pages.length, anchor: widget.params.pageAnchorEnd, duration: duration);
        return true;
      case LogicalKeyboardKey.equal:
        if (isCommandKeyPressed) {
          _zoomUp(duration: duration);
          return true;
        }
      case LogicalKeyboardKey.minus:
        if (isCommandKeyPressed) {
          _zoomDown(duration: duration);
          return true;
        }
      case LogicalKeyboardKey.arrowDown:
        _goToManipulated((m) => m.translate(0.0, -widget.params.scrollByArrowKey));
        return true;
      case LogicalKeyboardKey.arrowUp:
        _goToManipulated((m) => m.translate(0.0, widget.params.scrollByArrowKey));
        return true;
      case LogicalKeyboardKey.arrowLeft:
        _goToManipulated((m) => m.translate(widget.params.scrollByArrowKey, 0.0));
        return true;
      case LogicalKeyboardKey.arrowRight:
        _goToManipulated((m) => m.translate(-widget.params.scrollByArrowKey, 0.0));
        return true;
      case LogicalKeyboardKey.keyA:
        if (isCommandKeyPressed) {
          selectAllText();
          return true;
        }
      case LogicalKeyboardKey.keyC:
        if (isCommandKeyPressed) {
          _copyTextSelection();
          return true;
        }
    }
    return false;
  }

  void _goToManipulated(void Function(Matrix4 m) manipulate) {
    final m = _txController.value.clone();
    manipulate(m);
    _txController.value = m;
  }

  Rect get _visibleRect => _txController.value.calcVisibleRect(_viewSize!);

  /// Set the current page number.
  ///
  /// Please note that the function does not scroll/zoom to the specified page but changes the current page number.
  void _setCurrentPageNumber(int? pageNumber, {bool doSetState = false}) {
    _gotoTargetPageNumber = pageNumber;
    if (pageNumber != null && _pageNumber != pageNumber) {
      _pageNumber = pageNumber;
      if (doSetState) {
        _invalidate();
      }
      if (widget.params.onPageChanged != null) {
        Future.microtask(() => widget.params.onPageChanged?.call(_pageNumber));
      }
    }
  }

  int? _guessCurrentPageNumber() {
    if (_layout == null || _viewSize == null) return null;
    if (widget.params.calculateCurrentPageNumber != null) {
      return widget.params.calculateCurrentPageNumber!(_visibleRect, _layout!.pageLayouts, _controller!);
    }

    final visibleRect = _visibleRect;
    double calcIntersectionArea(int pageNumber) {
      final rect = _layout!.pageLayouts[pageNumber - 1];
      final intersection = rect.intersect(visibleRect);
      if (intersection.isEmpty) return 0;
      final area = intersection.width * intersection.height;
      return area / (rect.width * rect.height);
    }

    if (_gotoTargetPageNumber != null &&
        _gotoTargetPageNumber! > 0 &&
        _gotoTargetPageNumber! <= _document!.pages.length) {
      final ratio = calcIntersectionArea(_gotoTargetPageNumber!);
      if (ratio > .2) return _gotoTargetPageNumber;
    }
    _gotoTargetPageNumber = null;

    int? pageNumber;
    double maxRatio = 0;
    for (int i = 1; i <= _document!.pages.length; i++) {
      final ratio = calcIntersectionArea(i);
      if (ratio == 0) continue;
      if (ratio > maxRatio) {
        maxRatio = ratio;
        pageNumber = i;
      }
    }
    return pageNumber;
  }

  /// Returns true if page layouts are changed.
  bool _relayoutPages() {
    if (_document == null) {
      _layout = null;
      return false;
    }
    final newLayout = (widget.params.layoutPages ?? _layoutPages)(_document!.pages, widget.params);
    if (_layout == newLayout) {
      return false;
    }

    _layout = newLayout;
    return true;
  }

  void _calcCoverFitScale() {
    if (_viewSize != null) {
      final s1 = _viewSize!.width / _layout!.documentSize.width;
      final s2 = _viewSize!.height / _layout!.documentSize.height;
      _coverScale = max(s1, s2);
    }
    final pageNumber = _pageNumber ?? _gotoTargetPageNumber;
    if (pageNumber != null) {
      final params = widget.params;
      final rect = _layout!.pageLayouts[pageNumber - 1];
      final m2 = params.margin * 2;
      _alternativeFitScale = min((_viewSize!.width - m2) / rect.width, (_viewSize!.height - m2) / rect.height);
      if (_alternativeFitScale! <= 0) {
        _alternativeFitScale = null;
      }
    } else {
      _alternativeFitScale = null;
    }
    if (_coverScale == null) {
      _minScale = _defaultMinScale;
      return;
    }
    _minScale =
        !widget.params.useAlternativeFitScaleAsMinScale
            ? widget.params.minScale
            : _alternativeFitScale == null
            ? _coverScale!
            : min(_coverScale!, _alternativeFitScale!);
  }

  void _calcZoomStopTable() {
    _zoomStops.clear();
    double z;
    if (_alternativeFitScale != null && !_areZoomsAlmostIdentical(_alternativeFitScale!, _coverScale!)) {
      if (_alternativeFitScale! < _coverScale!) {
        _zoomStops.add(_alternativeFitScale!);
        z = _coverScale!;
      } else {
        _zoomStops.add(_coverScale!);
        z = _alternativeFitScale!;
      }
    } else {
      z = _coverScale!;
    }
    // in some case, z may be 0 and it causes infinite loop.
    if (z < 1 / 128) {
      _zoomStops.add(1.0);
      return;
    }
    while (z < widget.params.maxScale) {
      _zoomStops.add(z);
      z *= 2;
    }
    if (!_areZoomsAlmostIdentical(z, widget.params.maxScale)) {
      _zoomStops.add(widget.params.maxScale);
    }

    if (!widget.params.useAlternativeFitScaleAsMinScale) {
      z = _zoomStops.first;
      while (z > widget.params.minScale) {
        z /= 2;
        _zoomStops.insert(0, z);
      }
      if (!_areZoomsAlmostIdentical(z, widget.params.minScale)) {
        _zoomStops.insert(0, widget.params.minScale);
      }
    }
  }

  double _findNextZoomStop(double zoom, {required bool zoomUp, bool loop = true}) {
    if (zoomUp) {
      for (final z in _zoomStops) {
        if (z > zoom && !_areZoomsAlmostIdentical(z, zoom)) return z;
      }
      if (loop) {
        return _zoomStops.first;
      } else {
        return _zoomStops.last;
      }
    } else {
      for (int i = _zoomStops.length - 1; i >= 0; i--) {
        final z = _zoomStops[i];
        if (z < zoom && !_areZoomsAlmostIdentical(z, zoom)) return z;
      }
      if (loop) {
        return _zoomStops.last;
      } else {
        return _zoomStops.first;
      }
    }
  }

  static bool _areZoomsAlmostIdentical(double z1, double z2) => (z1 - z2).abs() < 0.01;

  List<Widget> _buildPageOverlayWidgets(BuildContext context) {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return [];

    final linkWidgets = <Widget>[];
    final overlayWidgets = <Widget>[];
    final targetRect = _getCacheExtentRect();

    for (int i = 0; i < _document!.pages.length; i++) {
      final rect = _layout!.pageLayouts[i];
      final intersection = rect.intersect(targetRect);
      if (intersection.isEmpty) continue;

      final page = _document!.pages[i];
      final rectExternal = _documentToRenderBox(rect, renderBox);
      if (rectExternal != null) {
        if (widget.params.linkHandlerParams == null && widget.params.linkWidgetBuilder != null) {
          linkWidgets.add(
            SelectionContainer.disabled(
              child: PdfPageLinksOverlay(
                key: Key('#__pageLinks__:${page.pageNumber}'),
                page: page,
                pageRect: rectExternal,
                params: widget.params,
                // FIXME: workaround for link widget eats wheel events.
                wrapperBuilder:
                    (child) => Listener(
                      child: child,
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          _onWheelDelta(event);
                        }
                      },
                    ),
              ),
            ),
          );
        }

        final overlay = widget.params.pageOverlaysBuilder?.call(context, rectExternal, page);
        if (overlay != null && overlay.isNotEmpty) {
          overlayWidgets.add(
            Positioned(
              key: Key('#__pageOverlay__:${page.pageNumber}'),
              left: rectExternal.left,
              top: rectExternal.top,
              width: rectExternal.width,
              height: rectExternal.height,
              child: SelectionContainer.disabled(child: Stack(children: overlay)),
            ),
          );
        }
      }
    }

    return [...linkWidgets, ...overlayWidgets];
  }

  void _onSelectionChange() {
    _textSelectionChangedThrottleTimer?.cancel();
    _textSelectionChangedThrottleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.params.textSelectionParams?.onTextSelectionChange?.call(this);
    });
  }

  Rect _getCacheExtentRect() {
    final visibleRect = _visibleRect;
    return visibleRect.inflateHV(
      horizontal: visibleRect.width * widget.params.horizontalCacheExtent,
      vertical: visibleRect.height * widget.params.verticalCacheExtent,
    );
  }

  Rect? _documentToRenderBox(Rect rect, RenderBox renderBox) {
    final tl = _documentToGlobal(rect.topLeft);
    if (tl == null) return null;
    final br = _documentToGlobal(rect.bottomRight);
    if (br == null) return null;
    return Rect.fromPoints(renderBox.globalToLocal(tl), renderBox.globalToLocal(br));
  }

  /// [_CustomPainter] calls the function to paint PDF pages.
  void _paintPages(ui.Canvas canvas, ui.Size size) {
    if (!_initialized) return;
    _paintPagesCustom(
      canvas,
      cache: _imageCache,
      maxImageCacheBytes: widget.params.maxImageBytesCachedOnMemory,
      targetRect: _getCacheExtentRect(),
      resolutionMultiplier: MediaQuery.of(context).devicePixelRatio,
      filterQuality: FilterQuality.low,
    );
  }

  void _paintPagesCustom(
    ui.Canvas canvas, {
    required _PdfPageImageCache cache,
    required int maxImageCacheBytes,
    required Rect targetRect,
    double resolutionMultiplier = 1.0,
    bool previewEnabled = true,
    FilterQuality filterQuality = FilterQuality.high,
  }) {
    final scale = _currentZoom * resolutionMultiplier;
    final unusedPageList = <int>[];
    final dropShadowPaint = widget.params.pageDropShadow?.toPaint()?..style = PaintingStyle.fill;

    for (int i = 0; i < _document!.pages.length; i++) {
      final rect = _layout!.pageLayouts[i];
      final intersection = rect.intersect(targetRect);
      if (intersection.isEmpty) {
        final page = _document!.pages[i];
        cache.cancelPendingRenderings(page.pageNumber);
        if (cache.pageImages.containsKey(i + 1)) {
          unusedPageList.add(i + 1);
        }
        continue;
      }

      final page = _document!.pages[i];
      final previewImage = cache.pageImages[page.pageNumber];
      final partial = cache.pageImagesPartial[page.pageNumber];

      final previewScaleLimit =
          widget.params.getPageRenderingScale?.call(
            context,
            page,
            _controller!,
            widget.params.onePassRenderingScaleThreshold,
          ) ??
          widget.params.onePassRenderingScaleThreshold;

      if (dropShadowPaint != null) {
        final offset = widget.params.pageDropShadow!.offset;
        final spread = widget.params.pageDropShadow!.spreadRadius;
        final shadowRect = rect.translate(offset.dx, offset.dy).inflateHV(horizontal: spread, vertical: spread);
        canvas.drawRect(shadowRect, dropShadowPaint);
      }

      if (widget.params.pageBackgroundPaintCallbacks != null) {
        for (final callback in widget.params.pageBackgroundPaintCallbacks!) {
          callback(canvas, rect, page);
        }
      }

      if (previewEnabled && previewImage != null) {
        canvas.drawImageRect(
          previewImage.image,
          Rect.fromLTWH(0, 0, previewImage.image.width.toDouble(), previewImage.image.height.toDouble()),
          rect,
          Paint()..filterQuality = filterQuality,
        );
      } else {
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }

      if (previewEnabled && (previewImage == null || previewImage.scale != previewScaleLimit)) {
        _requestPagePreviewImageCached(cache, page, previewScaleLimit);
      }

      final pageScale = scale * max(rect.width / page.width, rect.height / page.height);
      if (pageScale > previewScaleLimit) {
        _requestRealSizePartialImage(cache, page, pageScale);
      }

      if (pageScale > previewScaleLimit && partial != null) {
        canvas.drawImageRect(
          partial.image,
          Rect.fromLTWH(0, 0, partial.image.width.toDouble(), partial.image.height.toDouble()),
          partial.rect,
          Paint()..filterQuality = filterQuality,
        );
      }

      final selectionColor =
          Theme.of(context).textSelectionTheme.selectionColor ?? DefaultSelectionStyle.of(context).selectionColor!;
      final text = _getCachedTextOrDelayLoadText(page.pageNumber);
      if (text != null) {
        final selectionInPage = _textSelection[page.pageNumber];
        if (selectionInPage != null) {
          for (final r in selectionInPage.enumerateFragmentBoundingRects()) {
            canvas.drawRect(
              r.bounds.toRectInDocument(page: page, pageRect: rect),
              Paint()
                ..color = selectionColor
                ..style = PaintingStyle.fill,
            );
          }
        }
        if (widget.params.debugShowTextFragments) {
          final paint = Paint()
            ..color = Colors.red.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          for (final fragment in text.fragments) {
            canvas.drawRect(
              fragment.bounds.toRectInDocument(page: page, pageRect: rect),
              paint,
            );
          }
        }
      }

      if (_canvasLinkPainter.isEnabled) {
        _canvasLinkPainter.paintLinkHighlights(canvas, rect, page);
      }

      if (widget.params.pagePaintCallbacks != null) {
        for (final callback in widget.params.pagePaintCallbacks!) {
          callback(canvas, rect, page);
        }
      }

      if (unusedPageList.isNotEmpty) {
        final currentPageNumber = _pageNumber;
        if (currentPageNumber != null && currentPageNumber > 0) {
          final currentPage = _document!.pages[currentPageNumber - 1];
          cache.removeCacheImagesIfCacheBytesExceedsLimit(
            unusedPageList,
            maxImageCacheBytes,
            currentPage,
            dist:
                (pageNumber) =>
                    (_layout!.pageLayouts[pageNumber - 1].center -
                            _layout!.pageLayouts[currentPage.pageNumber - 1].center)
                        .distanceSquared,
          );
        }
      }
    }
  }

  /// Loads text for the specified page number.
  ///
  /// If the text is not loaded yet, it will be loaded asynchronously
  /// and [onTextLoaded] callback will be called when the text is loaded.
  /// If [onTextLoaded] is not provided and [invalidate] is true, the widget will be rebuilt when the text is loaded.
  PdfPageText? _getCachedTextOrDelayLoadText(int pageNumber, {void Function()? onTextLoaded, bool invalidate = true}) {
    if (_textCache.containsKey(pageNumber)) return _textCache[pageNumber];
    if (onTextLoaded == null && invalidate) {
      onTextLoaded = () {
        if (mounted) {
          setState(() {});
        }
      };
    }
    _loadTextAsync(pageNumber, onTextLoaded: onTextLoaded);
    return null;
  }

  Future<PdfPageText> _loadTextAsync(int pageNumber, {void Function()? onTextLoaded}) async {
    if (_textCache.containsKey(pageNumber)) return _textCache[pageNumber]!;
    return await synchronized(() async {
      if (_textCache.containsKey(pageNumber)) return _textCache[pageNumber]!;
      final page = _document!.pages[pageNumber - 1];
      final text = await page.loadText();
      _textCache[pageNumber] = text;
      if (onTextLoaded != null) {
        onTextLoaded();
      }
      return text;
    });
  }

  bool _hitTestForTextSelection(ui.Offset position) {
    for (int i = 0; i < _document!.pages.length; i++) {
      final pageRect = _layout!.pageLayouts[i];
      if (!pageRect.contains(position)) continue;
      final page = _document!.pages[i];
      final text = _getCachedTextOrDelayLoadText(
        page.pageNumber,
        invalidate: false,
      ); // the routine may be called multiple times, we can ignore the chance
      if (text == null) continue;
      for (final f in text.fragments) {
        final rect = f.bounds.toRectInDocument(page: page, pageRect: pageRect).inflate(_hitTestMargin);
        if (rect.contains(position)) {
          return true;
        }
      }
    }
    return false;
  }

  PdfPageLayout _layoutPages(List<PdfPage> pages, PdfViewerParams params) {
    final width = pages.fold(0.0, (w, p) => max(w, p.width)) + params.margin * 2;

    final pageLayout = <Rect>[];
    var y = params.margin;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final rect = Rect.fromLTWH((width - page.width) / 2, y, page.width, page.height);
      pageLayout.add(rect);
      y += page.height + params.margin;
    }

    return PdfPageLayout(pageLayouts: pageLayout, documentSize: Size(width, y));
  }

  void _invalidate() => _updateStream.add(_txController.value);

  Future<void> _requestPagePreviewImageCached(_PdfPageImageCache cache, PdfPage page, double scale) async {
    final width = page.width * scale;
    final height = page.height * scale;
    if (width < 1 || height < 1) return;

    // if this is the first time to render the page, render it immediately
    if (!cache.pageImages.containsKey(page.pageNumber)) {
      _cachePagePreviewImage(cache, page, width, height, scale);
      return;
    }

    cache.pageImageRenderingTimers[page.pageNumber]?.cancel();
    if (!mounted) return;
    cache.pageImageRenderingTimers[page.pageNumber] = Timer(
      _pageImageCachingDelay,
      () => _cachePagePreviewImage(cache, page, width, height, scale),
    );
  }

  Future<void> _cachePagePreviewImage(
    _PdfPageImageCache cache,
    PdfPage page,
    double width,
    double height,
    double scale,
  ) async {
    if (!mounted) return;
    if (cache.pageImages[page.pageNumber]?.scale == scale) return;
    final cancellationToken = page.createCancellationToken();

    cache.addCancellationToken(page.pageNumber, cancellationToken);
    await synchronized(() async {
      if (!mounted || cancellationToken.isCanceled) return;
      if (cache.pageImages[page.pageNumber]?.scale == scale) return;
      final img = await page.render(
        fullWidth: width,
        fullHeight: height,
        backgroundColor: Colors.white,
        annotationRenderingMode: widget.params.annotationRenderingMode,
        flags: widget.params.limitRenderingCache ? PdfPageRenderFlags.limitedImageCache : PdfPageRenderFlags.none,
        cancellationToken: cancellationToken,
      );
      if (img == null) return;
      if (!mounted || cancellationToken.isCanceled) {
        img.dispose();
        return;
      }
      final newImage = _PdfImageWithScale(await img.createImage(), scale);
      if (!mounted || cancellationToken.isCanceled) {
        img.dispose();
        newImage.dispose();
        return;
      }
      cache.pageImages[page.pageNumber]?.dispose();
      cache.pageImages[page.pageNumber] = newImage;
      img.dispose();
      _invalidate();
    });
  }

  Future<void> _requestRealSizePartialImage(_PdfPageImageCache cache, PdfPage page, double scale) async {
    cache.pageImagePartialRenderingRequests[page.pageNumber]?.cancel();
    final cancellationToken = page.createCancellationToken();
    cache.pageImagePartialRenderingRequests[page.pageNumber] = _PdfPartialImageRenderingRequest(
      Timer(_partialImageLoadingDelay, () async {
        if (!mounted || cancellationToken.isCanceled) return;
        final newImage = await _createRealSizePartialImage(cache, page, scale, cancellationToken);
        if (cache.pageImagesPartial[page.pageNumber] == newImage) return;
        cache.pageImagesPartial.remove(page.pageNumber)?.dispose();
        if (newImage != null) {
          cache.pageImagesPartial[page.pageNumber] = newImage;
        }
        _invalidate();
      }),
      cancellationToken,
    );
  }

  Future<_PdfImageWithScaleAndRect?> _createRealSizePartialImage(
    _PdfPageImageCache cache,
    PdfPage page,
    double scale,
    PdfPageRenderCancellationToken cancellationToken,
  ) async {
    final pageRect = _layout!.pageLayouts[page.pageNumber - 1];
    final rect = pageRect.intersect(_visibleRect);
    final prev = cache.pageImagesPartial[page.pageNumber];
    if (prev?.rect == rect && prev?.scale == scale) return prev;
    if (rect.width < 1 || rect.height < 1) return null;
    final inPageRect = rect.translate(-pageRect.left, -pageRect.top);

    if (!mounted || cancellationToken.isCanceled) return null;

    final img = await page.render(
      x: (inPageRect.left * scale).toInt(),
      y: (inPageRect.top * scale).toInt(),
      width: (inPageRect.width * scale).toInt(),
      height: (inPageRect.height * scale).toInt(),
      fullWidth: pageRect.width * scale,
      fullHeight: pageRect.height * scale,
      backgroundColor: Colors.white,
      annotationRenderingMode: widget.params.annotationRenderingMode,
      flags: widget.params.limitRenderingCache ? PdfPageRenderFlags.limitedImageCache : PdfPageRenderFlags.none,
      cancellationToken: cancellationToken,
    );
    if (img == null) return null;
    if (!mounted || cancellationToken.isCanceled) {
      img.dispose();
      return null;
    }
    final result = _PdfImageWithScaleAndRect(await img.createImage(), scale, rect);
    img.dispose();
    return result;
  }

  void _onWheelDelta(PointerScrollEvent event) {
    _startInteraction();
    final m = _txController.value.clone();
    final dx = -event.scrollDelta.dx * widget.params.scrollByMouseWheel!;
    final dy = -event.scrollDelta.dy * widget.params.scrollByMouseWheel!;
    if (widget.params.scrollHorizontallyByMouseWheel) {
      m.translate(dy, dx);
    } else {
      m.translate(dx, dy);
    }
    _txController.value = m;
    _stopInteraction();
  }

  /// Restrict matrix to the safe range.
  Matrix4 _makeMatrixInSafeRange(Matrix4 newValue) {
    if (widget.params.normalizeMatrix != null) {
      return widget.params.normalizeMatrix!(newValue, _viewSize!, _layout!, _controller);
    }
    return _normalizeMatrix(newValue);
  }

  Matrix4 _normalizeMatrix(Matrix4 newValue) {
    final layout = _layout;
    final viewSize = _viewSize;
    if (layout == null || viewSize == null) return newValue;
    final position = newValue.calcPosition(viewSize);
    final newZoom = max(newValue.zoom, minScale);
    final hw = viewSize.width / 2 / newZoom;
    final hh = viewSize.height / 2 / newZoom;
    final x = position.dx.range(hw, layout.documentSize.width - hw);
    final y = position.dy.range(hh, layout.documentSize.height - hh);

    return _calcMatrixFor(Offset(x, y), zoom: newZoom, viewSize: viewSize).scaled(1.0, 1.0, newZoom);
  }

  /// Calculate matrix to center the specified position.
  Matrix4 _calcMatrixFor(Offset position, {required double zoom, required Size viewSize}) {
    final hw = viewSize.width / 2;
    final hh = viewSize.height / 2;
    return Matrix4.compose(
      vec.Vector3(-position.dx * zoom + hw, -position.dy * zoom + hh, 0),
      vec.Quaternion.identity(),
      vec.Vector3(zoom, zoom, 1),
    );
  }

  /// The minimum zoom ratio allowed.
  double get minScale => _minScale;

  Matrix4 _calcMatrixForRect(Rect rect, {double? zoomMax, double? margin}) {
    margin ??= 0;
    var zoom = min((_viewSize!.width - margin * 2) / rect.width, (_viewSize!.height - margin * 2) / rect.height);
    if (zoomMax != null && zoom > zoomMax) zoom = zoomMax;
    return _calcMatrixFor(rect.center, zoom: zoom, viewSize: _viewSize!);
  }

  Matrix4 _calcMatrixForArea({required Rect rect, double? zoomMax, double? margin, PdfPageAnchor? anchor}) =>
      _calcMatrixForRect(
        _calcRectForArea(rect: rect, anchor: anchor ?? widget.params.pageAnchor),
        zoomMax: zoomMax,
        margin: margin,
      );

  /// The function calculate the rectangle which should be shown in the view.
  ///
  /// If the rect is smaller than the view size, it will
  Rect _calcRectForArea({required Rect rect, required PdfPageAnchor anchor}) {
    final viewSize = _visibleRect.size;
    final w = min(rect.width, viewSize.width);
    final h = min(rect.height, viewSize.height);
    switch (anchor) {
      case PdfPageAnchor.top:
        return Rect.fromLTWH(rect.left, rect.top, rect.width, h);
      case PdfPageAnchor.left:
        return Rect.fromLTWH(rect.left, rect.top, w, rect.height);
      case PdfPageAnchor.right:
        return Rect.fromLTWH(rect.right - w, rect.top, w, rect.height);
      case PdfPageAnchor.bottom:
        return Rect.fromLTWH(rect.left, rect.bottom - h, rect.width, h);
      case PdfPageAnchor.topLeft:
        return Rect.fromLTWH(rect.left, rect.top, viewSize.width, viewSize.height);
      case PdfPageAnchor.topCenter:
        return Rect.fromLTWH(rect.topCenter.dx - w / 2, rect.top, viewSize.width, viewSize.height);
      case PdfPageAnchor.topRight:
        return Rect.fromLTWH(rect.topRight.dx - w, rect.top, viewSize.width, viewSize.height);
      case PdfPageAnchor.centerLeft:
        return Rect.fromLTWH(rect.left, rect.center.dy - h / 2, viewSize.width, viewSize.height);
      case PdfPageAnchor.center:
        return Rect.fromLTWH(rect.center.dx - w / 2, rect.center.dy - h / 2, viewSize.width, viewSize.height);
      case PdfPageAnchor.centerRight:
        return Rect.fromLTWH(rect.right - w, rect.center.dy - h / 2, viewSize.width, viewSize.height);
      case PdfPageAnchor.bottomLeft:
        return Rect.fromLTWH(rect.left, rect.bottom - h, viewSize.width, viewSize.height);
      case PdfPageAnchor.bottomCenter:
        return Rect.fromLTWH(rect.center.dx - w / 2, rect.bottom - h, viewSize.width, viewSize.height);
      case PdfPageAnchor.bottomRight:
        return Rect.fromLTWH(rect.right - w, rect.bottom - h, viewSize.width, viewSize.height);
      case PdfPageAnchor.all:
        return rect;
    }
  }

  Matrix4 _calcMatrixForPage({required int pageNumber, PdfPageAnchor? anchor}) =>
      _calcMatrixForArea(rect: _layout!.pageLayouts[pageNumber - 1].inflate(widget.params.margin), anchor: anchor);

  Rect _calcRectForRectInsidePage({required int pageNumber, required PdfRect rect}) {
    final page = _document!.pages[pageNumber - 1];
    final pageRect = _layout!.pageLayouts[pageNumber - 1];
    final area = rect.toRect(page: page, scaledPageSize: pageRect.size);
    return area.translate(pageRect.left, pageRect.top);
  }

  Matrix4 _calcMatrixForRectInsidePage({required int pageNumber, required PdfRect rect, PdfPageAnchor? anchor}) {
    return _calcMatrixForArea(rect: _calcRectForRectInsidePage(pageNumber: pageNumber, rect: rect), anchor: anchor);
  }

  Matrix4? _calcMatrixForDest(PdfDest? dest) {
    if (dest == null) return null;
    final page = _document!.pages[dest.pageNumber - 1];
    final pageRect = _layout!.pageLayouts[dest.pageNumber - 1];
    double calcX(double? x) => (x ?? 0) / page.width * pageRect.width;
    double calcY(double? y) => (page.height - (y ?? 0)) / page.height * pageRect.height;
    final params = dest.params;
    switch (dest.command) {
      case PdfDestCommand.xyz:
        if (params != null && params.length >= 2) {
          final zoom =
              params.length >= 3
                  ? params[2] != null && params[2] != 0.0
                      ? params[2]!
                      : _currentZoom
                  : 1.0;
          final hw = _viewSize!.width / 2 / zoom;
          final hh = _viewSize!.height / 2 / zoom;
          return _calcMatrixFor(
            pageRect.topLeft.translate(calcX(params[0]) + hw, calcY(params[1]) + hh),
            zoom: zoom,
            viewSize: _viewSize!,
          );
        }
        break;
      case PdfDestCommand.fit:
      case PdfDestCommand.fitB:
        return _calcMatrixForPage(pageNumber: dest.pageNumber, anchor: PdfPageAnchor.all);

      case PdfDestCommand.fitH:
      case PdfDestCommand.fitBH:
        if (params != null && params.length == 1) {
          final hh = _viewSize!.height / 2 / _currentZoom;
          return _calcMatrixFor(
            pageRect.topLeft.translate(0, calcY(params[0]) + hh),
            zoom: _currentZoom,
            viewSize: _viewSize!,
          );
        }
        break;
      case PdfDestCommand.fitV:
      case PdfDestCommand.fitBV:
        if (params != null && params.length == 1) {
          final hw = _viewSize!.width / 2 / _currentZoom;
          return _calcMatrixFor(
            pageRect.topLeft.translate(calcX(params[0]) + hw, 0),
            zoom: _currentZoom,
            viewSize: _viewSize!,
          );
        }
        break;
      case PdfDestCommand.fitR:
        if (params != null && params.length == 4) {
          // page /FitR left bottom right top
          return _calcMatrixForArea(
            rect: Rect.fromLTRB(
              calcX(params[0]),
              calcY(params[3]),
              calcX(params[2]),
              calcY(params[1]),
            ).translate(pageRect.left, pageRect.top),
            anchor: PdfPageAnchor.all,
          );
        }
        break;
      default:
        return null;
    }
    return null;
  }

  Future<void> _goTo(Matrix4? destination, {Duration duration = const Duration(milliseconds: 200)}) async {
    void update() {
      if (_animationResettingGuard != 0) return;
      _txController.value = _animGoTo!.value;
    }

    try {
      if (destination == null) return; // do nothing
      _animationResettingGuard++;
      _animController.reset();
      _animationResettingGuard--;
      _animGoTo = Matrix4Tween(
        begin: _txController.value,
        end: _makeMatrixInSafeRange(destination),
      ).animate(_animController);
      _animGoTo!.addListener(update);
      await _animController.animateTo(1.0, duration: duration, curve: Curves.easeInOut).orCancel;
    } on TickerCanceled {
      // expected
    } finally {
      _animGoTo?.removeListener(update);
    }
  }

  Matrix4 _calcMatrixToEnsureRectVisible(Rect rect, {double margin = 0}) {
    final restrictedRect = _txController.value.calcVisibleRect(_viewSize!, margin: margin);
    if (restrictedRect.containsRect(rect)) {
      return _txController.value; // keep the current position
    }
    if (rect.width <= restrictedRect.width && rect.height < restrictedRect.height) {
      final intRect = Rect.fromLTWH(
        rect.left < restrictedRect.left
            ? rect.left
            : rect.right < restrictedRect.right
            ? restrictedRect.left
            : restrictedRect.left + rect.right - restrictedRect.right,
        rect.top < restrictedRect.top
            ? rect.top
            : rect.bottom < restrictedRect.bottom
            ? restrictedRect.top
            : restrictedRect.top + rect.bottom - restrictedRect.bottom,
        restrictedRect.width,
        restrictedRect.height,
      );
      final newRect = intRect.inflate(margin / _currentZoom);
      return _calcMatrixForRect(newRect);
    }
    return _calcMatrixForRect(rect, margin: margin);
  }

  Future<void> _ensureVisible(Rect rect, {Duration duration = const Duration(milliseconds: 200), double margin = 0}) =>
      _goTo(_calcMatrixToEnsureRectVisible(rect, margin: margin), duration: duration);

  Future<void> _goToArea({
    required Rect rect,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) => _goTo(_calcMatrixForArea(rect: rect, anchor: anchor), duration: duration);

  Future<void> _goToPage({
    required int pageNumber,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    final pageCount = _document!.pages.length;
    final int targetPageNumber;
    if (pageNumber < 1) {
      targetPageNumber = 1;
    } else if (pageNumber != 1 && pageNumber >= pageCount) {
      targetPageNumber = pageNumber = pageCount;
      anchor ??= widget.params.pageAnchorEnd;
    } else {
      targetPageNumber = pageNumber;
    }
    _gotoTargetPageNumber = pageNumber;

    await _goTo(_calcMatrixForPage(pageNumber: targetPageNumber, anchor: anchor), duration: duration);
    _setCurrentPageNumber(targetPageNumber);
  }

  Future<void> _goToRectInsidePage({
    required int pageNumber,
    required PdfRect rect,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    _gotoTargetPageNumber = pageNumber;
    await _goTo(_calcMatrixForRectInsidePage(pageNumber: pageNumber, rect: rect, anchor: anchor), duration: duration);
    _setCurrentPageNumber(pageNumber);
  }

  Future<bool> _goToDest(PdfDest? dest, {Duration duration = const Duration(milliseconds: 200)}) async {
    final m = _calcMatrixForDest(dest);
    if (m == null) return false;
    if (dest != null) {
      _gotoTargetPageNumber = dest.pageNumber;
    }
    await _goTo(m, duration: duration);
    if (dest != null) {
      _setCurrentPageNumber(dest.pageNumber);
    }
    return true;
  }

  double get _currentZoom => _txController.value.zoom;

  PdfPageHitTestResult? _getPdfPageHitTestResult(Offset offset, {required bool useDocumentLayoutCoordinates}) {
    final pages = _document?.pages;
    final pageLayouts = _layout?.pageLayouts;
    if (pages == null || pageLayouts == null) return null;
    if (!useDocumentLayoutCoordinates) {
      final r = Matrix4.inverted(_txController.value);
      offset = r.transformOffset(offset);
    }
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageRect = pageLayouts[i];
      if (pageRect.contains(offset)) {
        return PdfPageHitTestResult(
          page: page,
          offset: offset.translate(-pageRect.left, -pageRect.top).toPdfPoint(page: page, scaledPageSize: pageRect.size),
        );
      }
    }
    return null;
  }

  double _getNextZoom({bool loop = true}) => _findNextZoomStop(_currentZoom, zoomUp: true, loop: loop);
  double _getPreviousZoom({bool loop = true}) => _findNextZoomStop(_currentZoom, zoomUp: false, loop: loop);

  Future<void> _setZoom(Offset position, double zoom, {Duration duration = const Duration(milliseconds: 200)}) =>
      _goTo(_calcMatrixFor(position, zoom: zoom, viewSize: _viewSize!), duration: duration);

  Offset get _centerPosition => _txController.value.calcPosition(_viewSize!);

  Future<void> _zoomUp({
    bool loop = false,
    Offset? zoomCenter,
    Duration duration = const Duration(milliseconds: 200),
  }) => _setZoom(zoomCenter ?? _centerPosition, _getNextZoom(loop: loop), duration: duration);

  Future<void> _zoomDown({
    bool loop = false,
    Offset? zoomCenter,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    await _setZoom(zoomCenter ?? _centerPosition, _getPreviousZoom(loop: loop), duration: duration);
  }

  RenderBox? get _renderBox {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return null;
    return renderBox;
  }

  /// Converts the global position to the local position in the widget.
  Offset? _globalToLocal(Offset global) {
    try {
      final renderBox = _renderBox;
      if (renderBox == null) return null;
      return renderBox.globalToLocal(global);
    } catch (e) {
      return null;
    }
  }

  /// Converts the local position to the global position in the widget.
  Offset? _localToGlobal(Offset local) {
    try {
      final renderBox = _renderBox;
      if (renderBox == null) return null;
      return renderBox.localToGlobal(local);
    } catch (e) {
      return null;
    }
  }

  /// Converts the global position to the local position in the PDF document structure.
  Offset? _globalToDocument(Offset global) {
    final ratio = 1 / _currentZoom;
    return _globalToLocal(
      global,
    )?.translate(-_txController.value.xZoomed, -_txController.value.yZoomed).scale(ratio, ratio);
  }

  /// Converts the local position in the PDF document structure to the global position.
  Offset? _documentToGlobal(Offset document) => _localToGlobal(
    document.scale(_currentZoom, _currentZoom).translate(_txController.value.xZoomed, _txController.value.yZoomed),
  );

  void _textTap(TapDownDetails details) {
    if (_isInteractionGoingOn) return;
    _clearTextSelections();
  }

  void _textDoubleTap(TapDownDetails details) {}

  void _textLongPress(LongPressStartDetails details) {
    if (_isInteractionGoingOn) return;
    selectWord(details.localPosition);
  }

  void _textSecondaryTapUp(TapUpDetails details) {
    _showTextSelectionContextMenuAt = details.globalPosition;
    _invalidate();
  }

  void _onTextPanStart(DragStartDetails details) {
    if (_isInteractionGoingOn) return;
    _selPartMoving = _TextSelectionPartMoving.free;
    _selA = _findTextAndIndexForPoint(details.localPosition);
    _textSelectAnchor = Offset(_txController.value.x, _txController.value.y);
    _selB = null;
    _showTextSelectionContextMenuAt = null;
    _updateTextSelection();
  }

  void _onTextPanUpdate(DragUpdateDetails details) {
    _updateTextSelectRectTo(details.localPosition);
  }

  void _onTextPanEnd(DragEndDetails details) {
    _updateTextSelectRectTo(details.localPosition);
    _selPartMoving = _TextSelectionPartMoving.none;
    _invalidate();
  }

  void _updateTextSelectRectTo(Offset panTo) {
    if (_selPartMoving != _TextSelectionPartMoving.free) return;
    final to = _findTextAndIndexForPoint(
      panTo + _textSelectAnchor! - Offset(_txController.value.x, _txController.value.y),
    );
    if (to != null) {
      _selB = to;
      _updateTextSelection();
    }
  }

  void _updateTextSelection({bool invalidate = true}) {
    final a = _selA;
    final b = _selB;
    if (a == null || b == null) {
      _textSelA = _textSelB = null;
      _textSelection.clear();
    } else if (a.text.pageNumber == b.text.pageNumber) {
      final page = _document!.pages[a.text.pageNumber - 1];
      final pageRect = _layout!.pageLayouts[a.text.pageNumber - 1];
      final range = a.text.getRangeFromAB(a.index, b.index);
      _textSelA = PdfTextSelectionAnchor(
        a.text.charRects[range.start].toRectInDocument(page: page, pageRect: pageRect),
        range.firstFragment?.direction ?? PdfTextDirection.ltr,
        PdfTextSelectionAnchorType.a,
        a.text,
        a.index,
      );
      _textSelB = PdfTextSelectionAnchor(
        a.text.charRects[range.end - 1].toRectInDocument(page: page, pageRect: pageRect),
        range.lastFragment?.direction ?? PdfTextDirection.ltr,
        PdfTextSelectionAnchorType.b,
        a.text,
        b.index,
      );
      _textSelection.clear();
      _textSelection[page.pageNumber] = range;
    } else {
      final first = a.text.pageNumber < b.text.pageNumber ? a : b;
      final second = a.text.pageNumber < b.text.pageNumber ? b : a;
      final rangeA = PdfPageTextRange(pageText: first.text, start: first.index, end: first.text.charRects.length);
      _textSelA = PdfTextSelectionAnchor(
        first.text.charRects[first.index].toRectInDocument(
          page: _document!.pages[first.text.pageNumber - 1],
          pageRect: _layout!.pageLayouts[first.text.pageNumber - 1],
        ),
        rangeA.firstFragment?.direction ?? PdfTextDirection.ltr,
        PdfTextSelectionAnchorType.a,
        first.text,
        first.index,
      );
      final rangeB = PdfPageTextRange(pageText: second.text, start: 0, end: second.index + 1);
      _textSelB = PdfTextSelectionAnchor(
        second.text.charRects[second.index].toRectInDocument(
          page: _document!.pages[second.text.pageNumber - 1],
          pageRect: _layout!.pageLayouts[second.text.pageNumber - 1],
        ),
        rangeB.lastFragment?.direction ?? PdfTextDirection.ltr,
        PdfTextSelectionAnchorType.b,
        second.text,
        second.index,
      );
      _textSelection.clear();
      _textSelection[first.text.pageNumber] = rangeA;
      _textSelection[second.text.pageNumber] = rangeB;
      for (int i = first.text.pageNumber + 1; i < second.text.pageNumber; i++) {
        final text = _getCachedTextOrDelayLoadText(i, onTextLoaded: () => _updateTextSelection());
        if (text == null) continue;
        _textSelection[i] = PdfPageTextRange(pageText: text, start: 0, end: text.charRects.length);
      }
    }

    if (invalidate) {
      _notifyTextSelectionChange();
    }
  }

  /// [point] is in the document coordinates.
  _TextSelectionPoint? _findTextAndIndexForPoint(Offset? point, {double hitTestMargin = 8}) {
    if (point == null) return null;
    for (int pageIndex = 0; pageIndex < _document!.pages.length; pageIndex++) {
      final pageRect = _layout!.pageLayouts[pageIndex];
      if (!pageRect.contains(point)) {
        continue;
      }
      final page = _document!.pages[pageIndex];
      final text = _getCachedTextOrDelayLoadText(pageIndex + 1, onTextLoaded: () => _updateTextSelection());
      if (text == null) continue;
      final pt = point.translate(-pageRect.left, -pageRect.top).toPdfPoint(page: page, scaledPageSize: pageRect.size);
      double d2Min = double.infinity;
      int? closestIndex;
      for (int i = 0; i < text.charRects.length; i++) {
        final charRect = text.charRects[i];
        if (charRect.containsPoint(pt)) {
          return _TextSelectionPoint(text, i, point);
        }
        final d2 = charRect.distanceSquaredTo(pt);
        if (d2 < d2Min) {
          d2Min = d2;
          closestIndex = i;
        }
      }
      if (closestIndex != null && d2Min <= hitTestMargin * hitTestMargin) {
        return _TextSelectionPoint(text, closestIndex, point);
      }
    }
    return null;
  }

  void _notifyTextSelectionChange() {
    _onSelectionChange();
    _invalidate();
  }

  List<Widget> _placeTextSelectionWidgets(BuildContext context, Size viewSize, bool isCopyTextEnabled) {
    final renderBox = _renderBox;
    if (renderBox == null || _textSelA == null || _textSelB == null || _textSelection.isEmpty) {
      return [];
    }

    final rectA = _documentToRenderBox(_textSelA!.rect, renderBox);
    final rectB = _documentToRenderBox(_textSelB!.rect, renderBox);
    if (rectA == null || rectB == null) {
      return [];
    }

    final enableSelectionHandles = widget.params.textSelectionParams?.enableSelectionHandles ?? isMobile;

    double? aLeft, aTop, aRight, aBottom;
    double? bLeft, bTop, bRight;
    Widget? anchorA, anchorB;

    if (enableSelectionHandles && _selPartMoving != _TextSelectionPartMoving.free) {
      final builder = widget.params.textSelectionParams?.buildSelectionHandle ?? _buildDefaultSelectionHandle;

      if (_textSelA != null) {
        switch (_textSelA!.direction) {
          case PdfTextDirection.ltr:
          case PdfTextDirection.unknown:
            aRight = viewSize.width - rectA.left;
            aBottom = viewSize.height - rectA.top;
          case PdfTextDirection.rtl:
            aLeft = rectA.right;
            aBottom = viewSize.height - rectA.top;
          case PdfTextDirection.vrtl:
            aLeft = rectA.right;
            aBottom = viewSize.height - rectA.top;
        }
        anchorA = builder(context, _textSelA!);
      }
      if (_textSelB != null) {
        switch (_textSelB!.direction) {
          case PdfTextDirection.ltr:
          case PdfTextDirection.unknown:
            bLeft = rectB.right;
            bTop = rectB.bottom;
          case PdfTextDirection.rtl:
            bRight = viewSize.width - rectB.left;
            bTop = rectB.bottom;
          case PdfTextDirection.vrtl:
            bRight = viewSize.width - rectB.left;
            bTop = rectB.bottom;
        }
        anchorB = builder(context, _textSelB!);
      }
    }

    // Determines whether the widget is [Positioned] or [Align] to avoid unnecessary wrapping.
    bool isPositionalWidget(Widget? widget) => widget != null && (widget is Positioned || widget is Align);

    Widget? layoutWidget(Widget? widget, {Offset? position, Size? size}) {
      if (widget == null || isPositionalWidget(widget)) return widget;
      if (position != null) return Positioned(left: position.dx, top: position.dy, child: widget);

      const safeArea = 60.0;
      final selRect = rectA.expandToInclude(rectB).inflate(safeArea);

      return Positioned(left: 8, top: 8, child: widget);
    }

    Widget? magnifier;
    final magnifierParams = widget.params.textSelectionParams?.magnifier ?? const PdfViewerSelectionMagnifierParams();
    final magnifierEnabled =
        (magnifierParams.enabled ?? isMobile) &&
        (magnifierParams.shouldBeShown?.call(_controller!, magnifierParams) ?? (_currentZoom < magnifierParams.scale));
    if (magnifierEnabled) {
      final textAnchor = switch (_selPartMoving) {
        _TextSelectionPartMoving.a => _selA!.index < _selB!.index ? _textSelA : _textSelB,
        _TextSelectionPartMoving.b => _selA!.index < _selB!.index ? _textSelB : _textSelA,
        _ => null,
      };
      final magCenter = textAnchor?.anchorPoint;
      if (magCenter != null && textAnchor!.rect.height < magnifierParams.height * .7) {
        final magnifierMain = _buildMagnifier(context, magCenter, magnifierParams);
        final builder = magnifierParams.builder ?? _buildMagnifierDecoration;
        magnifier = layoutWidget(
          builder(context, magnifierParams, magnifierMain),
          size: Size(magnifierParams.width, magnifierParams.height),
        );
      }
    }

    bool showContextMenu = false;
    if (_showTextSelectionContextMenuAt != null) {
      showContextMenu = true;
    } else if (isMobile && _textSelA != null && _textSelB != null && _selPartMoving == _TextSelectionPartMoving.none) {
      // Show context menu on mobile when selection is not moving.
      showContextMenu = true;
    }

    Widget? contextMenu;
    if (showContextMenu) {
      final position =
          _showTextSelectionContextMenuAt != null ? renderBox.globalToLocal(_showTextSelectionContextMenuAt!) : null;
      final ctxMenuBuilder = widget.params.textSelectionParams?.buildContextMenu ?? _buildTextSelectionContextMenu;
      contextMenu = layoutWidget(
        ctxMenuBuilder(context, _textSelA!, _textSelB!, this, position, () {
          _showTextSelectionContextMenuAt = null;
          _invalidate();
        }),
        position: position,
      );
    }

    return [
      if (anchorA != null)
        Positioned(
          left: aLeft,
          top: aTop,
          right: aRight,
          bottom: aBottom,
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: GestureDetector(
              onPanStart: (details) => _onSelectionHandlePanStart(_TextSelectionPartMoving.a, details),
              onPanUpdate: (details) => _onSelectionHandlePanUpdate(_TextSelectionPartMoving.a, details),
              onPanEnd: (details) => _onSelectionHandlePanEnd(_TextSelectionPartMoving.a, details),
              child: anchorA,
            ),
          ),
        ),
      if (anchorB != null)
        Positioned(
          left: bLeft,
          top: bTop,
          right: bRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: GestureDetector(
              onPanStart: (details) => _onSelectionHandlePanStart(_TextSelectionPartMoving.b, details),
              onPanUpdate: (details) => _onSelectionHandlePanUpdate(_TextSelectionPartMoving.b, details),
              onPanEnd: (details) => _onSelectionHandlePanEnd(_TextSelectionPartMoving.b, details),
              child: anchorB,
            ),
          ),
        ),
      if (magnifier != null) magnifier,
      if (contextMenu != null) contextMenu,
    ];
  }

  Widget? _buildDefaultSelectionHandle(BuildContext context, PdfTextSelectionAnchor anchor) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
    );
  }

  Widget _buildMagnifier(BuildContext context, Offset docPos, PdfViewerSelectionMagnifierParams magnifierParams) {
    final magScale = magnifierParams.scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _CustomPainter.fromFunctions((canvas, size) {
              canvas.save();
              canvas.scale(magScale);
              canvas.translate(-docPos.dx + size.width / 2 / magScale, -docPos.dy + size.height / 2 / magScale);
              _paintPagesCustom(
                canvas,
                cache: _magnifierImageCache,
                maxImageCacheBytes:
                    widget.params.textSelectionParams?.magnifier?.maxImageBytesCachedOnMemory ??
                    PdfViewerSelectionMagnifierParams.defaultMaxImageBytesCachedOnMemory,
                targetRect: Rect.fromCenter(
                  center: docPos,
                  width: size.width / magScale,
                  height: size.height / magScale,
                ),
                resolutionMultiplier: magScale,
                previewEnabled: false,
                filterQuality: FilterQuality.low,
              );
              canvas.restore();
              canvas.drawLine(
                Offset(size.width / 2, size.height / 4),
                Offset(size.width / 2, size.height * 3 / 4),
                Paint()
                  ..color = Colors.blue
                  ..style = PaintingStyle.stroke,
              );

              if (magnifierParams.paintMagnifierContent != null) {
                magnifierParams.paintMagnifierContent!(canvas, size, docPos, magnifierParams);
              } else {
                canvas.drawLine(
                  Offset(size.width / 4, size.height / 2),
                  Offset(size.width * 3 / 4, size.height / 2),
                  Paint()
                    ..color = Colors.blue
                    ..style = PaintingStyle.stroke,
                );
              }
            }),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }

  Widget _buildMagnifierDecoration(BuildContext context, PdfViewerSelectionMagnifierParams params, Widget child) {
    return Container(
      width: params.width,
      height: params.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(15), child: child),
    );
  }

  Widget? _buildTextSelectionContextMenu(
    BuildContext context,
    PdfTextSelectionAnchor a,
    PdfTextSelectionAnchor b,
    PdfTextSelectionDelegate textSelectionDelegate,
    Offset? rightClickPosition,
    void Function() dismissContextMenu,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          RawMaterialButton(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed:
                textSelectionDelegate.isCopyAllowed
                    ? () {
                      if (textSelectionDelegate.isCopyAllowed) {
                        textSelectionDelegate.copyTextSelection();
                      }
                    }
                    : null,
            child: Text(
              'Copy',
              style: TextStyle(color: textSelectionDelegate.isCopyAllowed ? Colors.black : Colors.grey),
            ),
          ),
          if (textSelectionDelegate.isCopyAllowed)
            RawMaterialButton(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                textSelectionDelegate.selectAllText();
              },
              child: const Text('Select All'),
            ),
        ],
      ),
    );
  }

  void _onSelectionHandlePanStart(_TextSelectionPartMoving handle, DragStartDetails details) {
    if (_isInteractionGoingOn) return;
    _selPartMoving = handle;
    final position = _globalToDocument(details.globalPosition);
    final anchor = Offset(_txController.value.x, _txController.value.y);
    if (_selPartMoving == _TextSelectionPartMoving.a) {
      _textSelectAnchor = anchor + _textSelA!.rect.topLeft - position!;
      final a = _findTextAndIndexForPoint(_textSelA!.rect.center);
      if (a == null) return;
      _selA = a;
    } else if (_selPartMoving == _TextSelectionPartMoving.b) {
      _textSelectAnchor = anchor + _textSelB!.rect.bottomRight - position!;
      final b = _findTextAndIndexForPoint(_textSelB!.rect.center);
      if (b == null) return;
      _selB = b;
    } else {
      return;
    }
    _showTextSelectionContextMenuAt = null;
    _updateTextSelection();
  }

  void _updateSelectionHandlesPan(Offset? panTo) {
    if (panTo == null) return;
    if (_selPartMoving == _TextSelectionPartMoving.a) {
      final a = _findTextAndIndexForPoint(
        panTo + _textSelectAnchor! - Offset(_txController.value.x, _txController.value.y),
      );
      if (a == null) return;
      _selA = a;
    } else if (_selPartMoving == _TextSelectionPartMoving.b) {
      final b = _findTextAndIndexForPoint(
        panTo + _textSelectAnchor! - Offset(_txController.value.x, _txController.value.y),
      );
      if (b == null) return;
      _selB = b;
    } else {
      return;
    }
    _updateTextSelection();
  }

  void _onSelectionHandlePanUpdate(_TextSelectionPartMoving handle, DragUpdateDetails details) {
    if (_isInteractionGoingOn) return;
    _showTextSelectionContextMenuAt = null;
    _updateSelectionHandlesPan(_globalToDocument(details.globalPosition));
  }

  void _onSelectionHandlePanEnd(_TextSelectionPartMoving handle, DragEndDetails details) {
    if (_isInteractionGoingOn) return;
    _updateSelectionHandlesPan(_globalToDocument(details.globalPosition));
    _selPartMoving = _TextSelectionPartMoving.none;
  }

  void _clearTextSelections({bool invalidate = true}) {
    _selA = _selB = null;
    _textSelA = _textSelB = null;
    _showTextSelectionContextMenuAt = null;
    _updateTextSelection(invalidate: invalidate);
  }

  @override
  Future<void> clearTextSelection() async => _clearTextSelections();

  @override
  String get selectedText => _textSelection.values.map((p) => p.text).join();

  @override
  List<PdfPageTextRange> get selectedTextRange => _textSelection.values.toList();

  @override
  bool get isCopyAllowed => _document!.permissions?.allowsCopying != false;

  @override
  Future<void> selectAllText() async {
    if (_document!.pages.isEmpty && _layout != null) return;
    final textSelection = SplayTreeMap<int, PdfPageTextRange>();
    for (int i = 1; i <= _document!.pages.length; i++) {
      final text = await _loadTextAsync(i);
      textSelection[i] = PdfPageTextRange(pageText: text, start: 0, end: text.fullText.length);
    }
    _selA = _findTextAndIndexForPoint(
      textSelection[1]!.pageText.charRects.first.center.toOffsetInDocument(
        page: _document!.pages[0],
        pageRect: _layout!.pageLayouts[0],
      ),
    );
    _selB = _findTextAndIndexForPoint(
      textSelection[_document!.pages.length]!.pageText.charRects.last.center.toOffsetInDocument(
        page: _document!.pages.last,
        pageRect: _layout!.pageLayouts.last,
      ),
    );
    _showTextSelectionContextMenuAt = null;
    _updateTextSelection();
  }

  @override
  Future<void> selectWord(Offset offset) async {
    _textSelection.clear();
    for (int i = 0; i < _document!.pages.length; i++) {
      final pageRect = _layout!.pageLayouts[i];
      if (!pageRect.contains(offset)) {
        continue;
      }

      final text = await _loadTextAsync(i + 1);
      final page = _document!.pages[i];
      final point = offset
          .translate(-pageRect.left, -pageRect.top)
          .toPdfPoint(page: page, scaledPageSize: pageRect.size);
      final f = text.fragments.firstWhereOrNull((f) => f.bounds.containsPoint(point));
      if (f == null) {
        continue;
      }
      final range = _textSelection[i + 1] = PdfPageTextRange(pageText: text, start: f.index, end: f.end);
      final selectionRect = f.bounds.toRectInDocument(page: page, pageRect: pageRect);
      _selA = _TextSelectionPoint(
        text,
        f.index,
        text.charRects[f.index].center.toOffsetInDocument(page: page, pageRect: pageRect),
      );
      _selB = _TextSelectionPoint(
        text,
        f.end - 1,
        text.charRects[f.end - 1].center.toOffsetInDocument(page: page, pageRect: pageRect),
      );
      _textSelA = PdfTextSelectionAnchor(
        selectionRect,
        range.pageText.getFragmentForTextIndex(range.start)?.direction ?? PdfTextDirection.ltr,
        PdfTextSelectionAnchorType.a,
        text,
        _selA!.index,
      );
      _textSelB = _textSelA!.copyWith(type: PdfTextSelectionAnchorType.b, index: _selB!.index);
      _textSelectAnchor = Offset(_txController.value.x, _txController.value.y);
      break;
    }
    _notifyTextSelectionChange();
  }

  Future<bool> _copyTextSelection() async {
    if (_document!.permissions?.allowsCopying == false) return false;
    setClipboardData(selectedText);
    return true;
  }

  @override
  Future<bool> copyTextSelection() async {
    final result = await _copyTextSelection();
    _clearTextSelections();
    return result;
  }
}

class _PdfPageImageCache {
  final pageImages = <int, _PdfImageWithScale>{};
  final pageImageRenderingTimers = <int, Timer>{};
  final pageImagesPartial = <int, _PdfImageWithScaleAndRect>{};
  final cancellationTokens = <int, List<PdfPageRenderCancellationToken>>{};
  final pageImagePartialRenderingRequests = <int, _PdfPartialImageRenderingRequest>{};

  void addCancellationToken(int pageNumber, PdfPageRenderCancellationToken token) {
    var tokens = cancellationTokens.putIfAbsent(pageNumber, () => []);
    tokens.add(token);
  }

  void releaseAllImages() {
    for (final timer in pageImageRenderingTimers.values) {
      timer.cancel();
    }
    pageImageRenderingTimers.clear();
    for (final request in pageImagePartialRenderingRequests.values) {
      request.cancel();
    }
    pageImagePartialRenderingRequests.clear();
    for (final image in pageImages.values) {
      image.image.dispose();
    }
    pageImages.clear();
    for (final image in pageImagesPartial.values) {
      image.image.dispose();
    }
    pageImagesPartial.clear();
  }

  void cancelPendingRenderings(int pageNumber) {
    final tokens = cancellationTokens[pageNumber];
    if (tokens != null) {
      for (final token in tokens) {
        token.cancel();
      }
      tokens.clear();
    }
  }

  void cancelAllPendingRenderings() {
    for (final pageNumber in cancellationTokens.keys) {
      cancelPendingRenderings(pageNumber);
    }
    cancellationTokens.clear();
  }

  void removeCacheImagesForPage(int pageNumber) {
    final removed = pageImages.remove(pageNumber);
    if (removed != null) {
      removed.image.dispose();
    }
    final removedPartial = pageImagesPartial.remove(pageNumber);
    if (removedPartial != null) {
      removedPartial.image.dispose();
    }
  }

  void removeCacheImagesIfCacheBytesExceedsLimit(
    List<int> pageNumbers,
    int acceptableBytes,
    PdfPage currentPage, {
    required double Function(int pageNumber) dist,
  }) {
    pageNumbers.sort((a, b) => dist(b).compareTo(dist(a)));
    int getBytesConsumed(ui.Image? image) => image == null ? 0 : (image.width * image.height * 4).toInt();
    int bytesConsumed =
        pageImages.values.fold(0, (sum, e) => sum + getBytesConsumed(e.image)) +
        pageImagesPartial.values.fold(0, (sum, e) => sum + getBytesConsumed(e.image));
    for (final key in pageNumbers) {
      final removed = pageImages.remove(key);
      if (removed != null) {
        bytesConsumed -= getBytesConsumed(removed.image);
        removed.image.dispose();
      }
      final removedPartial = pageImagesPartial.remove(key);
      if (removedPartial != null) {
        bytesConsumed -= getBytesConsumed(removedPartial.image);
        removedPartial.image.dispose();
      }
      if (bytesConsumed <= acceptableBytes) {
        break;
      }
    }
  }
}

class _PdfPartialImageRenderingRequest {
  _PdfPartialImageRenderingRequest(this.timer, this.cancellationToken);
  final Timer timer;
  final PdfPageRenderCancellationToken cancellationToken;

  void cancel() {
    timer.cancel();
    cancellationToken.cancel();
  }
}

class _PdfImageWithScale {
  _PdfImageWithScale(this.image, this.scale);
  final ui.Image image;
  final double scale;

  void dispose() {
    image.dispose();
  }
}

class _PdfImageWithScaleAndRect extends _PdfImageWithScale {
  _PdfImageWithScaleAndRect(super.image, super.scale, this.rect);
  final Rect rect;
}

class _PdfViewerTransformationController extends TransformationController {
  _PdfViewerTransformationController(this._state);

  final _PdfViewerState _state;

  @override
  set value(Matrix4 newValue) {
    super.value = _state._makeMatrixInSafeRange(newValue);
  }
}

/// What selection part is moving by mouse-dragging/finger-panning.
enum _TextSelectionPartMoving { none, free, a, b }

@immutable
class _TextSelectionPoint {
  const _TextSelectionPoint(this.text, this.index, this.point);
  final PdfPageText text;
  final int index;
  final Offset point;

  @override
  String toString() => '$_TextSelectionPoint(text: $text, index: $index, point: $point)';
}

/// Represents the anchor point of the text selection.
///
/// It contains the rectangle of the anchor point, the text direction, and the type of the anchor (A or B).
@immutable
class PdfTextSelectionAnchor {
  const PdfTextSelectionAnchor(this.rect, this.direction, this.type, this.page, this.index);

  /// The rectangle of the character, on which the anchor is associated to.
  final Rect rect;

  /// The text direction of the anchored character.
  final PdfTextDirection direction;

  /// The type of the anchor, either [PdfTextSelectionAnchorType.a] or [PdfTextSelectionAnchorType.b].
  final PdfTextSelectionAnchorType type;

  /// The page text on which the anchor is associated to.
  final PdfPageText page;

  /// The index of the character in [page].
  ///
  /// Please note that the index is always inclusive, even for the end anchor (B).
  final int index;

  /// The point of the anchor in the document coordinates, which is an apex of [rect] depending on
  /// the [direction] and [type].
  Offset get anchorPoint {
    switch (direction) {
      case PdfTextDirection.ltr:
      case PdfTextDirection.unknown:
        return type == PdfTextSelectionAnchorType.a ? rect.topLeft : rect.bottomRight;
      case PdfTextDirection.rtl:
        return type == PdfTextSelectionAnchorType.a ? rect.topRight : rect.bottomLeft;
      case PdfTextDirection.vrtl:
        return type == PdfTextSelectionAnchorType.a ? rect.topRight : rect.bottomLeft;
    }
  }

  PdfTextSelectionAnchor copyWith({
    Rect? rect,
    PdfTextDirection? direction,
    PdfTextSelectionAnchorType? type,
    PdfPageText? page,
    int? index,
  }) {
    return PdfTextSelectionAnchor(
      rect ?? this.rect,
      direction ?? this.direction,
      type ?? this.type,
      page ?? this.page,
      index ?? this.index,
    );
  }
}

/// Defines the type of the text selection anchor.
///
/// It can be either [a] or [b], which represents the start and end of the selection respectively.
enum PdfTextSelectionAnchorType { a, b }

/// Defines page layout.
class PdfPageLayout {
  PdfPageLayout({required this.pageLayouts, required this.documentSize});
  final List<Rect> pageLayouts;
  final Size documentSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PdfPageLayout) return false;
    return listEquals(pageLayouts, other.pageLayouts) && documentSize == other.documentSize;
  }

  @override
  int get hashCode => pageLayouts.hashCode ^ documentSize.hashCode;
}

/// Represents the result of the hit test on the page.
class PdfPageHitTestResult {
  PdfPageHitTestResult({required this.page, required this.offset});

  /// The page that was hit.
  final PdfPage page;

  /// The offset in the PDF page coordinates; the origin is at the bottom-left corner.
  final PdfPoint offset;
}

/// Controls associated [PdfViewer].
///
/// It's always your option to extend (inherit) the class to customize the [PdfViewer] behavior.
///
/// Please note that almost all fields and functions are not working if the controller is not associated
/// to any [PdfViewer].
/// You can check whether the controller is associated or not by checking [isReady] property.
class PdfViewerController extends ValueListenable<Matrix4> {
  _PdfViewerState? __state;
  final _listeners = <VoidCallback>[];

  void _attach(_PdfViewerState? state) {
    __state?._txController.removeListener(_notifyListeners);
    __state = state;
    __state?._txController.addListener(_notifyListeners);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  _PdfViewerState get _state => __state!;

  /// Get the associated [PdfViewer] widget.
  PdfViewer get widget => _state.widget;

  /// Get the associated [PdfViewerParams] parameters.
  PdfViewerParams get params => widget.params;

  /// Determine whether the document/pages are ready or not.
  bool get isReady => __state?._document?.pages != null;

  /// The document layout size.
  Size get documentSize => _state._layout!.documentSize;

  /// Page layout.
  PdfPageLayout get layout => _state._layout!;

  /// The view port size (The widget's client area's size)
  Size get viewSize => _state._viewSize!;

  /// The zoom ratio that fits the page's smaller side (either horizontal or vertical) to the view port.
  double get coverScale => _state._coverScale!;

  /// The zoom ratio that fits whole the page to the view port.
  double? get alternativeFitScale => _state._alternativeFitScale;

  /// The minimum zoom ratio allowed.
  double get minScale => _state.minScale;

  /// The area of the document layout which is visible on the view port.
  Rect get visibleRect => _state._visibleRect;

  /// Get the associated document.
  ///
  /// Please note that the field does not ensure that the [PdfDocument] is alive during long asynchronous operations.
  /// If you want to do some time consuming asynchronous operation, use [useDocument] instead.
  @Deprecated('Use useDocument instead')
  PdfDocument get document => _state._document!;

  /// Get the associated pages.
  ///
  /// Please note that the field does not ensure that the associated [PdfDocument] is alive during long asynchronous
  /// operations. If you want to do some time consuming asynchronous operation, use [useDocument] instead.
  /// For page count, use [pageCount] instead.
  @Deprecated('Use useDocument instead')
  List<PdfPage> get pages => _state._document!.pages;

  /// Get the page count of the document.
  int get pageCount => _state._document!.pages.length;

  /// The current page number if available.
  int? get pageNumber => _state._pageNumber;

  /// The document reference associated to the [PdfViewer].
  PdfDocumentRef get documentRef => _state.widget.documentRef;

  /// Within call to the function, it ensures that the [PdfDocument] is alive (not null and not disposed).
  ///
  /// If [ensureLoaded] is true, it tries to ensure that the document is loaded.
  /// If the document is not loaded, the function does not call [task] and return null.
  /// [cancelLoading] is used to cancel the loading process.
  ///
  /// The following fragment explains how to use [PdfDocument]:
  ///
  /// ```dart
  /// await controller.useDocument(
  ///   (document) async {
  ///     // Use the document here
  ///   },
  /// );
  /// ```
  ///
  /// This is just a shortcut for the combination of [PdfDocumentRef.resolveListenable] and [PdfDocumentListenable.useDocument].
  ///
  /// For more information, see [PdfDocumentRef], [PdfDocumentRef.resolveListenable], and [PdfDocumentListenable.useDocument].
  FutureOr<T?> useDocument<T>(
    FutureOr<T> Function(PdfDocument document) task, {
    bool ensureLoaded = true,
    Completer? cancelLoading,
  }) => documentRef.resolveListenable().useDocument(task, ensureLoaded: ensureLoaded, cancelLoading: cancelLoading);

  @override
  Matrix4 get value => _state._txController.value;

  set value(Matrix4 newValue) => _state._txController.value = makeMatrixInSafeRange(newValue);

  @override
  void addListener(ui.VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(ui.VoidCallback listener) => _listeners.remove(listener);

  /// Restrict matrix to the safe range.
  Matrix4 makeMatrixInSafeRange(Matrix4 newValue) => _state._makeMatrixInSafeRange(newValue);

  double getNextZoom({bool loop = true}) => _state._findNextZoomStop(currentZoom, zoomUp: true, loop: loop);

  double getPreviousZoom({bool loop = true}) => _state._findNextZoomStop(currentZoom, zoomUp: false, loop: loop);

  void notifyFirstChange(void Function() onFirstChange) {
    void handler() {
      removeListener(handler);
      onFirstChange();
    }

    addListener(handler);
  }

  /// Go to the specified area.
  ///
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Future<void> goToArea({
    required Rect rect,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) => _state._goToArea(rect: rect, anchor: anchor, duration: duration);

  /// Go to the specified page.
  ///
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Future<void> goToPage({
    required int pageNumber,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) => _state._goToPage(pageNumber: pageNumber, anchor: anchor, duration: duration);

  /// Go to the specified area inside the page.
  ///
  /// [pageNumber] specifies the page number.
  /// [rect] specifies the area to go in page coordinates.
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Future<void> goToRectInsidePage({
    required int pageNumber,
    required PdfRect rect,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) => _state._goToRectInsidePage(pageNumber: pageNumber, rect: rect, anchor: anchor, duration: duration);

  /// Calculate the rectangle for the specified area inside the page.
  ///
  /// [pageNumber] specifies the page number.
  /// [rect] specifies the area to go in page coordinates.
  Rect calcRectForRectInsidePage({required int pageNumber, required PdfRect rect}) =>
      _state._calcRectForRectInsidePage(pageNumber: pageNumber, rect: rect);

  /// Calculate the matrix for the specified area inside the page.
  ///
  /// [pageNumber] specifies the page number.
  /// [rect] specifies the area to go in page coordinates.
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Matrix4 calcMatrixForRectInsidePage({required int pageNumber, required PdfRect rect, PdfPageAnchor? anchor}) =>
      _state._calcMatrixForRectInsidePage(pageNumber: pageNumber, rect: rect, anchor: anchor);

  /// Go to the specified destination.
  ///
  /// [dest] specifies the destination.
  /// [duration] specifies the duration of the animation.
  Future<bool> goToDest(PdfDest? dest, {Duration duration = const Duration(milliseconds: 200)}) =>
      _state._goToDest(dest, duration: duration);

  /// Calculate the matrix for the specified destination.
  ///
  /// [dest] specifies the destination.
  Matrix4? calcMatrixForDest(PdfDest? dest) => _state._calcMatrixForDest(dest);

  /// Calculate the matrix to fit the page into the view.
  ///
  /// `/Fit` command on [PDF 32000-1:2008, 12.3.2.2 Explicit Destinations, Table 151](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf#page=374)
  Matrix4? calcMatrixForFit({required int pageNumber}) =>
      calcMatrixForDest(PdfDest(pageNumber, PdfDestCommand.fit, null));

  /// Calculate the matrix to fit the specified page width into the view.
  ///
  Matrix4? calcMatrixFitWidthForPage({required int pageNumber}) {
    final page = layout.pageLayouts[pageNumber - 1];
    final zoom = (viewSize.width - params.margin * 2) / page.width;
    final y = (viewSize.height / 2 - params.margin) / zoom;
    return calcMatrixFor(page.topCenter.translate(0, y), zoom: zoom, viewSize: viewSize);
  }

  /// Calculate the matrix to fit the specified page height into the view.
  ///
  Matrix4? calcMatrixFitHeightForPage({required int pageNumber}) {
    final page = layout.pageLayouts[pageNumber - 1];
    final zoom = (viewSize.height - params.margin * 2) / page.height;
    return calcMatrixFor(page.center, zoom: zoom, viewSize: viewSize);
  }

  /// Get list of possible matrices that fit some of the pages into the view.
  ///
  /// [sortInSuitableOrder] specifies whether the result is sorted in a suitable order.
  ///
  /// Because [PdfViewer] can show multiple pages at once, there are several possible
  /// matrices to fit the pages into the view according to several criteria.
  /// The method returns the list of such matrices.
  ///
  /// In theory, the method can be also used to determine the dominant pages in the view.
  List<PdfPageFitInfo> calcFitZoomMatrices({bool sortInSuitableOrder = true}) {
    final viewRect = visibleRect;
    final result = <PdfPageFitInfo>[];
    final pos = centerPosition;
    for (int i = 0; i < layout.pageLayouts.length; i++) {
      final page = layout.pageLayouts[i];
      if (page.intersect(viewRect).isEmpty) continue;
      final zoom = (viewSize.width - params.margin * 2) / page.width;
      // NOTE: keep the y-position but center the x-position
      final newMatrix = calcMatrixFor(Offset(page.left + page.width / 2, pos.dy), zoom: zoom);

      final intersection = newMatrix.calcVisibleRect(viewSize).intersect(page);
      // if the page is not visible after changing the zoom, ignore it
      if (intersection.isEmpty) continue;
      final intersectionRatio = intersection.width * intersection.height / (page.width * page.height);
      result.add(PdfPageFitInfo(pageNumber: i + 1, matrix: newMatrix, visibleAreaRatio: intersectionRatio));
    }
    if (sortInSuitableOrder) {
      result.sort((a, b) => b.visibleAreaRatio.compareTo(a.visibleAreaRatio));
    }
    return result;
  }

  /// Calculate the matrix for the page.
  ///
  /// [pageNumber] specifies the page number.
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Matrix4 calcMatrixForPage({required int pageNumber, PdfPageAnchor? anchor}) =>
      _state._calcMatrixForPage(pageNumber: pageNumber, anchor: anchor);

  /// Calculate the matrix for the specified area.
  ///
  /// [rect] specifies the area in document coordinates.
  /// [anchor] specifies how the page is positioned if the page is larger than the view.
  Matrix4 calcMatrixForArea({required Rect rect, PdfPageAnchor? anchor}) =>
      _state._calcMatrixForArea(rect: rect, anchor: anchor);

  /// Go to the specified position by the matrix.
  ///
  /// All the `goToXXX` functions internally calls the function.
  /// So if you customize the behavior of the viewer, you can extend [PdfViewerController] and override the function:
  ///
  /// ```dart
  /// class MyPdfViewerController extends PdfViewerController {
  ///   @override
  ///   Future<void> goTo(
  ///     Matrix4? destination, {
  ///     Duration duration = const Duration(milliseconds: 200),
  ///     }) async {
  ///       print('goTo');
  ///       super.goTo(destination, duration: duration);
  ///   }
  /// }
  /// ```
  Future<void> goTo(Matrix4? destination, {Duration duration = const Duration(milliseconds: 200)}) =>
      _state._goTo(destination, duration: duration);

  /// Ensure the specified area is visible inside the view port.
  ///
  /// If the area is larger than the view port, the area is zoomed to fit the view port.
  /// [margin] adds extra margin to the area.
  Future<void> ensureVisible(Rect rect, {Duration duration = const Duration(milliseconds: 200), double margin = 0}) =>
      _state._ensureVisible(rect, duration: duration, margin: margin);

  /// Calculate the matrix to center the specified position.
  Matrix4 calcMatrixFor(Offset position, {double? zoom, Size? viewSize}) =>
      _state._calcMatrixFor(position, zoom: zoom ?? currentZoom, viewSize: viewSize ?? this.viewSize);

  Offset get centerPosition => value.calcPosition(viewSize);

  Matrix4 calcMatrixForRect(Rect rect, {double? zoomMax, double? margin}) =>
      _state._calcMatrixForRect(rect, zoomMax: zoomMax, margin: margin);

  Matrix4 calcMatrixToEnsureRectVisible(Rect rect, {double margin = 0}) =>
      _state._calcMatrixToEnsureRectVisible(rect, margin: margin);

  /// Do hit-test against laid out pages.
  ///
  /// Returns the hit-test result if the specified offset is inside a page; otherwise null.
  ///
  /// [useDocumentLayoutCoordinates] specifies whether the offset is in the document layout coordinates;
  /// if true, the offset is in the document layout coordinates; otherwise, the offset is in the widget coordinates.
  PdfPageHitTestResult? getPdfPageHitTestResult(Offset offset, {required bool useDocumentLayoutCoordinates}) =>
      _state._getPdfPageHitTestResult(offset, useDocumentLayoutCoordinates: useDocumentLayoutCoordinates);

  /// Set the current page number.
  ///
  /// This function does not scroll/zoom to the specified page but changes the current page number.
  void setCurrentPageNumber(int pageNumber) => _state._setCurrentPageNumber(pageNumber);

  double get currentZoom => value.zoom;

  Future<void> setZoom(Offset position, double zoom, {Duration duration = const Duration(milliseconds: 200)}) =>
      _state._setZoom(position, zoom, duration: duration);

  Future<void> zoomUp({bool loop = false, Offset? zoomCenter, Duration duration = const Duration(milliseconds: 200)}) =>
      _state._zoomUp(loop: loop, zoomCenter: zoomCenter, duration: duration);

  Future<void> zoomDown({
    bool loop = false,
    Offset? zoomCenter,
    Duration duration = const Duration(milliseconds: 200),
  }) => _state._zoomDown(loop: loop, zoomCenter: zoomCenter, duration: duration);

  RenderBox? get renderBox => _state._renderBox;

  /// Converts the global position to the local position in the widget.
  Offset? globalToLocal(Offset global) => _state._globalToLocal(global);

  /// Converts the local position to the global position in the widget.
  Offset? localToGlobal(Offset local) => _state._localToGlobal(local);

  /// Converts the global position to the local position in the PDF document structure.
  Offset? globalToDocument(Offset global) => _state._globalToDocument(global);

  /// Converts the local position in the PDF document structure to the global position.
  Offset? documentToGlobal(Offset document) => _state._documentToGlobal(document);

  /// Provided to workaround certain widgets eating wheel events. Use with [Listener.onPointerSignal].
  void handlePointerSignalEvent(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _state._onWheelDelta(event);
    }
  }

  /// Invalidates the current Widget display state.
  ///
  /// Almost identical to `setState` but can be called outside the state.
  void invalidate() => _state._invalidate();

  /// The text selection delegate.
  PdfTextSelectionDelegate get textSelectionDelegate => _state;
}

/// [PdfViewerController.calcFitZoomMatrices] returns the list of this class.
@immutable
class PdfPageFitInfo {
  const PdfPageFitInfo({required this.pageNumber, required this.matrix, required this.visibleAreaRatio});

  /// The page number of the target page.
  final int pageNumber;

  /// The matrix to fit the page horizontally into the view.
  final Matrix4 matrix;

  /// The ratio of the visible area of the page. 1 means the whole page is visible inside the view.
  final double visibleAreaRatio;

  @override
  String toString() => 'PdfPageFitInfo(pageNumber=$pageNumber, visibleAreaRatio=$visibleAreaRatio, matrix=$matrix)';
}

extension PdfMatrix4Ext on Matrix4 {
  /// Zoom ratio of the matrix.
  double get zoom => storage[0];

  /// X position of the matrix.
  double get xZoomed => storage[12];

  /// X position of the matrix.
  set xZoomed(double value) => storage[12] = value;

  /// Y position of the matrix.
  double get yZoomed => storage[13];

  /// Y position of the matrix.
  set yZoomed(double value) => storage[13] = value;

  double get x => xZoomed / zoom;

  set x(double value) => xZoomed = value * zoom;

  double get y => yZoomed / zoom;

  set y(double value) => yZoomed = value * zoom;

  /// Calculate the position of the matrix based on the specified view size.
  ///
  /// Because [Matrix4] does not have the information of the view size,
  /// this function calculates the position based on the specified view size.
  Offset calcPosition(Size viewSize) => Offset((viewSize.width / 2 - xZoomed), (viewSize.height / 2 - yZoomed)) / zoom;

  /// Calculate the visible rectangle based on the specified view size.
  ///
  /// [margin] adds extra margin to the area.
  /// Because [Matrix4] does not have the information of the view size,
  /// this function calculates the visible rectangle based on the specified view size.
  Rect calcVisibleRect(Size viewSize, {double margin = 0}) => Rect.fromCenter(
    center: calcPosition(viewSize),
    width: (viewSize.width - margin * 2) / zoom,
    height: (viewSize.height - margin * 2) / zoom,
  );

  Offset transformOffset(Offset xy) {
    final x = xy.dx;
    final y = xy.dy;
    final w = x * storage[3] + y * storage[7] + storage[15];
    return Offset(
      (x * storage[0] + y * storage[4] + storage[12]) / w,
      (x * storage[1] + y * storage[5] + storage[13]) / w,
    );
  }
}

extension _RangeDouble<T extends num> on T {
  /// Identical to [num.clamp] but it does nothing if [a] is larger or equal to [b].
  T range(T a, T b) => a < b ? clamp(a, b) as T : (a + b) / 2 as T;
}

extension RectExt on Rect {
  Rect operator *(double operand) => Rect.fromLTRB(left * operand, top * operand, right * operand, bottom * operand);

  Rect operator /(double operand) => Rect.fromLTRB(left / operand, top / operand, right / operand, bottom / operand);

  bool containsRect(Rect other) => contains(other.topLeft) && contains(other.bottomRight);

  Rect inflateHV({required double horizontal, required double vertical}) =>
      Rect.fromLTRB(left - horizontal, top - vertical, right + horizontal, bottom + vertical);
}

/// Create a [CustomPainter] from a paint function.
class _CustomPainter extends CustomPainter {
  /// Create a [CustomPainter] from a paint function.
  const _CustomPainter.fromFunctions(this.paintFunction, {this.hitTestFunction});
  final void Function(ui.Canvas canvas, ui.Size size) paintFunction;
  final bool Function(ui.Offset position)? hitTestFunction;
  @override
  void paint(ui.Canvas canvas, ui.Size size) => paintFunction(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(ui.Offset position) {
    if (hitTestFunction == null) return false;
    return hitTestFunction!(position);
  }
}

Widget _defaultErrorBannerBuilder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
  PdfDocumentRef documentRef,
) {
  return pdfErrorWidget(context, error, stackTrace: stackTrace);
}

/// Handles the link painting and tap handling.
class _CanvasLinkPainter {
  _CanvasLinkPainter(this._state);
  final _PdfViewerState _state;
  MouseCursor _cursor = MouseCursor.defer;
  final _links = <int, List<PdfLink>>{};

  bool get isEnabled => _state.widget.params.linkHandlerParams != null;

  /// Reset all the internal data.
  void resetAll() {
    _cursor = MouseCursor.defer;
    _links.clear();
  }

  /// Release the page data.
  void releaseLinksForPage(int pageNumber) {
    _links.remove(pageNumber);
  }

  List<PdfLink>? _ensureLinksLoaded(PdfPage page, {void Function()? onLoaded}) {
    final links = _links[page.pageNumber];
    if (links != null) return links;
    synchronized(() async {
      final links = _links[page.pageNumber];
      if (links != null) return links;
      final enableAutoLinkDetection = _state.widget.params.linkHandlerParams?.enableAutoLinkDetection ?? true;
      _links[page.pageNumber] = await page.loadLinks(compact: true, enableAutoLinkDetection: enableAutoLinkDetection);
      if (onLoaded != null) {
        onLoaded();
      } else {
        _state._invalidate();
      }
    });
    return null;
  }

  PdfLink? _findLinkAtPosition(Offset position) {
    final hitResult = _state._getPdfPageHitTestResult(position, useDocumentLayoutCoordinates: false);
    if (hitResult == null) return null;
    final links = _ensureLinksLoaded(hitResult.page);
    if (links == null) return null;
    for (final link in links) {
      for (final rect in link.rects) {
        if (rect.containsPoint(hitResult.offset)) {
          return link;
        }
      }
    }
    return null;
  }

  bool _handleLinkTap(Offset tapPosition) {
    _cursor = MouseCursor.defer;
    final link = _findLinkAtPosition(tapPosition);
    if (link != null) {
      final onLinkTap = _state.widget.params.linkHandlerParams?.onLinkTap;
      if (onLinkTap != null) {
        onLinkTap(link);
        return true;
      }
    }
    _state._clearTextSelections();
    return false;
  }

  void _handleLinkMouseCursor(Offset position, void Function(void Function()) setState) {
    final link = _findLinkAtPosition(position);
    final newCursor = link == null ? MouseCursor.defer : SystemMouseCursors.click;
    if (newCursor != _cursor) {
      _cursor = newCursor;
      setState(() {});
    }
  }

  /// Creates a [GestureDetector] for handling link taps and mouse cursor.
  Widget linkHandlingOverlay(Size size) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // link taps
      onTapUp: (details) => _handleLinkTap(details.localPosition),
      child: StatefulBuilder(
        builder: (context, setState) {
          return MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            onHover: (event) => _handleLinkMouseCursor(event.localPosition, setState),
            onExit: (event) {
              _cursor = MouseCursor.defer;
              setState(() {});
            },
            cursor: _cursor,
            child: IgnorePointer(child: SizedBox(width: size.width, height: size.height)),
          );
        },
      ),
    );
  }

  /// Paints the link highlights.
  void paintLinkHighlights(Canvas canvas, Rect pageRect, PdfPage page) {
    final links = _ensureLinksLoaded(page);
    if (links == null) return;

    final customPainter = _state.widget.params.linkHandlerParams?.customPainter;

    if (customPainter != null) {
      customPainter.call(canvas, pageRect, page, links);
      return;
    }

    final paint =
        Paint()
          ..color = _state.widget.params.linkHandlerParams?.linkColor ?? Colors.blue.withAlpha(50)
          ..style = PaintingStyle.fill;
    for (final link in links) {
      for (final rect in link.rects) {
        final rectLink = rect.toRectInDocument(page: page, pageRect: pageRect);
        canvas.drawRect(rectLink, paint);
      }
    }
  }
}

class _PdfViewerKeyHandler extends StatefulWidget {
  const _PdfViewerKeyHandler({required this.child, required this.onKeyRepeat, required this.params});

  /// Called on every key repeat.
  ///
  /// See [PdfViewerOnKeyCallback] for the parameters.
  final bool Function(PdfViewerKeyHandlerParams, LogicalKeyboardKey, bool) onKeyRepeat;
  final PdfViewerKeyHandlerParams params;
  final Widget child;

  @override
  _PdfViewerKeyHandlerState createState() => _PdfViewerKeyHandlerState();
}

class _PdfViewerKeyHandlerState extends State<_PdfViewerKeyHandler> {
  Timer? _timer;
  LogicalKeyboardKey? _currentKey;

  void _startRepeating(FocusNode node, LogicalKeyboardKey key) {
    _currentKey = key;

    // Initial delay before starting to repeat
    _timer = Timer(widget.params.initialDelay, () {
      // Start repeating at the specified interval
      _timer = Timer.periodic(widget.params.repeatInterval, (_) {
        widget.onKeyRepeat(widget.params, _currentKey!, false);
      });
    });
  }

  void _stopRepeating() {
    _timer?.cancel();
    _timer = null;
    _currentKey = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.params.focusNode,
      parentNode: widget.params.parentNode,
      autofocus: widget.params.autofocus,
      canRequestFocus: widget.params.canRequestFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Key pressed down
          if (_currentKey == null) {
            if (widget.onKeyRepeat(widget.params, event.logicalKey, true)) {
              _startRepeating(node, event.logicalKey);
              return KeyEventResult.handled;
            }
          }
        } else if (event is KeyUpEvent) {
          // Key released
          if (_currentKey == event.logicalKey) {
            _stopRepeating();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          return ListenableBuilder(
            listenable: focusNode,
            builder: (context, _) {
              return widget.child;
            },
          );
        },
      ),
    );
  }
}
