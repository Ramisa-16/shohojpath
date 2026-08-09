import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../app/route_observer.dart';
import '../theme/app_colors.dart';
import 'app_buttons.dart';

/// Loads something from the API and renders the four states every backed
/// screen has: loading, failed, empty, and data.
///
/// Written once because getting this wrong is how a screen ends up silently
/// blank — a participant looking at an empty Progress screen cannot tell
/// whether they have read nothing or the phone simply has no signal, and those
/// need different answers.
class ApiData<T> extends StatefulWidget {
  const ApiData({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nothing here yet',
    this.emptyBody = '',
    this.padding = const EdgeInsets.all(14),
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh)
      builder;

  /// Lets a caller say what "no data" means for its own payload — an empty
  /// list, a zero count, whatever.
  final bool Function(T data)? isEmpty;

  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;
  final EdgeInsets padding;

  @override
  State<ApiData<T>> createState() => _ApiDataState<T>();
}

class _ApiDataState<T> extends State<ApiData<T>>
    with RefreshOnRouteReturn<ApiData<T>> {
  T? _data;
  String? _error;
  bool _loading = true;

  /// True when a refresh finds no connection but we already have something on
  /// screen — the stale data stays rather than being replaced by an error, and
  /// the screen just says it could not update.
  bool _staleWarning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Whatever the reader did on the screen above may have changed this one:
  /// bookmarking from Reading, deleting from Bookmarks, finishing a quiz.
  /// The existing data stays on screen while this runs, so it re-reads
  /// without a flash of spinner.
  @override
  void onRouteReturn() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _data == null;
      _error = null;
    });

    try {
      final result = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
        _staleWarning = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = e.message;
        } else {
          _staleWarning = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_data == null) _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _data == null) {
      return ApiMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load this',
        body: _error!,
        action: PrimaryButton(
          label: 'Try again',
          onPressed: _load,
          expand: false,
        ),
      );
    }

    final data = _data as T;

    if (widget.isEmpty?.call(data) ?? false) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: widget.padding,
          children: [
            const SizedBox(height: 40),
            ApiMessage(
              icon: widget.emptyIcon,
              title: widget.emptyTitle,
              body: widget.emptyBody,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_staleWarning) const _StaleBanner(),
        Expanded(child: widget.builder(context, data, _load)),
      ],
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.chipNeutral,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved data — could not reach the server.',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The centred icon + title + body block used for empty and error states.
class ApiMessage extends StatelessWidget {
  const ApiMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body = '',
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: AppColors.borderStrong),
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
            if (body.isNotEmpty) ...[
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
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
