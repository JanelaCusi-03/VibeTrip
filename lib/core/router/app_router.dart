import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/places/presentation/map_screen.dart';
import '../../features/places/presentation/place_detail_screen.dart';
import '../../features/profile/presentation/home_gate.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'app_routes.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeGate(),
      ),
      GoRoute(
        path: AppRoutes.placeDetailPattern,
        builder: (context, state) =>
            PlaceDetailScreen(placeId: state.pathParameters['placeId']!),
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
