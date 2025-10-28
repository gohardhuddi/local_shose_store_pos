// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
// import 'package:local_shoes_store_pos/views/theme_bloc/theme_event.dart';
//
// import '../controller/connectivity_controller/connectivity_bloc.dart';
// import '../controller/connectivity_controller/connectivity_state.dart';
// import '../helper/constants.dart';
//
// class MoreScreen extends StatelessWidget {
//   const MoreScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final isLight = context.watch<ThemeBloc>().state == ThemeMode.light;
//
//     return Center(
//       child: Column(
//         children: [
//           ListTile(
//             leading: Icon(
//               isLight ? Icons.wb_sunny_outlined : Icons.nightlight_round,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             title: const Text("Theme"),
//             subtitle: Text(isLight ? "Light Mode" : "Dark Mode"),
//             trailing: Switch(
//               value: context.watch<ThemeBloc>().state == ThemeMode.light,
//               onChanged: (v) {
//                 context.read<ThemeBloc>().add(ThemeChanged(!v));
//               },
//             ),
//           ),
//           Text("Theme"),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               Text(
//                 context.watch<ThemeBloc>().state == ThemeMode.light
//                     ? "Light"
//                     : "Dark",
//               ),
//               Switch(
//                 value: context.watch<ThemeBloc>().state == ThemeMode.light,
//                 onChanged: (v) {
//                   context.read<ThemeBloc>().add(ThemeChanged(!v));
//                 },
//               ),
//             ],
//           ),
//           Text("Network & Connection"),
//           // 👇 listen to connectivity changes for icon colors
//           BlocBuilder<ConnectivityBloc, ConnectivityState>(
//             builder: (context, state) {
//               // Default color
//               Color connectivityStateIconColor =
//                   Colors.green; // Online by default
//               Color internetIconColor = Colors.green; // Online by default
//               Color cloudServiceIconColor = Colors.green; // Online by default
//
//               if (state.status == ConnectivityStatus.noInternet) {
//                 internetIconColor = Colors.red; // offline
//               } else if (state.status ==
//                   ConnectivityStatus.internetOnlyBackendDown) {
//                 cloudServiceIconColor =
//                     Colors.red; // internet ok but backend down
//               } else if (state.status == ConnectivityStatus.online) {
//                 connectivityStateIconColor = Colors.green; // fully online
//                 internetIconColor = Colors.green; // fully online
//                 cloudServiceIconColor = Colors.green; // fully online
//               }
//
//               return Card(
//                 elevation: 0,
//                 color: Theme.of(
//                   context,
//                 ).colorScheme.surfaceVariant.withOpacity(0.5),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 24.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildStatusColumn(
//                         iconPath: CustomImagesPaths.connectivityStateIcon,
//                         color: connectivityStateIconColor,
//                         label: "You",
//                       ),
//                       SpinKitThreeBounce(color: internetIconColor, size: 20.0),
//                       _buildStatusColumn(
//                         iconPath: CustomImagesPaths.internetIcon,
//                         color: internetIconColor,
//                         label: "Internet",
//                       ),
//                       SpinKitThreeBounce(
//                         color: cloudServiceIconColor,
//                         size: 20.0,
//                       ),
//                       _buildStatusColumn(
//                         iconPath: CustomImagesPaths.cloudServiceIcon,
//                         color: cloudServiceIconColor,
//                         label: "Server",
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusColumn({
//     required String iconPath,
//     required Color color,
//     required String label,
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         SizedBox(
//           width: 40,
//           height: 40,
//           child: Image.asset(iconPath, color: color),
//         ),
//         const SizedBox(height: 8),
//         Text(label),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_event.dart';

import '../controller/connectivity_controller/connectivity_bloc.dart';
import '../controller/connectivity_controller/connectivity_state.dart';
import '../helper/constants.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = context.watch<ThemeBloc>().state == ThemeMode.light;

    // Use a Material widget with a background color that matches the scaffold
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // --- Theme Section ---
          _buildSectionHeader(context, "Appearance"),
          ListTile(
            leading: Icon(
              isLight ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text("Theme"),
            subtitle: Text(isLight ? "Light Mode" : "Dark Mode"),
            trailing: Switch(
              value: context.watch<ThemeBloc>().state == ThemeMode.light,
              onChanged: (v) {
                context.read<ThemeBloc>().add(ThemeChanged(!v));
              },
            ),
          ),

          const Divider(height: 30),

          // --- Connection Status Section ---
          _buildSectionHeader(context, "Connection Status"),
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, state) {
              Color connectivityStateIconColor = Colors.grey;
              Color internetIconColor = Colors.grey;
              Color cloudServiceIconColor = Colors.grey;

              // Cleaner logic for setting colors
              switch (state.status) {
                case ConnectivityStatus.online:
                  connectivityStateIconColor = Colors.green;
                  internetIconColor = Colors.green;
                  cloudServiceIconColor = Colors.green;
                  break;
                case ConnectivityStatus.internetOnlyBackendDown:
                  connectivityStateIconColor = Colors.green;
                  internetIconColor = Colors.green;
                  cloudServiceIconColor = Colors.orange; // Warning color
                  break;
                case ConnectivityStatus.noInternet:
                  connectivityStateIconColor = Colors.red;
                  internetIconColor = Colors.red;
                  cloudServiceIconColor = Colors.red;
                  break;
              }

              // Use a Card for better visual grouping
              return Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusColumn(
                        iconPath: CustomImagesPaths.connectivityStateIcon,
                        color: connectivityStateIconColor,
                        label: "You",
                      ),
                      SpinKitThreeBounce(color: internetIconColor, size: 20.0),
                      _buildStatusColumn(
                        iconPath: CustomImagesPaths.internetIcon,
                        color: internetIconColor,
                        label: "Internet",
                      ),
                      SpinKitThreeBounce(
                        color: cloudServiceIconColor,
                        size: 20.0,
                      ),
                      _buildStatusColumn(
                        iconPath: CustomImagesPaths.cloudServiceIcon,
                        color: cloudServiceIconColor,
                        label: "Server",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Helper for status columns
  Widget _buildStatusColumn({
    required String iconPath,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Image.asset(iconPath, color: color),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
