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
 * mode over bluetooth, and keep Steam from talking it into flooding the radio
 * (the hw_request hook at the bottom).
 *
 * The stock descriptor puts the pad state on report 3 and calls report 4 "31
 * bytes of vendor constant". What the pad actually streams is report 4: the
 * same state, 11 bytes fresh off a power cycle and 32 once Steam or SDL's
 * hidapi has poked it (hid-core zero-pads the short one). It ignored every
 * one of them, so the pad was dead to everything on evdev while Steam,
 * parsing hidraw itself, worked fine. Lost an evening to that. So the state
 * lives on report 4 here, and the event hook below renames a stray report 3
 * to match, should one ever show up; defining the state on both doesn't
 * work, hid-input drops duplicate usages (HID_STAT_DUP_DETECTED).
 */
static const __u8 fixed_rdesc[] = {
    0x05, 0x01,         // Usage Page (Generic Desktop)
    0x09, 0x05,         // Usage (Gamepad)
    0xa1, 0x01,         // Collection (Application)
    0x85, 0x04,         //   Report ID (4)                          <-- was 3
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
    0x09, 0x23,         //   Usage (0x23)
    0x75, 0x08,         //   Report Size (8)
    0x95, 0x15,         //   Report Count (21)                      <-- was 31, the rest of report 4
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

/* Never seen one, but the stock descriptor promised it. */
SEC(HID_BPF_DEVICE_EVENT)
int BPF_PROG(hid_fix_event, struct hid_bpf_ctx *hctx) {
    __u8 *data = hid_bpf_get_data(hctx, 0 /* offset */, 1 /* size */);
    if (!data)
        return 0; /* EPERM check */
    if (data[0] == 3)
        data[0] = 4;
    return 0;
}

/*
 * Reading feature report 6 is how SDL's 8BitDo driver (and so Steam) asks the
 * pad who it is -- and, as a side effect nobody asked for, flips it into
 * "enhanced" mode: 32-byte reports with IMU data at ~120/s instead of 11
 * bytes at ~80/s, until the next power-off. On a single radio that's enough
 * to make A2DP skip and leave inquiry scans blind; my earbuds found out
 * (2026-10-27). So the read is answered here, from the reply this pad gave
 * once, and never reaches it. Gyro is the price; the battery and buttons are
 * the same in both modes. Another SN30 Pro would be handed this one's serial,
 * which only Steam's device list would notice.
 */
static const __u8 feature6[64] = {
    0x06, 0xcf, 0x00, 0x00, 0x00, 0x37, 0x7b, 0x42, 0x78, 0x41, 0x51, 0x01,
    0x60, 0xaa, 0xdd, 0x8c, 0xdd, 0xab, 0xdc, 0x1c, 0x02, 0x1c, 0x02, 0xd4,
    0x1f, 0x2c, 0xe0, 0x2e, 0x20, 0xd2, 0xdf, 0xff, 0x1f, 0x02, 0xe0, 0xf6,
    0xff,
};

SEC("struct_ops/hid_hw_request")
int BPF_PROG(hid_answer_feature6, struct hid_bpf_ctx *hctx, unsigned char reportnum,
             enum hid_report_type rtype, enum hid_class_request reqtype, __u64 source) {
    int i;

    if (reportnum != 6 || rtype != HID_FEATURE_REPORT || reqtype != HID_REQ_GET_REPORT)
        return 0; /* not ours; let hid-core forward it */

    /* The buffer is the caller's, sized by the caller; one byte at a time
     * keeps the verifier happy for any length they chose. */
    for (i = 0; i < sizeof(feature6); i++) {
        __u8 *data;
        if (i >= hctx->size)
            break;
        data = hid_bpf_get_data(hctx, i /* offset */, 1 /* size */);
        if (!data)
            break;
        *data = feature6[i];
    }
    return i; /* > 0: handled, this many bytes */
}

HID_BPF_OPS(sn30_pro_bt) = {
    .hid_rdesc_fixup = (void *)hid_fix_rdesc,
    .hid_device_event = (void *)hid_fix_event,
    .hid_hw_request = (void *)hid_answer_feature6,
};

SEC("syscall")
int probe(struct hid_bpf_probe_args *ctx) {
    ctx->retval = ctx->rdesc_size == RDESC_SIZE ? 0 : -EINVAL;
    return 0;
}

char _license[] SEC("license") = "GPL";
