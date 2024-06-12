##################################################
## ANEXA A GPU A MÀQUINA VIRTUAL                ##
##################################################

$vm = "NOME_DA_MAQUINA_VIRTUAL"

Add-VMGpuPartitionAdapter -VMName $vm
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionVRAM 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionVRAM 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionVRAM 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionEncode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionEncode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionEncode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionDecode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionDecode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionDecode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionCompute 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionCompute 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionCompute 10
Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1GB -VMName $vm
Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vm
Start-VM -Name $vm

##################################################
## COPIA OS DRIVERS PARA A MÀQUINA VIRTUAL      ##
##################################################

# Copia as DLLS
$GpuDllPaths = (Get-CimInstance Win32_VideoController -Filter "Name like 'N%'").InstalledDisplayDrivers.split(',') | Get-Unique

# Extraindo os diretorios
$GpuInfDirs = $GpuDllPaths | ForEach-Object {[System.IO.Path]::GetDirectoryName($_)} | Get-Unique

# Copia apenas os arquivos do driver NVIDIA em "nv"
$GpuInfDirs = $GpuInfDirs | Where-Object {(Split-Path $_ -Leaf ).StartsWith("nv")}

# Inicia a sessão da VM
$s = New-PSSession -VMName $vm -Credential (Get-Credential)

# Copia (Pasta e Arquivos coletados de $GpuDllPaths) nv_dispi.inf_amd64 para a VM.
$GpuInfDirs | ForEach-Object { Copy-Item -ToSession $s -Path $_ -Destination C:\Windows\System32\DriverStore\FileRepository\ -Recurse -Force }

# Copia o nvapi64.dll para a VM
Copy-Item -ToSession $s -Path C:\Windows\System32\nv*.dll -Destination C:\Windows\System32\

# Limpa a sessão aberta
Remove-PSSession $s

# Reinicia a VM
Restart-VM $vm -Force


##################################################
## PARA REMOVER A GPU ANEXAD A MÀQUINA VIRTUAL  ##
##################################################

$vm = "NOME_DA_MAQUINA_VIRTUAL"
Remove-VMGpuPartitionAdapter -VMName $vm
