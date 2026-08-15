# ============================================
#  Night Light Exam - manual APK build script
#  Build without Gradle, using SDK build-tools.
#  Output: program\NightLightExam.apk
# ============================================
$ErrorActionPreference = 'Stop'
$p = Split-Path -Parent $MyInvocation.MyCommand.Path
$jdk = Join-Path $p 'tools\jdk-17.0.13+11'
$bt  = Join-Path $p 'tools\android-sdk\build-tools\34.0.0'
$jar = Join-Path $p 'tools\android-sdk\platforms\android-34\android.jar'
$build = Join-Path $p 'build'
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$env:PATH"

New-Item -ItemType Directory -Force -Path $build | Out-Null

Write-Host '[1/7] Compile resources ...'
& "$bt\aapt2.exe" compile --dir (Join-Path $p 'app\src\main\res') -o (Join-Path $build 'res.zip')
if ($LASTEXITCODE -ne 0) { throw 'aapt2 compile failed' }

Write-Host '[2/7] Link resources (generate R.java + base.apk) ...'
& "$bt\aapt2.exe" link -o (Join-Path $build 'base.apk') -I $jar `
  --manifest (Join-Path $p 'app\src\main\AndroidManifest.xml') `
  --java (Join-Path $build 'gen') --auto-add-overlay `
  --version-code 1 --version-name '1.0' `
  (Join-Path $build 'res.zip')
if ($LASTEXITCODE -ne 0) { throw 'aapt2 link failed' }

Write-Host '[3/7] Compile Java sources ...'
New-Item -ItemType Directory -Force -Path (Join-Path $build 'classes') | Out-Null
& "$jdk\bin\javac.exe" -encoding UTF-8 -source 8 -target 8 -cp $jar `
  -d (Join-Path $build 'classes') `
  (Join-Path $build 'gen\com\jiakao\light\R.java') `
  (Join-Path $p 'app\src\main\java\com\jiakao\light\MainActivity.java')
if ($LASTEXITCODE -ne 0) { throw 'javac failed' }

Write-Host '[4/7] Convert to dex ...'
& "$bt\d8.bat" --release --lib $jar --min-api 24 --output (Join-Path $build 'dexout') `
  (Join-Path $build 'classes\com\jiakao\light\R.class') `
  (Join-Path $build 'classes\com\jiakao\light\MainActivity.class')
if ($LASTEXITCODE -ne 0) { throw 'd8 failed' }

Write-Host '[5/7] Add assets and dex into apk (forward slash paths) ...'
& "$jdk\bin\jar.exe" uf (Join-Path $build 'base.apk') -C (Join-Path $p 'app\src\main') assets
& "$jdk\bin\jar.exe" uf (Join-Path $build 'base.apk') -C (Join-Path $build 'dexout') classes.dex

Write-Host '[6/7] zipalign ...'
& "$bt\zipalign.exe" -f 4 (Join-Path $build 'base.apk') (Join-Path $build 'aligned.apk')
if ($LASTEXITCODE -ne 0) { throw 'zipalign failed' }

Write-Host '[7/7] Sign apk ...'
$out = Join-Path $p 'NightLightExam.apk'
& "$bt\apksigner.bat" sign --ks (Join-Path $p 'debug.keystore') `
  --ks-pass pass:android --key-pass pass:android --out $out (Join-Path $build 'aligned.apk')
if ($LASTEXITCODE -ne 0) { throw 'apksigner failed' }
& "$bt\apksigner.bat" verify $out | Out-Null

Write-Host ''
Write-Host ('Build OK! APK: ' + $out)
Write-Host ('Size: ' + (Get-Item $out).Length + ' bytes')
