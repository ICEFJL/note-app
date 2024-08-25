import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:note_app/models/dto.dart';
import 'package:note_app/util/log.dart';
import 'package:note_app/models/dto.dart' as dto;
import 'package:note_app/models/model.dart';
import 'package:system_theme/system_theme.dart';

// 定义一个类，用于管理应用的主题
class AppTheme extends ChangeNotifier {
  // 当前选中的项的索引
  int _selected = 0;
  int get selected => _selected;
  set selected(int x) {
    _selected = x;
    // 当选中的项发生变化时，通知所有监听器
    notifyListeners();
  }

  // 应用的主题色
  AccentColor _color = systemAccentColor;
  AccentColor get color => _color;
  set color(AccentColor color) {
    _color = color;
    // 当主题色发生变化时，通知所有监听器
    notifyListeners();
  }

  // 应用的主题模式，可以是亮色模式或暗色模式
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    // 当主题模式发生变化时，通知所有监听器
    notifyListeners();
  }

  // 导航面板的显示模式
  PaneDisplayMode _displayMode = PaneDisplayMode.top;
  PaneDisplayMode get displayMode => _displayMode;
  set displayMode(PaneDisplayMode displayMode) {
    _displayMode = displayMode;
    // 当显示模式发生变化时，通知所有监听器
    notifyListeners();
  }

  // 文本的方向
  TextDirection _textDirection = TextDirection.ltr;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection direction) {
    _textDirection = direction;
    // 当文本的方向发生变化时，通知所有监听器
    notifyListeners();
  }

  // 应用的语言环境
  Locale? _locale;
  Locale? get locale => _locale;
  set locale(Locale? locale) {
    _locale = locale;
    // 当语言环境发生变化时，通知所有监听器
    notifyListeners();
  }
}

// 获取系统的强调色
AccentColor get systemAccentColor {
  // 如果目标平台是Windows或Android，并且不是Web平台
  if ((defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.android) &&
      !kIsWeb) {
    // 返回系统的强调色
    return AccentColor.swatch({
      'darkest': SystemTheme.accentColor.darkest,
      'darker': SystemTheme.accentColor.darker,
      'dark': SystemTheme.accentColor.dark,
      'normal': SystemTheme.accentColor.accent,
      'light': SystemTheme.accentColor.light,
      'lighter': SystemTheme.accentColor.lighter,
      'lightest': SystemTheme.accentColor.lightest,
    });
  }
  // 如果不满足上述条件，返回蓝色
  return Colors.blue;
}

// 定义应用状态的枚举
enum MyState { kOnBookMarks, kOnCategories, kOnContents, kOnSave }

class AppState extends ChangeNotifier {
  MyState _state = MyState.kOnBookMarks;

  MyState get state => _state;
  set state(MyState state) {
    _state = state;
    notifyListeners();
  }
}

// 定义CallOnce类，用于只执行一次的操作
class CallOnce {
  // 定义私有变量_instance，用于存储CallOnce的单例
  static CallOnce? _instance;
  // 私有构造函数，接收一个回调函数，并执行它
  CallOnce._internal(VoidCallback callback) {
    callback();
  }
  // 工厂构造函数，如果_instance为null，创建一个新的CallOnce对象
  factory CallOnce(VoidCallback callback) {
    _instance ??= CallOnce._internal(callback);
    return _instance!;
  }
}

class CommonData extends ChangeNotifier {
  String _workPath = "";
  String get workPath => _workPath;
  setWorkPath(String markdownTxt) {
    _workPath = markdownTxt;
    notifyListeners();
  }

  String _editorPath = "";
  String get editorPath => _editorPath;
  setEditorPath(String markdownTxt) {
    _editorPath = markdownTxt;
    notifyListeners();
  }

  String _markdownTxt = "";
  String get markdownTxt => _markdownTxt;
  setMarkdownTxt(String markdownTxt) {
    _markdownTxt = markdownTxt;
    notifyListeners();
  }
}

class AppData extends ChangeNotifier {
  load() {
    CallOnce(() async {
      _books = await dto.Book.allBooks();
      _category = await dto.Category.allCategory();
      _allContents = await dto.Content.allContent();
    });
  }

  loadAsync() async {
    _books = await dto.Book.allBooks();
    _category = await dto.Category.allCategory();
    _allContents = await dto.Content.allContent();
    _values = await isar.kVModels.where().findAll();
    notifyListeners();
  }

  List<dto.Book> _books = [];
  List<dto.Book> get books {
    load();
    return _books;
  }

  set books(List<dto.Book> books) {
    _books = books;
    notifyListeners();
  }

  Future<int> addBook(dto.Book book) async {
    final id = await dto.Book.newBook(book);
    _books = await dto.Book.allBooks();
    notifyListeners();
    return id;
  }

  List<dto.Category> _category = [];
  List<dto.Category> get category {
    load();
    return _category;
  }

  set category(List<dto.Category> c) {
    _category = c;
    notifyListeners();
  }

  Future<int> addCategory(dto.Category category) async {
    final id = await dto.Category.newCategory(category);
    _category = await dto.Category.allCategory();
    notifyListeners();
    return id;
  }

  List<dto.Content> _allContents = [];
  List<dto.Content> get allContents {
    load();
    return _allContents;
  }

  set allContents(List<dto.Content> c) {
    _allContents = c;
    notifyListeners();
  }

  List<dto.Content> _contentsWithTitle = [];
  List<dto.Content> getContentsWithTitle() {
    return _contentsWithTitle;
  }

  setContentWithTitle(String title) async {
    _contentsWithTitle = await dto.Content.titleStartWith(title);
    logger.d('len:${_contentsWithTitle.length} $_contentsWithTitle');
    notifyListeners();
  }

  List<dto.Content> _contentsWithBook = [];
  List<dto.Content> getContentsWithBook() {
    return _contentsWithBook;
  }

  setContentWithBook(dto.Book book) async {
    _contentsWithBook = await dto.Book.allContents(book);
    logger.d('len:${_contentsWithBook.length} $_contentsWithBook');
    notifyListeners();
  }

  List<dto.Content> _contentsWithCate = [];
  List<dto.Content> getContentsWithCate() {
    return _contentsWithCate;
  }

  setContentWithCate(dto.Category cate) async {
    _contentsWithCate = await dto.Category.allContents(cate);
    logger.d('len:${_contentsWithCate.length} $_contentsWithCate');
    notifyListeners();
  }

  Future<int> addContent(dto.Content content, {needPlus = true}) async {
    final id = await dto.Content.newContent(content, needPlus: needPlus);
    _allContents = await dto.Content.allContent();
    _books = await dto.Book.allBooks();
    _category = await dto.Category.allCategory();
    notifyListeners();
    return id;
  }

  List<KVModel> _values = [];
  List<String>? getValuesByKey(String key) {
    if (_values.isEmpty) return null;
    final ret = <String>[];
    for (final v in _values) {
      if (key == v.key) ret.add(v.value);
    }
    return ret.isEmpty ? null : ret;
  }

  Future<int> addKeyValue(String key, String value) async {
    final id = await isar.writeTxn(() async {
      return await isar.kVModels.put(KVModel()
        ..key = key
        ..value = value);
    });
    return id;
  }

  void loadValues() {
    _values = isar.kVModels.where().findAllSync();
    notifyListeners();
  }

  Future<bool> deleteContent(dto.Content content) async {
    assert(content.category.id != Isar.autoIncrement);
    final a = await dto.Content.delete(content.id);
    if (content.category.count > 0) {
      content.category.count--;
    }
    await dto.Category.newCategory(content.category);
    _allContents = await dto.Content.allContent();
    _books = await dto.Book.allBooks();
    _category = await dto.Category.allCategory();
    notifyListeners();
    return a;
  }

  _updateData() async {
    _allContents = await dto.Content.allContent();
    _books = await dto.Book.allBooks();
    _category = await dto.Category.allCategory();
    notifyListeners();
  }

  Future<bool> deleteBook(dto.Book book) async {
    assert(book.id != Isar.autoIncrement);
    final a = await dto.Book.delete(book.id);
    await dto.Content.deleteByBookId(book.id);
    await _updateData();
    return a;
  }

  Future<bool> deleteCategory(dto.Category category) async {
    assert(category.id != Isar.autoIncrement);
    final a = await dto.Category.delete(category.id);
    await dto.Content.deleteByCategoryId(category.id);
    await _updateData();
    return a;
  }
}
