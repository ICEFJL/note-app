import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:note_app/models/dto.dart';

Future<void> showInfoBar(BuildContext context,
    {required Widget title,
    Widget? content,
    InfoBarSeverity severity = InfoBarSeverity.info}) async {
  return await displayInfoBar(context, builder: (context, close) {
    return InfoBar(
      title: title,
      content: content,
      action: IconButton(
        icon: const Icon(FluentIcons.clear),
        onPressed: close,
      ),
      severity: severity,
    );
  });
}

void contentBase64Encode(List<Content?> content) {
  for (final c in content) {
    if (c != null && c.detail != null) {
      c.detail = base64.encode(utf8.encode(c.detail!));
    }
  }
}

void contentBase64Decode(List<Content?> content) {
  for (final c in content) {
    if (c != null && c.detail != null) {
      c.detail = utf8.decode(base64.decode(c.detail!));
    }
  }
}

Future<String?> getDirctoryPath() async {
  return await FilePicker.platform
      .getDirectoryPath(dialogTitle: 'select working directory');
}

// 定义一个异步函数getFilePaths，用于获取用户选择的文件的路径
Future<List<String?>?> getFilePaths() async {
  // 使用FilePicker插件打开一个文件选择对话框
  // allowMultiple参数设置为true，表示允许用户选择多个文件
  // dialogTitle参数设置对话框的标题为'select file to executable'
  final ret = await FilePicker.platform
      .pickFiles(allowMultiple: true, dialogTitle: 'select file to executable');
  
  // 检查用户是否选择了文件
  if (ret == null) {
    // 如果用户没有选择文件，那么返回null
    return null;
  } else {
    // 如果用户选择了文件，那么使用map方法将每个文件的路径提取出来，然后转换为一个列表
    // 最后返回这个包含所有文件路径的列表
    return ret.files.map((e) => e.path).toList();
  }
}

showTextDialog(BuildContext context,
    {Text? title,
    Widget? content,
    required VoidCallback call,
    VoidCallback? noCall}) async {
  await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: title,
          content: content,
          actions: [
            FilledButton(
              child: const Text('Yes'),
              onPressed: () {
                call();
                Navigator.pop(context);
              },
            ),
            Button(
              child: const Text('No'),
              onPressed: () {
                if (noCall != null) noCall();
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}

Widget getHoverIcon<T>(T content, BuildContext context,
    {required VoidCallback call}) {
  return IconButton(
      icon: const Icon(FluentIcons.cancel),
      onPressed: () async {
        await showDialog(
            context: context,
            builder: (context) {
              return ContentDialog(
                title: const Text('Confirm remove'),
                content:
                    const Text('Are you sure you want to remove this card?'),
                actions: [
                  FilledButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      call();
                      Navigator.pop(context);
                    },
                  ),
                  Button(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            });
      });
}
