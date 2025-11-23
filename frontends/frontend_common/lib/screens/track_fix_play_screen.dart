// import 'package:common/generic/managers/theme_manager.dart';
// import 'package:common/track_fix/models/serializable_track_fix_game_state.dart';
// import 'package:common/track_fix/widgets/track_fix_game_grid.dart';
// import 'package:flutter/material.dart';
// import 'package:frontend_common/managers/game_manager.dart';

// class TrackFixPlayScreen extends StatelessWidget {
//   const TrackFixPlayScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final thm =
//         GameManager.instance.miniGameState as SerializableTrackFixGameState;
//     return Center(
//       child: Column(
//         children: [
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 20.0),
//             child: _Header(),
//           ),
//           LayoutBuilder(builder: (context, constraints) {
//             return SizedBox(
//               width: 0.8 * constraints.maxWidth,
//               height: (constraints.maxWidth * 1.5 -
//                   2 * 20 -
//                   2 * ThemeManager.instance.textSize),
//               child: Center(
//                 child: TrackFixGameGrid(
//                   rowCount: thm.grid.rowCount,
//                   columnCount: thm.grid.columnCount,
//                   getTileAt: (row, col) => thm.grid.tileAt(row: row, col: col)!,
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// class _Header extends StatefulWidget {
//   const _Header();

//   @override
//   State<_Header> createState() => _HeaderState();
// }

// class _HeaderState extends State<_Header> {
//   @override
//   void initState() {
//     super.initState();

//     final gm = GameManager.instance;
//     gm.onMiniGameStateUpdated.listen(refresh);
//   }

//   @override
//   void dispose() {
//     final gm = GameManager.instance;
//     gm.onMiniGameStateUpdated.cancel(refresh);

//     super.dispose();
//   }

//   void refresh() => setState(() {});

//   @override
//   Widget build(BuildContext context) {
//     final thm =
//         GameManager.instance.miniGameState as SerializableTrackFixGameState;
//     final tm = ThemeManager.instance;

//     return LayoutBuilder(builder: (context, constraints) {
//       return thm.timeRemaining.inSeconds > 0
//           ? Text('Temps restant ${thm.timeRemaining.inSeconds}',
//               style: tm.textFrontendSc
//                   .copyWith(fontSize: constraints.maxWidth * 0.05))
//           : Text('Retournons à la gare!',
//               style: tm.textFrontendSc
//                   .copyWith(fontSize: constraints.maxWidth * 0.05));
//     });
//   }
// }
