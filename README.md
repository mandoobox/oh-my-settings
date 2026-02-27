# oh-my-settings 🌌

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 개인 개발 환경 설정 모음

이 저장소는 개인적으로 사용하는 개발 환경 설정 파일들을 관리하기 위한 repo입니다.

설정파일의 경우 raw file 다운 시 확장자 맨 앞 `.` 가 사라질 수 있으니 git clone 추천드립니다. 

ex) `.wezterm.lua` -> `wezterm.lua`

## 📋 목차
- [🦎 tips](tips/README.md)
- [⚙️ settings](#️-settings)
  - [project](#project)
  - [android](#android)
  - [shell](#shell)
- [🚀 install & apply](#-install--apply)
  - [Wezterm](#wezterm)
  - [God-gitignore](#god-gitignore)
  - [EditorConfig for Ktlint](#editorconfig-for-ktlint)
  - [DetektConfig](#detektconfig)
  - [Gemini](#gemini)
  - [Github Setup](#github-setuppr-template-github-actionsktlint-detekt)
- [📄 LICENSE](#-license)

## ⚙️ settings

### 📦 project

- God-gitignore
- Gemini Setup
- Github Setup(PR template, github actions(ktlint, detekt))

### 🤖 android

- EditorConfig for ktlint
- DetektConfig

### 💻 shell

- Wezterm

## 🚀 install & apply

### 💻 Wezterm

[Wezterm 설치](https://wezterm.org/installation.html)

```shell
cp .wezterm.lua ~
```

`~` 위치에 `.wezterm.lua` 를 복사한다.

### 🚫 God-gitignore

`.god` 확장자를 제거하고 프로젝트 루트 디렉토리에 `.gitignore`로 배치.

대부분의 IDE, 빌드 파일, OS 임시 파일 등을 포함하는 포괄적인 gitignore 파일입니다. 적용 후 프로젝트 특성에 맞게 추가 규칙을 검토하세요.

### 📝 EditorConfig for Ktlint

ktlint 설정 파일. rootProject 위치에 배치.

```toml
[versions]
# ktlint
ktlint = "14.0.1"

[plugins]
ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlint" }
```

```kotlin
plugins {
    alias(libs.plugins.ktlint)
    alias(libs.plugins.ktlint) apply false // rootDir - build.gradle.kts
}
```

```gradle
gradle ktlintFormat // 자동 수정
gradle ktlintCheck
```

### 🔍 DetektConfig

`config/detekt`에 위치시킬 detekt 파일.

```toml
[versions]
# detekt
detekt = "1.23.8"

[plugins]
# detekt
detekt = { id = "io.gitlab.arturbosch.detekt", version.ref = "detekt" }
```

```kotlin
plugins {
    alias(libs.plugins.detekt)
    alias(libs.plugins.detekt) apply false // rootDir - build.gradle.kts
}
```

```kotlin
// rootDir - build.gradle.kts
val detektMergeSarif by tasks.registering(ReportMergeTask::class) {
    output.set(layout.buildDirectory.file("reports/detekt/merged.sarif"))
}

tasks.register("detektAll") {
    finalizedBy(detektMergeSarif)
}

subprojects {
    plugins.withId("io.gitlab.arturbosch.detekt") {
        val detektTaskProvider = tasks.named<Detekt>("detekt")

        configure<DetektExtension> {
            buildUponDefaultConfig = true
            allRules = false
            config.setFrom(files(rootProject.file("config/detekt/detekt.yml")))
            autoCorrect = false
        }

        tasks.withType<Detekt>().configureEach {
            jvmTarget = "11"
            reports {
                xml.required.set(false)
                txt.required.set(false)
                html.required.set(true)
                sarif.required.set(true)
                sarif.outputLocation.set(project.layout.buildDirectory.file("reports/detekt/${name}.sarif"))
                md.required.set(false)
            }

            val mergeTaskProvider = rootProject.tasks.named<ReportMergeTask>("detektMergeSarif")
            mergeTaskProvider.configure {
                input.from(this@configureEach.sarifReportFile)
            }
        }

        val mergeTaskProvider = rootProject.tasks.named<ReportMergeTask>("detektMergeSarif")
        detektTaskProvider.configure {
            finalizedBy(mergeTaskProvider)
        }

        rootProject.tasks.named("detektAll") {
            dependsOn(detektTaskProvider)
        }
    }
}
```

### ✨ Gemini

`.gemini` 폴더를 rootProject 위치에 배치 후 GitHub Configure에서 Gemini 사용 설정 ON

### 🔧 Github Setup(PR template, github actions(ktlint, detekt))

`.github` 폴더를 rootProject 위치에 배치

PR 올리면 detekt, ktlint 액션 자동 실행

> ⚠️ ISSUE_TEMPLATE는 아직 미구현


## 📄 LICENSE

> `MIT` - 개인 사용 목적의 설정 파일 모음입니다. 자유롭게 참고하실 수 있습니다.
