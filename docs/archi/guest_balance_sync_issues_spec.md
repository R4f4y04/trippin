# Guest Personal Balance & Splitting Constraints Spec

## 1. Context & Overview
During P2P multi-device testing with a host (`wasay`) and a guest (`r4`), the ledger synchronizes correctly, updating total spent across both devices. However, severe inconsistencies were observed regarding:
- **Personal Balance ("Your Balance" field)**: The guest device displays a flat balance of `₨ 0` regardless of splits or payments, while the host balance updates correctly.
- **Form Controls for Guest Role**: Guest devices retain the ability to select the host or other members as the payer when creating an expense.

This document logs these findings, traces the expected behavior, and sets the criteria for resolving these sync imbalance issues.

---

## 2. Testing Log Summary

### Participant Roles
- **Host**: `wasay` (Device Owner of the Host Device)
- **Guest**: `r4` (Device Owner of the Guest Device)

### Test Run Steps & Findings

1. **Step 1: Host-Added Expense**
   - **Action**: Host (`wasay`) adds an expense of **₨ 1,000**, paid by `wasay`, split equally between `wasay` and `r4`.
   - **Result**: 
     - Total Spent updates to **₨ 1,000** on both devices (Correct).
     - Host (`wasay`) balance shows **+₨ 500** (Correct).
     - Guest (`r4`) balance shows **₨ 0** (Incorrect - should be **-₨ 500**).

2. **Step 2: Guest-Added Expense**
   - **Action**: Guest (`r4`) adds an expense of **₨ 2,500** on the guest device.
   - **Result**:
     - Total Spent updates to **₨ 3,500** on both devices (Correct).
     - Host (`wasay`) balance updates to **-₨ 750** (Correct: $+500 - 1250$).
     - Guest (`r4`) balance shows **₨ 0** (Incorrect - should be **+₨ 750** ($ -500 + 1250 $)).
     - **UI Issue**: The guest's "Add Expense" form allows picking `wasay` as the payer.

3. **Step 3: Handshake Guest Expense on Host**
   - **Action**: Guest (`r4`) adds an expense of **₨ 700** on the host (`wasay`) device (paid by `r4`).
   - **Result**:
     - Total Spent updates to **₨ 4,200** on both devices (Correct).
     - Host (`wasay`) balance updates to **-₨ 1,100** (Correct: $-750 - 350$).
     - Guest (`r4`) balance shows **₨ 0** (Incorrect - should be **+₨ 1,100**).

---

## 3. Problems Identified

### Problem A: Guest Balance is Frozen at `₨ 0`
While total ledger sums are synced, the guest device fails to compute and display its local device owner's net position. 

### Problem B: Incomplete Guest UI Gating on Payer Inputs
Under P2P conditions, a guest should only be allowed to submit expenses they have paid themselves. Currently, the guest UI permits selecting the host or other trip members in the payer dropdown, which violates guest role permissions and poses ledger collision risks.

---

## 4. Expected Behaviors & Resolution Criteria

1. **Opposite and Equal Balance Updates**: 
   Every split expense transaction must dynamically modify both the payer's positive balance (amount owed to them) and all other beneficiaries' negative balances (amount they owe). If host balance is `-₨ X`, guest balance must be `+₨ X`.
   
2. **Strict Form Gating**:
   On the Guest Device, the "Payer" selection when creating an expense must be locked to the guest device owner's identity. Guests must not be able to log expenses paid by others.
