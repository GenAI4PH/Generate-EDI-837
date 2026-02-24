import csv
import os
import random
import datetime
from pathlib import Path

EDI_INPUT = r"\\Generate_EDI\Sample EDI\Sample_837P.txt"
SUBSCRIBER_CSV = r"\\Generate_EDI\Support Data\Subscribers.csv"
OUTPUT_DIR = r"\\Generate_EDI\Sample EDI\Output"

SEG_TERM = "~"
ELM_SEP = "*"

DIAG_CODES = ["J10", "E11", "I10", "M54", "R51"]
PROC_CODES = ["99213", "99214", "87070", "93000"]
CHARGE_RANGE = (60, 180)


def load_subscribers(path):
    subs = []
    with open(path, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            r["BirthDate"] = datetime.datetime.strptime(r["BirthDate"], "%Y-%m-%d")
            subs.append(r)
    return subs


def synthetic_date():
    return (datetime.date.today() - datetime.timedelta(days=random.randint(1, 120))).strftime("%Y%m%d")


def process_edi(edi_text, sub):
    segments = edi_text.split(SEG_TERM)
    output = []

    in_subscriber_loop = False
    claim_total = 0

    for seg in segments:
        seg = seg.strip()
        if not seg:
            continue

        elements = seg.split(ELM_SEP)
        seg_id = elements[0].strip()   # 🔥 FIX

        # ---- HL LOOP DETECTION ----
        if seg_id == "HL" and len(elements) >= 4:
            in_subscriber_loop = (elements[3] == "22")

        # ---- SUBSCRIBER PHI ----
        if in_subscriber_loop and seg_id == "NM1" and elements[1] == "IL":
            elements[3] = sub["LastName"]
            elements[4] = sub["FirstName"]
            elements[5] = sub["MiddleInitial"]
            elements[-1] = f"SUB{random.randint(100000,999999)}"

        elif in_subscriber_loop and seg_id == "N3":
            elements[1] = sub["Street1"]
            if len(elements) > 2:
                elements[2] = sub.get("Street2", "")

        elif in_subscriber_loop and seg_id == "N4":
            elements[1] = sub["City"]
            elements[2] = sub["State"]
            elements[3] = sub["ZipCode"]

        elif in_subscriber_loop and seg_id == "DMG":
            elements[2] = sub["BirthDate"].strftime("%Y%m%d")
            elements[3] = sub["Gender"]

        # ---- CLAIM / CLINICAL ----
        elif seg_id == "CLM":
            claim_total = 0
            elements[2] = "0"

        elif seg_id == "HI":
            elements[1] = f"ABK:{random.choice(DIAG_CODES)}"

        elif seg_id == "SV1":
            charge = random.randint(*CHARGE_RANGE)
            claim_total += charge
            elements[1] = f"HC:{random.choice(PROC_CODES)}"
            elements[2] = str(charge)
            elements[4] = "1"

        elif seg_id == "DTP" and elements[1] == "472":
            elements[3] = synthetic_date()

        output.append(ELM_SEP.join(elements))

    # ---- FIX CLAIM TOTAL ----
    for i, s in enumerate(output):
        if s.startswith("CLM"):
            p = s.split(ELM_SEP)
            p[2] = str(claim_total)
            output[i] = ELM_SEP.join(p)

    return SEG_TERM.join(output) + SEG_TERM


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    subscribers = load_subscribers(SUBSCRIBER_CSV)
    subscriber = random.choice(subscribers)

    with open(EDI_INPUT, "r", encoding="utf-8") as f:
        edi_text = f.read()

    new_edi = process_edi(edi_text, subscriber)

    out_file = Path(OUTPUT_DIR) / "Converted_837P.txt"
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(new_edi)

    print("✅ PHI replacement SUCCESSFUL")
    print(f"📄 Output file: {out_file}")


if __name__ == "__main__":
    main()