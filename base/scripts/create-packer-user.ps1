write-output "Creating packer Windows user..."
NET USER packer "@kx0JQSG?uz" /add
NET LOCALGROUP "Administrators" "packer" /add
write-output "packer user created."
