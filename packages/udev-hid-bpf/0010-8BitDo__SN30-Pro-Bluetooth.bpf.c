#include "vmlinux.h"
#include "hid_bpf.h"
#include "hid_bpf_helpers.h"
#include <bpf/bpf_tracing.h>

#define VID_8BITDO  0x2DC8
#define PID_SN30_PRO_BT     0x6101
#define RDESC_SIZE  149

HID_BPF_CONFIG(
    HID_DEVICE(BUS_BLUETOOTH, HID_GROUP_GENERIC, VID_8BITDO, PID_SN30_PRO_BT)
);

/*
 * Make the battery and R stick reports readable from my SN30 Pro in D-input
 * mode over bluetooth.
 */
static const __u8 fixed_rdesc[] = {
    0x05, 0x01,         // Usage Page (Generic Desktop)
    0x09, 0x05,         // Usage (Gamepad)
    0xa1, 0x01,         // Collection (Application)
    0x85, 0x03,         //   Report ID (3)
    0x05, 0x01,         //   Usage Page (Generic Desktop)
    0x15, 0x00,         //   Logical Minimum (0)
    0x25, 0x07,         //   Logical Maximum (7)
    0x46, 0x3b, 0x01,   //   Physical Maximum (315)
    0x95, 0x01,         //   Report Count (1)
    0x75, 0x04,         //   Report Size (4)
    0x65, 0x14,         //   Unit (Degrees)
    0x09, 0x39,         //   Usage (Hat switch)
    0x81, 0x42,         //   Input (Data,Var,Abs,Null)
    0x75, 0x01,         //   Report Size (1)
    0x95, 0x04,         //   Report Count (4)
    0x81, 0x01,         //   Input (Cnst,Arr,Abs)
    0x15, 0x00,         //   Logical Minimum (0)
    0x26, 0xff, 0x00,   //   Logical Maximum (255)
    0x09, 0x30,         //   Usage (X)
    0x09, 0x31,         //   Usage (Y)
    0x09, 0x33,         //   Usage (Rx)                             <-- was Z
    0x09, 0x34,         //   Usage (Ry)                             <-- was Rz
    0x95, 0x04,         //   Report Count (4)
    0x75, 0x08,         //   Report Size (8)
    0x81, 0x02,         //   Input (Data,Var,Abs)
    0x05, 0x02,         //   Usage Page (Simulation Controls)
    0x15, 0x00,         //   Logical Minimum (0)
    0x26, 0xff, 0x00,   //   Logical Maximum (255)
    0x09, 0xc4,         //   Usage (Accelerator)
    0x09, 0xc5,         //   Usage (Brake)
    0x95, 0x02,         //   Report Count (2)
    0x75, 0x08,         //   Report Size (8)
    0x81, 0x02,         //   Input (Data,Var,Abs)
    0x05, 0x09,         //   Usage Page (Button)
    0x19, 0x01,         //   Usage Minimum (1)
    0x29, 0x10,         //   Usage Maximum (16)
    0x15, 0x00,         //   Logical Minimum (0)
    0x25, 0x01,         //   Logical Maximum (1)
    0x75, 0x01,         //   Report Size (1)
    0x95, 0x10,         //   Report Count (16)
    0x81, 0x02,         //   Input (Data,Var,Abs)
    0x05, 0x06,         //   Usage Page (Generic Device Controls)   <-- moved
    0x09, 0x20,         //   Usage (Battery Strength)               <-- here
    0x15, 0x00,         //   Logical Minimum (0)
    0x25, 0x64,         //   Logical Maximum (100)
    0x75, 0x08,         //   Report Size (8)
    0x95, 0x01,         //   Report Count (1)
    0x81, 0x02,         //   Input (Data,Var,Abs)
    0x06, 0x00, 0xff,   //   Usage Page (Vendor Defined 0xff00)
    0x85, 0x04,         //   Report ID (4)
    0x09, 0x23,         //   Usage (0x23)
    0x75, 0x08,         //   Report Size (8)
    0x95, 0x1f,         //   Report Count (31)
    0x81, 0x03,         //   Input (Cnst,Var,Abs)
    0x06, 0x00, 0xff,   //   Usage Page (Vendor Defined 0xff00)
    0x85, 0x06,         //   Report ID (6)
    0x09, 0x23,         //   Usage (0x23)
    0x95, 0x3f,         //   Report Count (63)
    0xb1, 0x02,         //   Feature (Data,Var,Abs)
    0x05, 0x0f,         //   Usage Page (Physical Interface)
    0x09, 0x70,         //   Usage (Magnitude)
    0x85, 0x05,         //   Report ID (5)
    0x15, 0x00,         //   Logical Minimum (0)
    0x25, 0x64,         //   Logical Maximum (100)
    0x75, 0x08,         //   Report Size (8)
    0x95, 0x04,         //   Report Count (4)
    0x91, 0x02,         //   Output (Data,Var,Abs)
    0xc0,
};

SEC(HID_BPF_RDESC_FIXUP)
int BPF_PROG(hid_fix_rdesc, struct hid_bpf_ctx *hctx) {
    __u8 *data = hid_bpf_get_data(hctx, 0 /* offset */, HID_MAX_DESCRIPTOR_SIZE /* size */);
    if (!data)
        return 0; /* EPERM check */
    __builtin_memcpy(data, fixed_rdesc, sizeof(fixed_rdesc));
    return sizeof(fixed_rdesc);
}

HID_BPF_OPS(sn30_pro_bt) = {
    .hid_rdesc_fixup = (void *)hid_fix_rdesc,
};

SEC("syscall")
int probe(struct hid_bpf_probe_args *ctx) {
    ctx->retval = ctx->rdesc_size == RDESC_SIZE ? 0 : -EINVAL;
    return 0;
}

char _license[] SEC("license") = "GPL";
