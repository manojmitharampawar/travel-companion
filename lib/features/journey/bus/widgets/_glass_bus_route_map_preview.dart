part of '../add_bus_journey_screen.dart';

class _GlassBusRouteMapPreview extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint? destination;
  final RouteResult? routeResult;
  final bool isFetchingRoute;

  const _GlassBusRouteMapPreview({
    this.origin,
    this.destination,
    this.routeResult,
    this.isFetchingRoute = false,
  });

  @override
  State<_GlassBusRouteMapPreview> createState() =>
      _GlassBusRouteMapPreviewState();
}

