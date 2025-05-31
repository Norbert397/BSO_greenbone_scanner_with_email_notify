#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 You
# SPDX-License-Identifier: GPL-3.0-or-later

import sys
import time
from argparse import ArgumentParser, Namespace
from base64 import b64decode
from pathlib import Path
from typing import List, Dict

from gvm.protocols.gmp import Gmp


def parse_args() -> Namespace:
    p = ArgumentParser(description="Scan hosts and export reports as PDF")
    p.add_argument(
        "--hosts", "-H", nargs="+", required=True,
        help="Host(s) IPv4/IPv6 to scan"
    )
    p.add_argument(
        "--port-list", "-P", required=True,
        help="Port list UUID (e.g. iana-tcp-udp)"
    )
    p.add_argument(
        "--scan-config", "-C", default="daba56c8-73ec-11df-a475-002264764cea",
        help="Scan config UUID (default: Full and fast)"
    )
    p.add_argument(
        "--output-dir", "-O", default=".",
        help="Directory to write PDF reports into"
    )
    p.add_argument(
        "--poll-interval", "-I", type=int, default=10,
        help="Seconds between status checks (default: 10s)"
    )
    return p.parse_args(sys.argv[1:])


def create_target_and_task(
    gmp: Gmp, host: str, port_list_id: str, scan_config_id: str, scanner_id: str
) -> str:
    # 1) create unique target
    now = time.strftime("%Y%m%d-%H%M%S")
    tgt_name = f"scan-{host}-{now}"
    tgt = gmp.create_target(name=tgt_name, hosts=[host], port_list_id=port_list_id)
    tgt_id = tgt.get("id")

    # 2) create task
    task = gmp.create_task(
        name=f"Scan {host}",
        config_id=scan_config_id,
        target_id=tgt_id,
        scanner_id=scanner_id
    )
    task_id = task.get("id")

    # 3) start and grab report_id
    resp = gmp.start_task(task_id)
    report_id = resp[0].text
    print(f"  ↳ host={host} task={task_id} report={report_id}")
    return report_id


def wait_for_reports(
    gmp: Gmp, report_ids: List[str], interval: int
) -> None:
    remaining = set(report_ids)
    while remaining:
        time.sleep(interval)
        done = []
        resp = gmp.get_reports(
            ignore_pagination=True,
            details=True,
            filter_string="rows=-1 status=Running"
        )
        running = {r.get("id") for r in resp.xpath("report")}
        for rid in list(remaining):
            if rid not in running:
                done.append(rid)
                remaining.remove(rid)
        print(f"[+] {len(done)} done, {len(remaining)} remaining")
    print("[*] All scans completed.")


def export_pdf(
    gmp: Gmp, report_id: str, output_dir: Path
) -> None:
    fmt = "c402cc3e-b531-11e1-9163-406186ea4fc5"  # PDF format
    resp = gmp.get_report(
        report_id=report_id,
        report_format_id=fmt,
        ignore_pagination=True, details=True
    )
    elt = resp.find("report")
    data = elt.find("report_format").tail
    if not data:
        print(f"[!] report {report_id} empty or no PDF support")
        return
    pdf = b64decode(data.encode("ascii"))
    fn = output_dir / f"{report_id}.pdf"
    fn.write_bytes(pdf)
    print(f"[+] PDF written: {fn}")


def main(gmp: Gmp, args: Namespace) -> None:
    parsed = parse_args()
    outdir = Path(parsed.output_dir).expanduser()
    outdir.mkdir(parents=True, exist_ok=True)

    # find default scanner
    scanners = gmp.get_scanners().xpath("scanner")
    scanner_id = scanners[0].get("id")  # zwykle OpenVAS Default

    print(f"[*] Starting scans for {parsed.hosts}")
    reports: Dict[str,str] = {}
    for host in parsed.hosts:
        rid = create_target_and_task(
            gmp, host,
            parsed.port_list,
            parsed.scan_config,
            scanner_id
        )
        reports[host] = rid

    print("[*] Waiting for all scans to finish…")
    wait_for_reports(gmp, list(reports.values()), parsed.poll_interval)

    print("[*] Exporting PDFs…")
    for rid in reports.values():
        export_pdf(gmp, rid, outdir)

    print("[✓] Done.")


if __name__ == "__gmp__":
    main(gmp, args)

