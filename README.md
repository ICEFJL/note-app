项目源码在lib文件夹下。

参考来源：[acking-you/NoteWithCard: A cross-platform notes in the form of card record.](https://github.com/acking-you/NoteWithCard)

# ***\*直接运行\****

在Windows系统下，在build\windows\runner\Release文件夹下运行note_app.exe即可。笔记界面中的ICEFJL为本人标识，https://github.com/ICEFJL为本人GitHub地址。

# ***\*编译运行\****

在编译前请确保对应的环境已经准备好,关于flutter开发所需要的基本环境,本机使用的是IDEA，安装了flutter和dart插件，所用的flutter SDK版本为3.13.9，dart SDK版本为3.15

需运行flutter pub get来获取依赖，运行flutter build windows来编译生成。若编译不成功，可删除windows文件夹和build文件夹，运行flutter create --platforms=windows .来重新生成Windows文件夹，再运行flutter build windows来编译生成。

本项目选用了isar数据库，该数据库面向flutter框架，可提供提供高性能且高易用性的本地嵌入式 nosql 数据库。

