# 云音乐 · MyApplication

基于 **HarmonyOS / OpenHarmony ArkTS + ArkUI** 开发的音乐播放器示例应用（课程实训项目）。
工程为单模块 `entry`，`bundleName` 为 `com.example.myapplication`，版本 `4.1.0`，支持 `default`（手机）与 `tablet` 两类设备。

## 功能一览

| 模块 | 页面 | 说明 |
| --- | --- | --- |
| 启动 | `Guide` | 首次启动引导页，用 Preferences 记录是否已展示 |
| 开屏 | `AdPage` | 广告 / 开屏页 |
| 账号 | `Login` | 手机号 + 密码 / 短信验证码登录、注册 |
| 首页 | `Index` | 搜索、SVIP/VIP 卡片、分类导航、雷达歌单、热门歌曲、猜你喜欢的歌手、迷你播放栏、个人中心侧边栏、夜间模式开关 |
| 个人 | `PersonalInfo` / `PersonalEdit` | 个人信息展示与资料编辑（昵称、头像） |
| 个人 | `AccountSettings` | 账号设置、修改密码、注销账号 |
| 播放 | `FullPlayer` | 全屏播放器：播放/暂停、上一首/下一首、进度拖动、播放模式、收藏 |
| 播放 | `PlaylistDetail` / `Favorites` | 歌单详情、我的收藏 |
| 播放 | `common/AudioPlayerUtil.ts` | 基于 `@ohos.multimedia.media` AVPlayer 的全局单例播放器 |
| 流转 | `DistributedNet` / `MusicFlow` / `VideoFlow` | 分布式组网、音乐流转、视频（MV）流转 |
| 主题 | `ThemeSettings` | 暗色模式 / 主题切换 |

## 技术栈

- **语言 / UI**：ArkTS、ArkUI 声明式开发范式，`Tabs` / `TabContent`、自定义组件（如 `PlaylistDrawer`）
- **路由**：`@ohos.router`
- **响应式适配**：`@ohos.mediaquery`、`@ohos.display`
- **音频播放**：`@ohos.multimedia.media` 的 `AVPlayer`，封装为全局单例 `AudioPlayerState`，支持列表循环 / 单曲循环 / 随机 / 顺序四种播放模式
- **关系型数据库**：`@ohos.data.relationalStore`（`common/DatabaseUtil.ts`，`users` 表，支持登录、短信登录、注册、改密、注销、更新资料）
- **键值存储**：`@ohos.data.preferences`（`common/PreferencesUtil.ts`，登录态、引导页标记、主题）
- **资源**：`resources/rawfile` 本地音频 / 视频 / 图片，`$media`、`$string`、`$color` 资源引用

## 目录结构

```
MyApplication/
├── AppScope/                       # 应用级配置（app.json5、应用图标）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── common/             # AudioPlayerUtil / DatabaseUtil / PreferencesUtil / AppContext / PlaylistDrawer
│       │   ├── entryability/       # EntryAbility 入口
│       │   ├── model/              # 数据模型
│       │   └── pages/              # 14 个页面（见 main_pages.json）
│       ├── resources/
│       │   ├── base/               # element / media / profile
│       │   └── rawfile/            # 音频、视频、封面图等原始资源
│       └── module.json5
├── build-profile.json5             # 编译产物配置（compileSdkVersion 11）
├── hvigorfile.ts / hvigorw         # 构建脚本
├── oh-package.json5
└── README.md
```

页面清单（`entry/src/main/resources/base/profile/main_pages.json`）：
`Guide`、`AdPage`、`Index`、`Login`、`PersonalInfo`、`PersonalEdit`、`FullPlayer`、`PlaylistDetail`、`Favorites`、`ThemeSettings`、`DistributedNet`、`MusicFlow`、`VideoFlow`、`AccountSettings`。

## 运行方式

1. 用 **DevEco Studio** 打开本工程根目录（`MyApplication`）。
2. 首次打开需等待 `oh_modules` 依赖同步完成（或执行 `hvigorw sync`）。
3. 在 `local.properties` 中确认 `sdk.dir` 指向本机 HarmonyOS SDK（该文件不纳入版本管理）。
4. 选择 `entry` 模块 → 启动模拟器或连接真机 → Run。

编译配置：`compileSdkVersion = 11`、`compatibleSdkVersion = 11`、`runtimeOS = OpenHarmony`；`build-profile.json5` 中的签名配置为调试用本机证书路径，在其他机器上需要重新配置签名。

## 说明

- 仓库**未包含** `entry/src/main/resources/rawfile` 下的 `.mp3` / `.mp4` 文件：单个视频达 147MB，超过 GitHub 单文件 100MB 限制，且涉及版权内容。本地运行播放功能时请自行放置同名音频文件，或修改歌单中的 `rawfile` 字段。
- 仓库同样未包含课程资料目录 `eg/`（含 150MB+ 实训报告）。
- 所有 `.ets` / `.ts` 源码均为 UTF-8 编码。
