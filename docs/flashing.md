# Прошивка eMMC

`roki-cm4.img` намеренно содержит второй ext4-раздел размером 320 MiB. Это
уменьшает размер передаваемого raw-образа. После записи host-скрипт расширяет
раздел до 600 MiB и увеличивает ext4; CM4 в этой процедуре не участвует.

## Требования

На Linux host нужны `bash`, GNU `dd`, `lsblk`, `sfdisk`, `blockdev`, `awk`,
`e2fsck` и `resize2fs`. На Arch Linux они доступны из `coreutils` и
`util-linux`, а `e2fsck` и `resize2fs` - из `e2fsprogs`.

CM4 должен быть переведён в USB mass-storage mode. Устройство обычно
появляется как `/dev/sdX`; использовать надо диск целиком, не `/dev/sdX1` и
не `/dev/sdX2`.

## Запись

```sh
sudo ./scripts/flash-roki-cm4.sh /dev/sdX output/images/roki-cm4.img
```

Скрипт отказывается работать со смонтированными разделами, требует вручную
подтвердить путь к устройству и затем выполняет:

1. `dd` с `bs=16M`, `oflag=direct`, `conv=fsync` и `status=progress`.
2. Расширение MBR partition 2 до 600 MiB через `sfdisk`.
3. `e2fsck -fy` и `resize2fs` для второго раздела.

Для автоматизированного вызова, когда устройство уже проверено, доступен
флаг `--yes`:

```sh
sudo ./scripts/flash-roki-cm4.sh --yes /dev/sdX roki-cm4.img
```

## Release

К каждому GitHub release прикладываются `roki-cm4.img` и
`flash-roki-cm4.sh` из одного и того же commit. Запускать скрипт из release
можно с образом из того же release.
