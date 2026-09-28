# CAN bus capability roadmap

## Why this document exists

The 2026-09-22 resume refresh scoped vehicle-network experience to **CAN only**:

> Develop embedded Linux platforms for agricultural equipment electronics;
> working knowledge of CAN bus and protocol.

Resume feedback suggested claiming "CAN, J1939, and ISOBUS". That was **not**
adopted, because only CAN was confirmed. J1939 and ISOBUS stay off the resume
until the work below produces something defensible in an interview.

This matters more in agriculture than elsewhere: J1939 is the heavy-duty vehicle
standard and ISOBUS (ISO 11783) is the implement-to-tractor standard. For PTx,
AGCO, Precision Planting, John Deere, CNH, and Trimble roles, these are usually
screened for by name.

## The gap, concretely

| Layer | Status | What "defensible" looks like |
|---|---|---|
| CAN 2.0 A/B framing, arbitration, bit timing, error states | Confident | Can explain arbitration and error-passive/bus-off from memory |
| SocketCAN on Linux | Verify | Bring up an interface, capture and decode traffic unaided |
| CAN FD | Unknown | Explain what changes vs. classic CAN and when it matters |
| J1939 (PGN, SPN, addressing, transport protocol) | Gap | Decode a PGN by hand; explain BAM vs. RTS/CTS |
| ISOBUS / ISO 11783 | Gap | Explain the VT, TC, and address-claim procedure |
| CANopen | Gap | Lower priority for agriculture; skip unless a role asks |

## Step 1 — Ground the CAN claim (low effort, do first)

Nothing here needs hardware beyond a Linux machine.

- [ ] `sudo modprobe vcan && sudo ip link add dev vcan0 type vcan && sudo ip link set up vcan0`
- [ ] Install `can-utils`. Practise `candump`, `cansend`, `cangen`, `canplayer`.
- [ ] Write a small SocketCAN program in C and in Python (`python-can`) that
      sends and receives frames.
- [ ] Be able to explain, unprompted: arbitration by ID, bit stuffing, the error
      counters, and what puts a node bus-off.

Outcome: the existing resume line is fully backed.

## Step 2 — J1939 (highest return for agriculture)

- [ ] Read SAE J1939-21 (data link) and J1939-71 (application layer) — or a
      reliable summary if the standards are not accessible.
- [ ] Learn the 29-bit ID decomposition: priority, PGN (DP/PF/PS), source address.
- [ ] Decode a few real PGNs by hand, e.g. EEC1 (engine speed) and ET1.
- [ ] Understand the transport protocol: BAM for broadcast, RTS/CTS for
      destination-specific, and why >8-byte payloads need it.
- [ ] Understand address claiming (PGN 60928) and NAME arbitration.
- [ ] Use Linux's in-kernel J1939 stack (`CONFIG_CAN_J1939`, `AF_CAN`/`SOCK_DGRAM`
      with `CAN_J1939`) — this is a natural fit given the embedded Linux background.
- [ ] Build something: a J1939 decoder that turns `candump` logs into named
      SPNs, published to a personal repo.

Outcome: `J1939` becomes claimable, with a repo to point at.

## Step 3 — ISOBUS / ISO 11783

Harder to practise without equipment, so target understanding over hands-on.

- [ ] Learn how ISO 11783 extends J1939 for agriculture.
- [ ] Learn the roles: Virtual Terminal (VT), Task Controller (TC),
      implement ECU, and the tractor ECU.
- [ ] Understand object pools and how an implement presents a UI on the VT.
- [ ] Look at the open-source `AgIsoStack++` (formerly ISOBUS++) project;
      building and running its examples is the cheapest hands-on route.
- [ ] Understand AEF conformance testing at a conceptual level.

Outcome: survives a follow-up question even without shipping an ISOBUS product.

## Step 4 — Hardware, if you want real traffic

- [ ] A USB-CAN adapter with SocketCAN support (e.g. a CANable / candleLight
      running `gs_usb`, or a PEAK PCAN-USB).
- [ ] A second node so there is real arbitration — two adapters, or an MCU
      dev board with a CAN transceiver.
- [ ] Optional: a J1939 simulator or a logged capture from real equipment.

Deliberately not pursued: Vector tooling (CANalyzer, CANoe, CANape). It is
expensive, licence-gated, and was explicitly listed as a confirmed gap not
worth closing.

## Updating the resume as this progresses

Edit [config/_default/params.toml](../config/_default/params.toml) only — every
other artifact is derived. Suggested wording as each step lands:

- After step 1: keep the current line.
- After step 2: "…CAN and J1939 in agricultural equipment; built a J1939 decoder
  on Linux's in-kernel J1939 stack."
- After step 3: "…CAN, J1939, and ISOBUS (ISO 11783) in agricultural equipment."

Only make each change once you could defend it cold in an interview.
