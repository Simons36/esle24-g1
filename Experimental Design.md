## **Summary of Factors and Levels**

| **Factor**                    | **Level 1**              | **Level 2**                |
|------------------------       |--------------------------|----------------------------|
| **Number of Tservers**        | 3                        | 5                          |
| **CPU/RAM by VM** | **Instance type:** `n1-standard-2`<br>**vCPUs:** 2<br>**Memory:** 7.5 Gb| **Instance type:** `n1-standard-8`<br>**vCPUs:** 8<br>**Memory:** 30 Gb |
| **Number of Shards /p Table** | 1                        | 3                          |
| **Consistency Level**         | Snapshot               | Read Committed       |
| **Workload Type**             | Read-Only                | Write-Only                 |
| **Operation Size**            | 1 row p/ Operation                   | 100 rows p/ Operation                          |

## Number of Experiments

Number of experiments is calculated with the following formula: $n^kr$, being:

- **$n$:** Number of levels
- **$k$:** Number of factors
- **$r$:** Number of replications (number of repeated tests done, to minimize experimental error)

Using the above table we have:

- **$n=2$** 
- **$k=6$**

Therefore, if we test all the levels for all the factors, we will have **$64 \cdot r$** tests to do; **this number is too high.**

## Proposed Experimental Design

### $2^{k-p}$ Fractional Factorial Design

In order to reduce the high number of required experiments ($64\cdot r$), we propose a **fractional factorial design**, where we can reduce the number of experiments, by _cofounding_ (combining) several factors into one.

The number of experiments in a fractional factorial design is calculated by the expression **$2^{k-p}$**, where **$p$** represents the number of factors that are cofounded.

#### Value of $p$

We were thinking about using 2 as the value of $p$, making the number of total experiments equal to **$2^4=16$**. (Ver com Bia e João)

### Sign Table

| Runs | Operation Size (A) | Workload Type (B) | Nr. of TServers (C) | Consistency Level (D) | Nr. of Shards p/ Table (E = B × C) | CPU/RAM p/ VM (F = A × B) |
|------|---------------------|--------------------|----------------------|-----------------------|------------------------------------|---------------------------|
| 1    | -1                  | -1                 | -1                   | -1                    | 1                                  | 1                         |
| 2    | -1                  | -1                 | -1                   | 1                     | 1                                  | 1                         |
| 3    | -1                  | -1                 | 1                    | -1                    | -1                                 | 1                         |
| 4    | -1                  | -1                 | 1                    | 1                     | -1                                 | 1                         |
| 5    | -1                  | 1                  | -1                   | -1                    | -1                                 | -1                        |
| 6    | -1                  | 1                  | -1                   | 1                     | -1                                 | -1                        |
| 7    | -1                  | 1                  | 1                    | -1                    | 1                                  | -1                        |
| 8    | -1                  | 1                  | 1                    | 1                     | 1                                  | -1                        |
| 9    | 1                   | -1                 | -1                   | -1                    | 1                                  | -1                        |
| 10   | 1                   | -1                 | -1                   | 1                     | 1                                  | -1                        |
| 11   | 1                   | -1                 | 1                    | -1                    | -1                                 | -1                        |
| 12   | 1                   | -1                 | 1                    | 1                     | -1                                 | -1                        |
| 13   | 1                   | 1                  | -1                   | -1                    | -1                                 | 1                         |
| 14   | 1                   | 1                  | -1                   | 1                     | -1                                 | 1                         |
| 15   | 1                   | 1                  | 1                    | -1                    | 1                                  | 1                         |
| 16   | 1                   | 1                  | 1                    | 1                     | 1                                  | 1                         |

### Corrected Sign Table

| Runs | Operation Size (A)   | Workload Type (B) | Nr. of TServers (C) | Consistency Level (D) | Nr. of Shards p/ Table (E) | CPU/RAM p/ VM (F)                       |
|------|-----------------------|--------------------|----------------------|-----------------------|-----------------------------|------------------------------------------|
| 1    | 1 row p/ Operation    | Read-Only          | 3                    | Snapshot              | 3                           | `n1-standard-2`|
| 2    | 1 row p/ Operation    | Read-Only          | 3                    | Read Committed        | 3                           | `n1-standard-2`|
| 3    | 1 row p/ Operation    | Read-Only          | 5                    | Snapshot              | 1                           | `n1-standard-2`|
| 4    | 1 row p/ Operation    | Read-Only          | 5                    | Read Committed        | 1                           | `n1-standard-2`|
| 5    | 1 row p/ Operation    | Write-Only         | 3                    | Snapshot              | 1                           | `n1-standard-8`|
| 6    | 1 row p/ Operation    | Write-Only         | 3                    | Read Committed        | 1                           | `n1-standard-8`|
| 7    | 1 row p/ Operation    | Write-Only         | 5                    | Snapshot              | 3                           | `n1-standard-8`|
| 8    | 1 row p/ Operation    | Write-Only         | 5                    | Read Committed        | 3                           | `n1-standard-8`|
| 9    | 100 rows p/ Operation  | Read-Only          | 3                    | Snapshot              | 3                           | `n1-standard-8` |
| 10   | 100 rows p/ Operation  | Read-Only          | 3                    | Read Committed        | 3                           | `n1-standard-8` |
| 11   | 100 rows p/ Operation  | Read-Only          | 5                    | Snapshot              | 1                           | `n1-standard-8` |
| 12   | 100 rows p/ Operation  | Read-Only          | 5                    | Read Committed        | 1                           | `n1-standard-8` |
| 13   | 100 rows p/ Operation  | Write-Only         | 3                    | Snapshot              | 1                           | `n1-standard-2` |
| 14   | 100 rows p/ Operation  | Write-Only         | 3                    | Read Committed        | 1                           | `n1-standard-2` |
| 15   | 100 rows p/ Operation  | Write-Only         | 5                    | Snapshot              | 3                           | `n1-standard-2` |
| 16   | 100 rows p/ Operation  | Write-Only         | 5                    | Read Committed        | 3                           | `n1-standard-2` |
