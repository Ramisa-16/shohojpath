import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reading_settings.dart';
import '../../services/reader_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_header.dart';
import '../../widgets/settings_controls.dart';

/// Screen `taddreader` of the v2 design — a therapist registering a new
/// reader. Saving generates a real participant id and writes a real row via
/// [ReaderRepository]; that id is what the reader then types into Login's
/// Participant ID field to have their sessions attributed here.
class AddReaderScreen extends StatefulWidget {
  const AddReaderScreen({super.key});

  @override
  State<AddReaderScreen> createState() => _AddReaderScreenState();
}

class _AddReaderScreenState extends State<AddReaderScreen> {
  static const _startingProfileDescriptions = {
    ReadingProfile.standard: 'Baseline — no reading aids, the study control.',
    ReadingProfile.recommended: 'Evidence-based: audio, spacing, cream background.',
    ReadingProfile.custom: 'A blank slate the reader tunes themselves.',
  };

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _classGrade = TextEditingController();
  final _school = TextEditingController();
  final _notes = TextEditingController();
  ReadingProfile _startingProfile = ReadingProfile.recommended;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _classGrade.dispose();
    _school.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name for this reader.')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = context.read<ReaderRepository>();
    final existing = await repo.readerCount();
    final participantId = 'P-${(existing + 1).toString().padLeft(2, '0')}';
    await repo.addReader(
      participantId: participantId,
      name: name,
      age: int.tryParse(_age.text.trim()),
      classGrade: _classGrade.text.trim().isEmpty ? null : _classGrade.text.trim(),
      school: _school.text.trim().isEmpty ? null : _school.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      startingProfile: _startingProfile,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added as $participantId.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Add Reader', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _Field(label: 'Name', controller: _name, hint: 'সাদিয়া আক্তার'),
                    const SizedBox(height: 13),
                    // Two fields side by side only when there's genuinely
                    // room for both at the current font size — otherwise
                    // each gets the full width instead of being squeezed.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final age = _Field(
                          label: 'Age',
                          controller: _age,
                          hint: '10',
                          keyboardType: TextInputType.number,
                        );
                        final classGrade = _Field(label: 'Class / Grade', controller: _classGrade, hint: 'Class 4');
                        if (constraints.maxWidth < 280) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [age, const SizedBox(height: 13), classGrade],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: age),
                            const SizedBox(width: 10),
                            Expanded(child: classGrade),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 13),
                    _Field(label: 'School (optional)', controller: _school, hint: 'Udayan Primary School'),
                    const SizedBox(height: 13),
                    _Field(
                      label: 'Notes / observations',
                      controller: _notes,
                      hint: 'Referred by class teacher. Skips line endings, hesitates on conjuncts.',
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    const Text('Starting reading profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.body)),
                    const SizedBox(height: 8),
                    for (final profile in ReadingProfile.values) ...[
                      ProfileOptionTile(
                        title: profile.label,
                        description: _startingProfileDescriptions[profile]!,
                        selected: _startingProfile == profile,
                        onTap: () => setState(() => _startingProfile = profile),
                      ),
                      if (profile != ReadingProfile.values.last) const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Save Reader',
                      backgroundColor: AppColors.teal,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.body)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
