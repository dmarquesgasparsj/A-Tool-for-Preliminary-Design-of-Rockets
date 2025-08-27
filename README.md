# Toolkit MATLAB — Preliminary Rocket Design (Multi‑Estágio + Gravity Turn)

**Idioma:** Português (PT-PT)  
**Objetivo:** Estimar massas, dimensões e *payload ratio* para foguetões multi‑estágio, incluindo simulação de *gravity turn* 2D e iteração simples entre **trajetória** e **configuração**.

**Nota importante**: Estes modelos são preliminares/simplificados e usam aproximações (atmosfera exponencial, arrasto constante por estágio, controlo de *pitch* simplificado, queima por estágios em série, sem boosters laterais). São úteis para *trade‑offs* iniciais e sensibilidades, **não** para verificação de voo.

## Como usar
1. Abrir o `main.m` no MATLAB/Octave.
2. Escolher a configuração em `main.m` (e.g., `demo_config` ou criar uma em `configs/`).
3. Executar o `main.m`. O script vai:
   - Carregar a configuração do lançador e parâmetros de missão.
   - Otimizar (por defeito) a trajetória básica (tempo do *pitch* e *kick*).
   - Procurar, por bisseção, a **carga útil máxima** que ainda atinge a órbita-alvo.
   - Reportar o *payload ratio* (= m_payload / m0) e gráficos de altitude/velocidade.

## Pastas
- `configs/` — ficheiros com parâmetros por lançador (ex.: `demo_config.m`).  
  Crie variantes (ex.: `vega_config.m`, `protonkdm3_config.m`, `ariane5_config.m`) editando *Isp*, *thrust*, massas estruturais, massas de propelente, `CdA`, etc.
- `util/` — funções auxiliares.

## Limitações principais
- ISA simplificada (exponencial, altura de escala fixa).
- Arrasto modelado via `CdA` constante por estágio.
- Direção do impulso: vertical até `t_pitch`; janela curta de *pitch kick*; depois *gravity turn* com *thrust* alinhado com a velocidade.
- Sem modelação de boosters laterais/acoplagens assimétricas.
- Otimização *sem* toolboxes (usa *grid search* e `fminsearch` quando aplicável).

## Resultados esperados
- Estimativa de massa de descolagem, *payload ratio* e histórico temporal (altitude, velocidade, ângulo).
- Base para comparar configurações (alterando ficheiros em `configs/`) e fazer *what‑if* nos parâmetros.
