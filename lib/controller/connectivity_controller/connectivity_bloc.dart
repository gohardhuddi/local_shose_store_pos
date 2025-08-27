// controller/connectivity_controller/connectivity_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:local_shoes_store_pos/services/networking/network_service.dart';

import 'connectivity_events.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final NetworkService _networkService;

  ConnectivityBloc(this._networkService) : super(ConnectivityState.initial()) {
    on<CheckInternetConnectivityEvent>(_onConnectivityWatch);
  }

  Future<void> _onConnectivityWatch(
    CheckInternetConnectivityEvent event,
    Emitter<ConnectivityState> emit,
  ) async {
    final checker = InternetConnectionChecker.createInstance();

    // ---- Initial check (immediate) ----
    final hasNet = await checker.hasConnection;
    if (!hasNet) {
      emit(state.copyWith(status: ConnectivityStatus.noInternet));
    } else {
      final backendOk = await _networkService.isBackendHealthy();
      emit(
        state.copyWith(
          status: backendOk
              ? ConnectivityStatus.online
              : ConnectivityStatus.internetOnlyBackendDown,
        ),
      );
    }

    // ---- Continuous checks (every 3s) ----
    final stream = Stream.periodic(const Duration(seconds: 3)).asyncMap((
      _,
    ) async {
      final internet = await checker.hasConnection;
      if (!internet) {
        return ConnectivityStatus.noInternet;
      }
      final backendOk = await _networkService.isBackendHealthy();
      return backendOk
          ? ConnectivityStatus.online
          : ConnectivityStatus.internetOnlyBackendDown;
    });

    // Keep handler alive and map stream to state
    await emit.forEach<ConnectivityStatus>(
      stream,
      onData: (s) => state.copyWith(status: s),
      onError: (_, __) => state.copyWith(status: ConnectivityStatus.noInternet),
    );
  }
}
