param(
  [string]$path = '',
  [string]$app = ''
)
if(Get-Process $app.Replace(".exe","") -ErrorAction SilentlyContinue){
    if ($app.Contains("MessageManager") -or $app.Contains("PAFI") -or $app.Contains("Pafi_Wrapper")){
        echo "app is running"
        exit 0;
    }
    if (((Get-ChildItem $path ).count) -gt 1) { 
        if (Test-Path "$($env:TEMP)\$($app).log") { 
            $previous_value = Get-Content "$($env:TEMP)\$($app).log" 
        } 
        $new_value = Get-WmiObject Win32_Process -ComputerName "127.0.0.1" | ` 
            where {$_.Name -eq $app } | ` 
            foreach {"$($_.WriteTransferCount)"} 

        echo "running check for $($path)\$($app) log fie in  $($env:TEMP) "
        $new_value    | Out-File "$($env:TEMP)\$($app).log"  -Force 

        echo "new value $($new_value) vs old value $($previous_value)"

        if ($new_value -ne $previous_value) { 
            exit 0;
        } 
        else { 
            exit 1;
        } 
    
    }else{
        echo "no files in project folder"
        exit 1;
    }
}else{
        echo "app not running"
        exit 1;
}
