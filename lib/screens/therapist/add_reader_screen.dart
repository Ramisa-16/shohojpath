import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_exception.dart';
import '../../api/shohojpath_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/auth_form_field.dart';
import '../../l10n/app_strings.dart';

/// Screen `taddreader` — the directory of readers nobody has added yet.
///
/// The list only ever contains unclaimed readers: the moment any therapist
/// adds someone they drop out of every other therapist's list, so two
/// therapists can never unknowingly be working with the same participant.
/// That rule is enforced on the server; this screen just reflects it.
class AddReaderScreen extends StatefulWidget {
  const AddReaderScreen({super.key});

  @override
  State<AddReaderScreen> createState() => _AddReaderScreenState();
}

class _AddReaderScreenState extends State<AddReaderScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _readers = const [];
  bool _loading = true;
  String? _error;

  /// participant_ids currently being claimed, so a row shows a spinner and
  /// cannot be double-tapped into two claim requests.
  final Set<String> _claiming = {};

  /// Readers this therapist has asked in this sitting. The server also
  /// refuses a duplicate, but the button should stop offering it.
  final Set<String> _requested = {};

  /// How many readers this visit added, shown on the way back so the
  /// dashboard's roster count is not the only feedback.
  /// Requests sent in this sitting. Returned on pop purely so the
  /// dashboard knows something happened — nobody has been added yet.
  int _requestsSent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await context.read<ShohojpathApi>().availableReaders(
            search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _readers = results;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.messageFor(context.tOnce);
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    // Debounced: typing "Mitu" would otherwise fire four requests, and the
    // slowest could land last and overwrite the right results.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _add(Map<String, dynamic> reader) async {
    final participantId = reader['participant_id'] as String;
    final name = reader['display_name'] as String? ?? participantId;
    final t = context.tOnce;
    setState(() => _claiming.add(participantId));

    try {
      await context.read<ShohojpathApi>().requestSupervision(participantId);
      if (!mounted) return;
      // The row stays. Asking is not adding — the reader may still decline,
      // and removing them here would claim an outcome that has not happened.
      setState(() {
        _claiming.remove(participantId);
        _requested.add(participantId);
        _requestsSent++;
      });
      _toast(t.requestSentTo(name), AppColors.tealDeep);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _claiming.remove(participantId));

      if (e.isConflict) {
        // Someone else claimed them between this list loading and the tap.
        // Dropping the row is the honest response — they are genuinely no
        // longer available.
        setState(() {
          _readers = _readers
              .where((r) => r['participant_id'] != participantId)
              .toList();
        });
        _toast(
          'Another therapist added $name first.',
          AppColors.danger,
        );
      } else {
        _toast(e.messageFor(t), AppColors.danger);
      }
    }
  }

  void _toast(String message, Color colour) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: colour,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_requestsSent);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(context.t.addAReader),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              tooltip: context.t.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: AuthFormField(
                label: '',
                controller: _search,
                icon: Icons.search_rounded,
                hint: context.t.searchByNameIdSchool,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                trailing: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.t.clearSearch,
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: AppColors.muted),
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                      ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: context.t.couldNotLoadReaders,
        body: _error!,
        action: PrimaryButton(label: context.t.tryAgain, onPressed: _load, expand: false),
      );
    }

    if (_readers.isEmpty) {
      final searching = _search.text.trim().isNotEmpty;
      return _Message(
        icon: searching ? Icons.search_off_rounded : Icons.groups_2_outlined,
        title: searching ? context.t.noMatch : context.t.everyoneAdded,
        body: searching
            ? context.t.noMatchBody(_search.text.trim())
            : context.t.everyoneAddedBody,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        itemCount: _readers.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${_readers.length} reader${_readers.length == 1 ? '' : 's'} '
                'available',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.84,
                  color: AppColors.muted,
                ),
              ),
            );
          }
          final reader = _readers[index - 1];
          final id = reader['participant_id'] as String;
          return _AvailableReaderRow(
            reader: reader,
            busy: _claiming.contains(id),
            requested: _requested.contains(id),
            onAdd: () => _add(reader),
          );
        },
      ),
    );
  }
}

class _AvailableReaderRow extends StatelessWidget {
  const _AvailableReaderRow({
    required this.reader,
    required this.busy,
    required this.onAdd,
    this.requested = false,
  });

  final Map<String, dynamic> reader;
  final bool busy;
  final VoidCallback onAdd;
  final bool requested;

  @override
  Widget build(BuildContext context) {
    final name = reader['display_name'] as String? ?? '—';
    final participantId = reader['participant_id'] as String? ?? '';
    final age = reader['age'] as int?;
    final school = reader['school'] as String? ?? '';
    final classGrade = reader['class_grade'] as String? ?? '';

    final detail = [
      if (age != null) 'Age $age',
      if (classGrade.isNotEmpty) classGrade,
      if (school.isNotEmpty) school,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.tealTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name.characters.first,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.tealDeep,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  participantId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealText,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            height: 44,
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: requested ? null : onAdd,
                    icon: Icon(
                      requested ? Icons.schedule_rounded : Icons.add_rounded,
                      size: 20,
                    ),
                    label: Text(
                      requested ? context.t.requestSent : context.t.askToAdd,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          requested ? AppColors.borderStrong : AppColors.navy,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(92, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.borderStrong),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.body,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
