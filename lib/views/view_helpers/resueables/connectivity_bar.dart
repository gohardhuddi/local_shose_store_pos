import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../controller/connectivity_controller/connectivity_bloc.dart';
import '../../../controller/connectivity_controller/connectivity_state.dart';
import '../../../helper/constants.dart';
import '../../../helper/global.dart';

class ConnectivitySnackListener extends StatefulWidget {
  final Widget child;
  const ConnectivitySnackListener({super.key, required this.child});

  @override
  State<ConnectivitySnackListener> createState() =>
      _ConnectivitySnackListenerState();
}

class _ConnectivitySnackListenerState extends State<ConnectivitySnackListener> {
  bool _wasDisconnected = false; // 👈 track previous state

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        final messenger = Global.appScaffoldMessengerKey.currentState;
        if (messenger == null) return;

        messenger.clearSnackBars();

        SnackBar? bar;
        switch (state.status) {
          case ConnectivityStatus.noInternet:
            _wasDisconnected = true; // mark as disconnected
            bar = _buildBar("⦸⚪ You're offline", Colors.red);
            break;

          case ConnectivityStatus.internetOnlyBackendDown:
            _wasDisconnected = true; // also considered "disconnected" case
            bar = _buildBar(
              "⚠️⚪ Internet is up, but backend is down",
              Colors.orange,
            );
            break;

          case ConnectivityStatus.online:
            if (_wasDisconnected) {
              // only show "back online" if we were disconnected before
              bar = _buildBar(
                "⚪ Your connection is back",
                Colors.green,
                duration: const Duration(seconds: 5),
              );
            }
            _wasDisconnected = false; // reset after back online
            break;
        }

        if (bar != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messenger.showSnackBar(bar!);
          });
        }
      },
      child: widget.child,
    );
  }

  SnackBar _buildBar(String text, Color color, {Duration? duration}) {
    return SnackBar(
      content: Text(
        text,
        style: TextStyle(color: CustomColors.whiteButtonColors),
      ),
      backgroundColor: color,
      duration:
          duration ?? const Duration(days: 365), // persistent unless given
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        kBottomNavigationBarHeight + 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
    );
  }
}
