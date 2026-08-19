import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/model/server/snippet.dart';
import 'package:server_box/data/provider/server/all.dart';
import 'package:server_box/data/provider/snippet.dart';
import 'package:server_box/view/page/ssh/snippet_run.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_nav.dart';
import 'package:server_box/view/platform/ios_palette.dart';
import 'package:server_box/view/widget/page_columns.dart';

final class SnippetEditPageArgs {
  final Snippet? snippet;
  const SnippetEditPageArgs({this.snippet});
}

class SnippetEditPage extends ConsumerStatefulWidget {
  final SnippetEditPageArgs? args;

  const SnippetEditPage({super.key, this.args});

  @override
  ConsumerState<SnippetEditPage> createState() => _SnippetEditPageState();

  static const route = AppRoute(
    page: SnippetEditPage.new,
    path: '/snippets/edit',
  );
}

class _SnippetEditPageState extends ConsumerState<SnippetEditPage> {
  final _nameController = TextEditingController();
  final _scriptController = TextEditingController();
  final _noteController = TextEditingController();
  final _scriptNode = FocusNode();
  final _autoRunOn = ValueNotifier(<String>[]);
  final _tags = <String>{}.vn;

  /// Filled here rather than after the first layout: the page is opened beside
  /// the list, where its first frame is the one that animates in. Loading the
  /// snippet a frame later meant that animation started on an empty form and
  /// the fields appeared in the middle of it.
  @override
  void initState() {
    super.initState();
    final snippet = widget.args?.snippet;
    if (snippet == null) return;
    _nameController.text = snippet.name;
    _scriptController.text = snippet.script;
    if (snippet.note != null) _noteController.text = snippet.note!;
    if (snippet.tags != null) _tags.value = snippet.tags!.toSet();
    if (snippet.autoRunOn != null) _autoRunOn.value = snippet.autoRunOn!;
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _scriptController.dispose();
    _noteController.dispose();
    _scriptNode.dispose();
    _autoRunOn.dispose();
    _tags.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      final snippet = widget.args?.snippet;
      return IosNavBar(
        title: libL10n.edit,
        actions: [
          Tooltip(
            message: libL10n.save,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: _save,
              child: const Icon(CupertinoIcons.checkmark, size: 22),
            ),
          ),
          if (snippet != null)
            Tooltip(
              message: libL10n.delete,
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _confirmDelete(snippet),
                child: const Icon(CupertinoIcons.trash, size: 21),
              ),
            ),
        ],
        body: _buildIosBody(),
        bottom: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: CupertinoButton.filled(
              onPressed: _run,
              child: Text(libL10n.run),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(libL10n.edit),
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Future<void> _confirmDelete(Snippet snippet) async {
    final confirmed = await context.showRoundDialog<bool>(
      title: libL10n.attention,
      child: Text(
        libL10n.askContinue('${libL10n.delete} ${libL10n.snippet}(${snippet.name})'),
      ),
      actions: Btn.ok(red: true).toList,
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(snippetProvider.notifier).del(snippet);
    _leave();
  }

  Widget _buildIosBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        IosSection(
          children: [
            _iosField(
              controller: _nameController,
              label: libL10n.name,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_scriptNode),
            ),
            _iosField(
              controller: _noteController,
              label: libL10n.note,
              minLines: 3,
              maxLines: 3,
            ),
            _iosField(
              controller: _scriptController,
              label: libL10n.snippet,
              minLines: 3,
              maxLines: 10,
              node: _scriptNode,
            ),
          ],
        ),
        IosSection(
          children: [
            Consumer(
              builder: (_, ref, _) {
                final tags = ref.watch(snippetProvider.select((p) => p.tags));
                return IosRow(
                  title: libL10n.tag,
                  subtitle: _tags.value.isEmpty ? null : _tags.value.join(', '),
                  leading: const IosSettingsIcon(CupertinoIcons.tag),
                  chevron: true,
                  onTap: () => _showIosTagPicker(tags),
                );
              },
            ),
            _buildIosAutoRunOn(),
          ],
        ),
        _buildTip(),
      ],
    );
  }

  Widget _iosField({
    required TextEditingController controller,
    required String label,
    FocusNode? node,
    int minLines = 1,
    int? maxLines,
    void Function(String)? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: CupertinoTextField(
        controller: controller,
        focusNode: node,
        minLines: minLines,
        maxLines: maxLines,
        autocorrect: false,
        onSubmitted: onSubmitted,
        placeholder: label,
        placeholderStyle: TextStyle(
          color: IosPalette.secondaryLabelByBrightness(isDark),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: null,
      ),
    );
  }

  Future<void> _showIosTagPicker(Set<String> allTags) async {
    final all = {...allTags, ..._tags.value}.toList();
    final res = await context.showPickDialog(
      items: all,
      initial: _tags.value.toList(),
      clearable: true,
      actions: [
        TextButton(
          onPressed: () {
            context.popDialog();
            _tags.value = {};
          },
          child: Text(libL10n.clear),
        ),
        TextButton(
          onPressed: () => context.popDialog(true),
          child: Text(libL10n.ok),
        ),
      ],
    );
    if (res == null) return;
    _tags.value = res.cast<String>().toSet();
  }

  Future<void> _showIosAutoRunPicker() async {
    final validServerIds = _autoRunOn.value
        .where((e) => ref.read(serversProvider).serverOrder.contains(e))
        .toList();
    final serverIds = await context.showPickDialog(
      title: l10n.autoRun,
      items: ref.read(serversProvider).serverOrder,
      display: (e) => ref.read(serversProvider).servers[e]?.name ?? e,
      initial: validServerIds,
      clearable: true,
    );
    if (serverIds != null) {
      _autoRunOn.value = serverIds.cast<String>().toList();
    }
  }

  Widget _buildIosAutoRunOn() {
    return ValBuilder(
      listenable: _autoRunOn,
      builder: (vals) {
        final subtitle = vals.isEmpty
            ? null
            : vals
                  .map((e) => ref.read(serversProvider).servers[e]?.name ?? e)
                  .join(', ');
        return IosRow(
          title: l10n.autoRun,
          subtitle: subtitle,
          leading: const IosSettingsIcon(CupertinoIcons.play_circle),
          chevron: true,
          onTap: _showIosAutoRunPicker,
        );
      },
    );
  }

  /// Leaves the editor, wherever it is.
  ///
  /// A pushed page pops. As the content pane's root page there is nothing to
  /// pop — `context.pop()` there does nothing and looks broken — so the way
  /// out is closing the pane, which hands the width back to the list.
  void _leave() {
    final closePane = PaneScope.closeDetailOf(context);
    if (closePane != null) {
      closePane();
      return;
    }
    context.pop();
  }

  List<Widget> _buildAppBarActions() {
    final snippet = widget.args?.snippet;
    return [
      // Saving lives here rather than under the corner button it used to be:
      // running is what a snippet is for, and it is the corner that a thumb
      // reaches. Saving and deleting are both edits to this record, so they
      // sit together.
      IconButton(
        onPressed: _save,
        tooltip: libL10n.save,
        icon: const Icon(Icons.save),
      ),
      if (snippet != null) _buildDeleteBtn(snippet),
    ];
  }

  Widget _buildDeleteBtn(Snippet snippet) {
    return IconButton(
        onPressed: () async {
          // The dialog answers, and this — which is on the page — acts on the
          // answer. Deleting and closing the page from inside the dialog's
          // button meant two pops in a row from a callback that can see two
          // navigators, and getting their order or their target wrong is
          // silent.
          final confirmed = await context.showRoundDialog<bool>(
            title: libL10n.attention,
            child: Text(
              libL10n.askContinue(
                '${libL10n.delete} ${libL10n.snippet}(${snippet.name})',
              ),
            ),
            actions: Btn.ok(red: true).toList,
          );
          if (confirmed != true || !context.mounted) return;
          ref.read(snippetProvider.notifier).del(snippet);
          _leave();
        },
        tooltip: libL10n.delete,
        icon: const Icon(Icons.delete),
      );
  }

  /// What the fields say right now, saved or not.
  ///
  /// Running reads this rather than `widget.args.snippet`, so a script can be
  /// changed and tried without committing it first — which is the loop this
  /// page exists for.
  Snippet? _draft() {
    final name = _nameController.text;
    final script = _scriptController.text;
    if (name.isEmpty || script.isEmpty) {
      Toast.show(libL10n.empty);
      return null;
    }
    final note = _noteController.text;
    return Snippet(
      name: name,
      script: script,
      tags: _tags.value.isEmpty ? null : _tags.value.toList(),
      note: note.isEmpty ? null : note,
      autoRunOn: _autoRunOn.value.isEmpty ? null : _autoRunOn.value,
    );
  }

  void _save() {
    final snippet = _draft();
    if (snippet == null) return;
    final oldSnippet = widget.args?.snippet;
    final notifier = ref.read(snippetProvider.notifier);
    if (oldSnippet != null) {
      notifier.update(oldSnippet, snippet);
    } else {
      notifier.add(snippet);
    }
    _leave();
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'snippetRun',
      tooltip: libL10n.run,
      onPressed: _run,
      child: const Icon(Icons.play_arrow),
    );
  }

  /// Picks a server, then runs what is in the editor on it.
  ///
  /// No second confirmation: the script is the thing on screen behind this
  /// button, and a dialog quoting it back is the same text twice.
  Future<void> _run() async {
    final snippet = _draft();
    if (snippet == null) return;

    final servers = ref.read(serversProvider);
    final spis = [for (final id in servers.serverOrder) ?servers.servers[id]];
    if (spis.isEmpty) {
      Toast.show(libL10n.empty);
      return;
    }

    final chosen = await context.showPickSingleDialog<Spi>(
      title: libL10n.server,
      items: spis,
      display: (spi) => spi.name,
    );
    if (chosen == null || !mounted) return;

    SnippetRunPage.route.go(
      context,
      SnippetRunPageArgs(spi: chosen, snippet: snippet),
    );
  }

  Widget _buildBody() {
    return PageColumns(
        children: [
          Input(
            autoFocus: true,
            controller: _nameController,
            type: TextInputType.text,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_scriptNode),
            label: libL10n.name,
            icon: Icons.info,
            suggestion: true,
          ),
          Input(
            controller: _noteController,
            minLines: 3,
            maxLines: 3,
            type: TextInputType.multiline,
            label: libL10n.note,
            icon: Icons.note,
            suggestion: true,
          ),
          Consumer(
            builder: (_, ref, _) {
              final tags = ref.watch(snippetProvider.select((p) => p.tags));
              return TagTile(tags: _tags, allTags: tags).cardx;
            },
          ),
          Input(
            controller: _scriptController,
            node: _scriptNode,
            minLines: 3,
            maxLines: 10,
            type: TextInputType.multiline,
            label: libL10n.snippet,
            icon: Icons.code,
            suggestion: false,
          ),
          _buildAutoRunOn(),
          _buildTip(),
        ],
    );
  }

  Widget _buildAutoRunOn() {
    return CardX(
      child: ValBuilder(
        listenable: _autoRunOn,
        builder: (vals) {
          final subtitle = vals.isEmpty
              ? null
              : vals
                    .map((e) => ref.read(serversProvider).servers[e]?.name ?? e)
                    .join(', ');
          return ListTile(
            leading: const Padding(
              padding: EdgeInsets.only(left: 5),
              child: Icon(Icons.settings_remote, size: 19),
            ),
            title: Text(l10n.autoRun),
            trailing: const Icon(Icons.keyboard_arrow_right),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle,
                    maxLines: 1,
                    style: UIs.textGrey,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () async {
              // Create a filtered copy for the dialog, don't modify the original
              final validServerIds = vals
                  .where(
                    (e) => ref.read(serversProvider).serverOrder.contains(e),
                  )
                  .toList();
              final serverIds = await context.showPickDialog(
                title: l10n.autoRun,
                items: ref.read(serversProvider).serverOrder,
                display: (e) => ref.read(serversProvider).servers[e]?.name ?? e,
                initial: validServerIds,
                clearable: true,
              );
              if (serverIds != null) {
                _autoRunOn.value = serverIds;
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTip() {
    return CardX(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: SimpleMarkdown(
          data:
              '''
📌 ${l10n.supportFmtArgs}\n
${SnippetX.fmtArgs.keys.map((e) => '`$e`').join(', ')}\n

${SnippetX.fmtTermKeys.keys.map((e) => '`$e+?}`').join(', ')}\n
${libL10n.example}: 
- `\${ctrl+c}` (Control + C)
- `\${ctrl+b}d` (Tmux Detach)
''',
          styleSheet: MarkdownStyleSheet(
            codeblockDecoration: const BoxDecoration(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}
