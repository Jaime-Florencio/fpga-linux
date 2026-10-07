# FPGA Linux — iCESugar Nano

Levantamento de estudo e exemplo mínimo de desenvolvimento FPGA no Windows, usando WSL 2, Ubuntu e a placa **iCESugar Nano** com FPGA **Lattice iCE40LP1K-CM36**.

O objetivo inicial é gerar um bitstream que faça o LED amarelo onboard piscar. A gravação física ainda depende de a placa estar disponível.

## Hardware de referência

- Placa: iCESugar Nano
- FPGA: Lattice iCE40LP1K-CM36
- Clock padrão: 12 MHz, fornecido pelo iCELink
- LED amarelo onboard: pino B6
- Clock da FPGA: pino D1

As informações de modelo, LED, clock e opções de programação foram conferidas no [repositório oficial da iCESugar Nano](https://github.com/wuxx/icesugar-nano) e em um [exemplo específico para a placa](https://github.com/cjacker/opensource-toolchain-fpga).

## Estrutura

```text
.
├── constraints/
│   └── icesugar_nano.pcf  # Associação entre sinais Verilog e pinos físicos
├── src/
│   └── top.v              # Contador e LED piscante
├── build/                 # Gerada localmente; ignorada pelo Git
└── README.md
```

## Ambiente utilizado

- Windows com WSL 2
- Ubuntu 26.04.1 LTS
- Yosys 0.52
- nextpnr-ice40 0.9
- IceStorm / `icepack`
- GNU Make 4.4.1
- Git 2.53.0

No Ubuntu, os pacotes foram instalados com:

```bash
sudo apt update
sudo apt upgrade
sudo apt install yosys nextpnr-ice40 fpga-icestorm make
```

> No Ubuntu 26.04, o pacote do IceStorm chama-se `fpga-icestorm`. O executável usado para empacotar o bitstream é `icepack`.

## Exemplo Verilog

O módulo `top` recebe o clock e conta suas bordas de subida. O bit 23 do contador controla o LED:

```text
clock de 12 MHz → contador de 24 bits → counter[23] → LED
```

Um `reg [23:0]` representa 24 bits de armazenamento, sintetizados em 24 flip-flops. O contador percorre de `0` até `2^24 - 1` e então retorna a zero. Em 12 MHz, o bit 23 troca de estado aproximadamente a cada 0,7 s.

## Arquivo PCF

O arquivo `.pcf` faz a ligação entre os nomes do Verilog e os pinos físicos da FPGA:

```text
clk → D1
led → B6
```

Os nomes no PCF devem corresponder exatamente aos nomes das portas do módulo Verilog.

## Fluxo de compilação

Execute os comandos a partir da raiz do projeto:

```bash
yosys -p "synth_ice40 -top top -json build/top.json" src/top.v

nextpnr-ice40 --lp1k --package cm36 \
  --pcf constraints/icesugar_nano.pcf \
  --json build/top.json \
  --asc build/top.asc \
  --freq 12

icepack build/top.asc build/top.bin
```

O fluxo produzido é:

```text
src/top.v
  ↓ Yosys (síntese)
build/top.json
  ↓ nextpnr-ice40 (place and route)
build/top.asc
  ↓ icepack
build/top.bin
```

### Resultados da primeira compilação

- Síntese: 24 `SB_DFF`, 24 `SB_LUT4` e 22 `SB_CARRY`.
- Yosys: `0 problems`.
- Place and route: concluído normalmente.
- Frequência máxima estimada: **131,73 MHz**.
- Clock de operação real: **12 MHz**.

A frequência máxima é uma estimativa de timing do circuito roteado; não muda o clock fornecido pela placa. Como 12 MHz é bem menor que 131,73 MHz, o exemplo possui ampla margem de timing.

## Gravação na placa (pendente de hardware)

No Windows + WSL 2, o método recomendado para a primeira gravação é usar a unidade USB virtual **iCELink**, exposta pela placa ao Windows:

1. Conectar a iCESugar Nano com um cabo USB-C de dados.
2. Confirmar que o Windows detectou a unidade iCELink.
3. Copiar `build/top.bin` para a raiz dessa unidade.
4. Aguardar a programação automática e observar o LED amarelo piscando.

O arquivo gerado no WSL pode ser acessado pelo Explorador de Arquivos do Windows em:

```text
\\wsl$\Ubuntu\home\fpga\icesugar-example\build\top.bin
```

Não é necessário USB passthrough ou `usbipd-win` para esse método. A alternativa com `icesprog` será estudada após a confirmação da placa física.

## Próximos passos

- Conectar a placa e confirmar a unidade iCELink no Windows.
- Programar `top.bin` e verificar o LED.
- Registrar o procedimento de gravação validado.
- Evoluir para a leitura de sinais digitais de encoder e, posteriormente, multiplexação/demultiplexação do projeto Tetra Pak.
