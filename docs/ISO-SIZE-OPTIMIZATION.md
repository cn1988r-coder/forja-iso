# VENOM OS: otimização do tamanho da ISO

Data: 2026-11-20  
Branch isolada: `optimize/venom-iso-size`  
Base: build #50, commit `88143611d80214fd5b945c9346b352ce8e14f47d`

## Diagnóstico confirmado

A build #50 gerou um SquashFS de **3.731,72 MiB**, com filesystem descompactado de **10.526,9 MiB**. A ISO final ficou em aproximadamente **4,7 GiB**.

Os logs mostraram componentes pesados que não são necessários para o perfil MATE padrão:
- NVIDIA proprietários (nvidia-open e nvidia-utils), mantendo Mesa/Nouveau e firmware genérico;
- fontes CJK e variantes extras do Noto, mantendo Noto Sans e emoji;
- grupo base-devel e utilitários de manutenção/recuperação duplicados;
- Qt WebEngine, embora o módulo webview do Calamares já esteja explicitamente desativado;
- símbolos de depuração do Calamares e pacote shelly-git-debug;
- variantes Bibata não selecionadas;
- arquivos .pkg.tar.zst redundantes copiados para /usr/share/venom/packages, embora o instalador offline e o online copiem a imagem completa já instalada via unpackfs.

## Otimizações preparadas

1. Filtrar pacotes pesados não essenciais do perfil Live, preservando MATE, Firefox, Ferdium, Shelly, IPTVnator, Calamares, Materia Dark, Papirus e o cursor Bibata Modern Classic.
2. Preservar os dois kernels e seus cabeçalhos: linux, linux-headers, linux-lts e linux-lts-headers. Os manifestos de instalação não foram alterados.
3. Retirar dependências de Qt WebEngine e Doxygen do pacote Calamares, pois o módulo webview está desativado; habilitar stripping de símbolos no pacote Release.
4. Não instalar o pacote de depuração do Shelly.
5. Não duplicar os arquivos de pacotes próprios dentro da ISO; a instalação offline continua copiando a imagem completa, e a instalação online continua atualizando essa imagem pelos repositórios oficiais Arch.
6. Manter somente Bibata-Modern-Classic, que é a variante configurada no MATE.
7. Trocar a compressão SquashFS de Zstandard nível 19 para XZ com filtro x86 e dicionário de 100%, priorizando tamanho menor. A inicialização Live poderá ficar mais lenta.

## Meta e limites

Meta de engenharia: reduzir a ISO em aproximadamente 2 GB, aproximando-a da faixa de 2,5–3 GB. **Isso é uma meta, não um resultado medido.** A redução exata depende da nova compilação e da composição dos pacotes.

## Preservação e validação

- A build #50 e seu artefato/hash não foram alterados.
- Nenhuma nova build foi iniciada nesta etapa.
- As mudanças estão isoladas em branch que não está na lista de branches que dispara automaticamente a build ISO.
- Antes de aprovar a próxima ISO, executar validações estáticas, compilar, comparar o tamanho do SquashFS/ISO e testar boot, MATE e os dois modos do Calamares em VM.
- Não remover os dois kernels nem trocar o desktop MATE.
