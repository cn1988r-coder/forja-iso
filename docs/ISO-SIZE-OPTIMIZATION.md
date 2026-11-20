# Otimização de tamanho da VENOM OS

## Objetivo
Manter uma mídia live enxuta, sem comprometer MATE, LightDM, rede, Bluetooth, áudio, firmware, acessibilidade ou o instalador próprio planejado.

## Regras
- A imagem será construída pelo perfil Archiso oficial mantido no repositório.
- Pacotes vêm somente dos repositórios oficiais Arch, salvo autorização documentada para um pacote específico do projeto.
- Remover dependências redundantes e componentes de desktops que não fazem parte do MATE.
- Não retirar firmware ou ferramentas essenciais apenas para reduzir alguns megabytes.
- Não compilar ISO durante a etapa de desenvolvimento sem autorização expressa.

## Processo de medição futuro
1. Validar o manifesto e o perfil sem compilar.
2. Registrar o tamanho do conjunto de pacotes e das camadas de filesystem.
3. Quando houver autorização expressa, gerar uma mídia de teste e medir o tamanho final.
4. Comparar boot, sessão MATE, rede, Bluetooth, áudio e instalação em VM descartável.
5. Registrar os resultados reais, sem estimativas apresentadas como medições.

## Estado
A otimização quantitativa ainda não foi medida. O perfil Archiso está em preparação e a geração da mídia permanece bloqueada.
