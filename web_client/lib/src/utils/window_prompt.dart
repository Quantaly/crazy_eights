import 'dart:js';

/// Because apparently they forgot about it in dart:html.
///
/// See [https://www.w3schools.com/jsref/met_win_prompt.asp].
String windowPrompt(String text, [String defaultText]) {
  return context.callMethod("prompt", [
    text,
    if (defaultText != null) defaultText,
  ]);
}
