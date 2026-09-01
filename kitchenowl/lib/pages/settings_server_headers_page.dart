import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/custom_server_header.dart';

class SettingsServerHeadersPage extends StatefulWidget {
  const SettingsServerHeadersPage({super.key});

  @override
  State<SettingsServerHeadersPage> createState() =>
      _SettingsServerHeadersPageState();
}

class _SettingsServerHeadersPageState extends State<SettingsServerHeadersPage> {
  final _formKey = GlobalKey<FormState>();
  final List<_HeaderInputController> _headerInputs = [];
  bool _loading = true;

  bool get _supportsCustomHeaders =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  @override
  void dispose() {
    for (final input in _headerInputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsCustomHeaders) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.serverHeaders),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.underConstruction),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.serverHeaders),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 700),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        AppLocalizations.of(context)!.serverHeadersDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final entry in _headerInputs.asMap().entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: entry.value.name,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.headerName,
                                  ),
                                  validator: (value) =>
                                      _validateHeaderName(value, entry.key),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: entry.value.value,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .headerValue,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeHeader(entry.key),
                                icon: const Icon(Icons.delete_outline_rounded),
                                tooltip: AppLocalizations.of(context)!.delete,
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addHeader,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            AppLocalizations.of(context)!.addServerHeader,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LoadingElevatedButton(
                        onPressed: _save,
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _loadHeaders() async {
    final headers = await BlocProvider.of<AuthCubit>(context).loadServerHeaders();
    if (!mounted) return;

    setState(() {
      _headerInputs.clear();
      _headerInputs.addAll(
        headers.map((header) => _HeaderInputController.fromHeader(header)),
      );
      _loading = false;
    });
  }

  void _addHeader() {
    setState(() {
      _headerInputs.add(_HeaderInputController());
    });
  }

  void _removeHeader(int index) {
    setState(() {
      _headerInputs.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final headers = _headerInputs
        .map(
          (entry) => CustomServerHeader(
            name: entry.name.text,
            value: entry.value.text,
          ),
        )
        .toList();

    await BlocProvider.of<AuthCubit>(context).updateServerHeaders(headers);
    if (!mounted) return;

    showSnackbar(
      context: context,
      content: Text(AppLocalizations.of(context)!.serverHeadersSaved),
    );
    Navigator.of(context).pop();
  }

  String? _validateHeaderName(String? value, int index) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return AppLocalizations.of(context)!.fieldCannotBeEmpty(
        AppLocalizations.of(context)!.headerName,
      );
    }

    if (name.toLowerCase() == 'authorization' ||
        name.toLowerCase() == 'user-agent') {
      return AppLocalizations.of(context)!.headerNameReserved;
    }

    final isDuplicate = _headerInputs.asMap().entries.any(
          (entry) =>
              entry.key != index &&
              entry.value.name.text.trim().toLowerCase() == name.toLowerCase(),
        );
    if (isDuplicate) {
      return AppLocalizations.of(context)!.headerNameDuplicate;
    }

    return null;
  }
}

class _HeaderInputController {
  final TextEditingController name;
  final TextEditingController value;

  _HeaderInputController({
    String name = '',
    String value = '',
  })  : name = TextEditingController(text: name),
        value = TextEditingController(text: value);

  factory _HeaderInputController.fromHeader(CustomServerHeader header) =>
      _HeaderInputController(name: header.name, value: header.value);

  void dispose() {
    name.dispose();
    value.dispose();
  }
}
