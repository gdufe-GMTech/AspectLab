# 上传到 GitHub 出 ipa（Windows 版，全程网页操作）

不需要装 git，不需要命令行。整个流程大约 5 分钟。

---

## 0. 先做一件事：解压

把 `aspectlab-1.1.0.zip` 解压到桌面，得到 `aspectlab` 文件夹。

**不要直接把 zip 上传**——GitHub 只会把它当二进制文件存着，Actions 找不到里面的工作流。

---

## 1. 建仓库

1. 打开 https://github.com ，登录（没有就注册）。
2. 右上角 **+** → **New repository**。
3. 填：
   - **Repository name**：`aspectlab`
   - 可见性：**Public**（Actions 免费不限量；选 Private 也能跑，但 macOS 机器按 10 倍计分钟）
   - 下面三个勾（README / .gitignore / license）**全部不勾**
4. 点 **Create repository**。

---

## 2. 上传源码

新仓库页面会有一个链接 **uploading an existing file**，点它（或 **Add file** → **Upload files**）。

在资源管理器里打开解压后的 `aspectlab` 文件夹，把这些拖进网页的方框：

```
Sources/        ← 整个文件夹
Resources/      ← 整个文件夹
scripts/        ← 整个文件夹
tools/          ← 整个文件夹
project.yml
README.md
.gitignore
```

要点：

- **文件夹要整个拖**，浏览器会自动展开成层级（Chrome / Edge 都支持拖文件夹）。
- 拖完页面下方点 **Commit changes**。
- 如果 `.gitignore` 没上传成功，不影响编译，忽略即可。

---

## 3. 单独建工作流文件（关键一步）

`.github` 这个目录名以点开头，Windows 资源管理器可能不显示它，网页拖拽也常常漏掉。所以手动建：

1. 回到仓库首页，点 **Add file** → **Create new file**。
2. 文件名输入框里输入：

   ```
   .github/workflows/build-ipa.yml
   ```

   输入 `/` 时 GitHub 会自动把前面变成文件夹，这是正常的。

3. 打开解压目录里的 `aspectlab/.github/workflows/build-ipa.yml`，用记事本全选复制，粘贴到网页编辑框。
4. 点 **Commit changes**。

---

## 4. 跑构建

1. 点仓库顶部 **Actions** 标签。
2. 第一次进会看到一个提示，点 **I understand my workflows, go ahead and enable them**。
3. 左侧列表点 **Build IPA**。
4. 右侧 **Run workflow** → 分支保持 `main` → 点绿色 **Run workflow**。
5. 刷新页面，会出现一条运行记录，黄点是跑、绿勾是成功。约 1–3 分钟。

---

## 5. 下载 ipa

1. 点进那条运行记录。
2. 页面底部 **Artifacts** 区域 → 点 **AspectLab-ipa**。
3. 下载到的是一个 zip，解压后得到 `AspectLab-unsigned.ipa`（约几 MB）。

---

## 6. 装到手机

ipa 是**未签名**的，要重签：

- **SideStore / AltStore**：导入 ipa → 重签 → 安装
- **Sideloadly**（Windows 直接可用）：iPhone 插上电脑 → 拖入 ipa → 填 Apple ID → Start

免费 Apple ID 的限制：7 天有效期、最多 3 个 App。开发者模式要开着（你这台已开）。

---

## 7. 如果变红了（构建失败）

1. 点进失败的运行记录 → 左侧 **build** → 展开 **Build unsigned ipa** 这一步。
2. 从日志里找以 `error:` 开头的行，复制**第一段**（通常 1–3 行）。
3. 发给我，一般一轮就能修完。

也可以顺手把 **Inspect bundle** 那一步的日志一起贴，里面是 `.app` 目录结构和 Info.plist，方便定位。

---

## 8. 后续改代码怎么重跑

直接在 GitHub 网页上点开文件 → 右上角铅笔图标 → 改 → **Commit changes**。
只要改的是 `main` 分支，Actions 会自动重新构建（工作流里配了 `push` 触发），不用再点 Run workflow。

---

## 附：如果 github.com 打不开

Actions 需要能访问 github.com。如果网络不通：

- 换手机热点 / 换 DNS 再试；
- 或者找一台 Mac，把解压目录拷过去，执行：

  ```bash
  bash scripts/build-ipa.sh
  ```

  产物在 `build/AspectLab-unsigned.ipa`，同样需要重签。
