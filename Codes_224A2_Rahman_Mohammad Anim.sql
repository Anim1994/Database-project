/*******
Sample script for creating and populating tables for Assignment 2, ISYS224, 2018
*******/

/**
Drop old Tables
**/
DROP TABLE IF EXISTS T_Repayment;
DROP TABLE IF EXISTS T_Loan_Offset;
DROP TABLE IF EXISTS T_Loan;
DROP TABLE IF EXISTS T_Own;
DROP TABLE IF EXISTS T_Customer;
DROP TABLE IF EXISTS T_Account;
DROP TABLE IF EXISTS T_Loan_Type;
DROP TABLE IF EXISTS T_Acc_Type;


/**
Create Tables
**/

-- Customer --
CREATE TABLE T_Customer (
  CustomerID VARCHAR(10) NOT NULL,
  CustomerName VARCHAR(45) NULL,
  CustomerAddress VARCHAR(45) NULL,
  CustomerContactNo INT NULL,
  CustomerEmail VARCHAR(45) NULL,
  CustomerJoinDate DATETIME NULL,
  PRIMARY KEY (CustomerID));

-- Acc_Type --

CREATE TABLE IF NOT EXISTS T_Acc_Type (
  AccountTypeID VARCHAR(10) NOT NULL,
  TypeName SET('SAV','CHK','LON'),
  TypeDesc VARCHAR(45) NULL,
  TypeRate DECIMAL(4,2) NULL,
  TypeFee DECIMAL(2) NULL,
  PRIMARY KEY (AccountTypeID));
  
-- Account --

CREATE TABLE IF NOT EXISTS T_Account (
  BSB VARCHAR(10) NOT NULL,
  AccountNo VARCHAR(10) NOT NULL,
  AccountBal DECIMAL(10) NULL,
  AccountType VARCHAR(10) NOT NULL,
  PRIMARY KEY (BSB, AccountNo),
    FOREIGN KEY (AccountType)
    REFERENCES T_Acc_Type(AccountTypeID));


-- Loan_Type --

CREATE TABLE IF NOT EXISTS T_Loan_Type (
  LoanTypeID VARCHAR(10) NOT NULL,
  Loan_TypeName SET('HL','IL','PL'),
  Loan_TypeDesc VARCHAR(45) NULL,
  Loan_TypeMInRate DECIMAL(4,2) NULL,
  PRIMARY KEY (LoanTypeID));
  
-- Loan --

CREATE TABLE IF NOT EXISTS T_Loan (
  LoanID VARCHAR(10) NOT NULL,
  LoanRate DECIMAL(4,2) NULL,
  LoanAmount DECIMAL(8) NULL,
  Loan_Type VARCHAR(10) NOT NULL,
  Loan_AccountBSB VARCHAR(10) NOT NULL,
  Loan_AcctNo VARCHAR(10) NOT NULL,
  PRIMARY KEY (LoanID),
	FOREIGN KEY (Loan_Type)
    REFERENCES T_Loan_Type (LoanTypeID),
    FOREIGN KEY (Loan_AccountBSB , Loan_AcctNo)
    REFERENCES T_Account (BSB, AccountNo));

-- Repayment --

CREATE TABLE IF NOT EXISTS T_Repayment (
  RepaymentNo int NOT NULL AUTO_INCREMENT,
  Repayment_LoanID VARCHAR(10) NOT NULL,
  RepaymentAmount DECIMAL(6) NULL,
  RepaymentDate DATETIME NULL,
  PRIMARY KEY (RepaymentNo),
    FOREIGN KEY (Repayment_LoanID)
    REFERENCES T_Loan (LoanID));

-- Own --

CREATE TABLE IF NOT EXISTS T_Own (
  Customer_ID VARCHAR(10) NOT NULL,
  Account_BSB VARCHAR(10) NOT NULL,
  Account_No VARCHAR(10) NOT NULL,
  PRIMARY KEY (Customer_ID, Account_BSB, Account_No),
    FOREIGN KEY (Customer_ID)
    REFERENCES T_Customer (customerID),
    FOREIGN KEY (Account_BSB, Account_No)
    REFERENCES T_Account (BSB, AccountNo));
       
-- Offset Account --       

CREATE TABLE IF NOT EXISTS T_Loan_Offset(
	Loan_ID	VARCHAR (10) NOT NULL,	
    Offset_BSB VARCHAR (10) NOT NULL,
	Offset_AcctNo VARCHAR (10) NOT NULL,
    PRIMARY KEY (Loan_ID, Offset_BSB, Offset_AcctNo),
		FOREIGN KEY (Loan_ID)
		REFERENCES T_Loan (LoanID),
		FOREIGN KEY (Offset_BSB, Offset_AcctNo)
		REFERENCES T_Account (BSB, AccountNo));
/* 
Populate Tables
*/




INSERT INTO T_Customer VALUES ('C1','Adam','AdamHouse','234567891','aMail','2015-10-10');
INSERT INTO T_Customer VALUES ('C2','Badshah','BadshahPalace','234567892','bMail','2015-10-11');
INSERT INTO T_Customer VALUES ('C3','Chandni','ChandniBar','234567893','cMail','2015-10-12');

INSERT INTO T_Acc_Type VALUES ('AT1','SAV','Savings','0.1','15');
INSERT INTO T_Acc_Type VALUES ('AT2','CHK','Checking','0.2','16');
INSERT INTO T_Acc_Type VALUES ('AT3','LON','Loan','0','17');

INSERT INTO T_Account VALUES ('BSB1','Acct1','10.00','AT1');
INSERT INTO T_Account VALUES ('BSB2','Acct2','11.00','AT3');
INSERT INTO T_Account VALUES ('BSB3','Acct3','-5000','AT3');
INSERT INTO T_Account VALUES ('BSB3','Acct4','-7000','AT3');
INSERT INTO T_Account VALUES ('BSB1','Acct5','10.00','AT1');
INSERT INTO T_Account VALUES ('BSB1','Acct6','10.00','AT1');

INSERT INTO T_Loan_Type VALUES ('LT1','HL','Home Loan','0.01');
INSERT INTO T_Loan_Type VALUES ('LT2','IL','Investment Loan','0.02');
INSERT INTO T_Loan_Type VALUES ('LT3','PL','Personal Loan','0.03');

INSERT INTO T_Loan VALUES ('L1','0.05','5000.00','LT3','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L2','0.02','16200.00','LT2','BSB2','Acct2');
INSERT INTO T_Loan VALUES ('L3','0.03','670500.00','LT1','BSB3','Acct3');

INSERT INTO T_Repayment (Repayment_LoanID, RepaymentAmount, RepaymentDate)
       	VALUES ('L1','1.00','2017-10-10');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L2','2.00','2018-02-11');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L3','2.00','2018-02-11');

INSERT INTO T_Own VALUES ('C1','BSB2','Acct2');
INSERT INTO T_Own VALUES ('C2','BSB3','Acct3');
INSERT INTO T_Own VALUES ('C3','BSB3','Acct4');
INSERT INTO T_Own VALUES ('C1','BSB3','Acct4');
INSERT INTO T_Own VALUES ('C1','BSB1','Acct1');
INSERT INTO T_Own VALUES ('C2','BSB1','Acct5');
INSERT INTO T_Own VALUES ('C3','BSB1','Acct6');

INSERT INTO T_Loan_Offset VALUES ('L2', 'BSB1', 'Acct1');
INSERT INTO T_Loan_Offset VALUES ('L3', 'BSB1', 'Acct5');

/**
End Script
**/
/* task 2 */
Delimiter //
Drop procedure if exists Repay_loan //
Create procedure Repay_loan(IN from_BSB VARCHAR(10), IN from_accountNo VARCHAR(10) , IN to_loan VARCHAR(10), IN amount Decimal(10))
Begin   
	Declare msg VARCHAR (255);
	DECLARE found boolean DEFAULT False;
	Declare loan_customer varchar(10);
	Declare current_customer varchar(10);
	Declare tempamount decimal(10,0) Default 0;
	declare finished int default 0;

	declare customercurrent cursor for
	Select Customer_ID
	From T_Own
	Where from_BSB = Account_BSB AND from_accountNo = Account_No;
	
    declare get_customerid cursor for 
	Select Customer_ID 
	FROM T_Own
	Join T_Loan 
    ON T_Own.Account_BSB = T_Loan.Loan_AccountBSB AND T_Own.Account_No = T_Loan.Loan_AcctNo
    Where to_loan = T_Loan.LoanID;
    declare continue handler for not found
		Signal sqlstate '45000' SET MESSAGE_TEXT = "incorrect id for transaction";
		

    open customercurrent;
    while found = false DO
		fetch customercurrent into current_customer;
		open get_customerid;
			while found = false do
				fetch get_customerid into loan_customer;
				if loan_customer = current_customer then
					set found = true;
			end if;
        end while;
        close get_customerid;
	end while;
    close customercurrent;
    
	select accountbal into tempamount
	from T_Account
	where BSB = from_BSB AND AccountNo = from_accountNo;
        
	If tempamount < amount Then
		set msg = "Low Balance!";
		Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
	End if;
        
        
	Update T_Account
	SET accountbal = accountbal - amount
	where from_BSB = T_Account.BSB AND from_accountNo = T_Account.AccountNo ;
					
	insert into T_Repayment (Repayment_LoanID,RepaymentAmount,RepaymentDate)
    values(to_loan,amount, curdate());

End

//
Delimiter ;

call Repay_loan('BSB3', 'ACCT3', 'L2', 10); -- diff id
call Repay_loan('BSB2', 'ACCT2', 'L2', 10000); -- low bal
call Repay_loan('BSB2', 'ACCT2', 'L2', 5);
call Repay_loan('bsb3', 'acct3', 'L3',10);

select * from T_Repayment;
select * from T_Account;



-- task3
Delimiter //
Drop trigger IF EXISTS loanconcern //

Create Trigger loanconcern 
	Before Insert on T_Loan
	for each row
Begin
	declare customer varchar(10);
    declare customer_cursor_count int default 0;
    declare single_loan_cursor_count int default 0;
    declare single_loan_count int default 0;
    declare single_loan_BSB varchar(10);
    declare single_loan_Account varchar(10);
	declare total_loan_count int default 0;
    declare personal_loan_count int default 0;
    declare home_loan_count int default 0;
    declare total_loan_amount decimal(8,0) default 0;
    declare is_single_loan bool default false;
    declare msg varchar(255);
    
	declare customer_cursor cursor for 
		Select Customer_ID
        From T_Own
        Where new.Loan_AccountBSB = T_Own.Account_BSB AND new.Loan_AcctNo = T_Own.Account_No;
        
	declare single_loan_cursor cursor for
		Select Loan_AccountBSB, Loan_AcctNo
        From T_Loan, T_Own
        Where T_Loan.Loan_AccountBSB = T_Own.Account_BSB And T_Loan.Loan_AcctNo = T_Own.Account_No
		Group by T_Loan.LoanID
		Having count(T_Own.Customer_ID) = 1;
    
    open customer_cursor;
		select FOUND_ROWS() into customer_cursor_count;
        
        repeat
			fetch customer_cursor into customer;            
            open single_loan_cursor;
				Select FOUND_ROWS() into single_loan_cursor_count;
                Set single_loan_count = 0;
				repeat
					fetch single_loan_cursor into single_loan_BSB, single_loan_Account;
                    
                    If new.Loan_AccountBSB = single_loan_BSB
                    And new.Loan_AcctNo = single_loan_Account Then
						Set is_single_loan = True;
                    End If;
                    
					If customer = (Select Customer_ID
								   From T_Own
								   Where single_loan_BSB = T_Own.Account_BSB 
								   And single_loan_Account = T_Own.Account_No) Then
						Set single_loan_count = single_loan_count + 1;
					End If;
                    
                    Set single_loan_cursor_count = single_loan_cursor_count - 1;
				until single_loan_cursor_count = 0
                end repeat;
			close single_loan_cursor;
            
			Select count(LoanID) into total_loan_count
			From T_Loan, T_Own 
			where T_Loan.Loan_AccountBSB = T_Own.Account_BSB and T_Loan.Loan_AcctNo = T_Own.Account_No
			And Customer_ID  = customer;
			
            Select count(LoanID) into personal_loan_count
			From T_Loan, T_Own 
			where T_Loan.Loan_AccountBSB = T_Own.Account_BSB and T_Loan.Loan_AcctNo = T_Own.Account_No
			And Customer_ID  = customer and T_Loan.Loan_Type = 'LT3';
            
			Select count(LoanID) into home_loan_count
			From T_Loan, T_Own 
			where T_Loan.Loan_AccountBSB = T_Own.Account_BSB and T_Loan.Loan_AcctNo = T_Own.Account_No
			And Customer_ID  = customer and T_Loan.Loan_Type = 'LT1';
            
            Select sum(LoanAmount) into total_loan_amount
			From T_Loan, T_Own 
			where T_Loan.Loan_AccountBSB = T_Own.Account_BSB and T_Loan.Loan_AcctNo = T_Own.Account_No
			And Customer_ID  = customer;
            Set total_loan_amount = total_loan_amount + new.LoanAmount;
            
            If single_loan_count >= 5 And is_single_loan = True Then
				Set msg = "Individual loan limit reached!";
				Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
			End If;
            
            If total_loan_count >= 8 Then
				Set msg = "Total loan limit reached!";
				Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
			End If;
            
            If new.Loan_type = 'LT3' And personal_loan_count >= 1 Then
				Set msg = "Customer already has max(1) personal account loans!";
				Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
			End If;
            
            If new.Loan_type = 'LT1' And home_loan_count >= 3 Then
				Set msg = "Customer already has max(3) home account loans!";
				Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
			End If;
            
            If total_loan_amount > 10000000.00 Then
				Set msg = "Loan amount exceeds 10 million dollars!";
				Signal sqlstate '45000' SET MESSAGE_TEXT = msg;
			End If;
            
            Set customer_cursor_count = customer_cursor_count - 1;
		until customer_cursor_count = 0
		End repeat;
    close customer_cursor;
End 
//
Delimiter ;


-- Tests


-- limit 3 home loans
INSERT INTO T_Loan VALUES ('L100','0.02','1.00','LT1','BSB1','Acct5');
INSERT INTO T_Loan VALUES ('L15','0.02','1.00','LT1','BSB1','Acct5');
INSERT INTO T_Loan VALUES ('L50','0.02','1.00','LT1','BSB1','Acct5');
-- individual limit
INSERT INTO T_Loan VALUES ('L60','0.02','1.00','LT2','BSB1','Acct5');
INSERT INTO T_Loan VALUES ('L45','0.02','1.00','LT2','BSB1','Acct5');
INSERT INTO T_Loan VALUES ('L69','0.02','1.00','LT2','BSB1','Acct5');

-- limit 8 join test
INSERT INTO T_Loan VALUES ('L4','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L5','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L6','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L7','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L8','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L9','0.02','1.00','LT2','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L10','0.02','1.00','LT2','BSB3','Acct4');
-- personal loan
INSERT INTO T_Loan VALUES ('L84','0.02','1.00','LT3','BSB3','Acct3');
INSERT INTO T_Loan VALUES ('L46','0.02','1.00','LT3','BSB3','Acct3');

-- 10 million
INSERT INTO T_Loan VALUES ('L36','0.02','20000000.00','LT1','BSB1','Acct1');

-- task 4

Delimiter //
Drop procedure if exists Calculate_interest //
Create procedure Calculate_interest(IN loanID varchar(10), IN check_date datetime)
Begin  
	declare interest_amount decimal(14,10) default 0;
	declare interest_rate decimal(14,10) default 0;
    declare loan_amount decimal(50,10) default 0;
    declare offset_amount decimal(14,10) default 0;
    declare offset_count int default 0;
    declare loan_start_date datetime;
    declare loan_end_date datetime;
    declare date_cursor datetime;
	declare repayment_cursor_count int default 0;
    declare repayment_found bool default True;
	declare repayment_amount decimal(50,10) default 0;
    declare repayment_date datetime;
	declare repayment_cursor cursor for 
		select RepaymentAmount, RepaymentDate
		from T_Repayment
		where Repayment_LoanID = loanID;
    declare continue handler for not found
		set repayment_found = False;

    Select LoanRate into interest_rate
    From T_Loan
    Where T_Loan.LoanID = loanID;
    Set interest_rate = interest_rate / 365.00;
    
    Select AccountBal into loan_amount
    From T_Account, T_Loan
    Where T_Account.BSB = T_Loan.Loan_AccountBSB And T_Account.AccountNo = T_Loan.Loan_AcctNo
    And T_Loan.LoanID = loanID;
    
    Select count(offset_amount) into offset_count
    From T_Loan_Offset
    Where T_Loan_Offset.Loan_ID = loanID;
    
    If offset_count > 0 Then
		Select AccountBal into offset_amount
		From T_Account, T_Loan_Offset
		Where T_Account.BSB = T_Loan_Offset.Offset_BSB 
        And T_Account.AccountNo = T_Loan_Offset.Offset_AcctNo
		And T_Loan_Offset.Loan_ID = loanID;
        
		Set loan_amount = loan_amount + offset_amount;
    End If;
    
    Set loan_end_date = Date_Sub(check_date, Interval 1 Day);
    Set loan_start_date = Date_Sub(loan_end_date, Interval 30 Day);
    Set date_cursor = loan_start_date;
    
    If repayment_found = True Then
		open repayment_cursor;
			select FOUND_ROWS() into repayment_cursor_count;
			while repayment_cursor_count > 0 Do
				fetch repayment_cursor into repayment_amount, repayment_date;
				If repayment_date between loan_start_date and loan_end_date Then
					Set loan_amount = loan_amount - repayment_amount;  -- - repayment amount because I need to find the interest for loan start date where loan balance is already reduced due to repayment but since month to month calculation, this should not be taken in. Basically it balances things out. Hope it makes sense.
				End If;
				Set repayment_cursor_count = repayment_cursor_count - 1;
			end while;
		close repayment_cursor;
    End If;
    
    While date_cursor < loan_end_date Do
        open repayment_cursor;
			fetch repayment_cursor into repayment_amount, repayment_date;
            If repayment_date = date_cursor Then
				Set loan_amount = loan_amount + repayment_amount; -- + loan amount which is the account balance from T_Account is a negative number
			End If;
        close repayment_cursor;
        
        Set interest_amount = interest_amount + loan_amount * interest_rate;

		Set date_cursor = Date_Add(date_cursor, Interval 1 Day);
    End While;
    Select round(interest_amount,2) as 'total loan interest';
End 
//
DELIMITER ;

call Calculate_interest('L1', '2018-03-25');
call Calculate_interest('L2', '2018-05-25');
call Calculate_interest('L3', '2018-08-25');


