abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final bool isDark;
  ThemeChanged(this.isDark);
}

class SystemThemeChanged extends ThemeEvent {
  final bool isDark;
  SystemThemeChanged(this.isDark);
}
