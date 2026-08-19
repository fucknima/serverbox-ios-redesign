part of 'page.dart';

extension _VirtKey on SSHPageState {
  void _reloadVirtKeys() {
    _horizonVirtKeys = Stores.setting.horizonVirtKey.fetch();
    _initVirtKeys();
    _updateVirtKeysHeight();
  }

  void _doVirtualKey(VirtKey item, VirtKeyboard virtKeyNotifier) {
    if (item.func != null) {
      HapticFeedback.mediumImpact();
      _doVirtualKeyFunc(item.func!);
      return;
    }
    if (item.key != null) {
      HapticFeedback.mediumImpact();
      _doVirtualKeyInput(item.key!, virtKeyNotifier);
    }
    final inputRaw = item.inputRaw;
    if (inputRaw != null) {
      HapticFeedback.mediumImpact();
      _terminal.textInput(inputRaw);
    }
  }

  void _doVirtualKeyInput(TerminalKey key, VirtKeyboard virtKeyNotifier) {
    switch (key) {
      case TerminalKey.control:
        virtKeyNotifier.setCtrl(!virtKeyNotifier.ctrl);
        break;
      case TerminalKey.alt:
        virtKeyNotifier.setAlt(!virtKeyNotifier.alt);
        break;
      case TerminalKey.shift:
        virtKeyNotifier.setShift(!virtKeyNotifier.shift);
        break;
      default:
        _terminal.keyInput(key);
        break;
    }
  }

  Future<void> _doVirtualKeyFunc(VirtualKeyFunc type) async {
    switch (type) {
      case VirtualKeyFunc.toggleIME:
        _termKey.currentState?.toggleFocus();
        break;
      case VirtualKeyFunc.backspace:
        _terminal.keyInput(TerminalKey.backspace);
        break;
      case VirtualKeyFunc.clipboard:
        await _onClipboardAction();
        break;
      case VirtualKeyFunc.snippet:
        // Before the picker, not after it: a snippet's script is written
        // against a server, and browsing tags to choose one that is then
        // silently dropped is worse than the button doing nothing.
        final snippetSpi = widget.args.spi;
        if (snippetSpi == null) return;
        final snippetState = ref.read(snippetProvider);
        final snippets = await context.showPickWithTagDialog<Snippet>(
          title: libL10n.snippet,
          tags: snippetState.tags.vn,
          itemsBuilder: (e) {
            if (e == TagSwitcher.kDefaultTag) {
              return snippetState.snippets;
            }
            return snippetState.snippets
                .where((element) => element.tags?.contains(e) ?? false)
                .toList();
          },
          display: (e) => e.name,
        );
        if (snippets == null || snippets.isEmpty) return;

        final snippet = snippets.firstOrNull;
        if (snippet == null) return;
        snippet.runInTerm(_terminal, snippetSpi);
        break;
      case VirtualKeyFunc.file:
        await _openServerFiles();
        break;
      case VirtualKeyFunc.sudoPassword:
        await _insertSudoPassword();
        break;
      case VirtualKeyFunc.tmuxSwitch:
        await _showTmuxSwitcher();
        break;
    }
  }

  /// Opens the SFTP browser at the terminal's current directory.
  ///
  /// Runs the PWD probe, then — on iOS, where a route push while the text
  /// input/keyboard is still live has been seen to abort the app — releases
  /// terminal focus and waits for the keyboard to settle before pushing.
  Future<void> _openServerFiles() async {
    if (_isOpeningFileBrowser) return;
    final fileSpi = widget.args.spi;
    if (fileSpi == null) return;
    _isOpeningFileBrowser = true;
    try {
      // get $PWD from SSH session with unique markers
      const marker = 'ServerBoxOutput';
      const markerEnd = 'ServerBoxEnd';
      const pwdCommand = 'echo "$marker:\$PWD:$markerEnd"';
      _terminal.textInput(pwdCommand);
      _terminal.keyInput(TerminalKey.enter);

      // Wait for output with timeout
      String? initPath;
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      final startTime = DateTime.now();
      final timeout = const Duration(seconds: 3);

      while (initPath == null) {
        if (!mounted) return;
        // Check if we've exceeded timeout
        if (DateTime.now().difference(startTime) > timeout) {
          contextSafe?.showRoundDialog(
            title: libL10n.error,
            child: Text(libL10n.empty),
          );
          return;
        }

        // Search for marked output in terminal buffer
        final cmds = _terminal.buffer.lines.toList();
        for (final line in cmds.reversed) {
          final lineStr = line.toString();
          if (lineStr.contains(marker) && lineStr.contains(markerEnd)) {
            // Extract path between markers
            final start = lineStr.indexOf(marker) + marker.length + 1; // +1 for ':'
            final end = lineStr.indexOf(markerEnd) - 1; // -1 for ':'
            if (start < end) {
              initPath = lineStr.substring(start, end);
              if (initPath.isEmpty || initPath == '\$PWD') {
                initPath = null;
              } else {
                break;
              }
            }
          }
        }

        // Short wait before checking again
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;

      if (!initPath.startsWith('/')) {
        context.showRoundDialog(
          title: libL10n.error,
          child: Text('${l10n.remotePath}: $initPath'),
        );
        return;
      }

      // iOS: let go of the terminal's text input and wait for the keyboard
      // transition to finish before pushing the page — pushing over a live
      // IME has been seen to SIGABRT in Flutter's text input plumbing. The
      // system channel hide is the explicit text-input teardown on top of
      // focus removal.
      if (isIOS) {
        widget.args.focusNode?.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await _waitForKeyboardDismiss();
        if (!mounted) return;
      }

      // Open the file browser in the file **tab**, exactly like the shortcut
      // on a server card does. Pushing SftpPage as a route over the live
      // terminal crashes on iOS (flutter#110671): the route transition
      // transforms the continuously-painting terminal underneath and
      // CoreGraphics aborts with "Transformed points can't form a rect".
      // Switching tabs keeps the terminal out of the thing being repainted.
      ref.read(sftpRequestsProvider.notifier).add(fileSpi, initialPath: initPath);
      ref.read(homeTabRequestProvider.notifier).go(AppTab.file);
    } finally {
      _isOpeningFileBrowser = false;
    }
  }

  /// Waits until the keyboard's view inset is gone, with a timeout so a
  /// stuck keyboard never blocks the route forever.
  Future<void> _waitForKeyboardDismiss() async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (mounted) {
      final bottom = MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
      if (bottom <= 1 || DateTime.now().isAfter(deadline)) return;
      // Give the framework a frame to rebuild the insets before asking again.
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _initVirtKeys() {
    _virtKeysList.clear();
    final disabled = Stores.setting.sshVirtKeysDisabled.fetch().toSet();
    final virtKeys = VirtKeyX.loadFromStore()
        .where((key) => !disabled.contains(key.index))
        .toList();
    for (int len = 0; len < virtKeys.length; len += 7) {
      if (len + 7 > virtKeys.length) {
        _virtKeysList.add(virtKeys.sublist(len));
      } else {
        _virtKeysList.add(virtKeys.sublist(len, len + 7));
      }
    }
  }
}
