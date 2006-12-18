SET SQL DIALECT 3;

SET NAMES NONE;

CREATE DATABASE '127.0.0.1:C:\MEMBERSHIP_PROVIDER.FDB'
USER 'SYSDBA' PASSWORD 'masterkey'
PAGE_SIZE 4096
DEFAULT CHARACTER SET UNICODE_FSS;

CREATE DOMAIN BOOL AS
SMALLINT
NOT NULL
CHECK (value=1 or value=0 or value is null);

CREATE TABLE USERS (
    PKID                        CHAR(16) CHARACTER SET OCTETS NOT NULL,
    USERNAME                    VARCHAR(255) CHARACTER SET UNICODE_FSS NOT NULL,
    UPPERUSERNAME               VARCHAR(255) CHARACTER SET UNICODE_FSS,
    APPLICATIONNAME             VARCHAR(255) CHARACTER SET UNICODE_FSS NOT NULL,
    EMAIL                       VARCHAR(128) CHARACTER SET UNICODE_FSS NOT NULL,
    UPPEREMAIL                  VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT                     VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERPASSWORD                VARCHAR(128) CHARACTER SET UNICODE_FSS NOT NULL,
    PASSWORDSALT                VARCHAR(128) CHARACTER SET OCTETS,
    PASSWORDFORMAT              INTEGER,
    PASSWORDQUESTION            VARCHAR(255) CHARACTER SET UNICODE_FSS,
    PASSWORDANSWER              VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED                  BOOL /* BOOL = SMALLINT NOT NULL CHECK (value=1 or value=0 or value is null) */,
    LASTACTIVITYDATE            TIMESTAMP,
    LASTLOGINDATE               TIMESTAMP,
    LASTPASSWORDCHANGEDDATE     TIMESTAMP,
    CREATIONDATE                TIMESTAMP,
    ISONLINE                    BOOL /* BOOL = SMALLINT NOT NULL CHECK (value=1 or value=0 or value is null) */,
    ISLOCKEDOUT                 BOOL /* BOOL = SMALLINT NOT NULL CHECK (value=1 or value=0 or value is null) */,
    LASTLOCKEDOUTDATE           TIMESTAMP,
    FAILEDPASSWORDATTEMPTCOUNT  INTEGER,
    FAILEDPASSWORDATTEMPTSTART  TIMESTAMP,
    FAILEDPASSWORDANSWERCOUNT   INTEGER,
    FAILEDPASSWORDANSWERSTART   TIMESTAMP
);

ALTER TABLE USERS ADD PRIMARY KEY (PKID);

SET TERM ^ ;

CREATE PROCEDURE MEMBERSHIP_CREATEUSER (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERPASSWORD VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDSALT VARCHAR(128) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    PASSWORDANSWER VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    UNIQUEEMAIL SMALLINT,
    PASSWORDFORMAT INTEGER,
    USERID CHAR(16) CHARACTER SET OCTETS)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable newuserid char(16) character set octets;
BEGIN
 NEWUSERID = NULL;
 SELECT USERS.PKID FROM USERS WHERE USERS.UPPERUSERNAME = UPPER(:USERNAME) AND USERS.APPLICATIONNAME = :APPLICATIONNAME
 INTO :NEWUSERID;
 IF (:NEWUSERID IS NULL) THEN
 BEGIN
  IF ((:UNIQUEEMAIL = 1) AND ((EXISTS ( SELECT PKID FROM USERS WHERE UPPER(:EMAIL) = UPPEREMAIL)))) THEN
   RETURNCODE = 7;
  ELSE
  BEGIN
   INSERT INTO USERS
   (
    PKID,
    USERNAME, 
    UPPERUSERNAME,
    USERPASSWORD,
    EMAIL, 
    UPPEREMAIL,
    ISAPPROVED, 
    PASSWORDSALT,
    PASSWORDFORMAT,
    PASSWORDQUESTION,
    PASSWORDANSWER,
    APPLICATIONNAME,
    CREATIONDATE,
    LASTPASSWORDCHANGEDDATE,
    LASTACTIVITYDATE,
    ISLOCKEDOUT,
    ISONLINE,
    LASTLOCKEDOUTDATE,
    FAILEDPASSWORDATTEMPTCOUNT,
    FAILEDPASSWORDATTEMPTSTART,
    FAILEDPASSWORDANSWERCOUNT,
    FAILEDPASSWORDANSWERSTART
   )
   VALUES
   (
   :USERID,
   :USERNAME,
   UPPER(:USERNAME),
   :USERPASSWORD,
   :EMAIL,
   UPPER(:EMAIL),
   :ISAPPROVED,
   :PASSWORDSALT,
   :PASSWORDFORMAT,
   :passwordquestion,
   :passwordanswer,
   :APPLICATIONNAME,
   'NOW',
   'NOW',
   'NOW',
   0,
   0,
   'NOW',
   0,
   'NOW',
   0,
   'NOW'
   );
   RETURNCODE = 0;
  END
 END
 ELSE
  RETURNCODE = 6;

END^

CREATE PROCEDURE MEMBERSHIP_DELETEUSER (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    DELETEALLRELATEDDATA INTEGER)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable pkid char(16) character set octets;
declare variable uppername varchar(255) character set unicode_fss;
BEGIN
  SELECT PKID,UPPERUSERNAME FROM USERS WHERE UPPERUSERNAME = UPPER(:USERNAME) AND APPLICATIONNAME = :APPLICATIONNAME INTO :PKID,:UPPERNAME;
  IF (USERNAME IS NULL) THEN
     RETURNCODE = -1;
  ELSE
  BEGIN
   RETURNCODE = 1;
   DELETE FROM USERS WHERE PKID = :PKID;
   IF (DELETEALLRELATEDDATA = 1) THEN
   BEGIN
    DELETE FROM USERSINROLES WHERE UPPER(USERSINROLES.USERNAME) = :UPPERNAME AND APPLICATIONNAME = :APPLICATIONNAME;
    DELETE FROM PROFILES WHERE PROFILES.PKID = :PKID;
   END
  END

  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_FINDUSERSBYEMAIL (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAILTOMATCH VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PAGEINDEX INTEGER,
    PAGESIZE INTEGER)
RETURNS (
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    CREATIONDATE TIMESTAMP,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    LASTPASSWORDCHANGEDATE TIMESTAMP,
    PKID CHAR(16) CHARACTER SET OCTETS,
    ISLOCKEDOUT SMALLINT,
    LASTLOCKEDOUTDATE TIMESTAMP,
    TOTALRECORDS SMALLINT)
AS
DECLARE VARIABLE PAGELOWERBOUND INTEGER;
DECLARE VARIABLE PAGEUPPERBOUND INTEGER;
BEGIN
PAGELOWERBOUND = PAGESIZE * PAGEINDEX;
  PAGEUPPERBOUND = PAGESIZE;
 SELECT COUNT(1) FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME AND UPPEREMAIL LIKE UPPER(:EMAILTOMATCH) INTO :TOTALRECORDS;
 FOR SELECT FIRST(:PAGEUPPERBOUND) SKIP(:PAGELOWERBOUND)  USERNAME,EMAIL, PASSWORDQUESTION, COMMENT, ISAPPROVED,
            CREATIONDATE, LASTLOGINDATE, LASTACTIVITYDATE,
            LASTPASSWORDCHANGEDDATE,PKID, ISLOCKEDOUT,
            LASTLOCKEDOUTDATE
    FROM    USERS
    WHERE   APPLICATIONNAME = :APPLICATIONNAME AND UPPEREMAIL LIKE UPPER(:EMAILTOMATCH)
    ORDER BY USERNAME
    INTO :USERNAME,:EMAIL,:PASSWORDQUESTION,:COMMENT,:ISAPPROVED,:CREATIONDATE,:LASTLOGINDATE,
         :LASTACTIVITYDATE,:LASTPASSWORDCHANGEDATE,:PKID,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE
    DO
     SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_FINDUSERSBYNAME (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAMETOMATCH VARCHAR(255) CHARACTER SET UNICODE_FSS,
    PAGEINDEX INTEGER,
    PAGESIZE INTEGER)
RETURNS (
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    CREATIONDATE TIMESTAMP,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    LASTPASSWORDCHANGEDATE TIMESTAMP,
    PKID CHAR(16) CHARACTER SET OCTETS,
    ISLOCKEDOUT SMALLINT,
    LASTLOCKEDOUTDATE TIMESTAMP,
    TOTALRECORDS INTEGER)
AS
DECLARE VARIABLE PAGELOWERBOUND INTEGER;
DECLARE VARIABLE PAGEUPPERBOUND INTEGER;
BEGIN
PAGELOWERBOUND = PAGESIZE * PAGEINDEX;
  PAGEUPPERBOUND = PAGESIZE;
 SELECT COUNT(1) FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME AND UPPERUSERNAME LIKE UPPER(:USERNAMETOMATCH) INTO :TOTALRECORDS;
 FOR SELECT FIRST(:PAGEUPPERBOUND) SKIP(:PAGELOWERBOUND)  USERNAME,EMAIL, PASSWORDQUESTION, COMMENT, ISAPPROVED,
            CREATIONDATE, LASTLOGINDATE, LASTACTIVITYDATE,
            LASTPASSWORDCHANGEDDATE,PKID, ISLOCKEDOUT,
            LASTLOCKEDOUTDATE
    FROM    USERS
    WHERE   APPLICATIONNAME = :APPLICATIONNAME AND UPPERUSERNAME LIKE UPPER(:USERNAMETOMATCH)
    ORDER BY USERNAME
    INTO :USERNAME,:EMAIL,:PASSWORDQUESTION,:COMMENT,:ISAPPROVED,:CREATIONDATE,:LASTLOGINDATE,
         :LASTACTIVITYDATE,:LASTPASSWORDCHANGEDATE,:PKID,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE
    DO
     SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETALLUSERS (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    PAGEINDEX INTEGER,
    PAGESIZE INTEGER)
RETURNS (
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    CREATIONDATE TIMESTAMP,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    LASTPASSWORDCHANGEDATE TIMESTAMP,
    PKID CHAR(16) CHARACTER SET OCTETS,
    ISLOCKEDOUT SMALLINT,
    LASTLOCKEDOUTDATE TIMESTAMP,
    TOTALRECORDS SMALLINT)
AS
DECLARE VARIABLE PAGELOWERBOUND INTEGER;
DECLARE VARIABLE PAGEUPPERBOUND INTEGER;
BEGIN
PAGELOWERBOUND = PAGESIZE * PAGEINDEX;
  PAGEUPPERBOUND = PAGESIZE;
 SELECT COUNT(1) FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME INTO :TOTALRECORDS;
 FOR SELECT FIRST(:PAGEUPPERBOUND) SKIP(:PAGELOWERBOUND)  USERNAME,EMAIL, PASSWORDQUESTION, COMMENT, ISAPPROVED,
            CREATIONDATE, LASTLOGINDATE, LASTACTIVITYDATE,
            LASTPASSWORDCHANGEDDATE,PKID, ISLOCKEDOUT,
            LASTLOCKEDOUTDATE
    FROM    USERS
    WHERE   APPLICATIONNAME = :APPLICATIONNAME ORDER BY USERNAME
    INTO :USERNAME,:EMAIL,:PASSWORDQUESTION,:COMMENT,:ISAPPROVED,:CREATIONDATE,:LASTLOGINDATE,
         :LASTACTIVITYDATE,:LASTPASSWORDCHANGEDATE,:PKID,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE
    DO
     SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETPASSWORD (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    MAXINVALIDPASSWORDATTEMPTS INTEGER,
    PASSWORDATTEMPWINDOW INTEGER,
    REQUIRESQUESTIONANSWER INTEGER,
    PASSWORDANSWER VARCHAR(255) CHARACTER SET UNICODE_FSS)
RETURNS (
    USERPASSWORD VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDFORMAT INTEGER,
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set unicode_fss;
declare variable passwordanswer2 varchar(255) character set unicode_fss;
declare variable islockedout smallint;
declare variable lastlockedoutdate timestamp;
declare variable failedpasswordattemptcount integer;
declare variable failedpasswordattemptstart timestamp;
declare variable failedpasswordanswercount smallint;
declare variable failedpasswordanswerstart timestamp;
BEGIN
  SELECT PKID,USERPASSWORD,PASSWORDFORMAT, PASSWORDANSWER,ISLOCKEDOUT,LASTLOCKEDOUTDATE,FAILEDPASSWORDATTEMPTCOUNT,FAILEDPASSWORDATTEMPTSTART ,
  FAILEDPASSWORDANSWERCOUNT,FAILEDPASSWORDANSWERSTART
         FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME AND UPPERUSERNAME = UPPER(:USERNAME)
         INTO :USERID,:USERPASSWORD,:PASSWORDFORMAT,:PASSWORDANSWER2,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE,:FAILEDPASSWORDATTEMPTCOUNT,
              :FAILEDPASSWORDATTEMPTSTART,:FAILEDPASSWORDANSWERCOUNT,:FAILEDPASSWORDANSWERSTART;
   IF (USERID IS NULL) THEN
   BEGIN
    RETURNCODE = 1;
    SUSPEND;
    EXIT;
   END
   IF (ISLOCKEDOUT = 1) THEN
   BEGIN
    RETURNCODE = 99;
    SUSPEND;
    EXIT;
   END

   IF (REQUIRESQUESTIONANSWER = 1) THEN
   BEGIN
    IF ((:PASSWORDANSWER2 IS NULL) OR (UPPER(:PASSWORDANSWER2) <> UPPER(:PASSWORDANSWER)))  THEN
    BEGIN
     FAILEDPASSWORDANSWERSTART = 'NOW';
     FAILEDPASSWORDANSWERCOUNT = 1;
    END
    ELSE
    BEGIN
     FAILEDPASSWORDANSWERCOUNT = FAILEDPASSWORDANSWERCOUNT + 1 ;
     FAILEDPASSWORDANSWERSTART = 'NOW';
    END
    IF (FAILEDPASSWORDANSWERCOUNT > MAXINVALIDPASSWORDATTEMPTS) THEN
    BEGIN
     ISLOCKEDOUT = 1;
     LASTLOCKEDOUTDATE = 'NOW';
    END
    RETURNCODE = 3;
   END
   ELSE
   BEGIN
    IF  (FAILEDPASSWORDANSWERCOUNT > 0 ) THEN
     BEGIN
      FAILEDPASSWORDANSWERCOUNT = 0;
      FAILEDPASSWORDANSWERSTART = NULL;
     END
   END
   UPDATE USERS SET
   ISLOCKEDOUT = :ISLOCKEDOUT,
   LASTLOCKEDOUTDATE = :LASTLOCKEDOUTDATE,
   FAILEDPASSWORDATTEMPTCOUNT = :FAILEDPASSWORDATTEMPTCOUNT,
   FAILEDPASSWORDATTEMPTSTART = :FAILEDPASSWORDATTEMPTSTART,
   FAILEDPASSWORDANSWERCOUNT = :FAILEDPASSWORDANSWERCOUNT,
   FAILEDPASSWORDANSWERSTART = :FAILEDPASSWORDANSWERSTART
   WHERE PKID =:USERID;
   RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETPASSWORDANDFORMAT (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    UPDATELASTLOGINACTIVITYDATE SMALLINT)
RETURNS (
    USERPASSWORD VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDFORMAT INTEGER,
    PASSWORDSALT VARCHAR(128) CHARACTER SET UNICODE_FSS,
    FAILEDPASSWORDATTEMPDCOUNT INTEGER,
    FAILEDPASSWORDANSWERATTEMPCOUNT INTEGER,
    ISAPPROVED SMALLINT,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
declare variable islockedout smallint;
BEGIN
  SELECT PKID, ISLOCKEDOUT,USERPASSWORD,PASSWORDFORMAT,PASSWORDSALT, FAILEDPASSWORDATTEMPTCOUNT,FAILEDPASSWORDANSWERCOUNT,
         ISAPPROVED, LASTACTIVITYDATE, LASTLOGINDATE
         FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME AND UPPERUSERNAME = UPPER(:USERNAME)
         INTO :USERID,:ISLOCKEDOUT,:USERPASSWORD,:PASSWORDFORMAT,:PASSWORDSALT,:FAILEDPASSWORDATTEMPDCOUNT,
              :FAILEDPASSWORDANSWERATTEMPCOUNT,:ISAPPROVED,:LASTACTIVITYDATE,:LASTLOGINDATE;
   IF (USERID IS NULL) THEN
   BEGIN
    RETURNCODE = 1;
    SUSPEND;
    EXIT;
   END
   IF (ISLOCKEDOUT = 1) THEN
   BEGIN
    RETURNCODE = 99;
    SUSPEND;
    EXIT;
   END

   IF ((UPDATELASTLOGINACTIVITYDATE = 1) AND (ISAPPROVED = 1)) THEN
    BEGIN
        UPDATE  USERS
        SET     LASTLOGINDATE = 'NOW',
                LASTACTIVITYDATE = 'NOW'
        WHERE   PKID = :USERID;
    END
   RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETUSERBYEMAIL (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS)
RETURNS (
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    RETURNCODE INTEGER)
AS
BEGIN
  SELECT USERNAME FROM USERS WHERE UPPEREMAIL = UPPER(:EMAIL) AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERNAME;
  IF (USERNAME IS NULL) THEN
     RETURNCODE = 1;
  ELSE
    RETURNCODE = 0;

  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETUSERBYNAME (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    UPDATELASTACTIVITY INTEGER)
RETURNS (
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    CREATIONDATE TIMESTAMP,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    LASTPASSWORDCHANGEDATE TIMESTAMP,
    PKID CHAR(16) CHARACTER SET OCTETS,
    ISLOCKEDOUT SMALLINT,
    LASTLOCKEDOUTDATE TIMESTAMP,
    RETURNCODE INTEGER)
AS
BEGIN
SELECT PKID FROM USERS WHERE UPPERUSERNAME = UPPER(:USERNAME) AND APPLICATIONNAME = :APPLICATIONNAME INTO :PKID;
IF (PKID IS NULL) THEN
BEGIN
 RETURNCODE = -1;
 SUSPEND;
 EXIT;
END
IF ( UPDATELASTACTIVITY = 1 ) THEN
BEGIN
  UPDATE   USERS
  SET      LASTACTIVITYDATE = 'NOW'
  WHERE    PKID = :PKID;
END

    SELECT  EMAIL, PASSWORDQUESTION, COMMENT, ISAPPROVED,
            CREATIONDATE, LASTLOGINDATE, LASTACTIVITYDATE,
            LASTPASSWORDCHANGEDDATE, ISLOCKEDOUT,
            LASTLOCKEDOUTDATE
    FROM    USERS
    WHERE   PKID = :PKID
    INTO :EMAIL,:PASSWORDQUESTION,:COMMENT,:ISAPPROVED,:CREATIONDATE,:LASTLOGINDATE,
         :LASTACTIVITYDATE,:LASTPASSWORDCHANGEDATE,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE;
    RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETUSERBYUSERID (
    PKID CHAR(16) CHARACTER SET OCTETS,
    UPDATELASTACTIVITY INTEGER)
RETURNS (
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    CREATIONDATE TIMESTAMP,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    LASTPASSWORDCHANGEDATE TIMESTAMP,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISLOCKEDOUT SMALLINT,
    LASTLOCKEDOUTDATE TIMESTAMP,
    RETURNCODE INTEGER)
AS
BEGIN
IF ( UPDATELASTACTIVITY = 1 ) THEN
BEGIN
  UPDATE   USERS
  SET      LASTACTIVITYDATE = 'NOW'
  WHERE    PKID = :PKID;

  IF ( ROW_COUNT = 0 )  THEN
  BEGIN
   RETURNCODE =  -1;
   SUSPEND;
   EXIT;
  END
END

    SELECT  EMAIL, PASSWORDQUESTION, COMMENT, ISAPPROVED,
            CREATIONDATE, LASTLOGINDATE, LASTACTIVITYDATE,
            LASTPASSWORDCHANGEDDATE, USERNAME, ISLOCKEDOUT,
            LASTLOCKEDOUTDATE
    FROM    USERS
    WHERE   PKID = :PKID
    INTO :EMAIL,:PASSWORDQUESTION,:COMMENT,:ISAPPROVED,:CREATIONDATE,:LASTLOGINDATE,
         :LASTACTIVITYDATE,:LASTPASSWORDCHANGEDATE,:USERNAME,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE;

    IF ( ROW_COUNT = 0 )  THEN
    BEGIN
       RETURNCODE = -1;
       SUSPEND;
       EXIT;
    END

    RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_GETUSERSONLINE (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    SINCELASTINACTIVE TIMESTAMP)
RETURNS (
    NUMBERUSERS INTEGER)
AS
BEGIN
NUMBERUSERS = 0;
 SELECT COUNT(1) FROM USERS WHERE LASTACTIVITYDATE > :SINCELASTINACTIVE INTO :NUMBERUSERS;
 SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_PASSQUESTIONANSWER (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    NEWPASSWORDQUESTION VARCHAR(255) CHARACTER SET UNICODE_FSS,
    NEWPASSWORDANSWER VARCHAR(255) CHARACTER SET UNICODE_FSS)
RETURNS (
    RETURNCODE INTEGER)
AS
DECLARE VARIABLE USERID CHAR(16);
BEGIN
  USERID = NULL;
  SELECT PKID FROM USERS WHERE UPPER(USERNAME) = UPPERUSERNAME AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERID;
  IF (USERID IS NOT NULL) THEN
  BEGIN
   UPDATE USERS SET USERS.PASSWORDQUESTION = :NEWPASSWORDQUESTION,USERS.PASSWORDANSWER = :NEWPASSWORDANSWER
   WHERE USERS.PKID = :USERID;
   RETURNCODE = 0;
  END
  ELSE
  RETURNCODE = 1;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_RESETPASSWORD (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    NEWPASSWORD VARCHAR(128) CHARACTER SET UNICODE_FSS,
    MAXINVALIDPASSWORDATTEMPTS INTEGER,
    PASSWORDATTEMPTWINDOW INTEGER,
    PASSWORDSALT VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDFORMAT INTEGER,
    REQUIRESQUESTIONANDANSWER INTEGER,
    PASSWORDANSWER VARCHAR(255) CHARACTER SET UNICODE_FSS)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
DECLARE VARIABLE ISLOCKEDOUT INTEGER;
DECLARE VARIABLE LASTLOCKEDOUTDATE TIMESTAMP;
DECLARE VARIABLE FAILEDPASSWORDATTEMPTCOUNT INTEGER;
DECLARE VARIABLE FAILEDPASSWORDATTEMPTSTART TIMESTAMP;
DECLARE VARIABLE FAILEDPASSWORDANSWERCOUNT INTEGER;
DECLARE VARIABLE FAILEDPASSWORDANSWERSTART TIMESTAMP;
BEGIN
  USERID = NULL;
  SELECT PKID FROM USERS WHERE UPPER(:USERNAME) = UPPERUSERNAME AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERID;
  IF (USERID IS NOT NULL) THEN
  BEGIN
   SELECT ISLOCKEDOUT, LASTLOCKEDOUTDATE, FAILEDPASSWORDATTEMPTCOUNT, FAILEDPASSWORDATTEMPTSTART,
          FAILEDPASSWORDANSWERCOUNT , FAILEDPASSWORDANSWERSTART FROM USERS WHERE USERS.PKID =:USERID
          INTO :ISLOCKEDOUT,:LASTLOCKEDOUTDATE,:FAILEDPASSWORDATTEMPTCOUNT,:FAILEDPASSWORDATTEMPTSTART,
          :FAILEDPASSWORDANSWERCOUNT,:FAILEDPASSWORDANSWERSTART;
   IF (:ISLOCKEDOUT = 1) THEN
   BEGIN
   RETURNCODE = 99;
   SUSPEND;
   EXIT;
   END
   UPDATE USERS SET USERPASSWORD = :NEWPASSWORD, USERS.LASTPASSWORDCHANGEDDATE = 'NOW' , PASSWORDFORMAT = :PASSWORDFORMAT,
                    PASSWORDSALT = :PASSWORDSALT WHERE PKID = :USERID AND ((:REQUIRESQUESTIONANDANSWER = 0) OR (UPPER( PASSWORDANSWER ) = UPPER( :PASSWORDANSWER )));
   IF (ROW_COUNT = 0) THEN
   BEGIN
    IF (CAST('NOW' AS TIMESTAMP) > :FAILEDPASSWORDANSWERSTART + CAST(:PASSWORDATTEMPTWINDOW AS DOUBLE PRECISION)/1440.0) THEN
    BEGIN
     FAILEDPASSWORDANSWERSTART = 'NOW';
     FAILEDPASSWORDANSWERCOUNT = 1;
    END
    ELSE
    BEGIN
      FAILEDPASSWORDANSWERSTART = 'NOW';
      FAILEDPASSWORDANSWERCOUNT = FAILEDPASSWORDANSWERCOUNT + 1;
    END
    IF ( :FAILEDPASSWORDANSWERCOUNT >= :MAXINVALIDPASSWORDATTEMPTS ) THEN
    BEGIN
     ISLOCKEDOUT = 1;
     LASTLOCKEDOUTDATE = 'NOW';
    END
    RETURNCODE = 3;
   END
   ELSE
   BEGIN
    IF (:FAILEDPASSWORDANSWERCOUNT > 0) THEN
    BEGIN
     FAILEDPASSWORDANSWERCOUNT = 0;
     FAILEDPASSWORDANSWERSTART = 'NOW';
    END
   END
  END
  ELSE
  RETURNCODE = 1;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_SETPASSWORD (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    NEWPASSWORD VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDSALT VARCHAR(128) CHARACTER SET UNICODE_FSS,
    PASSWORDFORMAT INTEGER)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
BEGIN
  SELECT PKID FROM USERS WHERE UPPER(:USERNAME) = UPPERUSERNAME AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERID;
  IF (USERID IS NOT NULL) THEN
  BEGIN
   UPDATE USERS SET USERS.USERPASSWORD = :NEWPASSWORD,USERS.PASSWORDFORMAT = :PASSWORDFORMAT,USERS.PASSWORDSALT = :PASSWORDSALT,USERS.LASTPASSWORDCHANGEDDATE = 'NOW'
   WHERE USERS.PKID = :USERID;
   RETURNCODE = 0;
  END
  ELSE
  RETURNCODE = 1;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_UNLOCKUSER (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
BEGIN
  SELECT PKID FROM USERS WHERE UPPER(:USERNAME) = UPPERUSERNAME AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERID;
  IF (USERID IS NULL) THEN
  BEGIN
   RETURNCODE = 1;
   SUSPEND;
   EXIT;
  END

  UPDATE USERS
  SET USERS.ISLOCKEDOUT = 0,
  USERS.FAILEDPASSWORDATTEMPTCOUNT = 0,
  USERS.FAILEDPASSWORDATTEMPTSTART = 0,
  USERS.FAILEDPASSWORDANSWERCOUNT = 0,
  USERS.FAILEDPASSWORDANSWERSTART = 0,
  USERS.LASTLOCKEDOUTDATE = 0
  WHERE PKID = :USERID;

  RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_UPDATEUSER (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    EMAIL VARCHAR(128) CHARACTER SET UNICODE_FSS,
    COMMENT VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISAPPROVED SMALLINT,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP,
    UNIQUEEMAIL INTEGER)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
BEGIN
  SELECT PKID FROM USERS WHERE UPPER(:USERNAME) = UPPERUSERNAME AND APPLICATIONNAME = :APPLICATIONNAME INTO :USERID;
  IF (USERID IS NULL) THEN
  BEGIN
   RETURNCODE = 1;
   SUSPEND;
   EXIT;
  END

  IF (:UNIQUEEMAIL = 1) THEN
   IF (EXISTS(SELECT PKID FROM USERS WHERE APPLICATIONNAME = :APPLICATIONNAME AND PKID <> :USERID AND UPPEREMAIL = UPPER(:EMAIL))) THEN
   BEGIN
    RETURNCODE = 7;
    SUSPEND;
    EXIT;
   END
  UPDATE USERS
  SET USERS.LASTACTIVITYDATE = :LASTACTIVITYDATE,
  EMAIL = :EMAIL,
  UPPEREMAIL = UPPER(:EMAIL),
  COMMENT = :COMMENT,
  ISAPPROVED = :ISAPPROVED,
  LASTLOGINDATE = :LASTLOGINDATE
  WHERE PKID = :USERID;

  RETURNCODE = 0;
  SUSPEND;
END^

CREATE PROCEDURE MEMBERSHIP_UPDATEUSERINFO (
    APPLICATIONNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    USERNAME VARCHAR(255) CHARACTER SET UNICODE_FSS,
    ISPASSWORDCORRECT SMALLINT,
    UPDATELASTLOGINACTIVITYDATE INTEGER,
    MAXINVALIDPASSWORDATTEMPS INTEGER,
    PASSWORDATTEMPTWINDOW INTEGER,
    LASTLOGINDATE TIMESTAMP,
    LASTACTIVITYDATE TIMESTAMP)
RETURNS (
    RETURNCODE INTEGER)
AS
declare variable userid char(16) character set octets;
DECLARE VARIABLE ISAPPROVED INTEGER;
DECLARE VARIABLE ISLOCKEDOUT INTEGER;
DECLARE VARIABLE LASTLOCKEDOUTDATE TIMESTAMP;
DECLARE VARIABLE FAILEDPASSWORDATTEMPTCOUNT INTEGER;
DECLARE VARIABLE FAILEDPASSWORDATTEMPTSTART TIMESTAMP;
DECLARE VARIABLE FAILEDPASSWORDANSWERCOUNT INTEGER;
DECLARE VARIABLE FAILEDPASSWORDANSWERSTART TIMESTAMP;
BEGIN
  RETURNCODE = 0;
  SELECT PKID,ISAPPROVED, ISLOCKEDOUT,LASTLOCKEDOUTDATE,USERS.FAILEDPASSWORDATTEMPTCOUNT,
         USERS.FAILEDPASSWORDATTEMPTSTART,USERS.FAILEDPASSWORDANSWERCOUNT,USERS.FAILEDPASSWORDANSWERSTART
  FROM USERS  WHERE APPLICATIONNAME = :APPLICATIONNAME AND UPPERUSERNAME = UPPER(:USERNAME)
  INTO :USERID,:ISAPPROVED,:ISLOCKEDOUT,:LASTLOCKEDOUTDATE,:FAILEDPASSWORDATTEMPTCOUNT,:FAILEDPASSWORDATTEMPTSTART,
       :FAILEDPASSWORDANSWERCOUNT,:FAILEDPASSWORDANSWERSTART;

  IF (USERID IS NULL) THEN
  BEGIN
  RETURNCODE = 1;
  SUSPEND;
  EXIT;
  END
  IF (:ISLOCKEDOUT = 1) THEN
  BEGIN
  RETURNCODE = 99;
  SUSPEND;
  EXIT;
  END

  IF (ISPASSWORDCORRECT = 0) THEN
  BEGIN
  IF (CAST('NOW' AS TIMESTAMP) > FAILEDPASSWORDATTEMPTSTART + CAST(:PASSWORDATTEMPTWINDOW AS DOUBLE PRECISION)/1440.0) THEN
   BEGIN
    FAILEDPASSWORDATTEMPTSTART = 'NOW';
    FAILEDPASSWORDATTEMPTCOUNT = 1;
   END
   ELSE
   BEGIN
    FAILEDPASSWORDATTEMPTSTART = 'NOW';
    FAILEDPASSWORDATTEMPTCOUNT = FAILEDPASSWORDATTEMPTCOUNT + 1;
   END
   IF( FAILEDPASSWORDATTEMPTCOUNT >= MAXINVALIDPASSWORDATTEMPS )  THEN
   BEGIN
    ISLOCKEDOUT = 1;
    LASTLOCKEDOUTDATE = 'NOW';
   END

  END
  ELSE
  BEGIN
   IF ((FAILEDPASSWORDATTEMPTCOUNT > 0) OR (FAILEDPASSWORDANSWERCOUNT > 0) ) THEN
   BEGIN
    FAILEDPASSWORDATTEMPTCOUNT = 0;
    FAILEDPASSWORDATTEMPTSTART = NULL;
    FAILEDPASSWORDANSWERCOUNT = 0;
    FAILEDPASSWORDANSWERSTART = NULL;
    LASTLOCKEDOUTDATE = NULL;
   END
  END

  IF (UPDATELASTLOGINACTIVITYDATE = 1) THEN
  BEGIN
   UPDATE USERS SET
   LASTACTIVITYDATE = :LASTACTIVITYDATE,
   LASTLOGINDATE = :LASTLOGINDATE,
   ISLOCKEDOUT = :ISLOCKEDOUT,
   LASTLOCKEDOUTDATE = :LASTLOCKEDOUTDATE,
   FAILEDPASSWORDATTEMPTCOUNT = :FAILEDPASSWORDATTEMPTCOUNT,
   FAILEDPASSWORDATTEMPTSTART = :FAILEDPASSWORDATTEMPTSTART,
   FAILEDPASSWORDANSWERCOUNT = :FAILEDPASSWORDANSWERCOUNT,
   FAILEDPASSWORDANSWERSTART = :FAILEDPASSWORDANSWERSTART
   WHERE PKID = :USERID;
  END
  SUSPEND;
END^

SET TERM ; ^

GRANT SELECT,INSERT ON USERS TO PROCEDURE MEMBERSHIP_CREATEUSER;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_CREATEUSER TO SYSDBA;
GRANT SELECT,DELETE ON USERS TO PROCEDURE MEMBERSHIP_DELETEUSER;
GRANT SELECT,DELETE ON USERSINROLES TO PROCEDURE MEMBERSHIP_DELETEUSER;
GRANT SELECT,DELETE ON PROFILES TO PROCEDURE MEMBERSHIP_DELETEUSER;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_DELETEUSER TO SYSDBA;
GRANT SELECT ON USERS TO PROCEDURE MEMBERSHIP_FINDUSERSBYEMAIL;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_FINDUSERSBYEMAIL TO SYSDBA;
GRANT SELECT ON USERS TO PROCEDURE MEMBERSHIP_FINDUSERSBYNAME;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_FINDUSERSBYNAME TO SYSDBA;
GRANT SELECT ON USERS TO PROCEDURE MEMBERSHIP_GETALLUSERS;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETALLUSERS TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_GETPASSWORD;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETPASSWORD TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_GETPASSWORDANDFORMAT;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETPASSWORDANDFORMAT TO SYSDBA;
GRANT SELECT ON USERS TO PROCEDURE MEMBERSHIP_GETUSERBYEMAIL;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETUSERBYEMAIL TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_GETUSERBYNAME;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETUSERBYNAME TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_GETUSERBYUSERID;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETUSERBYUSERID TO SYSDBA;
GRANT SELECT ON USERS TO PROCEDURE MEMBERSHIP_GETUSERSONLINE;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_GETUSERSONLINE TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_PASSQUESTIONANSWER;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_PASSQUESTIONANSWER TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_RESETPASSWORD;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_RESETPASSWORD TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_SETPASSWORD;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_SETPASSWORD TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_UNLOCKUSER;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_UNLOCKUSER TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_UPDATEUSER;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_UPDATEUSER TO SYSDBA;
GRANT SELECT,UPDATE ON USERS TO PROCEDURE MEMBERSHIP_UPDATEUSERINFO;
GRANT EXECUTE ON PROCEDURE MEMBERSHIP_UPDATEUSERINFO TO SYSDBA;