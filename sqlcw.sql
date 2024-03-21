DROP VIEW IF EXISTS vNoCustomerEmployee; 
DROP VIEW IF EXISTS v10MostSoldMusicGenres; 
DROP VIEW IF EXISTS vTopAlbumEachGenre; 
DROP VIEW IF EXISTS v20TopSellingArtists; 
DROP VIEW IF EXISTS vTopCustomerEachGenre; 

/*
============================================================================
Task 1: Complete the query for vNoCustomerEmployee.
DO NOT REMOVE THE STATEMENT "CREATE VIEW vNoCustomerEmployee AS"
============================================================================
*/

CREATE VIEW vNoCustomerEmployee AS
SELECT emp.EmployeeId, emp.FirstName, emp.LastName, emp.Title
FROM employees emp
LEFT JOIN customers cust ON emp.EmployeeId = cust.SupportRepId
WHERE cust.CustomerId IS NULL;

/*
============================================================================
Task 2: Complete the query for v10MostSoldMusicGenres
DO NOT REMOVE THE STATEMENT "CREATE VIEW v10MostSoldMusicGenres AS"
============================================================================
*/

CREATE VIEW v10MostSoldMusicGenres AS
SELECT sub.Genre, sub.Sales
FROM (
    SELECT g.Name AS Genre, SUM(ii.Quantity) AS Sales
    FROM genres g
    INNER JOIN tracks t ON g.GenreId = t.GenreId
    INNER JOIN invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY g.Name
) sub
ORDER BY sub.Sales DESC
LIMIT 10;

/*
============================================================================
Task 3: Complete the query for vTopAlbumEachGenre
DO NOT REMOVE THE STATEMENT "CREATE VIEW vTopAlbumEachGenre AS"
============================================================================
*/

CREATE VIEW vTopAlbumEachGenre AS
SELECT g.Name AS Genre, al.Title AS Album,ar.Name AS Artist,sub.Sales
FROM (
    SELECT t.GenreId, t.AlbumId, SUM(ii.Quantity) AS Sales, 
    MAX(SUM(ii.Quantity)) OVER (PARTITION BY t.GenreId) AS MaxSales
    /* window function determines the maximum quantity sold per genre, 
    ’PARTITION BY‘ensuring the sales sum is computed and compared within each distinct genre.*/
    FROM tracks t
    JOIN invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY t.GenreId, t.AlbumId
    ) AS sub
JOIN albums al ON sub.AlbumId = al.AlbumId
JOIN genres g ON sub.GenreId = g.GenreId
JOIN artists ar ON al.ArtistId = ar.ArtistId
WHERE sub.Sales = sub.MaxSales;


/*
============================================================================
Task 4: Complete the query for v20TopSellingArtists
DO NOT REMOVE THE STATEMENT "CREATE VIEW v20TopSellingArtists AS"
============================================================================
*/

CREATE VIEW v20TopSellingArtists AS
SELECT sub.Artist, sub.TotalAlbum, sub.TrackSold
FROM (
    SELECT ar.Name AS Artist, COUNT(DISTINCT a.AlbumId) AS TotalAlbum, SUM(ii.Quantity) AS TrackSold
    FROM artists ar
    JOIN albums a ON ar.ArtistId = a.ArtistId
    JOIN tracks t ON a.AlbumId = t.AlbumId
    JOIN invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY ar.Name
) sub
ORDER BY sub.TrackSold DESC
LIMIT 20;



/*
============================================================================
Task 5: Complete the query for vTopCustomerEachGenre
DO NOT REMOVE THE STATEMENT "CREATE VIEW vTopCustomerEachGenre AS" 
============================================================================
*/

CREATE VIEW vTopCustomerEachGenre AS
SELECT g.Name AS Genre,(c.FirstName || ' ' || c.LastName) AS TopSpender,ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) AS TotalSpending

FROM invoice_items ii
JOIN invoices i ON ii.InvoiceId = i.InvoiceId
JOIN customers c ON i.CustomerId = c.CustomerId
JOIN tracks t ON ii.TrackId = t.TrackId
JOIN genres g ON t.GenreId = g.GenreId
GROUP BY g.GenreId, c.CustomerId
-- calculate the totalspending of each customer in each genre.
HAVING ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) = (
    SELECT MAX(TotalSpending)
    FROM (
        SELECT g.Name AS Genre,
               ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) AS TotalSpending
        FROM invoice_items ii
        JOIN invoices i ON ii.InvoiceId = i.InvoiceId
        JOIN customers c ON i.CustomerId = c.CustomerId
        JOIN tracks t ON ii.TrackId = t.TrackId
        JOIN genres g ON t.GenreId = g.GenreId
        GROUP BY g.GenreId, c.CustomerId
    ) AS subquery
    WHERE subquery.Genre = g.Name
)
ORDER BY g.Name ASC;
