# MIDI / XG Testing

## macOS Preview Smoke Test

目标环境：

- Apple Silicon Mac
- macOS 15.0+
- Xcode 16.4

### 测试文件准备

准备 MIDI 测试文件（不提交到 repo）：

```bash
mkdir -p /tmp/taply-test
# 复制 .mid 文件到 /tmp/taply-test/
```

### 检查项

- [ ] 打开一个 `.mid` 文件，确认开始播放
- [ ] 确认 pause / resume 工作
- [ ] 确认 loop 工作（当前曲目重新播放）
- [ ] 确认 mixed audio + MIDI playlist 中 next / previous 工作
- [ ] 确认进度条显示当前位置
- [ ] 确认关闭窗口后播放停止
- [ ] 确认不支持的 sound bank 配置会显示错误，而不是 crash

### Sound Bank 配置测试

```bash
# 设置 sound bank 路径
defaults write net.bluem.taply MIDISoundBankPath /path/to/soundbank.sf2

# 清除 sound bank 路径（使用系统默认）
defaults delete net.bluem.taply MIDISoundBankPath
```

- [ ] 设置自定义 sound bank 路径后，MIDI 播放使用该 sound bank
- [ ] 未设置 sound bank 时，使用系统默认 DLS synth
- [ ] 设置不存在的路径时，使用系统默认 synth（不崩溃）

## Windows S-YXG50 Reference Test

参考链路：

- foobar2000
- foo_midi
- `yamaha_syxg50_vsti.7z`
- `syxg50.dll`

检查项：

- 配置 foo_midi 加载 `syxg50.dll`
- 用 foobar2000 和 Taply 播放同一 MIDI 文件
- 记录 SysEx 行为、instrument selection、pitch bend、drum maps、reverb / chorus、loop timing 的差异

## 重要说明

Taply macOS 的 MIDI 播放使用 Apple 原生 `AVMIDIPlayer`，这是一个 **preview backend**，不是 S-YXG50 parity。以下功能不支持：

- Yamaha XG SysEx 参数
- 自定义 VSTi / AU instrument
- 精确的 MIDI controller 映射（与 S-YXG50 不同）

如需完整 XG parity，必须使用 Windows reference chain（foobar2000 + foo_midi + S-YXG50 VSTi）。

## PALDLL_DX9 Future Notes

PALDLL_DX9 是 Win32 / x86 C++ DLL 工作。未来整合必须定义：

- runtime file layout
- MIDI device or synth backend selection
- loop command behavior
- scene transition / battle entry latency target
- config persistence
- fallback for systems without S-YXG50
