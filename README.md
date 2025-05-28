# Instalaçao
```bash
:: Monta a partição EFI na letra B:
mountvol B: /s

:: (Opcional) Clona o seu repositório (caso tenha configs personalizadas)
git clone https://github.com/QuittoGames/dualboot_rEFIind
move dualboot_rEFIind refind

:: Copia os arquivos do rEFInd baixado para a partição EFI
mkdir B:\EFI\refind
xcopy /E /Y /I "C:\Users\Quitto\Downloads\dualboot\refind-bin-0.14.2\refind" B:\EFI\refind\

:: (Opcional) Sobrescreve com seu tema ou configurações personalizadas
xcopy /E /Y /I ".\refind" B:\EFI\refind\

:: Define o rEFInd como o gerenciador de boot padrão
bcdedit /set "{bootmgr}" path \EFI\refind\refind_x64.efi

```
