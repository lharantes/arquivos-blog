# Variaveis para conectar ao Entra ID
$ClientId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$TenantId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$SecretId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$SubscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$Secret = ConvertTo-SecureString -String $SecretId -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $Secret
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

$azContext            = Set-AzContext -Subscription $SubscriptionId
$subscriptionName     = (Get-AzSubscription -SubscriptionId $SubscriptionId).name 
$currentBillingPeriod = Get-AzBillingPeriod -MaxCount 1
$startDate            = $currentBillingPeriod.BillingPeriodStartDate.ToString("yyyy-MM-dd") 
$endDate              = $currentBillingPeriod.BillingPeriodEndDate.ToString("yyyy-MM-dd") 
$currentCost          = (Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate | Measure-Object -Property PretaxCost -Sum).sum
$currentCost          = ([Math]::Round($currentCost, 2))
$currency             = (Get-AzConsumptionusagedetail | Select-Object -First 1).Currency

# API RESP para consultar e calcular a previsao dos custos ate o final do periodo com os recursos atuais
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)

$authHeader = @{                                                                                                                                    
    'Content-Type'='application/json'  
    'Authorization'='Bearer ' + $token.AccessToken  
} 
$body = @"
{
    type: "Usage",
    dataset: {
              "granularity": "none",
              "aggregation":{
                             "totalCost":{
                                          "name":"Cost",
                                          "function":"Sum"
                                          }
                             }
             },
    timeframe: "MonthToDate",
    timePeriod: {
                 from: "$startDate",
                 to: "$endDate"
                 }
}
"@

$url = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/forecast?api-version=2024-08-01"

$UsageData = Invoke-RestMethod `
-Method Post `
-Uri $url `
-ContentType application/json `
-Headers $authHeader `
-Body $body

$forecastData = $UsageData.properties.rows

Foreach ($forecast in $forecastData){
       $forecastCost = $forecast[0]
}
$forecastTotal = ([Math]::Round($forecastCost + $currentCost, 2))

# Aqui é somente para estetica para exibir a data no formato dia/MES
$startDate = $currentBillingPeriod.BillingPeriodStartDate.ToString("dd/MM") 
$endDate = $currentBillingPeriod.BillingPeriodEndDate.ToString("dd/MM") 

# Conteudo para gerar uma pagina HTML
$bodyEmail = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0;  background-color: black}
        table { border-collapse: collapse; width: 100%; }
        td { padding: 10px; }
        .header { background-color: #009879; color: white; font-weight: bold; }
        .dark-bg { background-color: #282C34; color: white; }
        .card-title { color: #B0B0B0; font-size: 14px; font-weight: bold; }
        .card-value { font-size: 24px; font-weight: bold; color: white; }
        .circle-red { background-color: #d63031; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .circle-blue { background-color: #0984e3; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .circle-orange { background-color: #ff7675; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .border-left-red { border-left: 5px solid #d63031; }
        .border-left-blue { border-left: 5px solid #0984e3; }
        .border-left-orange { border-left: 5px solid #ff7675; }
        .resource-table th { border-bottom: 1px solid #3e3e56; color: white; text-align: left; padding: 10px; }
        .resource-table td { border-bottom: 1px solid #3e3e56; color: white; padding: 10px; }
    </style>
</head>
<body>
    <table>
        <tr class="header">
            <td style="font-size: 25px;">$subscriptionName</td>
        </tr>
    </table>

    <table style=" background-color: black; padding: 20px;">
        <tr>
            <td>
                <table>
                    <tr>
                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-orange" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">PERÍODO</p>
                                        <p class="card-value">$StartDate - $EndDate</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-orange" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128197;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>

                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-blue" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">CUSTO ATUAL</p>
                                        <p class="card-value">$currency $currentCost</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-blue" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128176;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>

                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-red" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">CUSTO PREVISTO</p>
                                        <p class="card-value">$currency $forecastTotal</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-red" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128181;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table style="height: 30px;"><tr><td></td></tr></table>

                <table class="dark-bg" style="width: 100%;">
                    <tr>
                        <td style="padding: 20px;">
                            <h2 style="text-align: center; color: white; margin-top: 0;">CUSTO POR GRUPO DE RECURSO</h2>
                            <table class="resource-table" style="width: 100%;">
                                <tr>
                                    <th>GRUPO DE RECURSO</th>
                                    <th>REGIÃO</th>
                                    <th>CUSTO - $currency</th>
                                </tr>
"@

# Para calcular o custo de cada Resource Group
$rgs = get-azresourcegroup

# quando temos muitos Resource Groups ele da o erro de "too request" então a cada 5 RGs eu dou uma pausa de 60 segundos
$i = 0

foreach ($rg in $rgs) {
    $currentRgCost = Get-AzConsumptionUsageDetail -StartDate $currentBillingPeriod.BillingPeriodStartDate -EndDate $currentBillingPeriod.BillingPeriodEndDate -ResourceGroup  $rg.resourcegroupname | Measure-Object -Property PretaxCost -Sum 
    $totalRgCost   = ([Math]::Round($currentRgCost.Sum, 2))
    $i++
    if ($i -eq 5 -Or $i -eq 10 -Or $i -eq 15) {
        Start-Sleep -Seconds 60
    }
    $bodyEmail += '<tr><td style="padding: 10px; font-size: 15px">'+($rg.resourcegroupname).ToUpper()+'</td><td>'+($rg.location).ToUpper()+'</td><td>'+$totalRgCost+'</td></tr>'
}

# Salva tudo em uma variavel para o corpo do e-mail
$bodyEmail += "</table></div></div></main></div></body></html>"

# Conectar ao Microsoft Graph 
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential

# Detalhes do E-mail 
$sender    = "no-reply@arantes.net.br"
$recipient = "luiz@arantes.net.br"
$subject   = "Cost Report - $subscriptionName"
$type      = "HTML"   # pode ser Text
$save      = "false"  # salvar o e-mail nos "Itens enviados"

$params = @{
    Message           = @{
        Subject       = $subject
        Body          = @{
            ContentType = $type
            Content     = $bodyEmail 
        }
        ToRecipients  = @(
            @{
                EmailAddress = @{
                    Address  = $recipient
                }
            }
        )
    }
    SaveToSentItems = $save
}

# Envia o e-mail
Send-MgUserMail -UserId $sender -BodyParameter $params