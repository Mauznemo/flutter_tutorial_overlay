import 'dart:ui';
import 'package:flutter/material.dart';
import 'tutorial_step.dart';

/// A customizable overlay widget for creating interactive tutorials.
///
/// This widget creates an overlay that highlights specific target widgets
/// and displays informative tooltips to guide users through your app.
///
/// Example usage:
/// ```dart
/// final tutorial = TutorialOverlay(
///   context: context,
///   steps: [
///     TutorialStep(
///       targetKey: myButtonKey,
///       title: "Action Button",
///       description: "Tap this button to perform the main action.",
///     ),
///   ],
///   onComplete: () => print('Tutorial finished!'),
/// );
/// tutorial.show();
/// ```
class TutorialOverlay {
  /// The build context used to insert the overlay.
  final BuildContext context;

  /// The list of tutorial steps to display.
  final List<TutorialStep> steps;

  /// Callback invoked when the tutorial is completed.
  final VoidCallback? onComplete;

  int _currentStep = 0;
  OverlayEntry? _overlayEntry;

  /// The estimated height of tooltips for positioning calculations.
  double tooltipEstimatedHeight;

  /// The maximum width of tooltips.
  double tooltipMaxWidth;

  /// Padding from screen edges when positioning tooltips.
  final double edgePadding;

  /// The blur intensity applied to the overlay background.
  final double blurSigma;

  /// The tint color applied over the blurred background.
  final Color overlayTint;

  /// The border radius of the highlighted target area.
  final double highlightRadius;

  /// The width of the border around highlighted targets.
  final double highlightBorderWidth;

  /// The color of the border around highlighted targets.
  final Color highlightBorderColor;

  /// Whether the overlay can be dismissed by tapping outside the tooltip.
  final bool dismissible;

  /// Custom style for the "Next" button.
  final ButtonStyle? nextButtonStyle;

  /// Custom style for the "Skip" button.
  final ButtonStyle? skipButtonStyle;

  /// Custom style for the "Finish" button.
  final ButtonStyle? finishButtonStyle;

  /// Callback invoked when the "Next" button is pressed.
  ///
  /// **Deprecated:** Use [TutorialStep.onStepNext] instead.
  @Deprecated(
    'Use TutorialStep.onStepNext instead. '
    'This will be removed in future releases.',
  )
  final VoidCallback? onNext;

  /// Callback invoked when the "Skip" button is pressed.
  final VoidCallback? onSkip;

  /// Callback invoked when the "Finish" button is pressed.
  final VoidCallback? onFinish;

  /// Whether to show navigation buttons in tooltips.
  final bool showButtons;

  /// The border radius of tooltip containers.
  final double tooltipBorderRadius;

  /// Additional padding around the highlighted target.
  final double targetPadding;

  /// The background color of tooltip containers.
  final Color tooltipBackgroundColor;

  /// The color of title text in tooltips.
  final Color? titleTextColor;

  /// The color of description text in tooltips.
  final Color? descriptionTextColor;

  /// The opacity of the blur overlay (0-255).
  int blurOpacity;

  /// Internal padding for tooltip content.
  EdgeInsetsGeometry? tooltipPadding;

  /// Custom text for the "Finish" button.
  final String? finishText;

  /// Custom text for the "Next" button.
  final String? nextText;

  /// Custom text for the "Skip" button.
  final String? skipText;

  /// Creates a new tutorial overlay.
  ///
  /// The [context] and [steps] parameters are required. All other parameters
  /// have sensible defaults but can be customized as needed.
  ///
  /// If [showButtons] is false, [dismissible] should be true to allow users
  /// to exit the tutorial.
  ///
  /// **Migration Note**: The [onNext] parameter is deprecated. Use [TutorialStep.onStepNext]
  /// in individual steps instead for better organization and step-specific handling.
  TutorialOverlay({
    @Deprecated(
      'Use TutorialStep.onStepNext instead. '
      'This will be removed in future releases.',
    )
    this.onNext,
    this.onSkip,
    this.onFinish,
    this.blurOpacity = 20,
    this.tooltipPadding,
    required this.context,
    required this.steps,
    this.onComplete,
    this.tooltipMaxWidth = 320,
    this.tooltipEstimatedHeight = 120,
    this.edgePadding = 16,
    this.blurSigma = 6,
    this.overlayTint = const Color(0x8A000000),
    this.highlightRadius = 12,
    this.highlightBorderWidth = 2,
    this.highlightBorderColor = Colors.transparent,
    this.tooltipBorderRadius = 8,
    this.tooltipBackgroundColor = Colors.white,
    this.titleTextColor,
    this.descriptionTextColor,
    this.targetPadding = 0,
    this.dismissible = false,
    this.nextButtonStyle,
    this.finishButtonStyle,
    this.skipButtonStyle,
    this.showButtons = true,
    this.nextText,
    this.finishText,
    this.skipText,
  }) : assert(
         dismissible || showButtons,
         'showButtons must be true or set dismissible to true\n'
         'If showButtons and dismissible is set ti false the user will not be able exit the tutorial overlay',
       ) {
    if (blurOpacity < 0) blurOpacity = 20;
  }

  /// Starts the tutorial by showing the first step.
  void show() => _showStep();

  /// Dismisses the tutorial overlay.
  void dismiss() => _removeOverlay();

  void _showStep() {
    if (_currentStep >= steps.length) {
      _removeOverlay();
      onComplete?.call();
      return;
    }

    final step = steps[_currentStep];
    final currentContext = step.targetKey.currentContext;
    assert(currentContext != null, '''
TutorialOverlay Error: Could not find target widget for step $_currentStep.

This happens because you're trying to highlight a widget that is not yet build like the widgets Flutter
creates automatically (example: the AppBar drawer button). That widget does
not exist in your widget tree, so it cannot have a GlobalKey.

Other possible causes:
- The widget is not built yet (e.g. off-screen in a scroll view).
- The GlobalKey is not assigned to the target widget.
''');

    final renderBox =
        step.targetKey.currentContext!.findRenderObject() as RenderBox;
    final holePos = renderBox.localToGlobal(Offset.zero);
    final holeSize = renderBox.size;

    final holeRect = Rect.fromLTWH(
      holePos.dx - targetPadding,
      holePos.dy - targetPadding,
      holeSize.width + targetPadding * 2,
      holeSize.height + targetPadding * 2,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screen = MediaQuery.of(context).size;

        final safetyBottomMargin = 20;

        // Decide whether tooltip goes above or below
        final bool showAtBottom =
            holeRect.bottom +
                edgePadding +
                tooltipEstimatedHeight +
                safetyBottomMargin >
            screen.height;

        // Tooltip vertical position
        double tooltipTop = showAtBottom
            ? (holeRect.top - edgePadding - tooltipEstimatedHeight)
            : (holeRect.bottom + edgePadding);

        tooltipTop = tooltipTop.clamp(
          edgePadding,
          screen.height - edgePadding - tooltipEstimatedHeight,
        );

        // Horizontal position: centered on hole
        final double tooltipWidth = tooltipMaxWidth;
        final double tooltipLeft = (holeRect.center.dx - tooltipWidth / 2)
            .clamp(edgePadding, screen.width - edgePadding - tooltipWidth);

        // Arrow offset inside tooltip (relative to its width)
        final arrowDx = (holeRect.center.dx - tooltipLeft)
            .clamp(20, tooltipWidth - 20)
            .toDouble();

        return Stack(
          children: [
            Positioned.fill(
              child: AbsorbPointer(absorbing: true, child: SizedBox()),
            ),

            _buildBlurWithHole(
              holeRect: holeRect,
              holeSize: holeSize,
              targetPadding: targetPadding,
              highlightRadius: highlightRadius,
              highlightBorderColor: highlightBorderColor,
            ),

            // Tooltip with arrow
            Positioned(
              top: tooltipTop,
              left: tooltipLeft,
              child: TooltipWrapper(
                onMeasured: (size) {
                  tooltipMaxWidth = size?.width ?? 0;
                  tooltipEstimatedHeight =
                      size?.height ?? 0; // update dynamically
                  _overlayEntry?.markNeedsBuild();
                },
                child: _buildTooltip(
                  title: step.title,
                  text: step.description,
                  showAtBottom: showAtBottom,
                  arrowDx: arrowDx,
                  width: tooltipWidth,
                  tooltipBorderRadius: tooltipBorderRadius,
                  tooltipBackgroundColor: tooltipBackgroundColor,
                  descriptionTextColor: descriptionTextColor,
                  titleTextColor: titleTextColor,
                  tooltipPadding: tooltipPadding,
                ),
              ),
            ),
            if (dismissible) GestureDetector(onTap: _removeOverlay),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildTooltip({
    required String title,
    required String text,
    required bool showAtBottom,
    required double arrowDx,
    required double width,
    required double tooltipBorderRadius,
    required Color tooltipBackgroundColor,
    required Color? descriptionTextColor,
    required Color? titleTextColor,
    required EdgeInsetsGeometry? tooltipPadding,
  }) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!showAtBottom)
            CustomPaint(
              painter: ArrowPainter(
                arrowDx: arrowDx,
                color: tooltipBackgroundColor,
                pointingDown: true,
              ),
              child: SizedBox(width: width, height: 12),
            ),
          Container(
            width: width,
            padding: tooltipPadding ?? EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tooltipBackgroundColor,
              borderRadius: BorderRadius.circular(tooltipBorderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: descriptionTextColor ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                if (showButtons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _removeOverlay();
                          onSkip?.call();
                        },
                        style:
                            skipButtonStyle ??
                            _buildDefaultButtonStyle(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                        child: Text(skipText ?? 'Skip'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _nextStep,
                        style: isLastStep
                            ? (finishButtonStyle ?? _buildDefaultButtonStyle())
                            : (nextButtonStyle ?? _buildDefaultButtonStyle()),
                        child: Text(
                          isLastStep
                              ? (finishText ?? 'Finish')
                              : (nextText ?? 'Next'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (showAtBottom)
            CustomPaint(
              painter: ArrowPainter(
                arrowDx: arrowDx,
                color: tooltipBackgroundColor,
                pointingDown: false,
              ),
              child: SizedBox(width: width, height: 12),
            ),
        ],
      ),
    );
  }

  ButtonStyle _buildDefaultButtonStyle({
    Color backgroundColor = Colors.blue,
    Color foregroundColor = Colors.white,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// Returns true if the current step is the last step in the tutorial.
  bool get isLastStep => _currentStep == steps.length - 1;

  Widget _buildBlurWithHole({
    required Rect holeRect,
    required Size holeSize,
    required double targetPadding,
    required double highlightRadius,
    required Color highlightBorderColor,
  }) {
    return Stack(
      children: [
        // Custom painted overlay with hole
        Positioned.fill(
          child: CustomPaint(
            painter: BlurOverlayPainter(
              holeRect: Rect.fromCenter(
                center: holeRect.center,
                width: holeSize.width + targetPadding * 2,
                height: holeSize.height + targetPadding * 2,
              ),
            ),
          ),
        ),

        // Apply blur to everything except the hole
        Positioned.fill(
          child: ClipPath(
            clipper: InvertedHoleClipper(
              holeRect: Rect.fromCenter(
                center: holeRect.center,
                width: holeSize.width + targetPadding * 2,
                height: holeSize.height + targetPadding * 2,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(color: Colors.black.withAlpha(blurOpacity)),
            ),
          ),
        ),

        // Highlight border
        Positioned(
          top: holeRect.center.dy - (holeSize.height / 2) - targetPadding,
          left: holeRect.center.dx - (holeSize.width / 2) - targetPadding,
          child: Container(
            height: holeSize.height + targetPadding * 2,
            width: holeSize.width + targetPadding * 2,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(highlightRadius),
              border: Border.all(color: highlightBorderColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    final step = steps[_currentStep];
    _currentStep++;

    if (_currentStep < steps.length) {
      _showStep();
      step.onStepNext?.call(step.getEffectiveTag(_currentStep));
      // ignore: deprecated_member_use_from_same_package
      onNext?.call();
    } else {
      step.onStepNext?.call(step.getEffectiveTag(_currentStep));
      _removeOverlay();
      onComplete?.call();
      onFinish?.call();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentStep = 0;
  }
}

/// Custom painter for drawing triangle arrows in tooltips.
class ArrowPainter extends CustomPainter {
  /// The horizontal offset of the arrow from the left edge.
  final double arrowDx;

  /// The color of the arrow.
  final Color color;

  /// Whether the arrow points down (true) or up (false).
  final bool pointingDown;

  /// Creates a new arrow painter.
  ArrowPainter({
    required this.arrowDx,
    required this.color,
    required this.pointingDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (pointingDown) {
      path.moveTo(arrowDx - 8, size.height);
      path.lineTo(arrowDx, 0);
      path.lineTo(arrowDx + 8, size.height);
    } else {
      path.moveTo(arrowDx - 8, 0);
      path.lineTo(arrowDx, size.height);
      path.lineTo(arrowDx + 8, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom clipper that creates an inverted hole in a path.
class InvertedHoleClipper extends CustomClipper<Path> {
  /// The rectangular area to exclude from the clipping path.
  final Rect holeRect;

  /// Creates a new inverted hole clipper.
  InvertedHoleClipper({required this.holeRect});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(8)));

    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Custom painter for the blur overlay background.
class BlurOverlayPainter extends CustomPainter {
  /// The rectangular area to exclude from the overlay.
  final Rect holeRect;

  /// Creates a new blur overlay painter.
  BlurOverlayPainter({required this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(0);

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(8)));

    final finalPath = Path.combine(PathOperation.difference, path, holePath);

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Internal widget for measuring tooltip dimensions.
class TooltipWrapper extends StatefulWidget {
  /// The child widget to measure.
  final Widget child;

  /// Callback invoked when the widget's size is measured.
  final void Function(Size? size) onMeasured;

  const TooltipWrapper({required this.child, required this.onMeasured});

  @override
  State<TooltipWrapper> createState() => _TooltipWrapperState();
}

class _TooltipWrapperState extends State<TooltipWrapper> {
  final GlobalKey _key = GlobalKey();
  bool offStage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _key.currentContext;
      if (context != null) {
        final size = context.size;
        widget.onMeasured(size);
        setState(() {
          offStage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: offStage,
      child: Container(key: _key, child: widget.child),
    );
  }
}
