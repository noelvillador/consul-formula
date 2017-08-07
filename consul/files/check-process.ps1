param(
  [string]$path = '',
  [string]$app = ''
)
while($true){
    if (((Get-ChildItem $path ).count) -gt 1) { 
        if (Test-Path "$($env:TEMP)\$($app).log") { 
            $previous_value = Get-Content "$($env:TEMP)\$($app).log" 
        } 
        $new_value = Get-WmiObject Win32_Process -ComputerName "127.0.0.1" | ` 
            where {$_.Name -eq $app } | ` 
            foreach {"$($_.WriteTransferCount)"} 

        $new_value    | Out-File "$($env:TEMP)\$($app).log"  -Force 

        echo "new value $($new_value) vs old value $($previous_value)"

        if ($new_value -ne $previous_value) { 
            exit 0;
        } 
        else { 
            exit 1;
        } 
    
    } 
}
