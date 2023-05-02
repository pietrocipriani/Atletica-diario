import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';

// TODO: keep up to date with [PlatformApp]
class GetPlatformApp extends PlatformWidgetBase<GetCupertinoApp, GetMaterialApp> {
  final Key? widgetKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver>? navigatorObservers;
  final TransitionBuilder? builder;
  final String? title;
  final GenerateAppTitle? onGenerateTitle;
  final Color? color;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale>? supportedLocales;
  final bool? showPerformanceOverlay;
  final bool? checkerboardRasterCacheImages;
  final bool? checkerboardOffscreenLayers;
  final bool? showSemanticsDebugger;
  final bool? debugShowCheckedModeBanner;
  final Map<LogicalKeySet, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final InitialRouteListFactory? onGenerateInitialRoutes;

  final PlatformBuilder<MaterialAppData>? material;
  final PlatformBuilder<CupertinoAppData>? cupertino;
  final PlatformBuilder<MaterialAppRouterData>? materialRouter;
  final PlatformBuilder<CupertinoAppRouterData>? cupertinoRouter;

  /// {@macro flutter.widgets.widgetsApp.routeInformationProvider}
  final RouteInformationProvider? routeInformationProvider;

  /// {@macro flutter.widgets.widgetsApp.routeInformationParser}
  final RouteInformationParser<Object>? routeInformationParser;

  /// {@macro flutter.widgets.widgetsApp.routerDelegate}
  final RouterDelegate<Object>? routerDelegate;

  /// {@macro flutter.widgets.widgetsApp.backButtonDispatcher}
  final BackButtonDispatcher? backButtonDispatcher;

  final String? restorationScopeId;

  final ScrollBehavior? scrollBehavior;

  final bool? useInheritedMediaQuery;

  const GetPlatformApp({
    super.key,
    this.widgetKey,
    this.navigatorKey,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales,
    this.showPerformanceOverlay,
    this.checkerboardRasterCacheImages,
    this.checkerboardOffscreenLayers,
    this.showSemanticsDebugger,
    this.debugShowCheckedModeBanner,
    this.shortcuts,
    this.actions,
    this.onGenerateInitialRoutes,
    this.restorationScopeId,
    this.scrollBehavior,
    this.useInheritedMediaQuery,
    this.material,
    this.cupertino,
  })  : routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null,
        materialRouter = null,
        cupertinoRouter = null;

  const GetPlatformApp.router({
    super.key,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.backButtonDispatcher,
    this.widgetKey,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales,
    this.showPerformanceOverlay,
    this.checkerboardRasterCacheImages,
    this.checkerboardOffscreenLayers,
    this.showSemanticsDebugger,
    this.debugShowCheckedModeBanner,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    this.useInheritedMediaQuery,
    PlatformBuilder<MaterialAppRouterData>? material,
    PlatformBuilder<CupertinoAppRouterData>? cupertino,
  })  : navigatorObservers = null,
        navigatorKey = null,
        onGenerateRoute = null,
        home = null,
        onGenerateInitialRoutes = null,
        onUnknownRoute = null,
        routes = null,
        initialRoute = null,
        this.material = null,
        this.cupertino = null,
        materialRouter = material,
        cupertinoRouter = cupertino;

  @override
  createMaterialWidget(BuildContext context) {
    final dataRouter = materialRouter?.call(context, platform(context));

    if (routeInformationParser != null || dataRouter?.routeInformationParser != null) {
      assert(dataRouter?.routerDelegate != null || routerDelegate != null);

      return GetMaterialApp.router(
        routeInformationProvider: dataRouter?.routeInformationProvider ?? routeInformationProvider,
        routeInformationParser: dataRouter?.routeInformationParser ?? routeInformationParser!,
        routerDelegate: dataRouter?.routerDelegate ?? routerDelegate!,
        backButtonDispatcher: dataRouter?.backButtonDispatcher ?? backButtonDispatcher,
        builder: dataRouter?.builder ?? builder,
        title: dataRouter?.title ?? title ?? '',
        onGenerateTitle: dataRouter?.onGenerateTitle ?? onGenerateTitle,
        color: dataRouter?.color ?? color,
        theme: (dataRouter?.theme ?? Theme.of(context)).copyWith(platform: TargetPlatform.android),
        darkTheme: dataRouter?.darkTheme?.copyWith(platform: TargetPlatform.android),
        highContrastDarkTheme: dataRouter?.highContrastDarkTheme,
        highContrastTheme: dataRouter?.highContrastTheme,
        themeMode: dataRouter?.themeMode ?? ThemeMode.system,
        locale: dataRouter?.locale ?? locale,
        localizationsDelegates: dataRouter?.localizationsDelegates ?? localizationsDelegates,
        localeListResolutionCallback: dataRouter?.localeListResolutionCallback ?? localeListResolutionCallback,
        localeResolutionCallback: dataRouter?.localeResolutionCallback ?? localeResolutionCallback,
        supportedLocales: dataRouter?.supportedLocales ?? supportedLocales ?? const <Locale>[Locale('en', 'US')],
        debugShowMaterialGrid: dataRouter?.debugShowMaterialGrid ?? false,
        showPerformanceOverlay: dataRouter?.showPerformanceOverlay ?? showPerformanceOverlay ?? false,
        checkerboardRasterCacheImages: dataRouter?.checkerboardRasterCacheImages ?? checkerboardRasterCacheImages ?? false,
        checkerboardOffscreenLayers: dataRouter?.checkerboardOffscreenLayers ?? checkerboardOffscreenLayers ?? false,
        showSemanticsDebugger: dataRouter?.showSemanticsDebugger ?? showSemanticsDebugger ?? false,
        debugShowCheckedModeBanner: dataRouter?.debugShowCheckedModeBanner ?? debugShowCheckedModeBanner ?? true,
        shortcuts: dataRouter?.shortcuts ?? shortcuts,
        actions: dataRouter?.actions ?? actions,
        key: dataRouter?.widgetKey ?? widgetKey,
        // restorationScopeId: dataRouter?.restorationScopeId ?? restorationScopeId,
        scaffoldMessengerKey: dataRouter?.scaffoldMessengerKey,
        scrollBehavior: dataRouter?.scrollBehavior ?? scrollBehavior,
        useInheritedMediaQuery: dataRouter?.useInheritedMediaQuery ?? useInheritedMediaQuery ?? false,
      );
    } else {
      final data = material?.call(context, platform(context));
      return GetMaterialApp(
        key: data?.widgetKey ?? widgetKey,
        navigatorKey: data?.navigatorKey ?? navigatorKey,
        home: data?.home ?? home,
        routes: data?.routes ?? routes ?? const <String, WidgetBuilder>{},
        initialRoute: data?.initialRoute ?? initialRoute,
        onGenerateRoute: data?.onGenerateRoute ?? onGenerateRoute,
        onUnknownRoute: data?.onUnknownRoute ?? onUnknownRoute,
        navigatorObservers: data?.navigatorObservers ?? navigatorObservers ?? const <NavigatorObserver>[],
        builder: data?.builder ?? builder,
        title: data?.title ?? title ?? '',
        onGenerateTitle: data?.onGenerateTitle ?? onGenerateTitle,
        color: data?.color ?? color,
        locale: data?.locale ?? locale,
        localizationsDelegates: data?.localizationsDelegates ?? localizationsDelegates,
        localeListResolutionCallback: data?.localeListResolutionCallback ?? localeListResolutionCallback,
        localeResolutionCallback: data?.localeResolutionCallback ?? localeResolutionCallback,
        supportedLocales: data?.supportedLocales ?? supportedLocales ?? const <Locale>[Locale('en', 'US')],
        showPerformanceOverlay: data?.showPerformanceOverlay ?? showPerformanceOverlay ?? false,
        checkerboardRasterCacheImages: data?.checkerboardRasterCacheImages ?? checkerboardRasterCacheImages ?? false,
        checkerboardOffscreenLayers: data?.checkerboardOffscreenLayers ?? checkerboardOffscreenLayers ?? false,
        showSemanticsDebugger: data?.showSemanticsDebugger ?? showSemanticsDebugger ?? false,
        debugShowCheckedModeBanner: data?.debugShowCheckedModeBanner ?? debugShowCheckedModeBanner ?? true,
        theme: (data?.theme ?? Theme.of(context)).copyWith(platform: TargetPlatform.android),
        debugShowMaterialGrid: data?.debugShowMaterialGrid ?? false,
        darkTheme: data?.darkTheme?.copyWith(platform: TargetPlatform.android),
        themeMode: data?.themeMode ?? ThemeMode.system,
        shortcuts: data?.shortcuts ?? shortcuts,
        actions: data?.actions ?? actions,
        onGenerateInitialRoutes: data?.onGenerateInitialRoutes ?? onGenerateInitialRoutes,
        highContrastDarkTheme: data?.highContrastDarkTheme,
        highContrastTheme: data?.highContrastTheme,
        // restorationScopeId: data?.restorationScopeId ?? restorationScopeId,
        scaffoldMessengerKey: data?.scaffoldMessengerKey,
        scrollBehavior: data?.scrollBehavior ?? scrollBehavior,
        useInheritedMediaQuery: data?.useInheritedMediaQuery ?? useInheritedMediaQuery ?? false,
      );
    }
  }

  @override
  createCupertinoWidget(BuildContext context) {
    final dataRouter = cupertinoRouter?.call(context, platform(context));

    if (routeInformationParser != null || dataRouter?.routeInformationParser != null) {
      assert(dataRouter?.routerDelegate != null || routerDelegate != null);

      return GetCupertinoApp.router(
        routeInformationProvider: dataRouter?.routeInformationProvider ?? routeInformationProvider,
        routeInformationParser: dataRouter?.routeInformationParser ?? routeInformationParser!,
        routerDelegate: dataRouter?.routerDelegate ?? routerDelegate!,
        backButtonDispatcher: dataRouter?.backButtonDispatcher ?? backButtonDispatcher,
        theme: dataRouter?.theme,
        builder: dataRouter?.builder ?? builder,
        title: dataRouter?.title ?? title ?? '',
        onGenerateTitle: dataRouter?.onGenerateTitle ?? onGenerateTitle,
        color: dataRouter?.color ?? color,
        locale: dataRouter?.locale ?? locale,
        localizationsDelegates: dataRouter?.localizationsDelegates ?? localizationsDelegates,
        localeListResolutionCallback: dataRouter?.localeListResolutionCallback ?? localeListResolutionCallback,
        localeResolutionCallback: dataRouter?.localeResolutionCallback ?? localeResolutionCallback,
        supportedLocales: dataRouter?.supportedLocales ?? supportedLocales ?? const <Locale>[Locale('en', 'US')],
        showPerformanceOverlay: dataRouter?.showPerformanceOverlay ?? showPerformanceOverlay ?? false,
        checkerboardRasterCacheImages: dataRouter?.checkerboardRasterCacheImages ?? checkerboardRasterCacheImages ?? false,
        checkerboardOffscreenLayers: dataRouter?.checkerboardOffscreenLayers ?? checkerboardOffscreenLayers ?? false,
        showSemanticsDebugger: dataRouter?.showSemanticsDebugger ?? showSemanticsDebugger ?? false,
        debugShowCheckedModeBanner: dataRouter?.debugShowCheckedModeBanner ?? debugShowCheckedModeBanner ?? true,
        shortcuts: dataRouter?.shortcuts ?? shortcuts,
        actions: dataRouter?.actions ?? actions,
        key: dataRouter?.widgetKey ?? widgetKey,
        /* restorationScopeId: dataRouter?.restorationScopeId ?? restorationScopeId,
        scrollBehavior: dataRouter?.scrollBehavior ?? scrollBehavior, */
        useInheritedMediaQuery: dataRouter?.useInheritedMediaQuery ?? useInheritedMediaQuery ?? false,
      );
    } else {
      final data = cupertino?.call(context, platform(context));
      return GetCupertinoApp(
        key: data?.widgetKey ?? widgetKey,
        navigatorKey: data?.navigatorKey ?? navigatorKey,
        home: data?.home ?? home,
        routes: data?.routes ?? routes ?? const <String, WidgetBuilder>{},
        initialRoute: data?.initialRoute ?? initialRoute,
        onGenerateRoute: data?.onGenerateRoute ?? onGenerateRoute,
        onUnknownRoute: data?.onUnknownRoute ?? onUnknownRoute,
        navigatorObservers: data?.navigatorObservers ?? navigatorObservers ?? const <NavigatorObserver>[],
        builder: data?.builder ?? builder,
        title: data?.title ?? title ?? '',
        onGenerateTitle: data?.onGenerateTitle ?? onGenerateTitle,
        color: data?.color ?? color,
        locale: data?.locale ?? locale,
        localizationsDelegates: data?.localizationsDelegates ?? localizationsDelegates,
        localeListResolutionCallback: data?.localeListResolutionCallback ?? localeListResolutionCallback,
        localeResolutionCallback: data?.localeResolutionCallback ?? localeResolutionCallback,
        supportedLocales: data?.supportedLocales ?? supportedLocales ?? const <Locale>[Locale('en', 'US')],
        showPerformanceOverlay: data?.showPerformanceOverlay ?? showPerformanceOverlay ?? false,
        checkerboardRasterCacheImages: data?.checkerboardRasterCacheImages ?? checkerboardRasterCacheImages ?? false,
        checkerboardOffscreenLayers: data?.checkerboardOffscreenLayers ?? checkerboardOffscreenLayers ?? false,
        showSemanticsDebugger: data?.showSemanticsDebugger ?? showSemanticsDebugger ?? false,
        debugShowCheckedModeBanner: data?.debugShowCheckedModeBanner ?? debugShowCheckedModeBanner ?? true,
        theme: data?.theme,
        shortcuts: data?.shortcuts ?? shortcuts,
        actions: data?.actions ?? actions,
        onGenerateInitialRoutes: data?.onGenerateInitialRoutes ?? onGenerateInitialRoutes,
        /* restorationScopeId: data?.restorationScopeId ?? restorationScopeId,
        scrollBehavior: data?.scrollBehavior ?? scrollBehavior, */
        useInheritedMediaQuery: data?.useInheritedMediaQuery ?? useInheritedMediaQuery ?? false,
      );
    }
  }
}
