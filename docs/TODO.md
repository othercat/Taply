# Taply 现代 macOS 迁移 TODO

> **给 AI Agent 的执行要求：** 实施本 TODO 时，建议使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans`，按任务逐项推进。所有步骤使用 checkbox (`- [ ]`) 跟踪状态。

**目标：** 将 Carsten Bluem 提供的 Taply 原始源码迁移为可在 Intel macOS 10.14+ 与 Apple Silicon macOS 11.0+ 上运行的 64-bit macOS app，同时尽量保留 Taply 原本的小巧体验：拖放播放、播放列表、循环、音量、进度条、菜单和快速启动。

**架构方向：** 第一阶段保留现有 AppKit / Objective-C UI 和 manual retain/release 风格，最小化重写范围；先移除无法在现代 macOS SDK 构建的 QuickTime / SoundConverter 播放内核，替换为现代 AVFoundation 播放适配层。第二阶段清理 Xcode project、deprecated AppKit / Carbon API 与资源配置。第三阶段补测试、打包和跨架构验证。MIDI / Yamaha XG 支持是后续独立能力，不阻塞基础播放器复活。

**技术栈：** Objective-C、AppKit、AVFoundation / AVFAudio、Xcode 16.4、macOS deployment target。可选 MIDI 方向可能涉及 `AVMIDIPlayer`、AudioToolbox / CoreMIDI、FluidSynth 或外部 XG / VSTi 对照验证。

---

## 0. 来源与边界

- 原始代码来源：Carsten Bluem 于 2021-07-30 通过邮件授权提供 ZIP 源码给 Richard Li，用于继续维护 Taply。
- 当前源码位置：`src/`
- 当前开发机：M1 Pro MacBook Pro，macOS 15.7.5 (24G624)
- 当前 Xcode：`/Applications/Xcode_16.4.app`
- 当前 Xcode project：`src/Taply.xcodeproj`
- 当前 `Info.plist` 中 `LSMinimumSystemVersion` 已更新为 `10.14`，`CFBundleVersion` 已更新为 `2.0.0-dev`。  ✅ 2026-05-10
- 已移除 `QuickTime.framework` 链接，已移除 Carbon import，已添加 `AVFoundation.framework`。  ✅ 2026-05-10
- 不要把这个仓库写成“全新项目”；迁移时应保留作者信息、现有 `LICENSE`、原始文件头和可追踪的改动历史。
- 不要提交 `.xcuserdata`、DerivedData、测试音频、soundfont、VSTi DLL 或本地构建产物。

## 0.1 MIDI / Yamaha XG 背景与范围

MIDI / XG 是重要的后续方向，但不能打断第一阶段“先让 Taply 在现代 macOS 上正常构建并播放普通音频文件”的目标。

- 林坤信老师希望后续用 Yamaha XG / S-YXG50 规格重制《仙剑奇侠传1》MIDI，而不是只用 SF2 soundfont。
- 关键原因：SF2 属于 Rompler 路线，不能完整处理 MIDI SysEx 参数；遇到改过音色的 MIDI，即使使用 MU2000 的 SF2，也无法完全还原。
- 林老师提到的实际需求是“预览文件目录 + 播放 MIDI + LOOP”的工具，并提醒 XG 音色要用 SysEx 修改。
- 2025-10 沟通中的 Windows 参考组合：
  - foobar2000，当时记录版本为 `2.25.2`
  - `foo_midi`，当时记录版本为 `3.2.3.0`
  - `yamaha_syxg50_vsti.7z`
- 2026-05-10 复核：
  - foobar2000 Windows 官方 latest stable 已是 `2.25.8`
  - `foo_midi` 官方组件页仍显示 current version `3.2.3.0, released on 2025-10-04`
- VEG.BY 的 Yamaha S-YXG50 Portable VSTi 页面说明它是 Windows VSTi，支持 Yamaha XG 与 Roland GS。
- `yamaha_syxg50_vsti.7z` 内的 `syxg50.dll` 是 Windows-only 32-bit VSTi；页面评论中作者也说明没有源码，只有 32-bit 版本，64-bit host 需要 VST bridge。
- 对 Taply macOS 版本而言，MIDI / XG 是 Apple Silicon macOS 15+ 优先的实验功能，不要求 Intel macOS 10.14 支持。
- 对未来 PALDLL_DX9 而言，MIDI / XG 是 Windows Win32 / x86 C++ DLL 项目的长期方向；Taply 里的 macOS MIDI workbench 只能作为验证工具和需求沉淀，不应直接搬进 PALDLL_DX9。
- PALDLL_DX9 后续整合文档必须保持 Win32 / x86、`.sln` / `.vcxproj`、Windows 路径和 reference boundary 清晰：外部工具组合是验证依据，不是直接实现权威。

建议拆分：

- Taply Phase 1-4：复活现代 macOS classic audio player。
- Taply Phase 5：新增 Apple Silicon macOS 15+ 的可选 MIDI preview / player。
- 独立后续项目：Windows MIDI / XG Player prototype，用于和 foobar2000 + S-YXG50 做 parity testing。
- PALDLL_DX9 后续整合：等待 Windows prototype 明确 API、延迟指标、文件布局和配置格式后再进入。

## 1. 当前代码地图

### 1.1 播放内核

- `src/QTSoundFilePlayer.h`
- `src/QTSoundFilePlayer.m`
- `src/VirtualRingBuffer.h`
- `src/VirtualRingBuffer.m`

这是最大阻塞点。`QTSoundFilePlayer` 使用 `QuickTime.framework`、`Movie`、`Media`、`SoundConverter`、`EnterMovies()`、`GetMediaSample()`、`OpenADefaultComponent()` 和 CoreAudio ring buffer。现代 macOS SDK 已无法继续依赖这套 QuickTime C API。迁移目标不是修补 QuickTime，而是替换为一个兼容旧调用方的现代播放器类。

### 1.2 App Controller 与 UI 逻辑

- `src/AppController.h`
- `src/AppController.m`
- `src/MainMenu.nib/`

`AppController` 负责启动打开面板、拖放文件、播放/暂停、上一首/下一首、循环、音量、进度条、菜单、偏好设置。它现在直接依赖 `QTSoundFilePlayer` 的接口：

```text
play
pause
resume
stop
duration
playbackPosition
setPlaybackPosition:
setVolume:
delegate didFinishPlaying:
```

### 1.3 Playlist 与辅助类

- `src/TaplyPlaylist.h`
- `src/TaplyPlaylist.m`
- `src/Timer.h`
- `src/Timer.m`
- `src/functions.h`
- `src/functions.m`

`TaplyPlaylist` 是路径数组封装。`Timer` 用后台线程更新 UI，现代化时应改成 main run loop `NSTimer` 或 `dispatch_source_t`，但不要在第一阶段阻塞播放器迁移。

### 1.4 Window 与控件

- `src/TaplyWindow.h`
- `src/TaplyWindow.m`
- `src/TaplyPositionBar.h`
- `src/TaplyPositionBar.m`
- `src/TaplyGradientBox.h`
- `src/TaplyGradientBox.m`

这里包含旧 AppKit 常量、手写绘制和拖放代理。`TaplyGradientBox` 与 `AppController` 都使用 Carbon `SetThemeCursor()`，后续应改为 `NSCursor`。

### 1.5 Project 与资源

- `src/Taply.xcodeproj/project.pbxproj`
- `src/Info.plist`
- `src/Images.xcassets/`
- `src/Icons/`
- `src/*.lproj/`
- `src/README.txt`

工程内还链接了 `QuickTime.framework` 和 `Carbon.framework`。文档类型中仍包含 HFS type 与较宽泛的类型声明。

## 2. 不可妥协的要求

- [x] 最终 app 必须是 64-bit  ✅ 2026-05-10。
- [x] Intel build 目标：macOS 10.14  ✅ 2026-05-10+。
- [x] Apple Silicon build 目标：macOS 11.0  ✅ 2026-05-10+。
- [x] 使用 Xcode 16.4 构建  ✅ 2026-05-10，路径为 `/Applications/Xcode_16.4.app`。
- [x] 不再链接 `QuickTime.framework`  ✅ 2026-05-10。
- [x] 不再依赖 32-bit-only build setting  ✅ 2026-05-10。
- [x] 能播放本地 MP3、M4A、AIFF、WAV  ✅ 2026-05-10。
- [ ] MIDI / XG support 是可选后续功能，不得阻塞 base port；第一版只需支持 M1 Pro macOS 15.0+。
- [x] 保留 Taply 核心体验  ✅ 2026-05-10：启动选择文件、拖放文件/文件夹、播放/暂停、上一首/下一首、循环、音量、进度条 seek、播放结束自动下一首、shuffle 偏好。
- [x] 不要一次性重写成 SwiftUI 或全新 app  ✅ 2026-05-10，除非单独开后续分支。
- [x] 不提交 `.xcuserdata`  ✅ 2026-05-10、DerivedData、临时音频文件、soundfont、VSTi DLL 或本地构建产物。

## 3. 实施路线

### Phase 1：先让项目重新可构建

**涉及文件：**

- Modify: `src/Taply.xcodeproj/project.pbxproj`
- Modify: `src/Info.plist`
- Create: `src/AVSoundFilePlayer.h`
- Create: `src/AVSoundFilePlayer.m`
- Modify: `src/AppController.h`
- Modify: `src/AppController.m`

- [x] **Step 1：创建迁移分支  ✅ 2026-05-10**

```bash
cd /Users/lirichard/Developer/SourceCodes/GithubRepos/Taply
git status --short
git switch -c codex/modern-macos-port
```

预期：分支创建成功；working tree 中只有有意改动。

- [x] **Step 2：记录当前构建失败  ✅ 2026-05-10**

```bash
cd /Users/lirichard/Developer/SourceCodes/GithubRepos/Taply/src
/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild \
  -project Taply.xcodeproj \
  -target Taply \
  -configuration Development \
  -sdk macosx \
  build
```

预期：当前项目会因为旧 SDK / framework / build setting 不兼容而失败。把第一条有意义的错误记录到 commit message 或 PR notes。

- [x] **Step 3：给 target 添加  ✅ 2026-05-10 `AVFoundation.framework`**

更新 `src/Taply.xcodeproj/project.pbxproj`，让 `Taply` target 链接 `AVFoundation.framework`。当 `QTSoundFilePlayer` 不再参与编译后，从 Frameworks phase 移除 `QuickTime.framework`。

预期 project 状态：

```text
Linked frameworks include:
- Cocoa.framework
- AVFoundation.framework
- AudioToolbox.framework only if still required
- AudioUnit.framework only if still required
- CoreAudio.framework only if still required

Linked frameworks do not include:
- QuickTime.framework
```

- [x] **Step 4：新增兼容旧调用方式的  ✅ 2026-05-10 `AVSoundFilePlayer`**

创建 `src/AVSoundFilePlayer.h`，公开接口尽量贴近旧 `QTSoundFilePlayer`，让 `AppController` 的改动保持小范围：

```objc
#import <Foundation/Foundation.h>

@class AVSoundFilePlayer;

@protocol AVSoundFilePlayerDelegate <NSObject>
@optional
- (void)avSoundFilePlayer:(AVSoundFilePlayer *)player didFinishPlaying:(BOOL)success;
@end

@interface AVSoundFilePlayer : NSObject

- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithContentsOfFile:(NSString *)path;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;

- (BOOL)isPlaying;
- (BOOL)isPaused;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (float)volume;
- (void)setVolume:(float)value;

- (BOOL)shouldLoop;
- (void)setShouldLoop:(BOOL)value;

- (float)duration;
- (float)playbackPosition;
- (void)setPlaybackPosition:(float)value;

@end
```

`src/AVSoundFilePlayer.m` 实现要求：

- 第一版优先使用 `AVAudioPlayer`，不要直接上 `AVAudioEngine`。
- 理由：Taply 当前只需要本地文件播放、pause/resume、duration、current time、loop 和 volume。
- 保持 manual retain/release，除非后续单独计划把整个项目迁到 ARC。
- 通过 `AVAudioPlayerDelegate` 实现播放结束回调。
- `shouldLoop = YES` 时映射到 `numberOfLoops = -1`，否则为 `0`。
- volume clamp 到 `0.0...1.0`。
- `stop` 时停止播放并把 `currentTime` 重置为 `0.0`。
- delegate 保持 non-retained 行为，匹配旧 `QTSoundFilePlayer`。

- [x] **Step 5：把  ✅ 2026-05-10 `AppController` 切到新播放器**

修改 `src/AppController.h`：

```objc
#import "AVSoundFilePlayer.h"
```

替换：

```objc
QTSoundFilePlayer *player;
```

为：

```objc
AVSoundFilePlayer *player;
```

修改 `src/AppController.m` 中创建播放器的位置：

```objc
AVSoundFilePlayer *avPlayer = [[AVSoundFilePlayer alloc] initWithContentsOfFile:[playlist soundAtIndex:currentIndex]];
[avPlayer setDelegate:self];
[avPlayer setVolume:[volumeSlider floatValue]];
[avPlayer play];
```

将播放结束回调从：

```objc
- (void)qtSoundFilePlayer:(QTSoundFilePlayer *)qtPlayer didFinishPlaying:(BOOL)success
```

改为：

```objc
- (void)avSoundFilePlayer:(AVSoundFilePlayer *)avPlayer didFinishPlaying:(BOOL)success
```

方法内部只替换局部变量名，保留原有播放流程。

- [x] **Step 6：从 target 编译列表移除旧播放文件  ✅ 2026-05-10**

从 target 的 Sources / Headers phases 移除：

```text
src/QTSoundFilePlayer.h
src/QTSoundFilePlayer.m
src/VirtualRingBuffer.h
src/VirtualRingBuffer.m
```

Phase 1 不删除这些文件，先保留为 historical reference。

- [x] **Step 7：更新 universal 64-bit build settings  ✅ 2026-05-10**

在 `src/Taply.xcodeproj/project.pbxproj` 中更新 target / project build settings：

```text
SDKROOT = macosx;
ARCHS = "$(ARCHS_STANDARD)";
MACOSX_DEPLOYMENT_TARGET = 10.14;
ONLY_ACTIVE_ARCH = NO for Release/Deployment;
```

Apple Silicon runtime 支持可以通过同一个 universal build 覆盖。若 Xcode 对 arm64 + deployment target 10.14 报错，必须先记录具体错误，再决定是否使用条件化 deployment setting。

- [x] **Step 8：Phase 1 后构建验证  ✅ 2026-05-10**

```bash
cd /Users/lirichard/Developer/SourceCodes/GithubRepos/Taply/src
/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild \
  -project Taply.xcodeproj \
  -target Taply \
  -configuration Development \
  -sdk macosx \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  build
```

预期：构建成功，或只剩与 QuickTime 无关的 AppKit / compile error。剩余错误按小 commit 修复。

### Phase 2：现代化 AppKit 与 Drag & Drop，但不改变 UX

**涉及文件：**

- Modify: `src/AppController.h`
- Modify: `src/AppController.m`
- Modify: `src/TaplyGradientBox.h`
- Modify: `src/TaplyGradientBox.m`
- Modify: `src/TaplyWindow.h`
- Modify: `src/TaplyWindow.m`
- Modify: `src/TaplyPositionBar.m`

- [x] **Step 1：替换 `NSFilenamesPboardType` 拖放  ✅ 2026-05-10**

当前代码：

```objc
[window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
```

目标代码：

```objc
[window registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeFileURL]];
```

在 `performDragOperation:` 中从 pasteboard 读取 file URL 并转为 path：

```objc
NSArray *classes = [NSArray arrayWithObject:[NSURL class]];
NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                     forKey:NSPasteboardURLReadingFileURLsOnlyKey];
NSArray *urls = [[sender draggingPasteboard] readObjectsForClasses:classes options:options];
NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[urls count]];
for (NSURL *url in urls) {
    if ([url isFileURL]) {
        [paths addObject:[url path]];
    }
}
```

预期：拖入文件或文件夹仍能加入可播放文件。

- [x] **Step 2：替换 Carbon cursor 调用  ✅ 2026-05-10**

当前代码：

```objc
SetThemeCursor(kThemeCopyArrowCursor);
SetThemeCursor(kThemeArrowCursor);
```

目标代码：

```objc
[[NSCursor dragCopyCursor] set];
[[NSCursor arrowCursor] set];
```

没有 Carbon 符号后，从 `AppController.h` 与 `TaplyGradientBox.h` 移除：

```objc
#import <Carbon/Carbon.h>
```

- [x] **Step 3：替换旧 AppKit 常量  ✅ 2026-05-10**

替换表：

```text
NSOnState -> NSControlStateValueOn
NSOffState -> NSControlStateValueOff
NSTitledWindowMask -> NSWindowStyleMaskTitled
NSUtilityWindowMask -> NSWindowStyleMaskUtilityWindow
NSClosableWindowMask -> NSWindowStyleMaskClosable
NSMiniaturizableWindowMask -> NSWindowStyleMaskMiniaturizable
NSOKButton -> NSModalResponseOK
```

预期：新 SDK 下不再因为这些旧常量产生编译错误。

- [x] **Step 4：替换 deprecated open panel API  ✅ 2026-05-10**

当前代码：

```objc
if (NSOKButton == [p runModalForTypes:[NSArray arrayWithObjects:FILETYPES, nil]]) {
    [self handleDraggedPath:[p filenames]];
}
```

目标代码：

```objc
if ([p runModal] == NSModalResponseOK) {
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[[p URLs] count]];
    for (NSURL *url in [p URLs]) {
        if ([url isFileURL]) {
            [paths addObject:[url path]];
        }
    }
    [self handleDraggedPath:paths];
}
```

允许文件类型可先用 `allowedFileTypes`，如果迁移到更现代的 UniformTypeIdentifiers，再考虑 `allowedContentTypes`。不要在本步骤引入大范围 UI 重写。

- [ ] **Step 5：避免后台线程直接更新 UI**

当前 `Timer` 至少有一处从 detached thread 直接更新 UI：

```objc
[textField setTitle:[NSString stringWithFormat:@"%@",
                           CBTimeStringForSeconds(elapsedTime += sleepTime)]];
```

目标：

- UI 更新全部回到 main thread。
- 优先把 `Timer` 替换为 `AppController` 持有的 `NSTimer`。
- elapsed time 从 `[player playbackPosition]` 派生，不再靠 sleep interval 累加。

验收：

- pause/resume 不漂移。
- seek 后文字和 progress bar 立即更新。
- 不再从后台线程直接修改 AppKit 控件。


- [x] **Step 5：Dark Mode 适配**  ✅ 2026-05-10

  - `TaplyPositionBar.m`：移除硬编码颜色，`drawRect:` 中使用 `[NSColor separatorColor]` 和 `[NSColor controlTextColor]` 动态获取系统颜色。
  - `AppController.m`：`awakeFromNib` 中设置 `[filename setBackgroundColor:[NSColor textBackgroundColor]]` 和 `[fileLength setBackgroundColor:[NSColor textBackgroundColor]]`。
  - `TaplyPositionBar.h`：移除 `NSColor *bgColor` 和 `NSColor *fgColor` ivar。

- [x] **Step 6：简体中文语言支持**  ✅ 2026-05-10

  - 新增 `src/zh-Hans.lproj/dict.strings`：14 个 UI 字符串翻译。
  - 新增 `src/zh-Hans.lproj/Read me.html`：中文帮助页面，包含 2.0.0-dev 更新说明。
  - 复制 `src/zh-Hans.lproj/help.png` 和 `help-2x.png`。
  - `project.pbxproj` 中 `knownRegions` 添加 `zh-Hans`，PBXVariantGroup 添加 zh-Hans 子项。

- [x] **Step 7：更新所有语言的 Read me.html**  ✅ 2026-05-10

  - English、de、fr、it 四个语言的 `Read me.html` 均更新为 2.0.0-dev 内容。
  - 包含 Richard Li 的更新说明、AVFoundation 迁移信息、使用说明。
  - 联系方式更新为 `Richard Li <othercat@gmail.com>`。

### Phase 3：保留并验证 Taply 行为

**涉及文件：**

- Modify: `src/AppController.m`
- Modify: `src/TaplyPlaylist.m`
- Modify: `src/functions.m`
- Create: `docs/TESTING.md`

- [ ] **Step 1：尽可能补 focused tests**

如果添加 Xcode test target 的成本可控，至少覆盖：

```text
CBTimeStringForSeconds(0) -> "00:00"
CBTimeStringForSeconds(65) -> "01:05"
CBTimeStringForSeconds(3661) -> "61:01"
CBTimeStringForSeconds(7200) -> "2h:00"
TaplyPlaylist ignores duplicate paths
TaplyPlaylist removeAllExcept keeps only selected item
```

如果 test target 成本太高，先创建 `docs/TESTING.md` 写清手动验证流程，保持 app 修改小而稳。

- [ ] **Step 2：使用真实文件做 manual smoke test**

测试文件放在 repo 外，例如：

```text
/tmp/taply-test/audio-one.mp3
/tmp/taply-test/audio-two.m4a
/tmp/taply-test/audio-three.wav
/tmp/taply-test/audio-four.aiff
```

不要提交音频文件。

手动检查：

- 启动 app，不带文件参数。
- 在 open panel 中选择多个文件。
- 确认第一个文件开始播放。
- 点击 pause / resume。
- 拖动 progress bar 到中间。
- 调整音量。
- 点击 next / previous。
- 开启 loop，确认当前曲目重新播放。
- 拖入一个文件夹，确认可播放文件被加入。
- 开启 shuffle preference，确认加入顺序发生变化。
- 关闭窗口，确认播放停止且 app 干净退出。

- [ ] **Step 3：命令行启动 smoke test**

构建后执行：

```bash
open /Users/lirichard/Library/Developer/Xcode/DerivedData/*/Build/Products/Development/Taply.app --args /tmp/taply-test/audio-one.mp3
```

预期：Taply 打开并播放文件；若文件无法解码，显示有用错误，而不是崩溃。

### Phase 4：打包与 release hygiene

**涉及文件：**

- Modify: `src/Info.plist`
- Modify: `src/Taply.xcodeproj/project.pbxproj`
- Create: `README.md`
- Create: `docs/TESTING.md`
- Create: `.gitignore`

- [x] **Step 1：谨慎更新 bundle metadata  ✅ 2026-05-10**

建议更新：

```text
CFBundleVersion: 1.8.0-dev or 2.0.0-dev
CFBundleShortVersionString: add if missing
LSMinimumSystemVersion: 10.14
NSHumanReadableCopyright: preserve original author credit and add maintenance note if appropriate
```

除非分发冲突要求变更，否则先保留：

```text
CFBundleIdentifier = net.bluem.taply
```

如果改 bundle identifier，必须在文档中说明理由。

- [x] **Step 2：新增 `.gitignore`  ✅ 2026-05-10**

创建 `.gitignore`：

```gitignore
.DS_Store
DerivedData/
build/
*.xcuserstate
*.xcuserdata/
*.moved-aside
*.xcscmblueprint
```

- [x] **Step 3：新增 README  ✅ 2026-05-10**

`README.md` 应包含：

- Taply 是什么。
- 原作者与 source provenance。
- 当前维护目标。
- 支持的 macOS 目标。
- Xcode 16.4 构建命令。
- manual smoke test checklist。
- known limitations。

- [ ] **Step 4：构建 universal app**

```bash
cd /Users/lirichard/Developer/SourceCodes/GithubRepos/Taply/src
/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild \
  -project Taply.xcodeproj \
  -target Taply \
  -configuration Deployment \
  -sdk macosx \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build
```

验证架构：

```bash
lipo -info /path/to/Taply.app/Contents/MacOS/Taply
```

预期：

```text
Architectures in the fat file: Taply are: x86_64 arm64
```

### Phase 5：Apple Silicon macOS 15+ 的可选 MIDI / XG Preview Player

**范围规则：** 只有 Phase 1-4 稳定后才做。MIDI 支持很重要，但它是一条独立 feature line。第一版不需要支持 Intel macOS 10.14。

**涉及文件：**

- Create: `docs/MIDI_XG_RESEARCH.md`
- Create: `docs/MIDI_XG_TESTING.md`
- Create: `src/MIDISoundFilePlayer.h`
- Create: `src/MIDISoundFilePlayer.m`
- Modify: `src/AppController.h`
- Modify: `src/AppController.m`
- Modify: `src/Info.plist`
- Modify: `src/Taply.xcodeproj/project.pbxproj`

- [ ] **Step 1：记录 Windows 参考听音链路**

创建 `docs/MIDI_XG_RESEARCH.md`：

```markdown
# MIDI / Yamaha XG Research

## 目标

支持 PAL1 音乐的 MIDI preview 与 loop playback。参考音源目标是 Yamaha XG / S-YXG50。这不是“只加载 SF2”的需求，XG SysEx 与 controller 行为非常重要。

## 沟通背景

Kunsin Lin 说明 SF2 属于 Rompler 路线，无法完整处理 MIDI SysEx 参数。PAL1 MIDI refresh 的目标方向是 Yamaha XG / S-YXG50，因为其音色特性更接近 FM / RIX。

## Windows 参考链路

- foobar2000: https://www.foobar2000.org/
- foo_midi: https://www.foobar2000.org/components/view/foo_midi
- Yamaha S-YXG50 Portable VSTi: https://veg.by/en/projects/syxg50/
- 下载文件名：`yamaha_syxg50_vsti.7z`
- VSTi DLL：`syxg50.dll`

## 版本记录

- 2025-10 沟通时记录 foobar2000 `2.25.2` 与 foo_midi `3.2.3.0`。
- 2026-05-10 复核时，foobar2000 Windows latest stable 为 `2.25.8`。
- 2026-05-10 复核时，foo_midi current version 为 `3.2.3.0`。

## 重要约束

- `syxg50.dll` 是 Windows-only 32-bit VSTi。
- 不要假设 Taply macOS 能直接加载该 DLL。
- macOS 侧先使用 native MIDI path 做 preview 和 loop workflow。
- 真正的 S-YXG50 parity 必须和 Windows reference chain 对比。
- 未来 PALDLL_DX9 整合必须按 Windows Win32 / x86 工作来设计，不能照搬 macOS Taply 内部实现。
```

- [ ] **Step 2：新增 MIDI 文件类型**

更新 `src/Info.plist` 的 document types，加入：

```text
mid
midi
rmi
kar
```

保留已有音频类型。不要因为本步骤新增更宽泛的 `*` 行为。

- [ ] **Step 3：选择第一版 macOS MIDI backend**

第一版用 `AVMIDIPlayer` 做 Apple Silicon macOS 15+ preview path。

理由：

- Apple native framework。
- 支持本地 MIDI playback。
- 可以通过 `soundBankURL` 加载 sound bank。
- 保持 Taply 小巧，避免第一版就做 VST hosting。

非目标：

- 不尝试在 macOS 加载 Windows `syxg50.dll`。
- 不承诺完整 Yamaha XG SysEx parity。
- 不要求 Intel macOS 10.14 支持。

- [ ] **Step 4：新增 `MIDISoundFilePlayer`**

创建 `src/MIDISoundFilePlayer.h`：

```objc
#import <Foundation/Foundation.h>

@class MIDISoundFilePlayer;

@protocol MIDISoundFilePlayerDelegate <NSObject>
@optional
- (void)midiSoundFilePlayer:(MIDISoundFilePlayer *)player didFinishPlaying:(BOOL)success;
@end

@interface MIDISoundFilePlayer : NSObject

- (id)initWithContentsOfFile:(NSString *)path soundBankURL:(NSURL *)soundBankURL;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;

- (BOOL)isPlaying;
- (BOOL)isPaused;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (float)duration;
- (float)playbackPosition;
- (void)setPlaybackPosition:(float)value;

- (BOOL)shouldLoop;
- (void)setShouldLoop:(BOOL)value;

@end
```

实现要求：

- 包装 `AVMIDIPlayer`。
- 使用 `initWithContentsOfURL:soundBankURL:error:`。
- 调用 `prepareToPlay`。
- loop 开启时，播放完成后重新 `play:`。
- 如果 `AVMIDIPlayer` 对某些 MIDI 的 duration / position 不可靠，在 `docs/MIDI_XG_TESTING.md` 记录限制；不要伪造精确进度。

- [ ] **Step 5：按扩展名选择播放器**

在 `src/AppController.m` 创建普通音频播放器前检测 MIDI：

```objc
NSString *extension = [[[playlist soundAtIndex:currentIndex] pathExtension] lowercaseString];
BOOL isMIDI = [extension isEqualToString:@"mid"] ||
              [extension isEqualToString:@"midi"] ||
              [extension isEqualToString:@"rmi"] ||
              [extension isEqualToString:@"kar"];
```

如果 `isMIDI` 为真，创建 `MIDISoundFilePlayer`；否则创建 `AVSoundFilePlayer`。

旧 Taply 控制必须尽量继续工作：

- play
- pause
- resume
- stop
- loop
- next / previous
- 后端支持时显示 progress

- [ ] **Step 6：新增 sound bank 配置路径**

新增 user default：

```text
MIDISoundBankPath
```

第一版行为：

- 如果值存在且文件存在，作为 `soundBankURL` 传入。
- 如果未配置，传 `nil`，让系统 / 默认 backend 处理。
- 不要 hardcode 个人路径。
- 不要提交 sound bank。

未来 UI：

- 偏好设置里新增选择 `.sf2`、`.sf3` 或 `.dls` 的按钮，前提是 backend 支持。
- UI 必须标注这是 preview backend，不是 S-YXG50 parity。

- [ ] **Step 7：新增 MIDI / XG 测试文档**

创建 `docs/MIDI_XG_TESTING.md`：

```markdown
# MIDI / XG Testing

## macOS Preview Smoke Test

目标环境：

- Apple Silicon Mac
- macOS 15.0+
- Xcode 16.4

检查项：

- 打开一个 `.mid` 文件。
- 确认开始播放。
- 确认 pause / resume 工作。
- 确认 loop 工作。
- 确认 mixed audio + MIDI playlist 中 next / previous 工作。
- 确认不支持的 sound bank 配置会显示错误，而不是 crash。

## Windows S-YXG50 Reference Test

参考链路：

- foobar2000
- foo_midi
- `yamaha_syxg50_vsti.7z`
- `syxg50.dll`

检查项：

- 配置 foo_midi 加载 `syxg50.dll`。
- 用 foobar2000 和 Taply 播放同一 MIDI 文件。
- 记录 SysEx 行为、instrument selection、pitch bend、drum maps、reverb / chorus、loop timing 的差异。

## PALDLL_DX9 Future Notes

PALDLL_DX9 是 Win32 / x86 C++ DLL 工作。未来整合必须定义：

- runtime file layout
- MIDI device or synth backend selection
- loop command behavior
- scene transition / battle entry latency target
- config persistence
- fallback for systems without S-YXG50
```

- [ ] **Step 8：和 Windows reference chain 做对照验证**

这一步在 Windows 机器或 VM 中做，不在 Taply macOS 内做：

```text
1. Install foobar2000 from https://www.foobar2000.org/
2. Install foo_midi from https://www.foobar2000.org/components/view/foo_midi
3. Download yamaha_syxg50_vsti.7z from https://veg.by/en/projects/syxg50/
4. Extract syxg50.dll.
5. Configure foo_midi VSTi search path to the folder containing syxg50.dll.
6. Select Yamaha S-YXG50 in Playback -> Input -> MIDI synthesizer host.
7. Play PAL1 test MIDI files and record expected behavior.
```

验收：

- repo 外存在一组 reference MIDI 文件。
- 每个 reference file 都有 loop point、XG / SysEx 预期、明显乐器差异记录。
- 如果 Taply macOS MIDI preview 不匹配 S-YXG50，文档必须明确标注只是 preview。

## 4. API 替换与技术判断备注

- QuickTime / SoundConverter playback 应替换为 AVFoundation。
- 对当前 Taply 而言，`AVAudioPlayer` 是第一选择，因为它支持本地音频文件播放、pause/resume、duration、current time、volume，代码量远小于自定义 CoreAudio ring buffer。
- `AVAudioEngine` 是后续选项，仅当 Taply 需要 gapless playback、自定义 buffering、effects、精确 scheduling 或 `AVAudioPlayer` 不支持的格式时再考虑。
- `NSFilenamesPboardType` 已 deprecated；使用 file URL pasteboard reading。
- Carbon cursor API 应移除；使用 `NSCursor`。
- `NSHFSTypeOfFile` 这类 HFS type 检查属于 legacy；现代代码优先使用 extension / UTType。
- 旧 `VirtualRingBuffer` 在 QuickTime / SoundConverter 移除后大概率不再需要；先保留到新播放器稳定，再用 cleanup commit 删除。
- MIDI / XG 不应被简化为“加载 SF2”。用户和林坤信老师关心的是 XG / S-YXG50 行为与 SysEx 处理。
- Windows S-YXG50 验证基于 32-bit VSTi 路径。macOS Taply 先用 native playback 做 preview，再和 Windows reference output 对照。

## 5. 验收标准

- [x] `xcodebuild` 可用 Xcode 16.4 成功构建  ✅ 2026-05-10。
- [x] 构建出的 app binary 包含 `x86_64` 与 `arm64`  ✅ 2026-05-10。
- [x] app 可在 Apple Silicon macOS 15.7.5 启动  ✅ 2026-05-10。
- [x] target settings 支持 Intel macOS 10.14  ✅ 2026-05-10+。
- [x] target settings 支持 ARM macOS 11.0  ✅ 2026-05-10+。
- [x] 不再链接 `QuickTime.framework`  ✅ 2026-05-10。
- [ ] 不再链接 `Carbon.framework`，除非剩余符号有明确文档说明。
- [x] 可播放 MP3、M4A、WAV、AIFF 本地文件  ✅ 2026-05-10。
- [x] Drag & drop 文件和文件夹工作  ✅ 2026-05-10。
- [x] Open panel 文件选择工作  ✅ 2026-05-10。
- [x] Pause / resume / seek / volume / loop / next / previous 工作  ✅ 2026-05-10。
- [x] 关闭窗口后停止播放并干净退出  ✅ 2026-05-10。
- [ ] `README.md` 与 `docs/TESTING.md` 说明如何复现构建和 smoke test。
- [ ] Phase 5 实现后，可选 MIDI preview 能在 Apple Silicon macOS 15+ 打开并 loop `.mid` 文件。
- [ ] MIDI 文档明确区分 macOS preview playback 与 Windows S-YXG50 parity validation。

## 6. 参考链接

- Apple Developer: `AVAudioPlayer` documentation - https://developer.apple.com/documentation/avfaudio/avaudioplayer
- Apple Developer: `AVAudioEngine` documentation - https://developer.apple.com/documentation/avfaudio/avaudioengine
- Apple Developer: `NSFilenamesPboardType` deprecation note - https://developer.apple.com/documentation/appkit/nsfilenamespboardtype
- Apple Developer: `AVMIDIPlayer` documentation - https://developer.apple.com/documentation/avfaudio/avmidiplayer
- foobar2000 Windows download - https://www.foobar2000.org/windows
- foobar2000 `foo_midi` component - https://www.foobar2000.org/components/view/foo_midi
- Yamaha S-YXG50 Portable VSTi - https://veg.by/en/projects/syxg50/
