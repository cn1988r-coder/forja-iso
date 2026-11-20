# VENOM OS

A VENOM OS é uma distribuição independente baseada no Arch Linux oficial.

## Definições
- Base: Arch Linux oficial, usando exclusivamente os repositórios oficiais.
- Desktop: MATE.
- Login gráfico: LightDM.
- Idioma: Português do Brasil.
- Teclado padrão: Brasil ABNT2.
- Aparência: identidade escura monocromática VENOM, Materia Dark, Papirus e Bibata.
- Aplicativos planejados: Firefox, Ferdium, Shelly e IPTVnator.

## Atualizações
O Pacman administra o sistema e os aplicativos: `sudo pacman -Syu`.

O VENON é um mecanismo separado, manual e independente do Pacman:
- `venon-upgrade`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-update`: instala atualizações VENON somente após confirmação explícita.

O backend, o servidor e o protocolo assinado do VENON ainda não estão implementados. Os comandos atuais permanecem bloqueios seguros e não alteram o sistema.

## Instalador
O instalador próprio será desenvolvido em C + GTK4, com interface totalmente gráfica e instalação offline a partir da própria mídia. Ainda não está implementado nem validado.

## Estrutura
- `build/`: perfil Archiso em preparação, pacotes e configuração do sistema live.
- `scripts/build-venom-iso.sh`: permanece bloqueado até implementação/validação do instalador e autorização expressa.
- `scripts/validate-build.sh`: validações estáticas, sem gerar ISO.
- `docs/PROJECT-CONTINUITY.md`: estado técnico e histórico de continuidade.

## Estado
Nenhuma ISO foi compilada ou aprovada nesta etapa. A base Archiso e o instalador ainda exigem implementação e validação.
