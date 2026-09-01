import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/custom_server_header.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<_HeaderInputController> _headerInputs = [];

  bool get _supportsCustomHeaders =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _loadCustomHeaders();
  }

  @override
  void dispose() {
    urlController.dispose();
    for (final input in _headerInputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _setupDefault,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.setupTitle,
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: urlController,
                      autofillHints: const [AutofillHints.url],
                      textInputAction: TextInputAction.go,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      onFieldSubmitted: (text) => _setup(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.address,
                        hintText: 'https://localhost',
                      ),
                      validator: (s) => s == null || s.isEmpty
                          ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                              AppLocalizations.of(context)!.address,
                            )
                          : null,
                    ),
                    if (_supportsCustomHeaders) ...[
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)!.serverHeaders,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        AppLocalizations.of(context)!.serverHeadersDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      for (final entry in _headerInputs.asMap().entries)
                        Row(
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
                                  labelText:
                                      AppLocalizations.of(context)!.headerValue,
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
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ElevatedButton(
                        onPressed: _setup,
                        child: Text(AppLocalizations.of(context)!.go),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setup() {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthCubit>(context).setupServer(
        urlController.text,
        customHeaders: _headerInputs
            .map(
              (entry) => CustomServerHeader(
                name: entry.name.text,
                value: entry.value.text,
              ),
            )
            .toList(),
      );
    }
  }

  void _setupDefault() {
    BlocProvider.of<AuthCubit>(context).setupDefaultServer();
  }

  Future<void> _loadCustomHeaders() async {
    if (!_supportsCustomHeaders) return;

    final headers = await BlocProvider.of<AuthCubit>(context).loadServerHeaders();
    if (!mounted) return;

    setState(() {
      _headerInputs.clear();
      _headerInputs.addAll(
        headers.map((header) => _HeaderInputController.fromHeader(header)),
      );
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
