import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One reader in a tap-to-choose list — the Login screen's short list and
/// the "All Readers" screen's full list both use this exact card, so a
/// reader recognises the same shape wherever they're looking for their own
/// name. Deliberately styled unlike a role-selector card (thinner border,
/// no tint-when-selected fill, a larger initial avatar) so it never reads
/// as a third role sitting under Reader and Therapist.
class ReaderTile extends StatelessWidget {
  const ReaderTile({
    super.key,
    required this.name,
    required this.participantId,
    required this.showNameAsPrimary,
    required this.onTap,
  });

  final String name;
  final String participantId;

  /// False only under the "Participant IDs only" privacy setting — the ID
  /// becomes the sole, primary line and the name is hidden entirely, since
  /// hiding the name is the whole point of that setting.
  final bool showNameAsPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = showNameAsPrimary && name.isNotEmpty ? name.substring(0, 1) : participantId.substring(0, 1);
    final primary = showNameAsPrimary ? name : participantId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tealTint,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      initial,
                      style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      primary,
                      style: TextStyle(
                        fontFamily: showNameAsPrimary ? 'NotoSansBengali' : 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (showNameAsPrimary) ...[
                      const SizedBox(height: 2),
                      Text(
                        participantId,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
