"""O03 bulk-job quotas: per-request ceilings for synchronous bulk writes.

Each bulk endpoint writes inside one request transaction, so its size bounds
lock time, memory and the latency every other tenant on the worker sees.  The
ceilings sit well above a realistic section, class or staff roster; a request
over a ceiling is rejected before any write rather than partially applied.
"""

# Students marked in one attendance register or one exam paper.
BULK_ROSTER_MAX_ENTRIES = 500

# Teachers marked in one staff attendance save.
BULK_STAFF_MAX_ENTRIES = 500

# Students invoiced by one class-wide bulk issuance.
BULK_INVOICE_MAX_STUDENTS = 1000
