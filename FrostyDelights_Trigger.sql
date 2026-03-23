USE FrostyDelightsDB;
GO
-- drop trigger if it already exists so we can recreate it cleanly, so wedont get an error
IF OBJECT_ID(N'dbo.trg_Product_PriceUpdate', N'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Product_PriceUpdate;
GO

/*
    I used AFTER INSERT, UPDATE so I can directly use BasePrice from inserted.
    Then I join with Product and TaxBracket and update values in one step. I handled recursion because trigger updates the same table. I used set-based update to handle single row as well as multiple rows. 
*/
CREATE TRIGGER dbo.trg_Product_PriceUpdate
ON dbo.Product
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- avoid recursive execution because this trigger performs an UPDATE internally
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- considered checking UPDATE(BasePrice) to avoid extra work, but  INSERT also needs calculation, using set-based update so it works for single row as well as multiple rows
    IF NOT UPDATE(BasePrice)
        RETURN;

     -- considered checking UPDATE(BasePrice) to avoid extra work, but  INSERT also needs calculation, using set-based update so it works for single row as well as multiple rows
    UPDATE p
    -- assign correct tax bracket based on new base price range
    SET
        p.TaxBracketID = tb.TaxBracketID,
        -- calculate tax amount using tax rate from matched bracket and rounded to 2 decimal places for currency format
        p.TaxAmount    = ROUND(i.BasePrice * tb.TaxRate, 2),
        -- calculate final price by adding base price and tax amount and rounded to 2 decimal places for currency format
        p.FinalPrice   = ROUND(i.BasePrice + ROUND(i.BasePrice * tb.TaxRate, 2), 2)
    FROM dbo.Product AS p
    -- Here join inserted table to get new base price so we can calculate tax amount and final price
    INNER JOIN inserted AS i
        ON p.ProductCode = i.ProductCode
    -- join with tax bracket table to find correct bracket using price range
    -- use inclusive min/max price range to find correct bracket
    INNER JOIN dbo.TaxBracket AS tb
        ON i.BasePrice >= tb.MinPrice
       AND i.BasePrice <= tb.MaxPrice;
END;
GO

-- TEST CASE 1 — Update the base price of ‘Classic Vanilla’ (FD-001) from $3.50 to $3.75. Since both prices fall within the Economy bracket ($0–$3.99), the TaxBracketID should remain the same, but TaxAmount and FinalPrice must be recalculated.


SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-001';

UPDATE dbo.Product SET BasePrice = 3.75 WHERE ProductCode = N'FD-001';

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-001';

UPDATE dbo.Product SET BasePrice = 3.50 WHERE ProductCode = N'FD-001';
GO

-- TEST CASE 2 — Update the base price of ‘Mango Tango’ (FD-008) from $4.00 to $7.50. Since $7.50 falls within the Premium bracket ($7.00–$9.99), the TaxBracketID should change to 3, and TaxAmount and FinalPrice must be recalculated.


SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-008';

UPDATE dbo.Product SET BasePrice = 7.50 WHERE ProductCode = N'FD-008';

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-008';

UPDATE dbo.Product SET BasePrice = 4.00 WHERE ProductCode = N'FD-008';
GO

-- TEST CASE 3 — Apply a 20% price increase to all products in the ‘Classic’ category. This will affect multiple rows at once and may cause some products to shift brackets.

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE Category = N'Classic' ORDER BY ProductCode;

UPDATE dbo.Product SET BasePrice = BasePrice * 1.20 WHERE Category = N'Classic';

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE Category = N'Classic' ORDER BY ProductCode;

UPDATE dbo.Product SET BasePrice = 3.50 WHERE ProductCode = N'FD-001';
UPDATE dbo.Product SET BasePrice = 3.75 WHERE ProductCode = N'FD-002';
UPDATE dbo.Product SET BasePrice = 4.50 WHERE ProductCode = N'FD-005';
UPDATE dbo.Product SET BasePrice = 4.25 WHERE ProductCode = N'FD-011';
UPDATE dbo.Product SET BasePrice = 3.99 WHERE ProductCode = N'FD-015';
GO

-- TEST CASE 4 — Insert a brand new product. Your trigger should automatically populate TaxBracketID, TaxAmount, and FinalPrice based on the BasePrice.


IF EXISTS (SELECT 1 FROM dbo.Product WHERE ProductCode = N'FD-026')
    DELETE FROM dbo.Product WHERE ProductCode = N'FD-026';

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-026';

INSERT INTO dbo.Product (ProductCode, ProductName, Category, BasePrice)
VALUES (N'FD-026', N'Salted Caramel Swirl', N'Specialty', 6.00);

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-026';

DELETE FROM dbo.Product WHERE ProductCode = N'FD-026';
GO

-- TEST CASE 5 — Update a product’s price to exactly $4.00 (the boundary between Economy and Standard). Verify it lands in the correct bracket.

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-001';

UPDATE dbo.Product SET BasePrice = 4.00 WHERE ProductCode = N'FD-001';

SELECT ProductCode, ProductName, BasePrice, TaxBracketID, TaxAmount, FinalPrice
FROM dbo.Product WHERE ProductCode = N'FD-001';

UPDATE dbo.Product SET BasePrice = 3.50 WHERE ProductCode = N'FD-001';
GO
