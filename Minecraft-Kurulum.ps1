$ErrorActionPreference = 'Stop'

try {
    $mcDir = "$env:APPDATA\.minecraft"
    $modsDir = "$mcDir\mods"
    New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

    $profilesFile = "$mcDir\launcher_profiles.json"
    if (-not (Test-Path $profilesFile)) {
        [System.IO.File]::WriteAllText($profilesFile, '{"profiles":{},"settings":{},"version":3}', (New-Object System.Text.UTF8Encoding($false)))
    }

    $tempDir = "$env:TEMP\mc-fabric-setup"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    $fabricVersionDir = "$mcDir\versions\fabric-loader-0.19.5-26.3"
    if (Test-Path $fabricVersionDir) {
        Write-Host "Fabric (26.3) zaten kurulu, kurulum adimi atlaniyor. Yeni profil acilmayacak."
    } else {
        $existingJava = Get-Command java -ErrorAction SilentlyContinue
        if (-not $existingJava) {
            Write-Host "Java bulunamadi, kurulum icin kucuk bir surum indiriliyor..."
            $jreZip = "$tempDir\jre.zip"
            Invoke-WebRequest -Uri "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse" -OutFile $jreZip
            Expand-Archive -Path $jreZip -DestinationPath "$tempDir\jre" -Force
            $inner = Get-ChildItem "$tempDir\jre" -Directory | Select-Object -First 1
            $javaExe = "$($inner.FullName)\bin\java.exe"
        } else {
            Write-Host "Sistemde Java bulundu, o kullanilacak."
            $javaExe = "java"
        }

        Write-Host "Fabric yukleyici indiriliyor..."
        $installerPath = "$tempDir\fabric-installer.jar"
        Invoke-WebRequest -Uri "https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.1.2/fabric-installer-1.1.2.jar" -OutFile $installerPath

        Write-Host "Fabric (Minecraft 26.3) kuruluyor, bu biraz surebilir..."
        & $javaExe -jar $installerPath client -mcversion 26.3 -dir $mcDir
        if ($LASTEXITCODE -ne 0) {
            throw "Fabric kurulumu basarisiz oldu (kod: $LASTEXITCODE)"
        }
    }

    $mods = @(
        @{ Name = "fabric-api-0.161.0+26.3.jar"; Url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/bNnaTiuM/fabric-api-0.161.0%2B26.3.jar" },
        @{ Name = "voicechat-fabric-2.6.24+26.3.jar"; Url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/OLnMVWXy/voicechat-fabric-2.6.24%2B26.3.jar" },
        @{ Name = "fabric-language-kotlin-1.14.1+kotlin.2.4.20.jar"; Url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/eRRZzGMc/fabric-language-kotlin-1.14.1%2Bkotlin.2.4.20.jar" },
        @{ Name = "yet_another_config_lib_v3-3.9.7+26.3-fabric.jar"; Url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/s9SjoFu1/yet_another_config_lib_v3-3.9.7%2B26.3-fabric.jar" },
        @{ Name = "sodium-fabric-0.9.3-alpha.1+mc26.3.jar"; Url = "https://cdn.modrinth.com/data/AANobbMI/versions/v4PSXean/sodium-fabric-0.9.3-alpha.1%2Bmc26.3.jar" },
        @{ Name = "iris-fabric-1.11.6+mc26.3.jar"; Url = "https://cdn.modrinth.com/data/YL57xq9U/versions/bAdKrpw8/iris-fabric-1.11.6%2Bmc26.3.jar" },
        @{ Name = "entityculling-fabric-1.11.2-mc26.3.jar"; Url = "https://cdn.modrinth.com/data/NNAgCjsB/versions/F4loCvYt/entityculling-fabric-1.11.2-mc26.3.jar" },
        @{ Name = "dynamic-fps-3.11.10+minecraft-26.3.0-fabric.jar"; Url = "https://cdn.modrinth.com/data/LQ3K71Q1/versions/Jwq069rR/dynamic-fps-3.11.10%2Bminecraft-26.3.0-fabric.jar" },
        @{ Name = "ferritecore-9.0.0-fabric.jar"; Url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar" },
        @{ Name = "xaerominimap-fabric-26.3-26.5.3.jar"; Url = "https://cdn.modrinth.com/data/1bokaNcj/versions/YPkAliDt/xaerominimap-fabric-26.3-26.5.3.jar" },
        @{ Name = "appleskin-fabric-mc26.3-3.0.10.jar"; Url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/PHjDtQay/appleskin-fabric-mc26.3-3.0.10.jar" },
        @{ Name = "zoomify-2.16.3+26.3.jar"; Url = "https://cdn.modrinth.com/data/w7ThoJFB/versions/bvz5KJLQ/zoomify-2.16.3%2B26.3.jar" },
        @{ Name = "modmenu-21.0.0.jar"; Url = "https://cdn.modrinth.com/data/mOgUt4GM/versions/kyy7dbrZ/modmenu-21.0.0.jar" }
    )

    Write-Host "Modlar kontrol ediliyor..."
    foreach ($mod in $mods) {
        $dest = "$modsDir\$($mod.Name)"
        if (Test-Path $dest) {
            Write-Host "  [var] $($mod.Name) - atlaniyor"
        } else {
            Write-Host "  [indiriliyor] $($mod.Name)"
            Invoke-WebRequest -Uri $mod.Url -OutFile $dest
        }
    }

    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "============================================"
    Write-Host "  KURULUM TAMAMLANDI!"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "Kurulan modlar: Fabric API, Simple Voice Chat, Sodium, Iris, Entity Culling,"
    Write-Host "Dynamic FPS, FerriteCore, Xaero's Minimap, AppleSkin, Zoomify, Mod Menu"
    Write-Host ""
    Write-Host "Simdi yapman gerekenler:"
    Write-Host "1. Minecraft Launcher'i (veya TLauncher'i) ac"
    Write-Host "2. Sol ustten (Installations/Kurulumlar) 'fabric-loader-26.3' secilini sec"
    Write-Host "3. Play/Oyna'ya bas (ilk acilista launcher gerekli oyun dosyalarini kendi indirir)"
    Write-Host "4. Multiplayer -> Add Server -> Eren'in sana verdigi IP adresini yaz"
    Write-Host ""
    Write-Host "Kisayollar:"
    Write-Host "- Sesli sohbet: V tusu (oyun icinde degistirilebilir)"
    Write-Host "- Zoom (yakinlastirma): C tusu (Zoomify varsayilani)"
    Write-Host "- Harita: Xaero'nun mini haritasi sag ustte otomatik gorunur"
    Write-Host "- Mod Menu: Ana menude 'Mods' butonundan tum modlari gorebilirsin"
}
catch {
    Write-Host ""
    Write-Host "BIR HATA OLUSTU:"
    Write-Host $_.Exception.Message
    Write-Host "Bu ekrani Eren'e goster."
}
