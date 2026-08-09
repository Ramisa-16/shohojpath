import 'package:flutter/widgets.dart';

/// Lets a screen know when the route on top of it was popped, so it can go
/// and fetch its numbers again.
///
/// Home reads its four tile captions once, in initState. Bookmarking a page
/// then returning left the Bookmarks tile still reading "0 saved" until the
/// reader pulled to refresh — the data was right on the server and stale on
/// screen. Rather than have each screen remember to reload after every
/// `Navigator.push` it makes, screens subscribe here and reload when they are
/// uncovered.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Mix into a [State] to run [onRouteReturn] whenever the route above this
/// one is popped. Handles the subscribe/unsubscribe bookkeeping, which is easy
/// to get wrong and silently stops the refresh.
mixin RefreshOnRouteReturn<T extends StatefulWidget> on State<T>
    implements RouteAware {
  /// Called when a route pushed over this screen has been popped.
  void onRouteReturn();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => onRouteReturn();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
