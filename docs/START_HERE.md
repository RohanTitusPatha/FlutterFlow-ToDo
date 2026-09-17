# My Tasks — for FlutterFlow

A to-do list custom widget with adding, editing, completing, deleting, filters,
progress, and device-local saving. No Firebase or account setup is needed.

This package contains custom-widget source, not a FlutterFlow project or APK.
It has not been installed or compiled in your FlutterFlow account. Flutter/Dart
is not available in the creation environment, so runtime verification remains
to be done in FlutterFlow.

## Add it to FlutterFlow

1. Open or create a blank FlutterFlow project.
2. Open **Custom Code**, add a **Custom Widget**, and name it exactly
   **TodoListWidget**.
3. Keep the generated **width** and **height** parameters (Double). No other
   parameters are needed.
4. Keep FlutterFlow's automatic import block and its “Do not remove or modify
   the code above” line. Replace the generated widget code BELOW that line
   with the contents of **todo_list_widget.dart**, including its imports.
   If `package:flutter/material.dart` already appears above, include it only once.
5. Ensure **shared_preferences** is available under pub dependencies. Use
   `^2.3.0`, or keep the existing compatible 2.x version if it is already 2.3.0
   or newer. Do not add a duplicate dependency.
6. Save and compile the widget. Add **TodoListWidget** to your blank page from
   the custom widgets section of the widget palette.
7. Set both dimensions. For a quick preview, use **width 390, height 700**.
   For the app, give it the available page width and a bounded height that
   fits the page body. If the page body is a Column, put the widget in an
   Expanded child so it fits the remaining space. Keep the page's outer
   scrolling disabled; the widget scrolls itself. Avoid adding a second app bar.
8. Start **Test Mode** or **Run Mode** to use the list. The design canvas alone
   is not a full interaction or persistence test.

## Use it

- Write a task and press **+** or Enter.
- Tick the checkbox to complete or reopen a task.
- Open **⋮ → Edit** to change its title, then press the check button to save.
- Open **⋮ → Delete** to remove a task. Deletion is immediate.
- Switch between **All**, **Active**, and **Done**.

## Quick check after compiling

1. Add two tasks. Try submitting an empty or whitespace-only task; it should
   display a message without creating a task.
2. Complete one task. Check the progress and Active/Done filters.
3. Edit the other task, save it, and reload the same app URL or reopen the app.
   Both tasks and the completed state should remain.
4. Delete a task and reload again. The deleted task should stay deleted.
5. Check the page on a small phone viewport with the keyboard open.

## Saving

Tasks stay in the same app/device/browser profile. They are not synced between
devices or accounts. Browser Test Mode and the published app may have different
storage. Clearing app data, browser site data, or using a private browser session
can remove them. Place one instance of this widget in the app; multiple instances
or browser tabs do not live-sync with one another.

## Customize

In `todo_list_widget.dart`, change `_green` for the accent colour and
`_background` for the background. The heading is the text `My tasks`.
Internal controls are edited in this code; FlutterFlow sees the list as one
custom widget, not a tree of separate drag-and-drop controls.

## Official references

- Custom widgets, compilation, and dimensions:
  https://docs.flutterflow.io/concepts/custom-code/custom-widgets/
- Custom code and dependencies:
  https://docs.flutterflow.io/concepts/custom-code/
- Local storage API:
  https://pub.dev/packages/shared_preferences
