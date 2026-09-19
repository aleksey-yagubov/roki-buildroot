Прошивка для головы робота Roki-2, который производится компанией Старкит\
Оригинальная прошивка базировалась на замусоренной распбиан ос debian 11 с графической оболочкой\
Поэтому я решил переделать всё на билдруте\
Голова основана на RPi CM4, 8гб оперативы, 32гб emmc, встроенный wifi\
камера с глобальным затвором по mipi-csi2+i2c(i2c0) через модуль arducam-pivariety\
на i2c0 также находится ds3231 часы rtc\
через i2c6+gpio2-17 расширитель gpio портов mcp23008 для кнопок на голове(я сделал его как нормальный input device через ядро)\
через spi0+gpio7-24-25-26 экран 240 на 240 цветной, он управляется через userspace spidev\
на gpio27 вентилятор охлаждения\
через i2s два аудио усилителя max98357a для воспроизведения звука\
через pcie-usb3(upd720201) подключен нейроускоритель Intel NCS2\
через uart5 и uart2(не используется), а также gpio6(ресет) подключена stm32h743vit\
stm32h743vit выполняет функционал моста в тело робота, и также привязывает кадр c сенсора к данным с spi IMU, получая по gpio strobe от сенсора\
к usb+uart0(очень странно, почему инженер его не вывел под консоль)+gpio9 подключена stm32f446rct6 "blue coin", этот микроконтроллер нужен чтоб давать массив из 4 микрофонов, а также 8 светодиодов маленьких и один rgb светодиод побольше\
встроенный USB2 Broadcom подключён к USB-хабу: на нём BlueCoin (ACM и USB-микрофон) и Type-C; перед хабом стоит USB-мультиплексор\
на корпусе переключатель boot: в режиме прошивки мультиплексор отключает хаб и подключает Type-C напрямую к USB2 Broadcom

## Принятые решения

- Основа системы — актуальный Buildroot `master` как отдельное дерево; этот
  репозиторий остаётся лёгким `br2-external` с defconfig, пакетами, board
  files и скриптами формирования образа. Wrapper перед сборкой резолвит SHA
  ветки `master` и скачивает его tarball без Git-истории в игнорируемое
  локальное дерево; Buildroot не добавляется Git submodule.
- Драйверы оборудования головы собираются в ядро. `/dev` предоставляет
  `devtmpfs`; `udev` и правила прав устройств не используются. Все сервисы
  и прикладной код работают от `root`.
- Для встроенного Wi-Fi в ядро добавляются firmware-файлы
  `brcmfmac43455-sdio.bin`, `brcmfmac43455-sdio.clm_blob` и
  `brcmfmac43455-sdio.raspberrypi,4-compute-module.txt`, а также
  `regulatory.db`.
- Raspberry Pi boot firmware и ядро Raspberry Pi берутся как GitHub tarball
  по закреплённым upstream commits, без Git-истории. Версии kernel и firmware
  обновляются намеренно и одной проверяемой парой; их commits записываются в
  build manifest образа.
- В boot-разделе используются `start4.elf`, `fixup4.dat`, наш `config.txt`,
  наш `cmdline.txt`, DTB ядра и только требуемые DT overlays.
- Экран ST7789 остаётся на `spidev` в userspace. В базовом ядре отключены
  VC4/V3D DRM, fbdev и fbcon; Mesa, OpenGL, Vulkan и GPU compute в образ не
  входят. Это не требуется для CSI/libcamera и ISP.
- Init-система — `dinit` с собственными сервисами, перенесёнными из текущего
  образа. Корень стартует смонтированным `ro`, проходит fsck и только затем
  перемонтируется в `rw`.
- Корневая ext4 создаётся с журналом и стандартным `data=ordered`; barriers
  не отключаются. Для корня задаётся `errors=remount-ro`. Сервис fsck обязан
  оставить `/` в режиме `ro` при любом неуспехе или неизвестном коде fsck.

## Первичный запуск

```sh
make setup
make defconfig
make xconfig
```

Buildroot source появится в игнорируемой `.buildroot/`, а конфигурация и все
артефакты -- в игнорируемой `output/`. После изменения конфигурации через
`xconfig` обновить versioned defconfig командой `make save-defconfig`.
Список пакетов Arch Linux для build host находится в
[`docs/arch-host-packages.txt`](docs/arch-host-packages.txt).
Известные проблемы upstream, обнаруженные при сборке и запуске образа:
[`docs/buildroot-upstream-issues.md`](docs/buildroot-upstream-issues.md) и
[`docs/dinit-upstream-issues.md`](docs/dinit-upstream-issues.md).

## Прошивка eMMC

Образ содержит initial rootfs размером 320 MiB, чтобы его было быстрее
передавать. Прошивать CM4 следует скриптом
[`scripts/flash-roki-cm4.sh`](scripts/flash-roki-cm4.sh): он записывает образ
на весь USB mass-storage device, затем на компьютере расширяет второй раздел
и ext4 до production-размера 600 MiB. Сама голова разделы не изменяет.

```sh
sudo ./scripts/flash-roki-cm4.sh /dev/sdX output/images/roki-cm4.img
```

`/dev/sdX` должен быть целым устройством CM4, а не его разделом. Скрипт
требует явного подтверждения перед стиранием данных. Подробности и требования
к host-утилитам: [`docs/flashing.md`](docs/flashing.md).

Каждый GitHub release должен содержать два артефакта из одного commit:
`roki-cm4.img` и `flash-roki-cm4.sh`.

