# test-network-connectivity.ps1

# Função para registrar mensagens com timestamp
function Write-Log {
  param(
    [Parameter(Mandatory=$true)][string]$Message,
    [Parameter(Mandatory=$false)][string]$LogFile = "network_connectivity_log.txt"
  )
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logEntry = "[$timestamp] $Message"
  Write-Host $logEntry
  Add-Content -Path $LogFile -Value $logEntry
}

# Função para testar conectividade via Ping
function Test-Ping {
  param(
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$false)][int]$Count = 4,
    [Parameter(Mandatory=$false)][int]$Timeout = 1000 # milliseconds
  )
  
  Write-Log "Iniciando teste de Ping para: $Target"
  $pingResult = Test-Connection -ComputerName $Target -Count $Count -BufferSize 32 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
  
  if ($pingResult) {
    $averageResponseTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
    $status = "Sucesso"
    $message = "Ping para $Target bem-sucedido. Tempo médio de resposta: $($averageResponseTime)ms."
    Write-Log $message
    return @{
      Target = $Target;
      Type = "Ping";
      Status = $status;
      ResponseTime = $averageResponseTime;
      Error = $null
    }
  } else {
    $status = "Falha"
    $message = "Ping para $Target falhou ou excedeu o tempo limite."
    Write-Log $message
    return @{
      Target = $Target;
      Type = "Ping";
      Status = $status;
      ResponseTime = $null;
      Error = $message
    }
  }
}

# Função para testar conectividade TCP/UDP
function Test-TcpUdp {
  param(
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$true)][int]$Port,
    [Parameter(Mandatory=$true)][string]$Protocol, # "TCP" or "UDP"
    [Parameter(Mandatory=$false)][int]$TimeoutSeconds = 5
  )

  Write-Log "Iniciando teste de $Protocol para ${Target}:${Port}"
  $status = "Falha"
  $errorMessage = ""
  $responseTime = $null

  try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    if ($Protocol -eq "TCP") {
      $tcpClient = New-Object System.Net.Sockets.TcpClient
      $connectTask = $tcpClient.ConnectAsync($Target, $Port)
      $connectTask.Wait($TimeoutSeconds * 1000) | Out-Null

      if ($connectTask.IsCompleted -and -not $connectTask.IsFaulted -and -not $connectTask.IsCanceled) {
        if ($tcpClient.Connected) {
          $status = "Sucesso"
          $responseTime = $stopwatch.ElapsedMilliseconds
          Write-Log "Conexão TCP para ${Target}:${Port} bem-sucedida. Tempo de resposta: $($responseTime)ms."
        } else {
          $errorMessage = "Conexão TCP para ${Target}:${Port} falhou."
          Write-Log $errorMessage
        }
      } else {
        $errorMessage = "Conexão TCP para ${Target}:${Port} excedeu o tempo limite ou falhou inesperadamente."
        Write-Log $errorMessage
      }
      $tcpClient.Dispose()
    } elseif ($Protocol -eq "UDP") {
      # Para UDP, a "conexão" é sem estado. Apenas tentar criar o cliente e conectar
      # pode indicar se o host/porta é alcançável, mas não garante que um serviço está ouvindo.
      # Para um teste UDP mais robusto, seria necessário enviar e receber dados.
      $udpClient = New-Object System.Net.Sockets.UdpClient
      $udpClient.Connect($Target, $Port)
      $status = "Sucesso" # Se não houver exceção, consideramos alcançável
      $responseTime = $stopwatch.ElapsedMilliseconds
      Write-Log "Conexão UDP para ${Target}:${Port} bem-sucedida (sem garantia de serviço ouvindo). Tempo de resposta: $($responseTime)ms."
      $udpClient.Dispose()
    } else {
      $errorMessage = "Protocolo '$Protocol' não suportado."
      Write-Log $errorMessage
    }
  } catch {
    $errorMessage = "Erro ao testar $Protocol para ${Target}:${Port}: $($_.Exception.Message)"
    Write-Log $errorMessage
  } finally {
    $stopwatch.Stop()
  }

  return @{
    Target = $Target;
    Port = $Port;
    Protocol = $Protocol;
    Status = $status;
    ResponseTime = $responseTime;
    Error = $errorMessage
  }
}

# Endpoints de exemplo
$endpoints = @(
  @{ Name = "Google DNS"; Address = "8.8.8.8"; Ping = $true; TcpPorts = @(53); UdpPorts = @(53) },
  @{ Name = "Supabase URL"; Address = "vatjkgtkiwxwszdznszh.supabase.co"; Ping = $true; TcpPorts = @(443); UdpPorts = @() },
  @{ Name = "Localhost"; Address = "127.0.0.1"; Ping = $true; TcpPorts = @(); UdpPorts = @() }
)

# Coleção para armazenar todos os resultados dos testes
$allTestResults = @()

# Exemplo de uso das funções e coleta de resultados
foreach ($endpoint in $endpoints) {
  if ($endpoint.Ping) {
    $allTestResults += Test-Ping -Target $endpoint.Address
  }
  foreach ($port in $endpoint.TcpPorts) {
    $allTestResults += Test-TcpUdp -Target $endpoint.Address -Port $port -Protocol "TCP"
  }
  foreach ($port in $endpoint.UdpPorts) {
    $allTestResults += Test-TcpUdp -Target $endpoint.Address -Port $port -Protocol "UDP"
  }
}

# Geração do Relatório Final
Write-Log "`n--- Relatório Final de Conectividade de Rede ---"
$report = "`n--- Relatório Final de Conectividade de Rede ---`n"
$overallStatus = "Operacional"
$failedTests = @()

foreach ($result in $allTestResults) {
  $report += "Tipo: $($result.Type)"
  if ($result.Protocol) { $report += ", Protocolo: $($result.Protocol)" }
  $report += ", Alvo: $($result.Target)"
  if ($result.Port) { $report += ", Porta: $($result.Port)" }
  $report += ", Status: $($result.Status)"
  if ($result.ResponseTime) { $report += ", Tempo de Resposta: $($result.ResponseTime)ms" }
  if ($result.Error) { 
    $report += ", Erro: $($result.Error)"
    $overallStatus = "Problemas Identificados"
    $failedTests += $result
  }
  $report += "`n"
}

$report += "`n--- Resumo ---`n"
$report += "Status Geral da Conexão: $overallStatus`n"
$report += "Total de Testes Executados: $($allTestResults.Count)`n"
$report += "Testes Bem-sucedidos: $(($allTestResults | Where-Object { $_.Status -eq 'Sucesso' }).Count)`n"
$report += "Testes com Falha: $($failedTests.Count)`n"

if ($failedTests.Count -gt 0) {
  $report += "`nDetalhes dos Testes com Falha:`n"
  foreach ($fail in $failedTests) {
    $report += "  - Tipo: $($fail.Type)"
    if ($fail.Protocol) { $report += ", Protocolo: $($fail.Protocol)" }
    $report += ", Alvo: $($fail.Target)"
    if ($fail.Port) { $report += ", Porta: $($fail.Port)" }
    $report += ", Erro: $($fail.Error)`n"
  }
}

Write-Log $report
Write-Host $report
