# Dinit Upstream Issues

## PID 1 can break when `/dev/console` is unavailable

### Reproducer

Boot Linux with Dinit 0.22.1 as PID 1 and no usable kernel console. One
reproducible configuration is to pass `console=null` on the kernel command
line, while retaining a `/dev/console` device node in the root filesystem:

```text
init=/usr/bin/dinit console=null
```

### Actual result

`dinit_main()` tries to open `/dev/console` for file descriptors 0, 1 and 2,
but does not provide a fallback when either open fails. The descriptors remain
closed. Later, `open_control_socket()` may allocate fd 0 for Dinit's control
socket, while PID 1 already has an event watcher registered for fd 0 as
console input. The overlapping watchers make boot fail or stall before the
service graph can start.

This is especially relevant to headless appliances that must not route a
kernel console to an electrically connected UART.

### Expected result

Dinit should boot normally without a kernel console. Its standard descriptors
must remain valid and must not alias internal sockets.

### Proposed upstream fix

When Dinit runs as PID 1 and `/dev/console` cannot be opened, attach stdin to
`/dev/null` opened read-only and stdout/stderr to `/dev/null` opened
write-only. This preserves fd 0/1/2 and intentionally discards console I/O.

### Local workaround

[`package/dinit/0001-fallback-to-dev-null-without-kernel-console.patch`](../package/dinit/0001-fallback-to-dev-null-without-kernel-console.patch)
implements the fallback for Dinit 0.22.1. The Roki image retains
`console=null` and does not enable a PL011 serial console in production.
