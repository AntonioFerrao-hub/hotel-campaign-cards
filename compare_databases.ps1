# Script de Comparação de Bancos de Dados Supabase (Origem vs Destino)
# Usa os comandos SQL diretamente via psql para evitar problemas de dump/DNS

param(
  [Parameter(Mandatory=$false)][string]$Source = $env:PGSRC,
  [Parameter(Mandatory=$false)][string]$Target = $env:PGDST
)

if (-not $Source -or -not $Target) {
  Write-Host "Defina PGSRC e PGDST ou passe -Source/-Target."
  exit 1
}

function Get-SchemaInfo($connectionString, $name) {
    Write-Host "Coletando informações do banco: $name"
    
    # Lista de Tabelas e Colunas
    $tables = & psql --dbname="$connectionString" -Atc "
      SELECT table_schema || '.' || table_name || '.' || column_name || ' (' || data_type || ')'
      FROM information_schema.columns 
      WHERE table_schema NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'supabase_internal', 'pgsodium', 'pg_cron', 'graphql', 'graphql_public', 'realtime', 'vault')
      ORDER BY 1;
    " --no-psqlrc 2>$null

    # Lista de Funções
    $functions = & psql --dbname="$connectionString" -Atc "
      SELECT n.nspname || '.' || p.proname || '(' || pg_get_function_arguments(p.oid) || ')'
      FROM pg_proc p 
      JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'supabase_internal', 'pgsodium', 'pg_cron', 'graphql', 'graphql_public', 'realtime', 'vault')
      ORDER BY 1;
    " --no-psqlrc 2>$null

    # Lista de Policies (RLS)
    $policies = & psql --dbname="$connectionString" -Atc "
      SELECT schemaname || '.' || tablename || ': ' || policyname || ' (' || cmd || ')'
      FROM pg_policies
      WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'supabase_internal', 'pgsodium', 'pg_cron', 'graphql', 'graphql_public', 'realtime', 'vault')
      ORDER BY 1;
    " --no-psqlrc 2>$null

    # Lista de Triggers
    $triggers = & psql --dbname="$connectionString" -Atc "
        SELECT event_object_schema || '.' || event_object_table || ': ' || trigger_name
        FROM information_schema.triggers
        WHERE event_object_schema NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'supabase_internal', 'pgsodium', 'pg_cron', 'graphql', 'graphql_public', 'realtime', 'vault')
        ORDER BY 1;
    " --no-psqlrc 2>$null

    # Contagem de Registros (apenas tabelas public)
    $counts = & psql --dbname="$connectionString" -Atc "
      SELECT table_schema || '.' || table_name, (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text::int
      FROM information_schema.tables
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    " --no-psqlrc 2>$null
    
    # Buckets (storage)
    $buckets = & psql --dbname="$connectionString" -Atc "
      SELECT id FROM storage.buckets ORDER BY 1;
    " --no-psqlrc 2>$null

    return @{
        Tables = $tables
        Functions = $functions
        Policies = $policies
        Triggers = $triggers
        Counts = $counts
        Buckets = $buckets
    }
}

$srcInfo = Get-SchemaInfo $Source "Origem"
$dstInfo = Get-SchemaInfo $Target "Destino"

Write-Host "`n--- RELATÓRIO DE COMPARAÇÃO ---`n"

function Compare-List($list1, $list2, $label) {
    Write-Host "Verificando $label..."
    $diff = Compare-Object -ReferenceObject ($list1 -split "`n") -DifferenceObject ($list2 -split "`n")
    
    $missingInDest = $diff | Where-Object { $_.SideIndicator -eq '<=' }
    if ($missingInDest) {
        Write-Host " [!] Faltando no Destino ($($missingInDest.Count)):" -ForegroundColor Red
        $missingInDest | ForEach-Object { Write-Host "   - $($_.InputObject)" }
    } else {
        Write-Host " [OK] Nenhum item faltando no destino." -ForegroundColor Green
    }
    Write-Host ""
}

Compare-List $srcInfo.Tables $dstInfo.Tables "Tabelas e Colunas"
Compare-List $srcInfo.Functions $dstInfo.Functions "Funções (Stored Procedures)"
Compare-List $srcInfo.Triggers $dstInfo.Triggers "Triggers"
Compare-List $srcInfo.Policies $dstInfo.Policies "Políticas de Segurança (RLS)"
Compare-List $srcInfo.Buckets $dstInfo.Buckets "Storage Buckets"

Write-Host "--- Comparação de Dados (Contagem de Linhas - Public) ---"
$srcCounts = @{}
($srcInfo.Counts -split "`n") | ForEach-Object { 
    if ($_) {
        $parts = $_ -split '\|'
        if ($parts.Count -eq 2) { $srcCounts[$parts[0].Trim()] = [int]$parts[1].Trim() }
    }
}

$dstCounts = @{}
($dstInfo.Counts -split "`n") | ForEach-Object { 
    if ($_) {
        $parts = $_ -split '\|'
        if ($parts.Count -eq 2) { $dstCounts[$parts[0].Trim()] = [int]$parts[1].Trim() }
    }
}

foreach ($table in $srcCounts.Keys) {
    $s = $srcCounts[$table]
    $d = if ($dstCounts.ContainsKey($table)) { $dstCounts[$table] } else { 0 }
    
    if ($s -ne $d) {
        Write-Host "DIFF"
    } else {
        Write-Host "OK"
    }
}
