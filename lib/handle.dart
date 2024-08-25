import 'package:isar/isar.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
import 'package:note_app/main.dart';
import 'package:note_app/models/dto.dart';
import 'package:note_app/models/model.dart';

typedef GetPidFunc = int Function(); // 定义一个函数类型
typedef ExistPidFunc = bool Function(int);
typedef ExistPidWithTitleFunc = bool Function(int, ffi.Pointer<ffi.Int8>);
typedef ShowWindowFunc = int Function(int, ffi.Pointer<ffi.Int8>);
typedef exist_pid_func = ffi.Bool Function(ffi.Int);
typedef exist_pid_with_title_func = ffi.Bool Function(
    ffi.Int, ffi.Pointer<ffi.Int8>);
typedef getpid_func = ffi.Int Function();
typedef show_window_func = ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Int8>);

class MyLibrary {
  static final ffi.DynamicLibrary nativeLib =
  ffi.DynamicLibrary.open("windowsapp_singleton.dll"); // Windows 上的动态链接库文件名

  static final GetPidFunc getPid =
  nativeLib.lookup<ffi.NativeFunction<getpid_func>>('getpid').asFunction();
  static final ExistPidFunc existPid = nativeLib
      .lookup<ffi.NativeFunction<exist_pid_func>>('exist_pid')
      .asFunction();
  static final ShowWindowFunc showWindow = nativeLib
      .lookup<ffi.NativeFunction<show_window_func>>('show_window')
      .asFunction();
  static final ExistPidWithTitleFunc existPidWithTitle = nativeLib
      .lookup<ffi.NativeFunction<exist_pid_with_title_func>>(
      'exist_pid_with_title')
      .asFunction();
}

updateStatus(StatusModel statusModel) {
  isar.writeTxnSync(() {
    isar.statusModels.putSync(statusModel);
  });
}

finalHandle() {
  final v = isar.statusModels.where().findFirstSync();
  if (v == null) {
    updateStatus(StatusModel()
      ..status = currentPid
      ..lastTimestamp = DateTime.now().microsecondsSinceEpoch);
    return;
  }
  v.lastTimestamp = v.latestTimstamp;
  updateStatus(v);
}

Future<bool> preHandle() async {
  isar = await isarFuture;
  final v = isar.statusModels.where().findFirstSync();
  if (v == null) {
    currentPid = MyLibrary.getPid();
    updateStatus(StatusModel()
      ..status = currentPid
      ..latestTimstamp = DateTime.now().microsecondsSinceEpoch);
    return true;
  }
  final nativeUtf8 = title.toNativeUtf8().cast<ffi.Int8>();
  if (MyLibrary.existPidWithTitle(v.status, nativeUtf8)) {
    calloc.free(nativeUtf8);
    currentPid = v.status;
    return false;
  }

  currentPid = v.status = MyLibrary.getPid();
  v.latestTimstamp = DateTime.now().microsecondsSinceEpoch;
  updateStatus(v);
  calloc.free(nativeUtf8);
  return true;
}
