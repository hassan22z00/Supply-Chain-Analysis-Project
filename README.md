# Supply-Chain-Analysis-Project
# Procurement Process Intelligence & Invoice Monitoring

( An end-to-end procurement analytics portfolio project using the real BPI Challenge 2019 event log )

This independent project examines purchase-order-item processing, invoice receipt and clearing, process variants, and procurement event patterns. It combines Python-based data preparation, PostgreSQL analytics, and a Power BI reporting layer to turn a large event log into operationally interpretable measures.

**Project status:** Python analysis, PostgreSQL data model and SQL analytics, and Power BI dashboard are implemented by the author. The repository contains the documented analytical results from the completed work. SAP S/4HANA / ABAP and Celonis are not presented as completed integrations or implemented components.


## Executive summary

The analysis uses a case-level time-window scope from the BPI Challenge 2019 event log. A case represents a **purchase-order item**, not a purchase-order header.

Measure | Result | Definition / population 

| Included purchase-order-item cases | **251,463** | Whole cases retained in the selected date window |
| Included events | **1,587,802** | All events belonging to the retained cases |
| Distinct activities | **42** | Observed activity labels in the analytical scope |
| Distinct process variants | **13,810** | Sequences ordered by timestamp, with source-row order as a deterministic tie-breaker |
| Cases with invoice receipt recorded | **211,113** | Cases containing `Record Invoice Receipt` |
| Cases cleared after invoice receipt | **183,009** | Both events exist and first clearing timestamp is later than first invoice-receipt timestamp |
| No recorded clearing event | **28,081** | Invoice-receipt cases without a `Clear Invoice` event in the log |
| Median invoice-receipt-to-clearing time | **42.07 days** | 183,009 correctly ordered cases |
| P90 invoice-receipt-to-clearing time | **97.13 days** | 183,009 correctly ordered cases |
| More than 30 days | **114,689 (62.67%)** | Denominator: 183,009 cases with a valid positive cycle time |

**Main finding:** invoice processing after recorded invoice receipt is the longest measured stage among the four transitions examined. The median interval is 42.07 days and the 90th percentile is 97.13 days. This is a descriptive finding from the event log—not proof of an SLA breach, late payment, or non-compliance.

## Business problem

A procurement process owner needs visibility into how purchase-order items move through the purchase-to-pay (P2P) process. The event log contains many different activity sequences and repeated events, so a static count of purchase orders is not enough.

The source challenge distinguishes four matching flows: three-way matching with invoice after goods receipt; three-way matching where the invoice can arrive before goods receipt but remains blocked until required checks; two-way matching without a goods-receipt requirement; and consignment, where PO-level invoicing is handled separately. This project version focuses on observed activity sequences and invoice-cycle timing; it does not yet perform full item-category-specific, amount-level reconciliation across multiple partial invoices and receipts.

This project addresses five practical questions:

1. **Process visibility:** What activities and process variants occur most frequently?
2. **Invoice throughput:** How long does it take from the first recorded invoice-receipt event to the first subsequent invoice-clearing event?
3. **Open / unobserved outcomes:** How many invoice-receipt cases have no recorded clearing event in the available log?
4. **Control and exception signals:** How often do payment-block removal, price changes, quantity changes, cancellations, and deletions appear?
5. **Segmentation:** How do invoice-processing measures vary by anonymized company and procurement attributes?

## Dataset and provenance

- [Official dataset record / citation](https://doi.org/10.4121/uuid:d06aff4b-79f0-45e6-8ec8-e19730c248f1)
- [Eindhoven University of Technology dataset description](https://research.tue.nl/en/datasets/bpi-challenge-2019/)
- [ICPM 2019 BPI Challenge page (includes a link to the CSV version and the original challenge questions)](https://icpmconference.org/2019/icpm-2019/contests-challenges/bpi-challenge-2019/)

## Key performance indicators
| KPI | Value | Calculation |
|---|---:|---|
| Invoice-receipt cases | 211,113 | Distinct cases containing `Record Invoice Receipt` |
| Cleared after receipt | 183,009 | First `Clear Invoice` timestamp > first `Record Invoice Receipt` timestamp |
| No recorded clearing | 28,081 | Invoice-receipt cases with no `Clear Invoice` event |
| Clearing not after receipt | 23 | A clearing event exists, but its first timestamp is equal to or earlier than invoice receipt |
| No-recorded-clearing rate | 13.30% | 28,081 / 211,113 |
| Median cycle time | 42.07 days | Median of positive receipt-to-clearing intervals |
| P90 cycle time | 97.13 days | 90th percentile of positive receipt-to-clearing intervals |
| P95 cycle time | 107.15 days | 95th percentile of positive receipt-to-clearing intervals |
| More than 30 days | 114,689 (62.67%) | Of 183,009 valid ordered cases |
| More than 60 days | 59,912 (32.74%) | Of 183,009 valid ordered cases |
| More than 90 days | 24,106 (13.17%) | Of 183,009 valid ordered cases |

## Business insights and interpretation

### 1. Invoice processing is the longest measured stage

The median from first recorded invoice receipt to first subsequent clearing is 42.07 days. P90 is 97.13 days, and 62.67% of valid ordered cases exceed 30 days. This makes the post-receipt stage a strong candidate for further investigation.

**Business follow-up:** segment the interval by document type, spend area, purchasing category, and matching requirement; then validate the relevant payment terms and internal service-level targets before labelling any case late.

### 2. Missing clearing events need a separate review queue

There are 28,081 invoice-receipt cases without a recorded `Clear Invoice` event. The event log alone cannot establish whether these invoices were unpaid, paid outside the captured process, or still open at the end of observation.

**Business follow-up:** distinguish genuinely open cases from cases with incomplete event capture, and reconcile against a verified payment-status or accounting source before making payment claims.

### 3. Company-level differences are strongly affected by sample size

| Company | Invoice-receipt cases | No recorded clearing | Valid cleared cases | Median days | P90 days |
|---|---:|---:|---:|---:|---:|
| companyID_0000 | 210,442 | 27,700 (13.16%) | 182,719 | 42.09 | 97.13 |
| companyID_0003 | 670 | 381 (56.87%) | 289 | 5.25 | 22.01 |
| companyID_0001 | 1 | 0 (0.00%) | 1 | 7.89 | 7.89 |

Company `0000` represents nearly all invoice-receipt cases in this cohort. Company `0003` has a high no-recorded-clearing percentage but a much smaller sample and only 289 valid cleared cases. Company `0001` has one case and should not be used for performance comparison.

**Business follow-up:** validate sample size, document mix, process coverage, and event completeness before comparing company performance.

### 4. Payment-block removal is usually followed by clearing

Among 50,521 cases containing both payment-block removal and invoice clearing, 49,105 have removal earlier than clearing (97.20%). The median interval for this ordered subset is 28.90 days and P90 is 93.04 days.

**Business follow-up:** investigate what causes long post-release intervals and whether additional approval, accounting, or payment steps are represented in the event log. The result does not establish that the payment block caused the entire delay.

### 5. Repeated service-entry events deserve a closer look

`Record Service Entry Sheet` occurs 163,427 times but affects 5,566 cases (2.21% of cases). This indicates repeated event capture within a relatively small set of cases and warrants a focused review of service-related purchasing flows.

### 6. Process paths are highly varied

There are 13,810 distinct variants. The most common variant accounts for 20.00% of cases, while the top five account for 45.15%. Process execution is therefore not represented by a single dominant path.

**Business follow-up:** compare variants within the same item category and document type before interpreting a path as exceptional.

## Tools and technologies actually used

| Tool | Use in this project |
|---|---|
| Python | Data extraction, timestamp normalization, case-level filtering, process sequence analysis, data quality checks |
| pandas / NumPy | Chunked CSV processing, grouping, case-level feature engineering and KPI calculations |
| PostgreSQL | Relational model, foreign keys, indexes, SQL views and validation queries |
| SQL | Aggregation, joins, filtered counts, percentile measures and process timing analysis |
| Power BI Desktop | Interactive procurement and invoice-processing report |
| Power Query | Importing and typing the prepared Parquet tables |
| DAX | Dynamic KPI measures and report calculations |
| Jupyter Notebook | Iterative analysis and validation |

## Architecture

flowchart TD
    A[Official BPI Challenge 2019 CSV] --> B[Python / pandas chunked extraction]
    B --> C[Timestamp parsing and case-level scope]
    C --> D[Parquet data products]
    D --> E[PostgreSQL]
    E --> F[Case dimension]
    E --> G[Event fact]
    E --> H[Invoice monitoring mart]
    F --> I[Power BI model]
    G --> J[Procurement Overview]
    H --> K[Invoice Processing]
    I --> L[Process Analysis]

## Power BI report

The implemented report has three pages:

1. **Procurement Overview** — case volume, event volume, invoice cohort, no-recorded-clearing rate, spend-area distribution and clearing-status split.
2. **Invoice Processing** — median, P90, aging thresholds, company comparison and payment-block timing.
3. **Process Analysis** — activity frequency, affected-case coverage, process-variant summary and event-sequence analysis.

## Data quality and validation

The ETL output validation passed all 13 checks in the completed run:

- 1,587,802 event rows written.
- 1,587,802 unique source-row positions.
- 251,463 unique cases in the event table.
- 251,463 case-dimension rows and unique case IDs.
- Case-level event counts sum to 1,587,802.
- 211,113 rows in the invoice monitoring mart.
- 183,009 cleared-after-receipt cases.
- 28,081 cases without a recorded clearing event.
- 23 cases where clearing was not strictly after receipt.
- No missing event timestamps or case IDs in the processed event table.
- No event cases outside the case dimension.

Small cross-tool precision differences remain documented: the Python reference median for payment-block-removal-to-clearing is 28.90 days, while the PostgreSQL view returned 28.92 days; for companyID_0003, the Python P90 was 22.00 days and PostgreSQL returned 22.01 days. These small differences should be reconciled before claiming exact cross-tool parity.
