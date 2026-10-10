import 'package:flutter/material.dart';

/// Represents a single step in a tutorial sequence.
///
/// Each step defines a target widget to highlight and the content to display
/// in the associated tooltip.
class TutorialStep {
  /// The GlobalKey of the widget to highlight in this tutorial step.
  ///
  /// This key must be assigned to the widget you want to target before
  /// showing the tutorial.
  final GlobalKey targetKey;

  /// The description text displayed in the tooltip.
  ///
  /// This is the main content that explains what the highlighted element does
  /// or how the user should interact with it.
  final String description;

  /// The title text displayed at the top of the tooltip.
  ///
  /// This should be a brief, descriptive title for the tutorial step.
  final String title;

  /// A unique identifier tag for this tutorial step.
  ///
  /// This can be used to identify specific steps in callbacks or analytics.
  /// If not provided, the step index will be used internally.
  final String? tag;

  /// Callback invoked when the user taps "Next" on this specific step.
  ///
  /// This callback is called before moving to the next step and provides
  /// step-specific handling. Use this instead of the deprecated [TutorialOverlay.onNext].
  ///
  /// The callback receives the current step's tag (or index as string if no tag is provided).
  final void Function(String stepTag)? onStepNext;

  /// Callback invoked before this step is shown, and awaited.
  ///
  /// Use it to get the target ready: scroll it into view, switch to the tab
  /// it is on, wait for an animation to end. The target is only looked up
  /// and measured once the returned future completes. Until then the overlay
  /// stays dimmed, without a highlight and without a tooltip.
  ///
  /// The callback receives the step's tag (or index as string if no tag is
  /// provided).
  final Future<void> Function(String stepTag)? onBeforeShow;

  /// Creates a new tutorial step.
  ///
  /// Required parameters:
  /// - [targetKey]: The key of the widget to highlight
  /// - [description]: The explanatory text for this step
  /// - [title]: The title for this step
  ///
  /// Optional parameters:
  /// - [tag]: A unique identifier for this step
  /// - [onStepNext]: Callback for when user taps "Next" on this step
  /// - [onBeforeShow]: Awaited before this step is shown
  TutorialStep({
    required this.targetKey,
    required this.description,
    required this.title,
    this.tag,
    this.onStepNext,
    this.onBeforeShow,
  });

  /// Returns the effective tag for this step.
  ///
  /// If [tag] is provided, returns it. Otherwise, returns the step index as a string.
  String getEffectiveTag(int stepIndex) {
    return tag ?? stepIndex.toString();
  }
}
