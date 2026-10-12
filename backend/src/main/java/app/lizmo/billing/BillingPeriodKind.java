package app.lizmo.billing;

/**
 * What a billing period is for.
 *
 * <p>Rent for a month, or the security deposit. Both are owed, paid, declared
 * and confirmed the same way, which is the point of their sharing a table.
 * They differ in what they mean afterwards: rent is the landlord's income, and
 * a deposit is money they are holding and will give back. So everything that
 * adds up rent -- collections, the rent roll, arrears -- leaves deposits out.
 */
public enum BillingPeriodKind {
    RENT,
    DEPOSIT
}
