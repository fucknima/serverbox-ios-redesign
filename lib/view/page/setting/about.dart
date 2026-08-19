part of 'entry.dart';

const _sponsorUrl = 'https://cdn.lpkt.cn/donate';

final class _AppAboutPage extends StatefulWidget {
  const _AppAboutPage();

  @override
  State<_AppAboutPage> createState() => _AppAboutPageState();
}

final class _AppAboutPageState extends State<_AppAboutPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isIOS) return _buildIos();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          UIs.height13,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 47, maxWidth: 47),
            child: UIs.appIcon,
          ),
          const Text(
            '${BuildData.name}\nv${BuildData.build}',
            textAlign: TextAlign.center,
            style: UIs.text15,
          ),
          UIs.height13,
          SizedBox(
            height: 77,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Btn.elevated(
                  icon: const Icon(Icons.edit_document),
                  text: libL10n.menuWiki,
                  onTap: Urls.appWiki.launchUrl,
                ),
                Btn.elevated(
                  icon: const Icon(Icons.feedback),
                  text: libL10n.feedback,
                  onTap: Urls.appHelp.launchUrl,
                ),
                Btn.elevated(
                  icon: const Icon(MingCute.question_fill),
                  text: libL10n.license,
                  onTap: () => showLicensePage(context: context),
                ),
                Btn.elevated(
                  icon: const Icon(MingCute.heart_fill),
                  text: l10n.sponsor,
                  onTap: () => _sponsorUrl.launchUrl(),
                ),
              ].joinWith(UIs.width13),
            ),
          ),
          UIs.height13,
          SimpleMarkdown(
            data:
                '''
#### Contributors
${GithubIds.contributors.map((e) => e.markdownLink).join(' ')}

#### Participants
${GithubIds.participants.map((e) => e.markdownLink).join(' ')}

#### My other apps
[GPT Box](https://github.com/lollipopkit/flutter_gpt_box)

${l10n.madeWithLove('[lollipopkit](${Urls.myGithub})')}
''',
          ).paddingAll(13).cardx,
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}


extension _IosAbout on _AppAboutPageState {
  Widget _buildIos() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox.square(
                  dimension: 76,
                  child: UIs.appIcon,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                BuildData.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'v${BuildData.build}',
                style: TextStyle(
                  fontSize: 13,
                  color: IosPalette.secondaryLabelByBrightness(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        IosSection(
          header: l10n.info,
          children: [
            IosRow(
              title: libL10n.menuWiki,
              leading: const IosSettingsIcon(CupertinoIcons.book),
              chevron: true,
              onTap: Urls.appWiki.launchUrl,
            ),
            IosRow(
              title: libL10n.feedback,
              leading: const IosSettingsIcon(CupertinoIcons.chat_bubble),
              chevron: true,
              onTap: Urls.appHelp.launchUrl,
            ),
            IosRow(
              title: libL10n.license,
              leading: const IosSettingsIcon(CupertinoIcons.doc_text),
              chevron: true,
              onTap: () => showLicensePage(context: context),
            ),
            IosRow(
              title: l10n.sponsor,
              leading: const IosSettingsIcon(CupertinoIcons.heart),
              chevron: true,
              onTap: () => _sponsorUrl.launchUrl(),
            ),
          ],
        ),
        IosSection(
          header: l10n.community,
          children: [
            IosRow(
              title: 'Contributors',
              subtitle: '${GithubIds.contributors.length}',
              leading: const IosSettingsIcon(CupertinoIcons.person_2),
              chevron: true,
              onTap: () => _pushGhList(
                'Contributors',
                GithubIds.contributors.toList(),
              ),
            ),
            IosRow(
              title: 'Participants',
              subtitle: '${GithubIds.participants.length}',
              leading: const IosSettingsIcon(CupertinoIcons.person_3),
              chevron: true,
              onTap: () => _pushGhList(
                'Participants',
                GithubIds.participants.toList(),
              ),
            ),
          ],
        ),
        IosSection(
          children: [
            IosRow(
              title: 'GPT Box',
              leading: const IosSettingsIcon(CupertinoIcons.chevron_left_slash_chevron_right),
              chevron: true,
              onTap: () => 'https://github.com/lollipopkit/flutter_gpt_box'.launchUrl(),
            ),
            IosRow(
              title: l10n.developer,
              subtitle: 'lollipopkit',
              leading: const IosSettingsIcon(CupertinoIcons.person_crop_circle),
              chevron: true,
              onTap: Urls.myGithub.launchUrl,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            l10n.madeWithLove('lollipopkit'),
            style: TextStyle(
              fontSize: 12,
              color: IosPalette.secondaryLabelByBrightness(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pushes a plain list of GitHub ids, one row each, linking to their
  /// profile — instead of dumping dozens of names on the about page.
  void _pushGhList(String title, List<GhId> ids) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(title),
            backgroundColor: IosPalette.groupedBackgroundByBrightness(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          child: IosGroupedList(
            children: [
              IosSection(
                children: [
                  for (final id in ids)
                    IosRow(
                      title: id,
                      titleMaxLines: 1,
                      leading: const IosSettingsIcon(CupertinoIcons.person),
                      chevron: true,
                      onTap: () => id.url.launchUrl(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
