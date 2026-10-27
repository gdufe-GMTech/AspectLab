# AspectLab · 宽高比实验室

把「改分辨率换 4:3 拉伸」这件事**量化清楚**的 iOS 工具：给预设与自定义比例，算出游戏应当渲染多少像素、面板怎么铺、物体变宽多少、视野丢多少、头部在屏幕上多几个像素。

> **它不能改你的系统分辨率。** iOS 没有 Android `wm size` 的对等接口。
> 这个限制不是没做，是做不了——细节见下文「能力边界」。

---

## 一、这个 App 到底做什么

四个页签：

| 页签 | 内容 |
|---|---|
| **分辨率** | 预设（原生 / 16:9 / 16:10 / 3:2 / 4:3 / 21:9）+ 自定义宽高；渲染基准（高度 / 宽度 / 像素量）；垂直视野；实时换算。选完点「应用」。 |
| **预览** | 拉伸铺满 vs 保持比例的真实畸变示意；原生 vs 目标的取景对照；4:3 视野窗口在原生画面里的位置。 |
| **数据** | 全部读数、10/20/30/50 m 头部像素对照表、系统分辨率实情说明、复制完整读数。 |
| **取证** | 只读采样 `nativeBounds` / `bounds` / `nativeScale`，记录基线并与当前比对，判断「系统分辨率到底变没变」。用来验证别人卖的那个工具。 |

关键数字全部来自实测面板像素（`UIScreen.nativeBounds`），不是猜的型号表。

### 取证页怎么用（验证第三方「改分辨率」工具）

1. 记下「当前屏幕状态」，点 **记录基线**。
2. 切到那个工具，按它的流程「应用 / 连接」。
3. 切回来，点 **采样一次**。

判定只有三档：

| 现象 | 含义 |
|---|---|
| **面板像素**变了 | 系统分辨率确实被改了（这才能产生拉伸） |
| 只有**逻辑分辨率**变 | 属于显示缩放/兼容模式的画布变化，宽高比不变，拿不到拉伸 |
| 两个都没变 | 那个工具没触及系统层，无论它界面上写了什么 |

### 数学口径

- 一律按横屏算：长边 × 短边。
- 宽高比 → 渲染分辨率：4:3 铺 19.5:9 时按高度取 1206，宽度需 1608（小于面板 2622），于是横向拉伸系数 `2622/1608 = 1.63`。
- 视角用 Hor+ 模型：垂直视野固定，水平视野随比例变。`hFOV = 2·atan(tan(vFOV/2)·aspect)`。
- 头部像素用等距投影近似：`px = renderW · (r/d) / tan(hFOV/2) · 横向缩放`，头半径取 0.11 m。
- 结论之一：**头部像素放大倍数恒等于横向拉伸系数**，与距离无关。这是几何必然。

---

## 二、能力边界（重要）

「修改系统分辨率」在 iOS 上分四种情况，只有前两种存在：

| 做法 | 是否可行 | 说明 |
|---|---|---|
| 读面板信息 | ✅ | `nativeBounds` / `nativeScale` / `bounds`，本 App 用这个 |
| 官方「显示缩放」 | ✅ | 设置 › 显示与亮度 › 显示。换逻辑分辨率，**宽高比不变**，拿不到 4:3 |
| 第三方 App 改系统分辨率 | ❌ | `UIScreen` 只有 `availableModes` / `currentMode`，**没有 `setMode`**。写入需要私有 entitlement |
| 越狱 / TrollStore 工具（如 ResSet16） | ⚠️ | 靠 CoreTrust 绕过拿平台权限。iPhone19,2 / iOS 27 无公开链，本机未越狱 |

所以：

- 你在网上看到的「iOS 改分辨率」工具，要么是越狱态工具，要么是安慰剂 UI，要么是破解客户端。
- iPad 之所以「看起来本来就是 4:3」，是因为它的面板比例在 1.41–1.52 之间（靠近 4:3），游戏铺满时几乎不需要拉伸；这不是改出来的。
- 本 App 把「假如可达会是多少」算到小数点后三位，让你在动手之前就能判断值不值得。

### 关于「pairing file + LocalDevVPN + debugserver」这条管线

它和 StikDebug 用的是同一套底层：手机用 LocalDevVPN 起回环 → 自己连自己 `10.7.0.1` 的 `lockdown` → 拉起 DDI 里的 `debugserver`。但这条管线**只有一个权限档位**：

- StikDebug 官方描述的能力是「为带 `get-task-allow` 的自签 App 打开 JIT」，外加启动已装 App、看日志、杀进程、模拟定位。
- 它拿不到 `task_for_pid` 到 SpringBoard 或系统守护进程的权限；`debugserver` 会拒绝调试「不是我们自己签名」的进程。
- 改系统分辨率要的是另一档：`platform-application` + 能改写 SpringBoard 显示模式。历史上这一档由 TrollStore（CoreTrust 绕过）提供，ResSet16 的适用范围写得很直白：**iOS 15.0 – 16.1.2**。
- 所以「思路差不多」只说对了一半：管线一样，权限差两档。用 StikDebug 那一档去改分辨率，缺的不是代码，是权限。

### 实测换算（垂直视野 60°，以高度为基准）

面板 2622×1206（iPhone 16/17 Pro 一类）：

| 目标 | 渲染分辨率 | 拉伸 | 水平视野 | 保留 | 头部 20 m |
|---|---|---|---|---|---|
| 4:3 | 1608×1206 | ×1.631 | 102.9° → 75.2° | 61% | 11.5 → 18.7 px |
| 16:9 | 2144×1206 | ×1.223 | 102.9° → 91.5° | 82% | 11.5 → 14.1 px |
| 16:10 | 1930×1206 | ×1.359 | 102.9° → 85.5° | 74% | 11.5 → 15.6 px |
| 21:9 | 2622×1124 | ×0.932 | 102.9° → 106.8° | 100% | 11.5 → 10.7 px |

`tools/check_math.py` 会把上面这套数字复算一遍，并断言三条恒等式：拉伸系数 = 1/视野保留、像素负担 = 视野保留、头部放大倍数 = 拉伸系数。

---

## 三、怎么拿到 ipa

ipa 需要 macOS 上的 Xcode 工具链编译，Windows 上做不出来。两条路：

### 路线 A：GitHub Actions（Windows 可用，推荐）

1. 浏览器打开 GitHub，新建空仓库（Private 也行）。
2. 上传本目录全部内容（拖拽上传即可，不用 git）。
3. 进 **Actions** → 左侧 **Build IPA** → **Run workflow**。
4. 约 2 分钟后，该次运行页面底部 **Artifacts** 下载 `AspectLab-ipa`。
5. 解压得到 `AspectLab-unsigned.ipa`。

### 路线 B：本机 macOS

```bash
bash scripts/build-ipa.sh
# 产物：build/AspectLab-unsigned.ipa
```

想用 Xcode 调试（可选）：

```bash
brew install xcodegen
xcodegen generate
open AspectLab.xcodeproj   # 选自己的 Team，真机运行
```

### 装到手机

ipa 是**未签名**的，必须用自己的证书重签：

- **SideStore / AltStore**：导入 ipa → 重签 → 安装（需在同一 Wi-Fi 的 AltServer，或 SideStore 的配对文件）。
- **Sideloadly**：Windows 端直接拖入 ipa，用 Apple ID 重签安装。

限制：免费 Apple ID 签名 7 天有效、最多 3 个 App。系统设置里 **开发者模式**要开着（你这台已开）。

---

## 四、首次构建可能出的问题

这套代码在本机（Windows）**无法编译验证**，只做了括号配对与笔误静态检查。首次 CI 构建如果报错，把 Actions 日志里第一段 `error:` 贴给我，基本一轮能修完。

已知需要留意的点：

- `swiftc -framework SwiftUI` 需要 SDK 路径正确（脚本已用 `xcrun --sdk iphoneos --show-sdk-path`）。
- 若 `macos-15` runner 的 Xcode 版本偏新，`-swift-version 5` 仍可编译，个别 deprecation 只会告警。
- 部署目标 iOS 17.0，你的 iOS 27 直接可装。

---

## 五、反馈 bug 请带这些字段

1. 机型标识符（App 内「设备面板」页签第一条，形如 `iPhone19,2`）
2. 面板像素 + 逻辑分辨率（同页签）
3. 显示缩放状态（同页签）
4. 出问题的页签 + 截图
5. 期望值 vs 实际值（尤其是渲染分辨率、横向倍率、头部像素三个数）

如果怀疑是崩溃，从「设置 › 隐私与安全性 › 分析与改进 › 分析数据」里找 `AspectLab` 开头的 `.ips` 文件。

---

## 六、文件地图

| 路径 | 作用 |
|---|---|
| `Sources/Models.swift` | 比例、面板信息、换算（`LabMath`） |
| `Sources/LabModel.swift` | 状态、草稿/已应用、持久化、导出 |
| `Sources/DisplayProbe.swift` | 读 `UIScreen` 与机型标识符 |
| `Sources/SetupView.swift` | 预设 + 自定义 + 应用 |
| `Sources/PreviewView.swift` | 畸变示意与取景对照 |
| `Sources/MetricsView.swift` | 读数、头部像素表、系统分辨率实情 |
| `Sources/SceneView.swift` | 纯几何示意图（圆 → 椭圆） |
| `Sources/DisplayLogger.swift` | 只读屏幕采样器（取证页的数据源） |
| `Sources/ForensicsView.swift` | 取证页：基线、采样、判定 |
| `Sources/Theme.swift` | 配色与卡片组件 |
| `scripts/build-ipa.sh` | 直接调用 swiftc 出未签名 ipa |
| `.github/workflows/build-ipa.yml` | macOS runner 自动打包 |
| `project.yml` | XcodeGen 规格（可选） |
| `tools/make_icons.py` | 生成图标 |
| `tools/check_math.py` | 复算公式并断言三条恒等式 |
| `tools/swift_lint.py` | 括号配对与笔误自查 |

---

## 七、附：对「霖霖比例助手」截图的读法

那张界面上真正起作用的是这几行：

- **「未连接 / 未验证」** —— 工具自己说现在没有建立任何连接。
- **「本页不会自动扫描、配对、连接或操作游戏」** —— 它明确声明不碰游戏。
- **「不代表本 IPA 已应用」「不是真实渲染分辨率或全屏保证」** —— 它把「应用」这件事的保证排除掉了。

再看预设：`1600×1536`、`1920×1536`、`2048×1536`——高度全是 1536。这不是 iPhone 的比例族，而是 **iPad 的分辨率族**（`2048×1536` 正是 iPad 9.7/ mini 4/5 的原生分辨率）。所以更合理的解释是：它是个**按 iPad 目标值做换算的助手**，「已实测」指的是那个数字在 iPad 上测过，而不是「这个 IPA 在 iPhone 上改成功了」。

要证伪只需要上面的取证页：跑一次，看**面板像素**有没有变。

---

## 八、版本

`1.1.0` · 只读计算 + 只读取证 · 不写系统 · 不碰其它 App 容器
