/**************************************************************
	SP Name			    : USP_PlaceOrder
	Purpose		        : 
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	Modified            : Initial version
****************************************************************/

EXEC sp_rename 'uspPlaceOrder', 'USP_PlaceOrder';

CREATE PROCEDURE USP_PlaceOrder
    @PrescriptionId INT
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10,2);
    DECLARE @OrderId INT;
    DECLARE @PrescriptionExists INT;
    DECLARE @MedicineExists INT;
    DECLARE @StockIssue INT;

    -- Check if PrescriptionId exists
    SELECT @PrescriptionExists = PrescriptionId FROM Prescription WHERE PrescriptionId = @PrescriptionId;

    IF @PrescriptionExists IS NULL
    BEGIN
        PRINT ' Invalid PrescriptionId. No order placed.';
        RETURN;
    END;

    -- Check if there are medicines linked to the prescription
    SELECT @MedicineExists = PrescriptionId FROM PrescriptionDetails WHERE PrescriptionId = @PrescriptionId;

    IF @MedicineExists IS NULL
    BEGIN
        PRINT 'Error: No medicines found for the given PrescriptionId.';
        RETURN;
    END;

    -- Check if stock is available for all medicines
    SELECT @StockIssue = pd.PrescriptionId
    FROM PrescriptionDetails pd
    JOIN Medicine m ON pd.MedicineId = m.MedicineId
    WHERE pd.PrescriptionId = @PrescriptionId
    AND pd.Quantity > m.Stock;

    IF @StockIssue IS NOT NULL
    BEGIN
        PRINT 'Error: Not enough stock available for one or more medicines. Order cannot be placed.';
        RETURN;
    END;

    -- Calculate total cost of medicines in the prescription
    SELECT @TotalAmount = SUM(m.Price * pd.Quantity)
    FROM PrescriptionDetails pd
    INNER JOIN Medicine m ON pd.MedicineId = m.MedicineId
    WHERE pd.PrescriptionId = @PrescriptionId;

    -- Insert order
    INSERT INTO Orders (PrescriptionId, TotalAmount, PaymentStatus, OrderDate, CreatedAt)
    VALUES (@PrescriptionId, @TotalAmount, 'Pending', GETDATE(), GETDATE());

    -- Get the newly created OrderId
    SET @OrderId = SCOPE_IDENTITY();

    -- Insert order details
    INSERT INTO OrderDetails (OrderId, MedicineId, Quantity, Price, CreatedAt)
    SELECT @OrderId, pd.MedicineId, pd.Quantity, m.Price, GETDATE()
    FROM PrescriptionDetails pd
    JOIN Medicine m ON pd.MedicineId = m.MedicineId
    WHERE pd.PrescriptionId = @PrescriptionId;

    -- Update medicine stock after ordering
    UPDATE m
    SET m.Stock = m.Stock - pd.Quantity
    FROM Medicine m
    JOIN PrescriptionDetails pd ON m.MedicineId = pd.MedicineId
    WHERE pd.PrescriptionId = @PrescriptionId;

    PRINT 'Order placed successfully with OrderId: ' + CAST(@OrderId AS VARCHAR);
END;

select * from Orders
SELECT * FROM OrderDetails
select * from medicine
SELECT * FROM Prescription
SELECT * FROM PrescriptionDetails

EXEC uspPlaceOrder @PrescriptionId = 8

-----------------------------------------------------------------------
/* PAYMENT */

EXEC sp_rename 'uspConfirmPayment', 'USP_ConfirmPayment';

CREATE PROCEDURE USP_ConfirmPayment
    @OrderId INT
AS
BEGIN
    DECLARE @ExistingOrderId INT;

    -- Check if the OrderId exists
    SELECT @ExistingOrderId = OrderId FROM Orders WHERE OrderId = @OrderId;

    -- If OrderId does not exist, return an error message
    IF @ExistingOrderId IS NULL
    BEGIN
        PRINT 'Error: Order ID not found.';
        RETURN;
    END

    -- Update payment status to 'Paid'
    UPDATE Orders
    SET PaymentStatus = 'Paid'
    WHERE OrderId = @OrderId;

    PRINT 'Payment received. Order marked as Paid.';
END;


EXEC uspConfirmPayment @OrderId = 1;


-- Test Case 1: Valid Order Placement
-- Expected Result: Order should be placed successfully, stock should be updated, and entries should be made in Orders and OrderDetails tables.
EXEC USP_PlaceOrder @PrescriptionId = 1;

SELECT * FROM Orders WHERE PrescriptionId = 1;
SELECT * FROM OrderDetails WHERE OrderId IN (SELECT OrderId FROM Orders WHERE PrescriptionId = 1);
SELECT * FROM Medicine;

-- Test Case 2: Invalid PrescriptionId
-- Expected Result: Error message "Invalid PrescriptionId. No order placed."
EXEC USP_PlaceOrder @PrescriptionId = 999;

-- Test Case 3: Insufficient Stock
-- Expected Result: Error message "Error: Not enough stock available for one or more medicines. Order cannot be placed."
EXEC USP_PlaceOrder @PrescriptionId = 3; -- Ensure PrescriptionId 3 has a medicine with insufficient stock.

UPDATE Medicine
SET Stock = 0  -- Increase stock by 10
WHERE MedicineId = 1;   -- Update for a specific medicine


-- Test Case 5: Check Stock Update After Order Placement
-- Expected Result: Medicine stock should decrease after successful order placement.

select * from Orders
SELECT * FROM OrderDetails
select * from medicine
SELECT * FROM Prescription
SELECT * FROM PrescriptionDetails

-- Test Case 6: Check Payment Status
-- Expected Result: PaymentStatus should be 'Pending' after order placement.
EXEC USP_PlaceOrder @PrescriptionId = 5;
SELECT PaymentStatus FROM Orders WHERE PrescriptionId = 5;

