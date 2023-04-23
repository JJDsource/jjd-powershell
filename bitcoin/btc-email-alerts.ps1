param (
    [Parameter(Mandatory = $true)]
    [int]
    $alert,

    [Parameter(Mandatory = $true)]
    [string]
    $smtpuser,

    [Parameter(Mandatory = $true)]
    [securestring]
    $smtpPass

)

#Log file path current directory. Create if doesnt exist
$log = (Get-Location).Path + '\btc-email-alerts.log'
if (!(Test-Path $log)) {
    New-Item -Path $log -ItemType File | Out-Null
}

#check price every 1 minutes and send email if price is over $alert and log price
while ($true) {

    #Get date
    $date = Get-Date -Format "MM/dd/yyyy HH:mm:ss"

    try {
        #coindesk Price
        $price = (Invoke-WebRequest -Uri "https://api.coindesk.com/v1/bpi/currentprice.json").Content | ConvertFrom-Json
        $price = $price.bpi.USD.rate_float
    }
    catch {
        #coinbase Price
        $price = (Invoke-WebRequest -Uri "https://api.coinbase.com/v2/prices/spot?currency=USD").Content | ConvertFrom-Json
        $price = $price.data.amount
    }

    #log price
    $date + ' ' + '$' + $price >> $log

    if ($price -gt $alert) {
        #Email setup.
        $message = "BTC is now over $alert. Current Price is $price"
        $subject = "BTC Alert Price is $price"
        $smtpServer = "smtp.office365.com"
        $smtpPort = 587
        $smtpUser = $smtpUser
        $smtpPass = $smtpPass
        $smtpFrom = $smtpUser
        $smtpTo = $smtpUser
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
        
        $mail = New-Object System.Net.Mail.MailMessage($smtpFrom, $smtpTo, $subject, $message)
        $smtp.Send($mail)

        #Don't email for an hour.
        Start-Sleep -Seconds 3600
    }
    Start-Sleep -Seconds 60
}