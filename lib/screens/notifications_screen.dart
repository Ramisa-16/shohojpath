import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/api_data.dart';
import '../widgets/app_header.dart';

/// The reader's inbox — currently "a therapist added you" and passage
/// assignments.
///
/// Messages are stored server-side and fetched, not pushed: the app is
/// offline-first, so a reader who was added while their phone was off must
/// still find out the next time they open it. A push-only notification would
/// simply have been lost.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _version = 0;

  Future<void> _markAllRead() async {
    try {
      await context.read<ShohojpathApi>().markAllNotificationsRead();
      if (!mounted) return;
      setState(() => _version++);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.messageFor(context.tOnce))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ShohojpathApi>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: context.t.notifications,
              onBack: () => Navigator.of(context).maybePop(),
              trailing: [
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(
                    context.t.markAllRead,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<List<Map<String, dynamic>>>(
                  key: ValueKey(_version),
                  load: api.notifications,
                  isEmpty: (rows) => rows.isEmpty,
                  emptyIcon: Icons.notifications_none_rounded,
                  emptyTitle: context.t.noMessages,
                  emptyBody: context.t.noNotificationsBody,
                  builder: (context, rows, refresh) => RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 11),
                      itemBuilder: (context, i) => _NotificationCard(
                        notification: rows[i],
                        onRead: () => setState(() => _version++),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onRead});

  final Map<String, dynamic> notification;

  /// Called after marking read, and after answering a supervision request —
  /// the list has to reload either way, because accepting changes what the
  /// rest of the app is allowed to show.
  final VoidCallback onRead;

  static const _icons = {
    'therapist_added': Icons.person_add_alt_1_rounded,
    'passage_assigned': Icons.menu_book_rounded,
    'supervision_requested': Icons.how_to_reg_rounded,
    'supervision_accepted': Icons.check_circle_rounded,
    'supervision_declined': Icons.cancel_rounded,
    'general': Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final kind = notification['kind'] as String? ?? 'general';
    final isRead = notification['is_read'] == true;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final created = DateTime.tryParse(
      notification['created_at'] as String? ?? '',
    );

    // Only offer the buttons while the request is genuinely open. Answered on
    // another device, or superseded because they accepted someone else, and
    // the buttons would only produce a 409.
    final requestId = (notification['supervision_request'] as num?)?.toInt();
    final awaitingAnswer = requestId != null &&
        notification['supervision_status'] == 'pending';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isRead
          ? null
          : () async {
              final id = (notification['id'] as num?)?.toInt();
              if (id == null) return;
              try {
                await context.read<ShohojpathApi>().markNotificationRead(id);
                onRead();
              } on ApiException {
                // Failing to mark as read is not worth interrupting anyone —
                // the message itself is already on screen.
              }
            },
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.tealTintSoft,
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.teal,
            width: isRead ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead ? AppColors.navyTint : AppColors.tealTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icons[kind] ?? Icons.info_outline_rounded,
                size: 22,
                color: isRead ? AppColors.navy : AppColors.tealDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 5, left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                  if (awaitingAnswer) ...[
                    const SizedBox(height: 11),
                    _SupervisionActions(
                      requestId: requestId,
                      onAnswered: onRead,
                    ),
                  ],
                  if (created != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      _ago(context.t, created.toLocal()),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  if (!isRead) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.t.tapToMarkRead,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ago(AppStrings t, DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return t.yesterday;
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${when.day}/${when.month}/${when.year}';
  }
}

/// A bell with an unread count, for the Home header.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.color = Colors.white});

  final Color color;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final rows =
          await context.read<ShohojpathApi>().notifications(unreadOnly: true);
      if (!mounted) return;
      setState(() => _unread = rows.length);
    } on ApiException {
      // Offline: leave the badge as it was rather than showing a zero that
      // would read as "nothing new".
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: context.t.notifications,
          icon: Icon(Icons.notifications_rounded, color: widget.color, size: 26),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            _refresh();
          },
        ),
        if (_unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


/// Accept / Decline for a supervision request, drawn on the notification
/// itself so the reader answers where they are told, rather than being sent
/// somewhere else to find the decision.
class _SupervisionActions extends StatefulWidget {
  const _SupervisionActions({required this.requestId, required this.onAnswered});

  final int requestId;
  final VoidCallback onAnswered;

  @override
  State<_SupervisionActions> createState() => _SupervisionActionsState();
}

class _SupervisionActionsState extends State<_SupervisionActions> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    if (_busy) return;
    final t = context.tOnce;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      final result = await context
          .read<ShohojpathApi>()
          .respondToSupervision(widget.requestId, accept: accept);

      if (!mounted) return;
      final therapist = result['therapist_name'] as String? ?? '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept ? t.acceptedTherapist(therapist) : t.declinedRequest,
          ),
        ),
      );
      widget.onAnswered();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isConflict ? t.requestAlreadyAnswered : e.messageFor(t),
          ),
        ),
      );
      // Reload either way: a conflict means the truth on screen is stale.
      if (e.isConflict) widget.onAnswered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => _respond(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(t.accept),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _respond(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
              side: const BorderSide(color: AppColors.dangerBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(t.decline),
          ),
        ),
      ],
    );
  }
}
