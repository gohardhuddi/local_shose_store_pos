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

    return Center(
      child: Column(
        children: [
          Text("Theme"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                context.watch<ThemeBloc>().state == ThemeMode.light
                    ? "Light"
                    : "Dark",
              ),
              Switch(
                value: context.watch<ThemeBloc>().state == ThemeMode.light,
                onChanged: (v) {
                  context.read<ThemeBloc>().add(ThemeChanged(!v));
                },
              ),
            ],
          ),
          Text("Network & Connection"),
          // 👇 listen to connectivity changes for icon colors
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, state) {
              // Default color
              Color connectivityStateIconColor =
                  Colors.green; // Online by default
              Color internetIconColor = Colors.green; // Online by default
              Color cloudServiceIconColor = Colors.green; // Online by default

              if (state.status == ConnectivityStatus.noInternet) {
                internetIconColor = Colors.red; // offline
              } else if (state.status ==
                  ConnectivityStatus.internetOnlyBackendDown) {
                cloudServiceIconColor =
                    Colors.red; // internet ok but backend down
              } else if (state.status == ConnectivityStatus.online) {
                connectivityStateIconColor = Colors.green; // fully online
                internetIconColor = Colors.green; // fully online
                cloudServiceIconColor = Colors.green; // fully online
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          CustomImagesPaths.connectivityStateIcon,
                          color: connectivityStateIconColor,
                        ),
                      ),
                      Text("You"),
                    ],
                  ),
                  SpinKitThreeBounce(color: internetIconColor, size: 20.0),
                  Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          CustomImagesPaths.internetIcon,
                          color: internetIconColor,
                        ),
                      ),
                      Text("Internet"),
                    ],
                  ),
                  SpinKitThreeBounce(color: cloudServiceIconColor, size: 20.0),
                  Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          CustomImagesPaths.cloudServiceIcon,
                          color: cloudServiceIconColor,
                        ),
                      ),
                      Text("Server"),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
