[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Source = $env:PGSRC,

    [Parameter(Mandatory=$false)]
    [string]$Target = $env:PGDST,

    [Parameter(Mandatory=$false)]
    [switch]$MigrateAuth,

    [Parameter(Mandatory=$false)]
    [string]$AuthSource = $env:PGSRC_AUTH,

    [Parameter(Mandatory=$false)]
    [string]$AuthTarget = $env:PGDST_AUTH,

    [Parameter(Mandatory=$false)]
    [switch]$MigrateStorage,

    [Parameter(Mandatory=$false)]
    [string]$StorageSourceUrl = $env:SUPABASE_SRC_URL,

    [Parameter(Mandatory=$false)]
    [string]$StorageSourceKey = $env:SUPABASE_SRC_SERVICE_KEY,

    [Parameter(Mandatory=$false)]
    [string]$StorageTargetUrl = $env:SUPABASE_DST_URL,

    [Parameter(Mandatory=$false)]
    [string]$StorageTargetKey = $env:SUPABASE_DST_SERVICE_KEY,

    [Parameter(Mandatory=$false)]
    [switch]$Verify
)

function Ensure-Tool($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "$name não encontrado. $hint"
    exit 1
  }
}

function Test-DbConnection {
  param(
    [Parameter(Mandatory=$true)][string]$ConnectionUri,
    [Parameter(Mandatory=$true)][string]$ConnectionName,
    [Parameter(Mandatory=$false)][int]$TimeoutSeconds = 30,
    [Parameter(Mandatory=$false)][int]$MaxRetries = 3,
    [Parameter(Mandatory=$false)][int]$InitialBackoffSeconds = 1
  )

  $psql = (Get-Command psql).Source
  $attempt = 0
  while ($attempt -lt $MaxRetries) {
    $attempt++
    $backoff = $InitialBackoffSeconds * [Math]::Pow(2, ($attempt - 1))
    $logMessage = "[$ConnectionName] Tentativa $($attempt)/$($MaxRetries) de conexão... (Aguardando $($backoff)s antes da próxima tentativa se falhar)"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath log.txt -Append
    
    $errorOutput = [System.IO.Path]::GetTempFileName()
    $process = Start-Process -FilePath $psql -ArgumentList "--dbname=`"$ConnectionUri`" --command=`"SELECT 1;`" --no-psqlrc --set=ON_ERROR_STOP=1 --pset pager=off" -NoNewWindow -PassThru -RedirectStandardError $errorOutput -Wait
    $errorContent = Get-Content $errorOutput | Out-String

    if ([string]::IsNullOrWhiteSpace($errorContent)) {
        $logMessage = "[$ConnectionName] Conexão bem-sucedida na tentativa $($attempt)."
        Write-Host $logMessage -ForegroundColor Green
        $logMessage | Out-File -FilePath log.txt -Append
        Remove-Item $errorOutput
        return $true
    } else {
        $logMessage = "[$ConnectionName] Falha na conexão na tentativa $($attempt). Erro: $errorContent"
        Write-Host $logMessage -ForegroundColor Red
        $logMessage | Out-File -FilePath log.txt -Append
    }
    Remove-Item $errorOutput

    if ($attempt -lt $MaxRetries) {
      Start-Sleep -Seconds $backoff
    }
  }

  $errorMessage = "[$ConnectionName] Falha ao conectar após $($MaxRetries) tentativas. Abortando migração."
  Write-Error $errorMessage
  $errorMessage | Out-File -FilePath log.txt -Append
  return $false
}

if ($Verify) {
     if (-not $Target) {
         Write-Error "Para verificação, defina PGDST ou passe -Target."
         exit 1
     }
     Write-Host "Verificando o banco de dados de destino..."
     $psql = "C:\Program Files\PostgreSQL\16\bin\psql.exe"

    try {
        $uri = [System.Uri]$Target
        $userInfo = $uri.UserInfo.Split(':', 2)
        $DbUser = $userInfo[0]
        $env:PGPASSWORD = $userInfo[1]
        $DbHost = $uri.Host
        $DbPort = if ($uri.Port -eq -1) { 5432 } else { $uri.Port }
        $DbName = $uri.AbsolutePath.TrimStart('/')
    } catch {
        Write-Error "Falha ao parsear a string de conexão do Target: $Target. Formato esperado: postgresql://user:password@host:port/dbname"
        exit 1
    }

    Write-Host "Conectando a $($DbHost):$($DbPort), DB: $($DbName), User: $($DbUser)"
     & $psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c "\dt"
     if ($LASTEXITCODE -ne 0) { Write-Error "Falha na verificação"; exit 1 }
     exit 0
 }

if ((-not $MigrateAuth) -and (-not $MigrateStorage) -and (-not $Source -or -not $Target)) {
  Write-Host "Para migração de banco de dados, defina PGSRC e PGDST ou passe -Source/-Target."
  exit 1
}

if ($MigrateAuth -and (-not $AuthSource -or -not $AuthTarget)) {
  Write-Host "Defina PGSRC_AUTH e PGDST_AUTH ou passe -AuthSource/-AuthTarget."
  exit 1
}

if ($MigrateStorage -and (-not $StorageSourceUrl -or -not $StorageSourceKey -or -not $StorageTargetUrl -or -not $StorageTargetKey)) {
  Write-Host "Defina SUPABASE_SRC_URL, SUPABASE_SRC_SERVICE_KEY, SUPABASE_DST_URL, SUPABASE_DST_SERVICE_KEY."
  exit 1
}

if ($MigrateStorage) {
    Ensure-Tool node "Instale o Node.js para migrar o storage."
}

$dump = Join-Path $PSScriptRoot ("dump_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".dump")

if (-not $MigrateAuth -and -not $MigrateStorage) {
    Ensure-Tool psql "Instale os clientes do PostgreSQL"
    Ensure-Tool pg_dump "Instale os clientes do PostgreSQL"
    Ensure-Tool pg_restore "Instale os clientes do PostgreSQL"
    
    $psql = (Get-Command psql).Source
    $pgDump = (Get-Command pg_dump).Source
    $pgRestore = (Get-Command pg_restore).Source

    Write-Host "Testando conexão origem (com retry e timeout)"
    if (-not (Test-DbConnection -ConnectionUri $Source -ConnectionName "Origem")) {
        exit 1
    }

    Write-Host "Testando conexão destino (com retry e timeout)"
    if (-not (Test-DbConnection -ConnectionUri $Target -ConnectionName "Destino")) {
        exit 1
    }

    Write-Host "Habilitando extensões no destino"
    $exts = & $psql --dbname="$Source" -At --command="select extname from pg_extension where extname not in ('plpgsql') order by 1;" --no-psqlrc --set=ON_ERROR_STOP=1 --pset pager=off
    $exts = $exts | Where-Object { $_ -and $_.Trim().Length -gt 0 }
    foreach ($e in $exts) {
        $ename = $e.Trim()
        $cmd = 'create extension if not exists "' + $ename + '";'
        $cmd | & $psql --dbname="$Target" --no-psqlrc --set=ON_ERROR_STOP=1 --pset pager=off
        if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao criar extensão $ename"; exit 1 }
    }

    Write-Host "Gerando dump"
    & $pgDump -d $Source -Fc --no-owner --no-privileges -n public -f $dump
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha no pg_dump"; exit 1 }

    Write-Host "Restaurando dump"
    $list = Join-Path $PSScriptRoot ("restore_list_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".list")
    & $pgRestore -l $dump | Set-Content -Path $list
    $listLines = Get-Content $list | Where-Object {
        $_ -notmatch '\bSCHEMA\b.*\bpublic\b' -and
        $_ -notmatch '\bCOMMENT\b.*\bSCHEMA\b.*\bpublic\b' -and
        $_ -notmatch '\bFUNCTION\b.*\bpublic\b.*\bhandle_new_user\b' -and
        $_ -notmatch '\bCOMMENT\b.*\bFUNCTION\b.*\bpublic\b.*\bhandle_new_user\b'
    }
    $listLines | Set-Content -Path $list
    & $pgRestore -d $Target --no-owner --no-privileges --clean -L $list $dump
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha no pg_restore"; exit 1 }
    
    Write-Host "Verificação"
    & $psql --dbname="$Target" --command="select nspname, relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where relkind='r' and nspname not in ('pg_catalog','information_schema','supabase_internal') order by 1,2 limit 20;" --no-psqlrc --set=ON_ERROR_STOP=1 --pset pager=off
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha na verificação"; exit 1 }

    Write-Host "Concluído. Backup salvo em $dump"
}

if ($MigrateAuth) {
    Ensure-Tool psql "Instale os clientes do PostgreSQL"
    Ensure-Tool pg_dump "Instale os clientes do PostgreSQL"
    Ensure-Tool pg_restore "Instale os clientes do PostgreSQL"

    $psql = (Get-Command psql).Source
    $pgDump = (Get-Command pg_dump).Source
    $pgRestore = (Get-Command pg_restore).Source

    Write-Host "Testando conexão Auth Origem (com retry e timeout)"
    if (-not (Test-DbConnection -ConnectionUri $AuthSource -ConnectionName "Auth Origem")) {
        exit 1
    }
    Write-Host "Testando conexão Auth Destino (com retry e timeout)"
    if (-not (Test-DbConnection -ConnectionUri $AuthTarget -ConnectionName "Auth Destino")) {
        exit 1
    }
    Write-Host "Gerando dump do auth"
    $authDump = Join-Path $PSScriptRoot ("auth_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".dump")
    & $pgDump -d $AuthSource -Fc --no-owner --no-privileges -n auth -f $authDump
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha no pg_dump auth"; exit 1 }

    Write-Host "Restaurando auth"
    & $pgRestore -d $AuthTarget --no-owner --no-privileges --clean -U supabase_auth_admin $dumpAuth--if-exists $authDump
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha no pg_restore auth"; exit 1 }
}

if ($MigrateStorage) {
  Write-Host "Migrando storage"
  $nodeScript = @'
const { createClient } = require('@supabase/supabase-js')
const srcUrl = process.env.SUPABASE_SRC_URL
const srcKey = process.env.SUPABASE_SRC_SERVICE_KEY
const dstUrl = process.env.SUPABASE_DST_URL
const dstKey = process.env.SUPABASE_DST_SERVICE_KEY
const src = createClient(srcUrl, srcKey, { auth: { autoRefreshToken: false, persistSession: false } })
const dst = createClient(dstUrl, dstKey, { auth: { autoRefreshToken: false, persistSession: false } })

async function listAllFiles(bucket) {
  const results = []
  const stack = ['']
  while (stack.length) {
    const prefix = stack.pop()
    let offset = 0
    while (true) {
      const { data, error } = await src.storage.from(bucket).list(prefix, { limit: 1000, offset })
      if (error) throw error
      if (!data || data.length === 0) break
      for (const item of data) {
        if (item.id === null && item.name) {
          stack.push(prefix ? `${prefix}/${item.name}` : item.name)
        } else if (item.name) {
          results.push(prefix ? `${prefix}/${item.name}` : item.name)
        }
      }
      if (data.length < 1000) break
      offset += data.length
    }
  }
  return results
}

async function ensureBucket(name, publicBucket) {
  const { data, error } = await dst.storage.listBuckets()
  if (error) throw error
  if (!data.find(b => b.name === name)) {
    const { error: createError } = await dst.storage.createBucket(name, { public: publicBucket })
    if (createError) throw createError
  }
}

async function run() {
  const { data: buckets, error } = await src.storage.listBuckets()
  if (error) throw error
  for (const bucket of buckets) {
    await ensureBucket(bucket.name, bucket.public)
    const files = await listAllFiles(bucket.name)
    for (const path of files) {
      const { data, error: downloadError } = await src.storage.from(bucket.name).download(path)
      if (downloadError) throw downloadError
      const arrayBuffer = await data.arrayBuffer()
      const buffer = Buffer.from(arrayBuffer)
      const { error: uploadError } = await dst.storage.from(bucket.name).upload(path, buffer, { upsert: true, contentType: data.type });
      if (uploadError) throw uploadError
      process.stdout.write(`Copiado ${bucket.name}/${path}\n`)
    }
  }
}

run().catch(err => { console.error(err); process.exit(1) })
'@
  $env:SUPABASE_SRC_URL = $StorageSourceUrl
  $env:SUPABASE_SRC_SERVICE_KEY = $StorageSourceKey
  $env:SUPABASE_DST_URL = $StorageTargetUrl
  $env:SUPABASE_DST_SERVICE_KEY = $StorageTargetKey
  & node -e $nodeScript
  if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao migrar storage"; exit 1 }
}
