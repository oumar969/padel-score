import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/new_match_screen.dart';
import '../screens/score_screen.dart';
import '../screens/stats_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/new', builder: (_, __) => const NewMatchScreen()),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(
      path: '/match/:id',
      builder: (_, state) => ScoreScreen(matchId: state.pathParameters['id']!),
    ),
  ],
);
