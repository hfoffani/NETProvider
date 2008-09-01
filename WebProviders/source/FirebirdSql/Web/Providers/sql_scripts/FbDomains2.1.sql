
SET SQL DIALECT 3;

SET NAMES UTF8;

CREATE DOMAIN WP_BLOB_TEXT AS
BLOB SUB_TYPE 1 ;

CREATE DOMAIN WP_BLOB_BINARY AS
BLOB SUB_TYPE 0 ;

CREATE DOMAIN WP_BOOL AS
SMALLINT
NOT NULL
CHECK (value=1 or value=0 or value is null);

CREATE DOMAIN WP_CHAR16_OCTETS AS
CHAR(16) CHARACTER SET OCTETS
NOT NULL;

CREATE DOMAIN WP_INTEGER AS
INTEGER;

CREATE DOMAIN WP_TIMESTAMP AS
TIMESTAMP;

CREATE DOMAIN WP_VARCHAR100 AS
VARCHAR(100);

CREATE DOMAIN WP_VARCHAR80_OCTETS AS
VARCHAR(80) CHARACTER SET OCTETS
NOT NULL;


