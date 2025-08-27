import 'package:equatable/equatable.dart';

enum ConnectivityStatus {
  noInternet, // device is offline
  internetOnlyBackendDown, // device online, backend unreachable
  online, // device online, backend healthy
}

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  final bool hasInternet;
  final bool backendUp;
  final String? lastError;

  const ConnectivityState({
    required this.status,
    required this.hasInternet,
    required this.backendUp,
    this.lastError,
  });

  const ConnectivityState.initial()
    : status = ConnectivityStatus.noInternet,
      hasInternet = false,
      backendUp = false,
      lastError = null;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? hasInternet,
    bool? backendUp,
    String? lastError,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      hasInternet: hasInternet ?? this.hasInternet,
      backendUp: backendUp ?? this.backendUp,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [status, hasInternet, backendUp, lastError];
}
