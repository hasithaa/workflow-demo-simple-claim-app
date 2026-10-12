-- The claims the workflow records at every step; the employee portal lists them.
USE claims;
CREATE TABLE IF NOT EXISTS claims (
    claim_id     VARCHAR(64)    PRIMARY KEY,
    workflow_id  VARCHAR(255),
    employee     VARCHAR(255)   NOT NULL,
    description  VARCHAR(255)   NOT NULL,
    amount       DECIMAL(12, 2) NOT NULL,
    status       VARCHAR(16)    NOT NULL,
    bill_name    VARCHAR(255),
    bill_url     VARCHAR(512),
    comment      VARCHAR(512),
    submitted_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Ann's earlier claims, so the portal is not empty on first sign-in.
INSERT IGNORE INTO claims (claim_id, employee, description, amount, status, bill_name, bill_url, comment, submitted_at, updated_at)
VALUES
    ('CLM-20417', 'ann@example.com', 'Taxi to the airport', 38.40, 'APPROVED', 'taxi-receipt.png',
        '/files/seed/taxi-receipt.png', 'Thanks Ann', NOW() - INTERVAL 21 DAY, NOW() - INTERVAL 20 DAY),
    ('CLM-31986', 'ann@example.com', 'Conference ticket', 690.00, 'REJECTED', 'ticket-invoice.png',
        '/files/seed/ticket-invoice.png', 'Please book this through the training budget', NOW() - INTERVAL 9 DAY,
        NOW() - INTERVAL 8 DAY);
