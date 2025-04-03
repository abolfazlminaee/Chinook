# 1_ 10 آهنگ برتر که بیشترین درآمد را داشتند به همراه درآمد ایجاد شده
SELECT t.Name AS track_name, SUM(il.UnitPrice * il.Quantity) AS total_income
FROM Track t
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY t.TrackId
ORDER BY total_income DESC
LIMIT 10;
# 2_محبوب‌ترین ژانر به ترتیب از نظر تعداد آهنگ‌های فروخته شده و کل درآمد
SELECT g.Name AS genre_name, 
       COUNT(il.TrackId) AS total_tracks_sold, 
       SUM(il.UnitPrice * il.Quantity) AS total_income
FROM Genre g
JOIN Track t ON g.GenreId = t.GenreId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY g.GenreId
ORDER BY total_tracks_sold DESC, total_income DESC;
#3_کاربرانی که تاکنون خرید نداشتند
SELECT c.FirstName, c.LastName
FROM Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId
WHERE i.InvoiceId IS NULL;
#4_میانگین زمان آهنگ‌ها در هر آلبوم
SELECT a.Title AS album_title, 
       AVG(t.Milliseconds) AS average_track_length
FROM Album a
JOIN Track t ON a.AlbumId = t.AlbumId
GROUP BY a.AlbumId;
#5_کارمندی که بیشترین تعداد فروش را داشته است
SELECT e.FirstName, e.LastName, COUNT(i.InvoiceId) AS total_sales
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId
ORDER BY total_sales DESC
LIMIT 1;
#6_کاربرانی که از بیش از یک ژانر خرید کردند
SELECT c.FirstName, c.LastName
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
JOIN Track t ON il.TrackId = t.TrackId
GROUP BY c.CustomerId
HAVING COUNT(DISTINCT t.GenreId) > 1;
#7_سه آهنگ برتر از نظر درآمد فروش برای هر ژانر
WITH RankedTracks AS (
    SELECT t.Name AS track_name,
           g.Name AS genre_name,
           SUM(il.UnitPrice * il.Quantity) AS total_income,
           ROW_NUMBER() OVER (PARTITION BY g.GenreId ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS track_rank
    FROM Track t
    JOIN Genre g ON t.GenreId = g.GenreId
    JOIN InvoiceLine il ON t.TrackId = il.TrackId
    GROUP BY t.TrackId, g.GenreId
)
SELECT track_name, genre_name, total_income
FROM RankedTracks
WHERE track_rank <= 3;
#8_تعداد آهنگ‌های فروخته شده به صورت تجمعی در هر سال به صورت جداگانه
WITH TrackSales AS (
    SELECT YEAR(i.InvoiceDate) AS sale_year,
           SUM(il.Quantity) AS total_tracks_sold
    FROM Invoice i
    JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
    GROUP BY YEAR(i.InvoiceDate)
)
SELECT sale_year,
       total_tracks_sold,
       SUM(total_tracks_sold) OVER (ORDER BY sale_year) AS cumulative_tracks_sold
FROM TrackSales
ORDER BY sale_year;
#9_کاربرانی که مجموع خریدشان بالاتر از میانگین مجموع خرید تمام کاربران است
WITH TotalPurchases AS (
    SELECT c.CustomerId, 
           SUM(il.UnitPrice * il.Quantity) AS total_spent
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
    GROUP BY c.CustomerId
),
AveragePurchase AS (
    SELECT AVG(total_spent) AS avg_spent FROM TotalPurchases
)
SELECT c.FirstName, c.LastName, tp.total_spent
FROM TotalPurchases tp
JOIN Customer c ON tp.CustomerId = c.CustomerId
WHERE tp.total_spent > (SELECT avg_spent FROM AveragePurchase);
