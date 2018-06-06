-- Create table for ECB exchange rates import, if it not exists.


-- Remark: For the "ExcDate" the data type "date" is used; this data type


--         is new in SQL Server version 2008.


--         If you want to use it in a version 2005, please modify it to "datetime"


IF OBJECT_ID('dbo.EcbDailyExchangeRates', 'U ') IS NULL   


    CREATE TABLE dbo.EcbDailyExchangeRates


        ( [ExcDate]  date NOT NULL


         ,[Currency] char(3) NOT NULL


         ,[Rate]     decimal(19, 6) NOT NULL


         ,CONSTRAINT [PK_EcbDailyExchangeRates] 


          PRIMARY KEY CLUSTERED 


             ( [ExcDate] ASC


              ,[Currency] ASC


             ) 


        );



　


-- Import of ECB Exchange Rates 


 


-- Load the XML file into a XML variable. 


-- Please modify the file name in OPENROWSET to meet your enviroment!!! 


DECLARE @ecb XML; 


SET @ecb = (SELECT CONVERT(xml, EcbSrc.BulkColumn) AS XmlRates 


            FROM OPENROWSET(BULK N'f:\Share\TaxlevelHBLPrd\EZB\eurofxref-hist.xml' 


                           ,SINGLE_BLOB) AS EcbSrc); 


 


-- Selection of the rates; insert only missing values. 


;WITH XMLNAMESPACES 


     ( 'http://www.gesmes.org/xml/2002-08-01' as gesmes 


      ,DEFAULT 'http://www.ecb.int/vocabulary/2002-08-01/eurofxref') 


,ecb AS 


   (SELECT Cubes.Rows.value('../@time', 'date') AS [ExcDate] 


          ,Cubes.Rows.value('@currency', 'char(3)') AS [Currency] 


          ,Cubes.Rows.value('@rate', 'decimal(19, 6)') AS [Rate] 


    FROM @ecb.nodes('/gesmes:Envelope/Cube/Cube/Cube') AS Cubes(Rows)) 



INSERT INTO dbo.EcbDailyExchangeRates 


    ([ExcDate] 


    ,[Currency] 


    ,[Rate]) 


SELECT ecb.[ExcDate] 


      ,ecb.[Currency] 


      ,ecb.[Rate] 


FROM ecb 


     LEFT JOIN dbo.EcbDailyExchangeRates AS Dst 


         ON Dst.ExcDate = ecb.ExcDate 


            AND Dst.Currency = ecb.Currency 


WHERE Dst.ExcDate IS NULL 


      AND NOT ecb.Currency IS NULL;



	  
