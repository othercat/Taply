# MIDI / Yamaha XG Research

## 目标

支持 PAL1 音乐的 MIDI preview 与 loop playback。参考音源目标是 Yamaha XG / S-YXG50。这不是"只加载 SF2"的需求，XG SysEx 与 controller 行为非常重要。

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

## macOS 实现方案

### 选择 AVMIDIPlayer

第一版使用 Apple 原生 `AVMIDIPlayer` 做 Apple Silicon macOS 15+ preview path。

理由：
- Apple native framework，无需额外依赖
- 支持本地 MIDI playback
- 可以通过 `soundBankURL` 加载 sound bank (.sf2, .dls)
- 保持 Taply 小巧，避免第一版就做 VST hosting

限制：
- 不支持 Yamaha XG SysEx 参数
- 不支持自定义 VSTi / AU instrument
- duration / position 对某些 MIDI 文件可能不精确
- 仅作为 preview backend，不是 S-YXG50 parity

### Sound Bank 配置

通过 user default `MIDISoundBankPath` 配置：
- 如果值存在且文件存在，作为 `soundBankURL` 传入 `AVMIDIPlayer`
- 如果未配置，传 `nil`，让系统使用默认 DLS synth
- 支持格式：`.sf2`、`.sf3`、`.dls`

## 重要约束

- `syxg50.dll` 是 Windows-only 32-bit VSTi。
- 不要假设 Taply macOS 能直接加载该 DLL。
- macOS 侧先使用 native MIDI path 做 preview 和 loop workflow。
- 真正的 S-YXG50 parity 必须和 Windows reference chain 对比。
- 未来 PALDLL_DX9 整合必须按 Windows Win32 / x86 工作来设计，不能照搬 macOS Taply 内部实现。
