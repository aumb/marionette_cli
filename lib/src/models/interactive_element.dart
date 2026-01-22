/// Represents an interactive UI element in the Flutter app.
///
/// Elements are discoverable via the `elements` command and can be
/// interacted with using commands like `tap`, `text`, and `scroll`.
class InteractiveElement {
  /// Unique key identifier for this element.
  ///
  /// Use this key with interaction commands like `tap` and `text`.
  final String key;

  /// The widget type (e.g., 'ElevatedButton', 'TextField', 'Text').
  final String type;

  /// Human-readable label or text content of the element.
  final String? label;

  /// Bounding rectangle of the element in logical pixels.
  final ElementBounds? bounds;

  /// Whether the element is currently enabled for interaction.
  final bool isEnabled;

  /// Whether the element is currently visible on screen.
  final bool isVisible;

  /// Whether this element appears to be a loading indicator.
  final bool isLoading;

  /// Whether this element is a dialog or popup overlay.
  final bool isDialog;

  /// Child elements within this element.
  final List<InteractiveElement> children;

  const InteractiveElement({
    required this.key,
    required this.type,
    this.label,
    this.bounds,
    this.isEnabled = true,
    this.isVisible = true,
    this.isLoading = false,
    this.isDialog = false,
    this.children = const [],
  });

  /// Creates an InteractiveElement from a JSON map.
  factory InteractiveElement.fromJson(Map<String, dynamic> json) {
    return InteractiveElement(
      key: json['key'] as String? ?? '',
      type: json['type'] as String? ?? 'Unknown',
      label: json['label'] as String?,
      bounds: json['bounds'] != null
          ? ElementBounds.fromJson(json['bounds'] as Map<String, dynamic>)
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isVisible: json['isVisible'] as bool? ?? true,
      isLoading: json['isLoading'] as bool? ?? false,
      isDialog: json['isDialog'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map(
                  (e) => InteractiveElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this element to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'type': type,
      if (label != null) 'label': label,
      if (bounds != null) 'bounds': bounds!.toJson(),
      'isEnabled': isEnabled,
      'isVisible': isVisible,
      if (isLoading) 'isLoading': isLoading,
      if (isDialog) 'isDialog': isDialog,
      if (children.isNotEmpty)
        'children': children.map((c) => c.toJson()).toList(),
    };
  }

  /// Returns a compact string representation for display.
  String toCompactString() {
    final buffer = StringBuffer()
      ..write(type)
      ..write('(key: "$key"');
    if (label != null) {
      buffer.write(', label: "$label"');
    }
    if (!isEnabled) {
      buffer.write(', disabled');
    }
    if (isLoading) {
      buffer.write(', loading');
    }
    if (isDialog) {
      buffer.write(', dialog');
    }
    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() => toCompactString();
}

/// Represents the bounding rectangle of an element.
class ElementBounds {
  /// Left edge position in logical pixels.
  final double left;

  /// Top edge position in logical pixels.
  final double top;

  /// Width in logical pixels.
  final double width;

  /// Height in logical pixels.
  final double height;

  const ElementBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Right edge position.
  double get right => left + width;

  /// Bottom edge position.
  double get bottom => top + height;

  /// Creates bounds from a JSON map.
  factory ElementBounds.fromJson(Map<String, dynamic> json) {
    return ElementBounds(
      left: (json['left'] as num?)?.toDouble() ?? 0,
      top: (json['top'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  @override
  String toString() => 'Bounds($left, $top, $width x $height)';
}
