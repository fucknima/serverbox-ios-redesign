part of 'edit.dart';

extension _Widgets on _ServerEditPageState {
  Widget _buildAuth() {
    final switch_ = ListTile(
      title: Text(l10n.keyAuth),
      trailing: _keyIdx.listenVal(
        (v) => Switch(
          value: v != null,
          onChanged: (val) {
            if (val) {
              _keyIdx.value = -1;
            } else {
              _keyIdx.value = null;
            }
          },
        ),
      ),
    );
    final password = Input(
      controller: _passwordController,
      obscureText: true,
      type: TextInputType.text,
      label: libL10n.pwd,
      icon: Icons.password,
      suggestion: false,
      onSubmitted: (_) => _onSave(),
    );

    /// Keep static auth fields outside [ValueBuilder] to avoid rebuilding them.
    return _keyIdx.listenVal((v) {
      final children = <Widget>[switch_];
      if (v != null) {
        children.add(_buildKeyAuth());
      }
      children.add(password);
      return Column(children: children);
    });
  }

  Widget _buildKeyAuth() => _buildKeyAuthFor(_keyIdx);

  /// The private-key picker, parameterised by which selection it drives.
  ///
  /// Two independent SSH credentials can be on this page — the direct one and
  /// the tunnel's — and they must not share a selection.
  Widget _buildKeyAuthFor(ValueNotifier<int?> keyIdx) {
    const padding = EdgeInsets.only(left: 13, right: 13, bottom: 7);
    final privateKeyState = ref.watch(privateKeyProvider);
    final pkis = privateKeyState.keys;

    final choice = keyIdx.listenVal((val) {
      final selectedPki = val != null && val >= 0 && val < pkis.length
          ? pkis[val]
          : null;
      return Choice<int>(
        multiple: false,
        clearable: true,
        value: selectedPki != null ? [val!] : [],
        builder: (state, _) => Column(
          children: [
            Wrap(
              children: List<Widget>.generate(pkis.length, (index) {
                final item = pkis[index];
                return ChoiceChipX<int>(
                  key: ValueKey(index),
                  label: item.id,
                  state: state,
                  value: index,
                  onSelected: (idx, on) {
                    if (on) {
                      keyIdx.value = idx;
                    } else {
                      keyIdx.value = -1;
                    }
                  },
                );
              }),
            ),
            UIs.height7,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (selectedPki != null)
                  Btn.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    text: libL10n.edit,
                    onTap: () => PrivateKeyEditPage.route.go(
                      context,
                      args: PrivateKeyEditPageArgs(pki: selectedPki),
                    ),
                  ),
                Btn.icon(
                  icon: const Icon(Icons.add, size: 20),
                  text: libL10n.add,
                  onTap: () => PrivateKeyEditPage.route.go(context),
                ),
              ],
            ),
          ],
        ),
      );
    });

    return ExpandTile(
      leading: const Icon(Icons.key),
      initiallyExpanded: keyIdx.value != null && keyIdx.value! >= 0,
      childrenPadding: padding,
      title: Text(l10n.privateKey),
      children: [choice],
    ).cardx;
  }

  Widget _buildEnvs() {
    return _env.listenVal((val) {
      final subtitle = val.isEmpty
          ? null
          : Text(val.keys.join(','), style: UIs.textGrey);
      return ListTile(
        leading: const Icon(HeroIcons.variable),
        subtitle: subtitle,
        title: Text(l10n.envVars),
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: () async {
          final res = await KvEditor.route.go(
            context,
            KvEditorArgs(data: spi?.envs ?? {}),
          );
          if (res == null) return;
          _env.value = res;
        },
      ).cardx;
    });
  }

  Widget _buildMore() {
    return ExpandTile(
      title: Text(libL10n.more),
      children: [
        _buildSudoPassword(),
        Input(
          controller: _logoUrlCtrl,
          type: TextInputType.url,
          icon: Icons.image,
          label: 'Logo URL',
          hint: 'https://example.com/logo.png',
          suggestion: false,
        ),
        _buildAltUrl(),
        _buildProxyCommand(),
        _buildScriptDir(),
        _buildEnvs(),
        _buildPVEs(),
        _buildCustomCmds(),
        _buildStorageCollection(),
        _buildDisabledCmdTypes(),
        _buildCustomDev(),
        _buildWOLs(),
      ],
    );
  }

  Widget _buildSudoPassword() {
    return _hasStoredSudoPassword.listenVal((hasValue) {
      final subtitle = switch (hasValue) {
        true => Text(libL10n.configured, style: UIs.textGrey),
        false => Text(libL10n.empty, style: UIs.textGrey),
        null => Text(libL10n.loadingEllipsis, style: UIs.textGrey),
      };
      return ListTile(
        leading: const Icon(Icons.password),
        title: Text(libL10n.sudoPassword),
        subtitle: subtitle,
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: _onTapSudoPassword,
      ).cardx;
    });
  }

  Widget _buildScriptDir() {
    return Input(
      controller: _scriptDirCtrl,
      type: TextInputType.text,
      label: '${l10n.remotePath} (Shell ${libL10n.install})',
      icon: Icons.folder,
      hint: '~/.config/server_box',
      suggestion: false,
    );
  }

  Widget _buildCustomDev() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterGreyTitle(l10n.specifyDev),
        ListTile(
          leading: const Icon(MingCute.question_line),
          title: TipText(libL10n.note, l10n.specifyDevTip),
        ).cardx,
        Input(
          controller: _preferTempDevCtrl,
          type: TextInputType.text,
          label: libL10n.temperature,
          icon: MingCute.low_temperature_line,
          hint: 'nvme-pci-0400',
          suggestion: false,
        ),
        ListTile(
          leading: const Icon(MingCute.question_line),
          title: TipText('${libL10n.temperature} (°C)', l10n.tempIsCelsiusTip),
          trailing: _tempIsCelsius.listenVal(
            (v) => Switch(
              value: v,
              onChanged: (val) {
                _tempIsCelsius.value = val;
              },
            ),
          ),
        ).cardx,
        Input(
          controller: _netDevCtrl,
          type: TextInputType.text,
          label: libL10n.net,
          icon: ZondIcons.network,
          hint: 'eth0',
          suggestion: false,
        ),
      ],
    );
  }

  Widget _buildSystemType() {
    return _systemType.listenVal((val) {
      return ListTile(
        leading: Icon(MingCute.laptop_2_line),
        title: Text(l10n.system),
        trailing: PopupMenu<SystemType?>(
          initialValue: val,
          items: [
            PopupMenuItem(value: null, child: Text(libL10n.auto)),
            PopupMenuItem(value: SystemType.linux, child: Text('Linux')),
            PopupMenuItem(value: SystemType.bsd, child: Text('BSD')),
            PopupMenuItem(value: SystemType.windows, child: Text('Windows')),
          ],
          onSelected: (value) => _systemType.value = value,
          child: Text(
            val?.name ?? libL10n.auto,
            style: TextStyle(color: val == null ? Colors.grey : null),
          ),
        ),
      ).cardx;
    });
  }

  Widget _buildAltUrl() {
    return Input(
      controller: _altUrlController,
      type: TextInputType.url,
      node: _alterUrlFocus,
      onSubmitted: (_) => _focusScope.requestFocus(_proxyCommandFocus),
      label: l10n.fallbackSshDest,
      icon: MingCute.link_line,
      hint: 'user@ip:port',
      suggestion: false,
    );
  }

  Widget _buildProxyCommand() {
    return Input(
      controller: _proxyCommandCtrl,
      type: TextInputType.multiline,
      node: _proxyCommandFocus,
      label: 'ProxyCommand',
      icon: MingCute.command_line,
      hint: 'socat - PROXY:x.x.x.x:%h:%p,proxyport=5002',
      suggestion: false,
      maxLines: 3,
    );
  }

  Widget _buildPVEs() {
    const addr = 'https://127.0.0.1:8006';
    return _keyIdx.listenVal((v) {
      final useKeyAuth = v != null && v >= 0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CenterGreyTitle('PVE'),
          Input(
            controller: _pveAddrCtrl,
            type: TextInputType.url,
            icon: MingCute.web_line,
            label: 'URL',
            hint: addr,
            suggestion: false,
          ),
          if (useKeyAuth)
            Input(
              controller: _pvePwdCtrl,
              type: TextInputType.visiblePassword,
              icon: MingCute.lock_line,
              label: l10n.pvePassword,
              hint: l10n.pvePasswordHint,
              obscureText: true,
              suggestion: false,
            ),
          ListTile(
            leading: const Icon(MingCute.certificate_line),
            title: TipText('PVE ${l10n.ignoreCert}', l10n.pveIgnoreCertTip),
            trailing: _pveIgnoreCert.listenVal(
              (v) => Switch(
                value: v,
                onChanged: (val) {
                  _pveIgnoreCert.value = val;
                },
              ),
            ),
          ).cardx,
        ],
      );
    });
  }

  /// SSH+shell vs monitor's HTTP API — mutually exclusive connection
  /// methods for reaching this server (see `Spi.monitorHttp`'s doc comment).
  Widget _buildConnMethodSwitch() {
    return _useMonitorHttp.listenVal((useHttp) {
      return SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('SSH'),
            icon: Icon(Icons.terminal, size: 16),
          ),
          ButtonSegment(
            value: true,
            label: Text('Monitor HTTP'),
            icon: Icon(MingCute.web_line, size: 16),
          ),
        ],
        selected: {useHttp},
        onSelectionChanged: (selection) {
          _useMonitorHttp.value = selection.first;
        },
      );
    });
  }

  /// SSH host/port/user — hidden when `_useMonitorHttp` is selected, since
  /// they're not used by the monitor HTTP connection path at all.
  Widget _buildSshConnFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Input(
          controller: _ipController,
          type: TextInputType.url,
          onSubmitted: (_) => _focusScope.requestFocus(_portFocus),
          node: _ipFocus,
          label: libL10n.host,
          icon: BoxIcons.bx_server,
          hint: 'example.com',
          suggestion: false,
        ),
        Input(
          controller: _portController,
          type: TextInputType.number,
          node: _portFocus,
          onSubmitted: (_) => _focusScope.requestFocus(_usernameFocus),
          label: libL10n.port,
          icon: Bootstrap.number_123,
          hint: '22',
          suggestion: false,
        ),
        Input(
          controller: _usernameController,
          type: TextInputType.text,
          node: _usernameFocus,
          onSubmitted: (_) => _focusScope.requestFocus(_alterUrlFocus),
          label: libL10n.user,
          icon: Icons.account_box,
          hint: 'root',
          suggestion: false,
        ),
      ],
    );
  }

  /// Monitor's HTTP API connection fields — shown instead of `_buildAuth()`
  /// when `_useMonitorHttp` is selected, never alongside it.
  Widget _buildMonitorHttp() {
    const addr = 'https://127.0.0.1:3770';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterGreyTitle(libL10n.network),
        Input(
          controller: _monitorAddrCtrl,
          type: TextInputType.url,
          icon: MingCute.web_line,
          label: 'URL',
          hint: addr,
          suggestion: false,
        ),
        // Prefixed because the shell section below has a second account with
        // the same two labels, and they are not interchangeable: this one is
        // the panel login, that one is a system account on the far host.
        Input(
          controller: _monitorUserCtrl,
          type: TextInputType.text,
          icon: MingCute.user_2_line,
          label: 'Monitor ${libL10n.user}',
          suggestion: false,
        ),
        Input(
          controller: _monitorPwdCtrl,
          type: TextInputType.visiblePassword,
          icon: MingCute.lock_line,
          label: 'Monitor ${libL10n.pwd}',
          obscureText: true,
          suggestion: false,
        ),
        ListTile(
          leading: const Icon(MingCute.certificate_line),
          title: TipText('Monitor ${l10n.ignoreCert}', l10n.pveIgnoreCertTip),
          trailing: _monitorIgnoreCert.listenVal(
            (v) => Switch(
              value: v,
              onChanged: (val) {
                _monitorIgnoreCert.value = val;
              },
            ),
          ),
        ).cardx,
      ],
    );
  }

  /// The SSH account the agent logs in as on the far host.
  ///
  /// Deliberately has no host/port field: the agent connects to the address in
  /// its own `remote_access.ssh_addr` and refuses to take one from a client,
  /// which is what stops it being usable to reach anything else on its
  /// network. All that is needed here is who to log in as.
  ///
  /// Labels carry the `SSH` prefix because the network section above has a
  /// second account with the same two labels. They are not interchangeable —
  /// that one is the panel login, this one has to exist on the far host and
  /// be permitted by its sshd.

  Widget _buildCustomCmds() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterGreyTitle(l10n.customCmd),
        // No count and no preview: the commands are on the server, and this
        // page has not asked it. The editor is what reads them.
        ListTile(
          leading: const Icon(MingCute.command_line),
          title: Text(libL10n.edit),
          trailing: const Icon(Icons.keyboard_arrow_right),
          onTap: _onTapCustomItem,
        ).cardx,
        ListTile(
          leading: const Icon(MingCute.doc_line),
          title: Text(libL10n.doc),
          trailing: const Icon(Icons.open_in_new, size: 17),
          onTap: libL10n.customCmdDocUrl.launchUrl,
        ).cardx,
      ],
    );
  }

  Widget _buildStorageCollection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterGreyTitle(libL10n.disk),
        _disabledCmdTypes.listenVal((_) {
          final diskInfoEnabled = !_isCmdGroupDisabled(_diskInfoCmdTypes);
          final diskHealthEnabled = !_isCmdGroupDisabled(_diskHealthCmdTypes);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.storage),
                title: Text(libL10n.disk),
                subtitle: Text(
                  _diskInfoCmdTypes.map((e) => e.displayName).join(', '),
                  style: UIs.textGrey,
                ),
                trailing: Switch(
                  value: diskInfoEnabled,
                  onChanged: (value) {
                    _setCmdGroupDisabled(_diskInfoCmdTypes, !value);
                  },
                ),
                onTap: () {
                  _setCmdGroupDisabled(_diskInfoCmdTypes, diskInfoEnabled);
                },
              ).cardx,
              ListTile(
                leading: const Icon(MingCute.heartbeat_line),
                title: Text(l10n.diskHealth),
                subtitle: Text(
                  _diskHealthCmdTypes.map((e) => e.displayName).join(', '),
                  style: UIs.textGrey,
                ),
                trailing: Switch(
                  value: diskHealthEnabled,
                  onChanged: (value) {
                    _setCmdGroupDisabled(_diskHealthCmdTypes, !value);
                  },
                ),
                onTap: () {
                  _setCmdGroupDisabled(_diskHealthCmdTypes, diskHealthEnabled);
                },
              ).cardx,
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDisabledCmdTypes() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterGreyTitle('${libL10n.disabled} ${libL10n.cmd}'),
        _disabledCmdTypes.listenVal((disabled) {
          return ListTile(
            leading: const Icon(Icons.disabled_by_default),
            title: Text('${libL10n.disabled} ${libL10n.cmd}'),
            subtitle: disabled.isEmpty
                ? null
                : Text(disabled.join(', '), style: UIs.textGrey),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: _onTapDisabledCmdTypes,
          );
        }).cardx,
      ],
    );
  }

  Widget _buildWOLs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CenterGreyTitle('Wake On LAN (beta)'),
        ListTile(
          leading: const Icon(BoxIcons.bxs_help_circle),
          title: TipText(libL10n.about, l10n.wolTip),
        ).cardx,
        Input(
          controller: _wolMacCtrl,
          type: TextInputType.text,
          label: 'MAC ${libL10n.addr}',
          icon: Icons.computer,
          hint: '00:11:22:33:44:55',
          suggestion: false,
        ),
        Input(
          controller: _wolIpCtrl,
          type: TextInputType.text,
          label: 'IP ${libL10n.addr}',
          icon: ZondIcons.network,
          hint: '192.168.1.x',
          suggestion: false,
        ),
        Input(
          controller: _wolPwdCtrl,
          type: TextInputType.text,
          obscureText: true,
          label: libL10n.pwd,
          icon: Icons.password,
          suggestion: false,
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _onSave,
      child: const Icon(Icons.save),
    );
  }

  Widget _buildJumpServer() {
    const padding = EdgeInsets.only(left: 13, right: 13, bottom: 7);
    final srvs = ref
        .watch(serversProvider)
        .servers
        .values
        .where((e) => e.id != spi?.id)
        .where((e) => !_isInvalidJumpSelection(e.id))
        .toList();
    final choice = _jumpServers.listenVal((val) {
      final selectedSrvs = <Spi>[];
      for (final id in val) {
        final srv = srvs.firstWhereOrNull((e) => e.id == id);
        if (srv != null) selectedSrvs.add(srv);
      }
      return Choice<Spi>(
        multiple: true,
        clearable: true,
        value: selectedSrvs,
        builder: (state, _) => Wrap(
          children: List<Widget>.generate(srvs.length, (index) {
            final item = srvs[index];
            final selectedIndex = val.indexOf(item.id);
            return ChoiceChipX<Spi>(
              key: ValueKey(item),
              label: selectedIndex == -1
                  ? item.name
                  : '${selectedIndex + 1}. ${item.name}',
              state: state,
              value: item,
              onSelected: (srv, on) {
                final next = List<String>.from(_jumpServers.value);
                if (on) {
                  if (next.contains(srv.id)) return;
                  if (next.length >= 2) {
                    Toast.show('${l10n.jumpServer}: 2');
                    return;
                  }
                  next.add(srv.id);
                } else {
                  next.remove(srv.id);
                }
                _jumpServers.value = next;
              },
            );
          }),
        ),
      );
    });
    return ExpandTile(
      leading: const Icon(Icons.map),
      initiallyExpanded: _jumpServers.value.isNotEmpty,
      childrenPadding: padding,
      title: Text(l10n.jumpServer),
      children: [choice],
    ).cardx;
  }

  Widget _buildDiscoverBtn() {
    return IconButton(
      tooltip: l10n.discoverSshServers,
      onPressed: _onTapDiscover,
      icon: const Icon(Icons.radar),
    );
  }

  Widget _buildWriteScriptTip() {
    return IconButton(
      tooltip: libL10n.attention,
      onPressed: () {
        context.showRoundDialog(
          title: libL10n.attention,
          child: SimpleMarkdown(data: l10n.writeScriptTip),
          actions: Btnx.oks,
        );
      },
      icon: const Icon(Icons.tips_and_updates),
    );
  }

  Widget _buildDelBtn() {
    return IconButton(tooltip: libL10n.delete, 
      onPressed: _confirmDelete,
      icon: const Icon(Icons.delete),
    );
  }
}

extension _IosWidgets on _ServerEditPageState {
  /// The iPhone form: grouped sections under a standard nav bar, save in the
  /// bar, delete at the very bottom. The values, controllers and save logic
  /// are the same ones the Material form uses.
  Widget _buildIosForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _useMonitorHttp.listenVal((useHttp) {
            return CupertinoSlidingSegmentedControl<bool>(
              groupValue: useHttp,
              onValueChanged: (v) {
                if (v != null) _useMonitorHttp.value = v;
              },
              children: {
                false: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Text('SSH', style: TextStyle(fontSize: 13)),
                ),
                true: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Text('Monitor HTTP', style: TextStyle(fontSize: 13)),
                ),
              },
            );
          }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              IosSection(
                header: libL10n.conn,
                children: [
                  _iosField(
                    controller: _nameController,
                    label: libL10n.name,
                    node: _nameFocus,
                    onSubmitted: (_) => _focusScope.requestFocus(_ipFocus),
                  ),
                  if (!_useMonitorHttp.value) ...[
                    _iosField(
                      controller: _ipController,
                      label: libL10n.host,
                      hint: 'example.com',
                      node: _ipFocus,
                      onSubmitted: (_) => _focusScope.requestFocus(_portFocus),
                    ),
                    _iosField(
                      controller: _portController,
                      label: libL10n.port,
                      hint: '22',
                      type: TextInputType.number,
                      node: _portFocus,
                      onSubmitted: (_) =>
                          _focusScope.requestFocus(_usernameFocus),
                    ),
                    _iosField(
                      controller: _usernameController,
                      label: libL10n.user,
                      hint: 'root',
                      type: TextInputType.text,
                      node: _usernameFocus,
                      onSubmitted: (_) => _focusScope.requestFocus(_alterUrlFocus),
                    ),
                  ],
                ],
              ),
              if (_useMonitorHttp.value)
                IosSection(
                  header: libL10n.network,
                  children: [
                    _iosField(
                      controller: _monitorAddrCtrl,
                      label: 'URL',
                      hint: 'https://127.0.0.1:3770',
                    ),
                    _iosField(
                      controller: _monitorUserCtrl,
                      label: 'Monitor ${libL10n.user}',
                    ),
                    _iosField(
                      controller: _monitorPwdCtrl,
                      label: 'Monitor ${libL10n.pwd}',
                      obscure: true,
                    ),
                    _monitorIgnoreCert.listenVal(
                      (v) => IosSwitchRow(
                        title: 'Monitor ${l10n.ignoreCert}',
                        value: v,
                        onChanged: (val) => _monitorIgnoreCert.value = val,
                      ),
                    ),
                  ],
                )
              else
                IosSection(
                  header: l10n.keyAuth,
                  children: [
                    _keyIdx.listenVal(
                      (v) => IosSwitchRow(
                        title: l10n.keyAuth,
                        value: v != null,
                        onChanged: (val) => _keyIdx.value = val ? -1 : null,
                      ),
                    ),
                    if (_keyIdx.value != null) _buildIosKeyPickerRow(),
                    _iosField(
                      controller: _passwordController,
                      label: libL10n.pwd,
                      obscure: true,
                      onSubmitted: (_) => _onSave(),
                    ),
                  ],
                ),
              IosSection(
                header: libL10n.setting,
                children: [
                  _autoConnect.listenVal(
                    (v) => IosSwitchRow(
                      title: l10n.autoConnect,
                      value: v,
                      onChanged: (val) => _autoConnect.value = val,
                    ),
                  ),
                  _buildIosTagRow(),
                ],
              ),
              IosSection(children: [_buildMore()]),
              if (spi != null) ...[
                const SizedBox(height: 20),
                IosSection(
                  children: [
                    IosRow(
                      title: '${libL10n.delete} ${libL10n.server}',
                      titleColor: IosPalette.redLight,
                      onTap: _confirmDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One form field on the cell surface: no box of its own — the section is
  /// the surface, and the row separators are what tell the fields apart, the
  /// way an iOS settings form reads.
  Widget _iosField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? type,
    bool obscure = false,
    FocusNode? node,
    void Function(String)? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: CupertinoTextField(
        controller: controller,
        focusNode: node,
        obscureText: obscure,
        keyboardType: type,
        autocorrect: false,
        onSubmitted: onSubmitted,
        placeholder: label,
        placeholderStyle: TextStyle(
          color: IosPalette.secondaryLabelByBrightness(isDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 9),
        decoration: null,
      ),
    );
  }

  Widget _buildIosKeyPickerRow() {
    final pkis = ref.read(privateKeyProvider).keys;
    final idx = _keyIdx.value;
    final selected = idx != null && idx >= 0 && idx < pkis.length
        ? pkis[idx]
        : null;
    return IosRow(
      title: l10n.privateKey,
      subtitle: selected?.id,
      chevron: true,
      onTap: _showIosKeyPicker,
    );
  }

  Future<void> _showIosKeyPicker() async {
    final pkis = ref.read(privateKeyProvider).keys;
    final picked = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.privateKey),
        actions: [
          for (var i = 0; i < pkis.length; i++)
            CupertinoActionSheetAction(
              isDefaultAction: _keyIdx.value == i,
              onPressed: () => Navigator.pop(context, i),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_keyIdx.value == i) ...[
                    const Icon(CupertinoIcons.checkmark, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(pkis[i].id),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              PrivateKeyEditPage.route.go(context);
            },
            child: Text(libL10n.add),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(libL10n.cancel),
        ),
      ),
    );
    if (picked != null) _keyIdx.value = picked;
  }

  Widget _buildIosTagRow() {
    final allTags = ref.watch(serversProvider).tags;
    return _tags.listenVal(
      (vals) => IosRow(
        title: libL10n.tag,
        subtitle: vals.isEmpty ? null : vals.join(', '),
        leading: const IosSettingsIcon(CupertinoIcons.tag),
        chevron: true,
        onTap: () => _showIosTagPicker(allTags),
      ),
    );
  }

  Future<void> _showIosTagPicker(Set<String> allTags) async {
    final allTags_ = {...allTags, ..._tags.value}.toList();
    final res = await context.showPickDialog(
      items: allTags_,
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

  /// The delete flow, shared by the bar's bin and the iOS bottom row: the
  /// dialog answers, this — which is on the page — acts and closes it.
  Future<void> _confirmDelete() async {
    final confirmed = await context.showRoundDialog<bool>(
      title: libL10n.attention,
      child: Text(
        libL10n.askContinue(
          '${libL10n.delete} ${libL10n.server}(${spi!.name})',
        ),
      ),
      actions: Btn.ok(red: true).toList,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(serversProvider.notifier).delServer(spi!.id);
    if (!mounted) return;
    context.pop(true);
  }

  Widget _buildIosDiscoverBtn() {
    return Tooltip(
      message: l10n.discoverSshServers,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: _onTapDiscover,
        child: const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 22),
      ),
    );
  }
}
