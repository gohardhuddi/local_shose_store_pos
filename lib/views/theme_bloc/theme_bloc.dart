import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_event.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(_getInitialTheme()) {
    var dispatcher = SchedulerBinding.instance.platformDispatcher;

    // Listen for system brightness changes
    dispatcher.onPlatformBrightnessChanged = () {
      var brightness = dispatcher.platformBrightness;
      add(SystemThemeChanged(brightness == Brightness.dark));
    };

    on<ThemeChanged>((event, emit) {
      emit(event.isDark ? ThemeMode.dark : ThemeMode.light);
    });

    on<SystemThemeChanged>((event, emit) {
      emit(event.isDark ? ThemeMode.dark : ThemeMode.light);
    });
  }

  static ThemeMode _getInitialTheme() {
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
