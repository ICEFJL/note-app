import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:note_app/common_widget.dart';
import 'package:note_app/cardmanager.dart';
import 'package:note_app/util/log.dart';
import 'package:note_app/models/dto.dart' as dto;
import 'package:note_app/models/dto.dart';
import 'package:note_app/handle.dart';
import 'package:note_app/screens/book_page.dart';
import 'package:note_app/screens/card_page.dart';
import 'package:note_app/screens/category_page.dart';
import 'package:note_app/screens/save_page.dart';
import 'package:note_app/theme.dart';
import 'package:note_app/util/font_util.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:tray_manager/tray_manager.dart' as stray;
import 'package:window_manager/window_manager.dart';

const appTitle = "Made By ICEFJL";
const title = 'Card notes';

var _listen = false;
var _trayOpen = false;

var preHandleStatus = true;
var currentPid = -1;

/// 检查当前环境是否为桌面环境。
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  if (isDesktop) {
    preHandleStatus = await preHandle();
    if (!preHandleStatus) {
      final process = await Process.start(
          'windowsapp_singleton_main.exe', ['$currentPid', title]);
      logger.d(await process.exitCode, currentPid);
      exit(0);
    }
  }
  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }
  if (isDesktop) {
    final iconPath = Platform.isWindows
        ? 'images/facebook-fill.ico'
        : 'images/facebook-fill.png';
    await flutter_acrylic.Window.initialize();
    await windowManager.ensureInitialized();
    await windowManager.setIcon(iconPath);
    await windowManager.setTitle(title);
    //如果应用已经被打开,则显示原本的窗口结束自身进程,如果显示失败则不结束进程

    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setSize(const Size(999, 760));
      await windowManager.setMinimumSize(const Size(999, 760));
      await windowManager.center();
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });

    // 设置系统托盘图标
    await stray.trayManager.setIcon(iconPath);

    // 创建一个新的系统托盘菜单
    stray.Menu menu = stray.Menu(items: [
      // 创建一个菜单项，当用户点击时，显示窗口
      stray.MenuItem(
        key: 'show_window',
        label: 'Show Window',
      ),
      // 添加一个分隔符，用于在视觉上分隔菜单项
      stray.MenuItem.separator(),
      // 创建一个菜单项，当用户点击时，退出应用程序
      stray.MenuItem(
        key: 'exit_app',
        label: 'Exit App',
      ),
    ]);

    // 设置系统托盘的上下文菜单为我们之前创建的菜单
    stray.trayManager.setContextMenu(menu);

    // 当接收到这个信号时，显示窗口
    ProcessSignal.sigint.watch().listen((event) {
      windowManager.show();
    });
  }
  runApp(const MyApp());
  if (isDesktop) {
    finalHandle();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // 定义一个无状态的MyApp组件

  FluentThemeData buildThemeData(
      AppTheme appTheme, Brightness brightness, BuildContext context) {
    return FluentThemeData(
      brightness: brightness,
      accentColor: appTheme.color,
      visualDensity: VisualDensity.standard,
      focusTheme: FocusThemeData(
        glowFactor: is10footScreen(context) ? 2.0 : 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppTheme()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => CommonData())
      ],
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: buildThemeData(appTheme, Brightness.dark, context),
          theme: buildThemeData(appTheme, Brightness.light, context),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: const NavigationPaneThemeData(),
                child: child!,
              ),
            );
          },
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          routeInformationProvider: router.routeInformationProvider,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key,
      required this.child,
      required this.shellContext,
      required this.state})
      : super(key: key);
  final Widget child;
  final BuildContext? shellContext;
  final GoRouterState state;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WindowListener, stray.TrayListener {
  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();
  final booksAddController = TextEditingController();

  final List<NavigationPaneItem> footerItems = [];
  final List<NavigationPaneItem> originnalItems = [];

  static showError(String error) async {
    await displayInfoBar(_shellNavigatorKey.currentState!.context,
        builder: (context, close) {
      return InfoBar(
        title: const Text('出现错误:'),
        content: Text(error),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: InfoBarSeverity.error,
      );
    });
  }

  Future<bool> checkBook(String name) async {
    // 检查name参数是否为空
    if (name.isEmpty) {
      await showError('书名不能为空');
      return false;
    }

    final ret = await Book.getByName(name) == null;
    if (!ret) {
      await showError('书名重复');
    }
    return ret;
  }

  Future<bool> checkCate(String name) async {
    // 检查name参数是否为空
    if (name.isEmpty) {
      showError('分类名不能为空');
      return false;
    }

    final ret = await dto.Category.getByName(name) == null;
    if (!ret) {
      showError('分类名重复');
    }
    return ret;
  }

  PaneItem createPaneItem(IconData icon, String title,
      {MyState? state, String? dest, Function? onTap}) {
    return PaneItem(
      icon: Icon(icon),
      title: Text(title),
      body: const SizedBox.shrink(),
      onTap: () {
        if (state != null && dest != null) {
          final appState = _rootNavigatorKey.currentContext!.watch<AppState>();
          appState.state = state;
          _rootNavigatorKey.currentContext!
              .goNamed("noteapp", queryParams: {"dest": dest});
        } else if (onTap != null) {
          onTap();
        }
      },
    );
  }

  void beforeInit() async {
    final items = [
      createPaneItem(FluentIcons.diet_plan_notebook, 'Bookmarks',
          state: MyState.kOnBookMarks, dest: "book"),
      createPaneItem(FluentIcons.auto_fill_template, 'Categories',
          state: MyState.kOnCategories, dest: "category"),
      createPaneItem(FluentIcons.collapse_content, 'Cards',
          state: MyState.kOnContents, dest: "card"),
      createPaneItem(FluentIcons.saved_offline, 'Import&Export',
          state: MyState.kOnSave, dest: "save"),
    ];
    originnalItems.addAll(items);

    final appData = context.read<AppData>();
    final commonData = context.read<CommonData>();
    await appData.loadAsync();
    final wList = appData.getValuesByKey('work');
    final eList = appData.getValuesByKey('editor');
    if (wList != null && wList.isNotEmpty) {
      commonData.setWorkPath(wList.first);
    }
    if (eList != null && eList.isNotEmpty) {
      commonData.setEditorPath(eList.first);
    }

    if (!_listen) {
      searchController.addListener(() async {
        var text = searchController.text;
        if (text.endsWith('...')) {
          text = text.substring(0, text.length - 3);
        }
        await appData.setContentWithTitle(text);
      });
      _listen = true;
    }

    // 定义导航模式的列表
    final navigatorModes = ['top', 'open', 'compact', 'minimal', 'auto'];

    // 向footerItems列表中添加一个PaneItem对象
    footerItems.add(createPaneItem(FluentIcons.settings, 'Setting',
        // 设置PaneItem的点击事件处理器
        onTap: () async {
      // 当PaneItem被点击时，显示一个对话框
      await showDialog(
          // 允许点击对话框外部区域关闭对话框
          barrierDismissible: true,
          context: context,
          builder: (context) {
            // 对话框的内容为一个ContentDialog对象
            return ContentDialog(
                // 设置ContentDialog的最大宽度和高度
                constraints:
                    const BoxConstraints(maxWidth: 300.0, maxHeight: 400.0),
                // 设置ContentDialog的标题为一个包含文本和图标的行
                title: Row(
                  children: [
                    const Text('Display Mode'),
                    const Expanded(child: SizedBox()),
                    IconButton(
                        icon: const Icon(FluentIcons.cancel),
                        onPressed: () {
                          // 当图标被点击时，关闭对话框
                          Navigator.pop(context);
                        }),
                  ],
                ),
                // 设置ContentDialog的内容为一个Consumer对象
                content: Consumer(builder: (context, AppTheme value, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    // 为每个导航模式创建一个RadioButton
                    children: List.generate(5, (index) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RadioButton(
                              content: Text(
                                navigatorModes[index],
                                style: getFontStyle(size: 18.0),
                              ),
                              // 如果当前选中的导航模式与此RadioButton对应的导航模式相同，设置此RadioButton为选中状态
                              checked: value.selected == index,
                              onChanged: (checked) {
                                if (checked) {
                                  // 如果此RadioButton被选中，设置当前选中的导航模式为此RadioButton对应的导航模式
                                  value.selected = index;
                                  Map<String, PaneDisplayMode> modeMap = {
                                    'top': PaneDisplayMode.top,
                                    'open': PaneDisplayMode.open,
                                    'compact': PaneDisplayMode.compact,
                                    'minimal': PaneDisplayMode.minimal,
                                    'auto': PaneDisplayMode.auto,
                                  };

                                  value.displayMode =
                                      modeMap[navigatorModes[index]] ??
                                          PaneDisplayMode.auto;
                                }
                              }),
                        ),
                      );
                    }),
                  );
                }));
          });
    }));
    // 向footerItems列表中添加一个PaneItem对象
    footerItems.add(createPaneItem(FluentIcons.add, 'New',
        // 设置PaneItem的点击事件处理器
        onTap: () async {
      // 获取应用状态和应用数据
      final mutState = Provider.of<AppState>(context, listen: false);
      final appData = Provider.of<AppData>(context, listen: false);

      // 如果当前应用状态为MyState.kOnContents
      if (mutState.state == MyState.kOnContents) {
        // 调用CardManager的editContent方法，传入一个新的Content对象和当前的context
        await CardManager.editContent(Content(), context);
        return;
      }

      // 根据当前应用状态，确定name的值
      final name =
          mutState.state == MyState.kOnBookMarks ? "bookmark" : "category";

      // 显示一个对话框
      await showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: Text("New $name"),
            content: Card(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4.0)),
              child: InfoLabel(
                label: "Enter your $name name:",
                child: TextBox(
                  placeholder: '$name name',
                  expands: false,
                  controller: booksAddController,
                ),
              ),
            ),
            actions: [
              FilledButton(
                child: const Text('Ok'),
                onPressed: () async {
                  final text = booksAddController.text;
                  // 检查输入的名字是否有效，如果有效则添加新的书签或分类
                  if ((name == "bookmark" && await checkBook(text)) ||
                      (name == "category" && await checkCate(text))) {
                    await (name == "bookmark"
                        ? appData.addBook(dto.Book()..name = text)
                        : appData.addCategory(dto.Category()..name = text));
                  }
                  // 清空输入框并关闭对话框
                  booksAddController.clear();
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  // 清空输入框并关闭对话框
                  booksAddController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }));
  }

  @override
  void initState() {
    // 添加窗口管理器和托盘管理器的监听器
    windowManager.addListener(this);
    stray.trayManager.addListener(this);
    super.initState();
    beforeInit();
    // 在第一帧绘制后执行
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // 如果原本窗口已经存在
      if (!preHandleStatus) {
        // 显示一个对话框，提示用户程序已经在运行，不要重复运行
        await showTextDialog(
          context,
          title:
              const Text('The program has been running, please do not repeat!'),
          call: () {
            // 点击对话框的确认按钮时，销毁窗口
            windowManager.destroy();
          },
          noCall: () {
            // 点击对话框的取消按钮时，销毁窗口
            windowManager.destroy();
          },
        );
      }
    });
  }

  int _calculateSelectedIndex(BuildContext context) {
    // 获取应用状态
    final appState = context.watch<AppState>();
    // 根据应用状态，计算选中的索引
    switch (appState.state) {
      case MyState.kOnBookMarks:
        return 0;
      case MyState.kOnCategories:
        return 1;
      case MyState.kOnContents:
        return 2;
      case MyState.kOnSave:
        return 3;
    }
  }

  @override
  void dispose() {
    // 移除窗口管理器和托盘管理器的监听器
    windowManager.removeListener(this);
    stray.trayManager.removeListener(this);
    // 释放搜索控制器和搜索焦点节点
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final theme = FluentTheme.of(context);
    final appState = context.watch<AppState>();

    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: () {
          if (kIsWeb) {
            return const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            );
          }
          return DragToMoveArea(
            child: Row(children: [
              const Text(
                appTitle,
                style: TextStyle(fontSize: 15.0, fontFamily: 'Pacifico'),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 420,
              )
            ]),
          );
        }(),
        actions: kIsWeb
            ? Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: ToggleSwitch(
                  content: const Text('Dark Mode'),
                  checked: FluentTheme.of(context).brightness.isDark,
                  onChanged: (v) {
                    if (v) {
                      appTheme.mode = ThemeMode.dark;
                    } else {
                      appTheme.mode = ThemeMode.light;
                    }
                  },
                ),
              )
            : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: ToggleSwitch(
                    content: const Text('Dark Mode'),
                    checked: FluentTheme.of(context).brightness.isDark,
                    onChanged: (v) {
                      if (v) {
                        appTheme.mode = ThemeMode.dark;
                      } else {
                        appTheme.mode = ThemeMode.light;
                      }
                    },
                  ),
                ),
                const WindowButtons(),
              ]),
      ),
      paneBodyBuilder: (item, child) {
        final name =
            item?.key is ValueKey ? (item!.key as ValueKey).value : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        // 计算并设置当前选中的导航项
        selected: _calculateSelectedIndex(context),
        // 设置导航面板的头部，这里是一个带有渐变色的Flutter Logo
        header: SizedBox(
          height: kOneLineTileHeight,
          child: ShaderMask(
            shaderCallback: (rect) {
              final color = appTheme.color.defaultBrushFor(
                theme.brightness,
              );
              return LinearGradient(
                colors: [
                  color,
                  color,
                ],
              ).createShader(rect);
            },
            child: const FlutterLogo(
              style: FlutterLogoStyle.markOnly,
              size: 28.0,
              textColor: Colors.white,
              duration: Duration.zero,
            ),
          ),
        ),
        // 设置导航面板的显示模式
        displayMode: appTheme.displayMode,
        // 设置导航面板的指示器
        indicator: () {
          switch (appTheme.displayMode) {
            case PaneDisplayMode.top:
              return const StickyNavigationIndicator();
            default:
              return const EndNavigationIndicator();
          }
        }(),
        // 设置导航面板的导航项
        items: originnalItems,
        // 设置导航面板的自动建议框，用于搜索内容
        autoSuggestBox: Consumer(
          builder: (context, AppData value, child) {
            final v = value.getContentsWithTitle();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AutoSuggestBox<Content>(
                key: searchKey,
                focusNode: searchFocusNode,
                controller: searchController,
                unfocusedColor: Colors.transparent,
                items: v.map((item) {
                  return AutoSuggestBoxItem<Content>(
                    label: getValidText(item.title, 12),
                    value: item,
                    // 当用户选择一个建议的内容时，改变应用的状态，并导航到一个新的页面
                    onSelected: () {
                      appState.state = MyState.kOnContents;
                      context.goNamed("noteapp",
                          queryParams: {"dest": "card", "filter": "title"});
                    },
                  );
                }).toList(),
                trailingIcon: IgnorePointer(
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(FluentIcons.search),
                  ),
                ),
                placeholder: 'Search',
              ),
            );
          },
        ),
        // 当自动建议框没有焦点时，显示一个搜索图标
        autoSuggestBoxReplacement: const Icon(FluentIcons.search),
        // 设置导航面板的页脚项
        footerItems: footerItems,
      ),
      onOpenSearch: () {
        searchFocusNode.requestFocus();
      },
    );
  }

  @override
  void onTrayIconMouseDown() {
    // 当用户点击系统托盘图标时，如果窗口未打开，则显示窗口，否则隐藏窗口
    if (!_trayOpen) {
      windowManager.show();
    } else {
      windowManager.hide();
    }
    // 切换_trayOpen的状态
    _trayOpen = !_trayOpen;
  }

  @override
  void onTrayIconRightMouseDown() {
    // 当用户右键点击系统托盘图标时，弹出上下文菜单
    stray.trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // 当用户右键点击并释放系统托盘图标时，可以在这里执行一些操作
  }

  @override
  void onTrayMenuItemClick(stray.MenuItem menuItem) {
    // 当用户点击系统托盘菜单项时，根据菜单项的key执行相应的操作
    if (menuItem.key == 'show_window') {
      // 如果用户点击的是'show_window'菜单项，那么显示窗口
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      // 如果用户点击的是'exit_app'菜单项，那么销毁窗口
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() async {
    // 当窗口关闭时，隐藏窗口
    windowManager.hide();
  }
}

// 定义一个无状态的窗口按钮组件
class WindowButtons extends StatelessWidget {
  // 构造函数，接受一个可选的key参数
  const WindowButtons({Key? key}) : super(key: key);

  // 重写build方法，返回一个组件
  @override
  Widget build(BuildContext context) {
    // 获取当前的主题数据
    final FluentThemeData theme = FluentTheme.of(context);

    // 返回一个SizedBox组件，设置其宽度为138，高度为50
    return SizedBox(
      width: 138,
      height: 50,
      // SizedBox的子组件是一个WindowCaption组件，设置其亮度和背景颜色
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

// 定义一个全局的导航器键，用于根导航器
final _rootNavigatorKey = GlobalKey<NavigatorState>();
// 定义一个全局的导航器键，用于shell导航器
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// 创建一个GoRouter对象，用于管理路由
final router = GoRouter(
  // 设置导航器的键为_rootNavigatorKey
  navigatorKey: _rootNavigatorKey,
  // 定义路由列表
  routes: [
    // 创建一个ShellRoute对象，它是一个包含子路由的路由
    ShellRoute(
        // 设置导航器的键为_shellNavigatorKey
        navigatorKey: _shellNavigatorKey,
        // 定义路由的构建器，它返回一个MyHomePage对象
        builder: (ctx, state, child) {
          return MyHomePage(
            shellContext: ctx,
            state: state,
            child: child,
          );
        },
        // 定义子路由列表
        routes: [
          /// Home
          // 创建一个GoRoute对象，它表示首页的路由
          GoRoute(
            // 设置路由的路径为'/'
            path: '/',
            // 设置路由的名称为'noteapp'
            name: 'noteapp',
            // 定义路由的构建器，它根据查询参数的"dest"值返回不同的页面
            builder: (context, state) {
              switch (state.queryParams["dest"]) {
                case "book":
                  return const BookPage();
                case "category":
                  return const CategoryPage();
                case "card":
                  return CardPage(
                    filter: state.queryParams['filter'],
                  );
                case "save":
                  return const SavePage();
                default:
                  return const BookPage();
              }
            },
          ),
        ]),
  ],
);
