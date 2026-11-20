# VENOM OS

## Definições do projeto

- **Base técnica:** Arch Linux, com componentes upstream do EndeavourOS ainda usados no processo de geração da ISO.
- **Atualizações do sistema:** exclusivamente pelo Pacman oficial, com `sudo pacman -Syu`.
- **Repositório próprio:** VENON, independente do Pacman e acionado somente por comandos manuais.
- **Ambiente gráfico:** MATE como único ambiente gráfico, com LightDM.
- **Aparência:** Materia Dark, ícones Papirus e cursor Bibata.
- **Área de trabalho:** identidade escura monocromática.
- **Aplicativos:** Firefox, Ferdium, Shelly e IPTVnator.

## Separação Pacman / VENON

O Pacman administra o sistema operacional e os aplicativos provenientes dos repositórios oficiais Arch. A configuração global do Pacman não deve conter o repositório VENON.

O VENON terá mecanismo, metadados, verificação de integridade e instalação próprios. Não pode executar `pacman`, `pacman-key`, usar uma configuração isolada do Pacman ou participar da atualização geral do sistema.

Comandos definitivos:

- `venon-update`: consulta e lista atualizações disponíveis no repositório VENON, sem instalar.
- `venon-upgrade`: baixa e instala atualizações VENON somente após confirmação explícita.

Os dois comandos são manuais. Nenhum serviço, timer ou inicialização automática ativa o VENON.

**Estado atual:** os comandos estão presentes como bloqueios seguros, mas o servidor, o protocolo de metadados assinados e o instalador independente ainda não foram implementados. Até lá, eles informam que o serviço não está configurado e não alteram o sistema. Não anunciar o repositório como operacional.

## Estrutura do projeto

- `Dockerfile`: ambiente de compilação.
- `build/packages.mate`: seleção de pacotes MATE, LightDM e aparência.
- `build/airootfs/`: configuração da sessão Live e comandos VENON.
- `scripts/build-container.sh`: ambiente isolado via Docker/Podman.
- `scripts/build-venom-iso.sh`: preparação e geração da ISO.
- `scripts/validate-build.sh`: verificações estáticas, sem compilar ou iniciar a ISO.
- `docs/ENDEAVOUROS-AUDIT.md`: auditoria dos componentes upstream utilizados.

## Estado de validação

Nenhuma ISO foi aprovada por compilação e instalação reais. Alterações de código e verificações estáticas não comprovam funcionamento do instalador, do hardware ou das atualizações.
